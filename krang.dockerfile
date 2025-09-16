# =============================================================================
# BASE IMAGES
# =============================================================================
ARG GOLANG_BASE_IMAGE_VERSION=1.25-alpine  # Go version for building Terraform providers
ARG PYTHON_BASE_IMAGE_VERSION=3.13-alpine  # Python base image for Ansible and tools
ARG PYTHON_VERSION=3.13  # Python version for path consistency across platforms

# =============================================================================
# COMPONENT ENABLE/DISABLE FLAGS
# =============================================================================
# Main Tools
ARG ADD_TERRAFORM=true  # Enable/disable Terraform infrastructure tool
ARG ANSIBLE_PACKAGE_TYPE=full  # Ansible package type: full, core, none
ARG ADD_ANSIBLE_MITOGEN=true  # Enable Mitogen for Ansible performance boost

# Kubernetes Tools
ARG ADD_KUBECTL=true  # Enable Kubernetes CLI tool
ARG ADD_HELM=true  # Enable Kubernetes package manager
ARG ADD_YQ=true  # Enable YAML processor for Kubernetes

# Terraform Providers
ARG ADD_PROXMOX_PROVIDER=true  # Enable Proxmox VE Terraform provider
ARG ADD_DNS_PROVIDER=true  # Enable DNS Terraform provider
ARG ADD_LOCAL_PROVIDER=true  # Enable Local Terraform provider
ARG ADD_KEYCLOAK_PROVIDER=true  # Enable Keycloak Terraform provider

# =============================================================================
# VERSION CONFIGURATION
# =============================================================================
# Terraform
ARG TERRAFORM_VERSION=v1.13.2  # Terraform version to install

# Ansible
ARG ANSIBLE_FULL_VERSION=12.0.0  # Full Ansible package version
ARG ANSIBLE_CORE_VERSION=2.19.2  # Ansible core package version
ARG MITOGEN_VERSION=0.3.27  # Mitogen version for Ansible acceleration

# Kubernetes Tools
ARG KUBECTL_VERSION=v1.34.1  # Kubernetes CLI version
ARG HELM_VERSION=v3.19.0  # Helm package manager version
ARG YQ_VERSION=v4.47.2  # YAML processor version

# Terraform Providers
ARG PROXMOX_PROVIDER_VERSION=v3.0.2-rc04  # Proxmox provider version
ARG PROXMOX_API_VERSION=master  # Proxmox API version for provider
ARG DNS_PROVIDER_VERSION=v3.4.3  # DNS provider version
ARG LOCAL_PROVIDER_VERSION=v2.5.2  # Local provider version
ARG KEYCLOACK_PROVIDER_VERSION=v5.2.0  # Keycloak provider version

# =============================================================================
# OPTIONAL FEATURES
# =============================================================================
# System Utilities
ARG INSTALL_CUSTOM_UTILS=true  # Enable installation of custom system packages
ARG CUSTOM_UTILS_PACKAGES="jq"  # Space-separated list of custom packages to install

# Python Packages
ARG INSTALL_CUSTOM_PIP_UTILS=true  # Enable installation of custom Python packages
ARG CUSTOM_PIP_PACKAGES=""  # Space-separated list of custom pip packages

# SSL Certificates
ARG INSTALL_CUSTOM_CA_SSL_CERT=true  # Enable custom CA certificate installation
ARG CA_CERT_URL=https://ca.example.com:8443/roots.pem  # URL to custom CA certificate

# =============================================================================
# BUILD STAGES
# =============================================================================
# Stage 0: Build Base image for Go builds
FROM golang:${GOLANG_BASE_IMAGE_VERSION} AS go-base
ENV CGO_ENABLED=0 \
    GOOS=linux \
    GOARCH=amd64 \
    GOMAXPROCS=$(nproc) \
    GO111MODULE=on \
    GOPROXY=https://proxy.golang.org,direct \
    GOSUMDB=sum.golang.org \
    GOCACHE=/tmp/go-cache \
    GOMODCACHE=/tmp/go-mod-cache

RUN mkdir -p /tmp/go-cache /tmp/go-mod-cache && \
    apk add --no-cache git ca-certificates openssh-client && \
    mkdir -p ~/.ssh && \
    ssh-keygen -t rsa -C "user.email" -N "" -f ~/.ssh/id_rsa && \
    ssh-keyscan -t rsa github.com >> ~/.ssh/known_hosts && \
    git config --global http.postBuffer 1572864000 && \
    git config --global pack.window 1

# Stage 1: Build Terraform
FROM go-base AS build-terraform
ARG TERRAFORM_VERSION

RUN git clone -b "${TERRAFORM_VERSION}" --depth=1 https://github.com/hashicorp/terraform.git /src
WORKDIR /src

RUN go build -ldflags="-s -w" -trimpath -buildmode=default -o /usr/local/bin/terraform .

# Stage 2: Build Proxmox Provider v3.x.x
FROM go-base AS build-telmate-proxmox
ARG PROXMOX_PROVIDER_VERSION
ARG PROXMOX_API_VERSION

RUN git clone https://github.com/Telmate/terraform-provider-proxmox.git -b ${PROXMOX_PROVIDER_VERSION} --depth=1 && \
    git clone https://github.com/Telmate/proxmox-api-go.git -b ${PROXMOX_API_VERSION} --depth=1

WORKDIR /go/proxmox-api-go
RUN go build -ldflags="-s -w" -trimpath -o /usr/local/bin/proxmox-api-go .

WORKDIR /go/terraform-provider-proxmox
RUN go build -ldflags="-s -w" -trimpath -o /usr/local/bin/terraform-provider-proxmox .

# Stage 3: Build DNS Provider
FROM go-base AS build-dns-hashicorp
ARG DNS_PROVIDER_VERSION

RUN git clone https://github.com/hashicorp/terraform-provider-dns.git -b ${DNS_PROVIDER_VERSION} --depth=1
WORKDIR /go/terraform-provider-dns
RUN go build -ldflags="-s -w" -trimpath -o /usr/local/bin/terraform-provider-dns .

# Stage 4: Build Local Provider
FROM go-base AS build-local-hashicorp
ARG LOCAL_PROVIDER_VERSION

RUN git clone https://github.com/hashicorp/terraform-provider-local.git -b ${LOCAL_PROVIDER_VERSION} --depth=1
WORKDIR /go/terraform-provider-local
RUN go build -ldflags="-s -w" -trimpath -o /usr/local/bin/terraform-provider-local .

# Stage 5: Build Keycloak Provider
FROM go-base AS build-keycloak-provider
ARG KEYCLOACK_PROVIDER_VERSION

RUN git clone https://github.com/keycloak/terraform-provider-keycloak.git
WORKDIR /go/terraform-provider-keycloak
RUN git checkout tags/${KEYCLOACK_PROVIDER_VERSION} -b ${KEYCLOACK_PROVIDER_VERSION}
RUN go build -ldflags="-s -w" -trimpath -o /usr/local/bin/terraform-provider-keycloak .

# Stage 6: Build kubectl
FROM go-base AS build-kubectl
ARG KUBECTL_VERSION
RUN git clone https://github.com/kubernetes/kubernetes.git --depth=1 --branch ${KUBECTL_VERSION} /src/kubernetes
WORKDIR /src/kubernetes
RUN go build -ldflags="-s -w" -trimpath -o /usr/local/bin/kubectl ./cmd/kubectl

# Stage 7: Build Helm
FROM go-base AS build-helm
ARG HELM_VERSION
RUN git clone https://github.com/helm/helm.git --depth=1 --branch ${HELM_VERSION} /src/helm
WORKDIR /src/helm
RUN go build -ldflags="-s -w" -trimpath -o /usr/local/bin/helm ./cmd/helm

# Stage 8: Build yq
FROM go-base AS build-yq
ARG YQ_VERSION
RUN git clone https://github.com/mikefarah/yq.git --depth=1 --branch ${YQ_VERSION} /src/yq
WORKDIR /src/yq
RUN go build -ldflags="-s -w" -trimpath -o /usr/local/bin/yq .

# Stage 9: Copy all binaries to intermediate layer
FROM alpine:3.19 AS binaries

# Add all ARG variables for conditional logic
ARG ADD_TERRAFORM
ARG ADD_KUBECTL
ARG ADD_HELM
ARG ADD_YQ
ARG ADD_PROXMOX_PROVIDER
ARG ADD_DNS_PROVIDER
ARG ADD_LOCAL_PROVIDER
ARG ADD_KEYCLOAK_PROVIDER

# Copy all binaries to /tmp/opt for organization
COPY --from=build-terraform /usr/local/bin/terraform /tmp/opt/usr/local/bin/
COPY --from=build-kubectl /usr/local/bin/kubectl /tmp/opt/usr/local/bin/
COPY --from=build-helm /usr/local/bin/helm /tmp/opt/usr/local/bin/
COPY --from=build-yq /usr/local/bin/yq /tmp/opt/usr/local/bin/
COPY --from=build-telmate-proxmox /usr/local/bin/terraform-provider-proxmox /tmp/opt/usr/local/bin/terraform-provider-proxmox
COPY --from=build-dns-hashicorp /usr/local/bin/terraform-provider-dns /tmp/opt/usr/local/bin/terraform-provider-dns
COPY --from=build-local-hashicorp /usr/local/bin/terraform-provider-local /tmp/opt/usr/local/bin/terraform-provider-local
COPY --from=build-keycloak-provider /usr/local/bin/terraform-provider-keycloak /tmp/opt/usr/local/bin/terraform-provider-keycloak

# Remove components based on flags
RUN if [ "${ADD_KUBECTL}" = "false" ]; then rm -rf /tmp/opt/usr/local/bin/kubectl; fi && \
    if [ "${ADD_HELM}" = "false" ]; then rm -rf /tmp/opt/usr/local/bin/helm; fi && \
    if [ "${ADD_YQ}" = "false" ]; then rm -rf /tmp/opt/usr/local/bin/yq; fi && \
    if [ "${ADD_TERRAFORM}" = "false" ]; then \
        rm -rf /tmp/opt/usr/local/bin/terraform /tmp/opt/usr/local/bin/terraform-provider-*; \
    else \
        if [ "${ADD_PROXMOX_PROVIDER}" = "false" ]; then rm -rf /tmp/opt/usr/local/bin/terraform-provider-proxmox; fi && \
        if [ "${ADD_DNS_PROVIDER}" = "false" ]; then rm -rf /tmp/opt/usr/local/bin/terraform-provider-dns; fi && \
        if [ "${ADD_LOCAL_PROVIDER}" = "false" ]; then rm -rf /tmp/opt/usr/local/bin/terraform-provider-local; fi && \
        if [ "${ADD_KEYCLOAK_PROVIDER}" = "false" ]; then rm -rf /tmp/opt/usr/local/bin/terraform-provider-keycloak; fi; \
    fi

# Stage 10: Build Final Image
FROM python:${PYTHON_BASE_IMAGE_VERSION} AS krang
ARG ANSIBLE_PACKAGE_TYPE
ARG ANSIBLE_FULL_VERSION
ARG ANSIBLE_CORE_VERSION
ARG MITOGEN_VERSION
ARG ADD_HELM
ARG ADD_KUBECTL
ARG ADD_YQ
ARG ADD_PROXMOX_PROVIDER
ARG ADD_DNS_PROVIDER
ARG ADD_LOCAL_PROVIDER
ARG ADD_KEYCLOAK_PROVIDER
ARG ADD_TERRAFORM
ARG ADD_ANSIBLE_MITOGEN
ARG MITOGEN_VERSION
ARG PROXMOX_PROVIDER_VERSION
ARG DNS_PROVIDER_VERSION
ARG LOCAL_PROVIDER_VERSION
ARG KEYCLOACK_PROVIDER_VERSION
ARG KUBECTL_VERSION
ARG HELM_VERSION
ARG YQ_VERSION
ARG INSTALL_CUSTOM_UTILS
ARG CUSTOM_UTILS_PACKAGES
ARG INSTALL_CUSTOM_CA_SSL_CERT
ARG PYTHON_VERSION
ARG CA_CERT_URL

# Copy all binaries
COPY --from=binaries /tmp/opt/usr/local/bin/ /usr/local/bin/

# Install dependencies and Python packages
RUN apk add --no-cache bash curl sshpass openssh-client git ; \
    if [ "${ADD_ANSIBLE_MITOGEN}" = "true" ]; then \
        pip install --no-cache-dir mitogen=="${MITOGEN_VERSION}"; \
    fi ; \
    # Install custom utilities if enabled
    if [ "${INSTALL_CUSTOM_UTILS}" = "true" ]; then \
        apk add --no-cache "${CUSTOM_UTILS_PACKAGES}"; \
    fi ; \
    # Install Ansible based on package type
    if [ "${ANSIBLE_PACKAGE_TYPE}" = "core" ]; then \
        pip install --no-cache-dir pyOpenSSL ansible-core=="${ANSIBLE_CORE_VERSION}" pyyaml jmespath; \
    elif [ "${ANSIBLE_PACKAGE_TYPE}" = "full" ]; then \
        pip install --no-cache-dir pyOpenSSL ansible=="${ANSIBLE_FULL_VERSION}" pyyaml jmespath; \
    elif [ "${ANSIBLE_PACKAGE_TYPE}" = "none" ]; then \
        pip install --no-cache-dir pyOpenSSL pyyaml jmespath; \
    fi ; \
    # Install custom Python packages if enabled
    if [ "${INSTALL_CUSTOM_PIP_UTILS}" = "true" ]; then \
        pip install --no-cache-dir "${CUSTOM_PIP_PACKAGES}"; \
    fi ; \    
    # Install Custom CA SSL certificates
    if [ "${INSTALL_CUSTOM_CA_SSL_CERT}" = "true" ]; then \
        curl -k "${CA_CERT_URL}" -o /usr/local/share/ca-certificates/custom_ca.crt && update-ca-certificates; \
    fi ; \
    # Create Terraform plugin directories and links only if Terraform is enabled
    if [ "${ADD_TERRAFORM}" = "true" ]; then \
        # Create plugin directories
        if [ "${ADD_PROXMOX_PROVIDER}" = "true" ]; then \
            mkdir -p /root/.terraform.d/plugins/registry.terraform.io/telmate/proxmox/$(echo "${PROXMOX_PROVIDER_VERSION}" | sed 's/^v//')/linux_amd64/; \
        fi ; \
        if [ "${ADD_DNS_PROVIDER}" = "true" ]; then \
            mkdir -p /root/.terraform.d/plugins/registry.terraform.io/hashicorp/dns/$(echo "${DNS_PROVIDER_VERSION}" | sed 's/^v//')/linux_amd64/; \
        fi ; \
        if [ "${ADD_LOCAL_PROVIDER}" = "true" ]; then \
            mkdir -p /root/.terraform.d/plugins/registry.terraform.io/hashicorp/local/$(echo "${LOCAL_PROVIDER_VERSION}" | sed 's/^v//')/linux_amd64/; \
        fi ; \
        if [ "${ADD_KEYCLOAK_PROVIDER}" = "true" ]; then \
            mkdir -p /root/.terraform.d/plugins/registry.terraform.io/keycloak/keycloak/$(echo "${KEYCLOACK_PROVIDER_VERSION}" | sed 's/^v//')/linux_amd64/; \
        fi ; \
        # Create plugin links
        if [ "${ADD_PROXMOX_PROVIDER}" = "true" ]; then \
            ln -sf /usr/local/bin/terraform-provider-proxmox /root/.terraform.d/plugins/registry.terraform.io/telmate/proxmox/$(echo ${PROXMOX_PROVIDER_VERSION} | sed 's/^v//')/linux_amd64/terraform-provider-proxmox; \
        fi ; \
        if [ "${ADD_DNS_PROVIDER}" = "true" ]; then \
            ln -sf /usr/local/bin/terraform-provider-dns /root/.terraform.d/plugins/registry.terraform.io/hashicorp/dns/$(echo ${DNS_PROVIDER_VERSION} | sed 's/^v//')/linux_amd64/terraform-provider-dns; \
        fi ; \
        if [ "${ADD_LOCAL_PROVIDER}" = "true" ]; then \
            ln -sf /usr/local/bin/terraform-provider-local /root/.terraform.d/plugins/registry.terraform.io/hashicorp/local/$(echo ${LOCAL_PROVIDER_VERSION} | sed 's/^v//')/linux_amd64/terraform-provider-local; \
        fi ; \
        if [ "${ADD_KEYCLOAK_PROVIDER}" = "true" ]; then \
            ln -sf /usr/local/bin/terraform-provider-keycloak /root/.terraform.d/plugins/registry.terraform.io/keycloak/keycloak/$(echo ${KEYCLOACK_PROVIDER_VERSION} | sed 's/^v//')/linux_amd64/terraform-provider-keycloak; \
        fi; \
    fi ; \ 
    # Remove build dependencies immediately
    apk del gcc libc-dev libffi-dev ; \
    # Remove GCC directories to reduce size
    rm -rf /usr/libexec/gcc /usr/lib/gcc ; \
    # Clear caches
    pip cache purge ; rm -rf /var/cache/apk/* ; \
    # Remove unused Ansible collections
    cd /usr/local/lib/python"${PYTHON_VERSION}"/site-packages/ansible_collections/ ; \
    rm -rf grafana microsoft telekom_mms hitachivantara ieisystem kaytus fortinet cisco dellemc netapp f5networks azure arista junipernetworks vyos ovirt purestorage vmware inspur \ 
    netapp_eseries amazon openstack ngine_io awx theforeman check_point ibm wti sensu t_systems_mms mellanox hetzner chocolatey cloudscale_ch frr infinidat netbox servicenow vultr \ 
    cloud cyberark gluster hpe infoblox lowlydba openvswitch splunk google ansible/windows ansible/netcommon containers/podman ; \
    # Clean community collections
    cd /usr/local/lib/python"${PYTHON_VERSION}"/site-packages/ansible_collections/community/ ; \
    rm -rf aws vmware azure zabbix windows mongodb fortios postgresql digitalocean okd grafana mysql microsoft telekom_mms rabbitmq proxysql hrobot \
    hashi_vault sops libvirt routeros ; \
    rm -rf /usr/local/lib/python"${PYTHON_VERSION}"/ensurepip/_bundled /usr/local/lib/python"${PYTHON_VERSION}"/idlelib ; \
    # Remove Python test files and directories
    cd /usr/local/lib/python"${PYTHON_VERSION}" ; \
    # Remove documentation from Python packages
    cd site-packages ; \
    find . -name "docs" -type d -exec rm -rf {} + ; \
    find . -name "doc" -type d -exec rm -rf {} + ; \
    # Remove unnecessary files
    cd /usr/local/lib/python"${PYTHON_VERSION}" ; \
    rm -rf test tests lib2to3 tkinter unittest ; \
    # Remove documentation, man pages, locale data and additional unnecessary files
    rm -rf /usr/share/zoneinfo /usr/share/doc /usr/share/man /usr/share/info /usr/share/locale /usr/share/terminfo /usr/share/tabset ; \
    # Strip binaries to reduce size
    strip /usr/local/bin/terraform* 2>/dev/null || true ; \
    # Final aggressive cleanup of all cache and temporary files
    find / -name "*.pyc" -delete 2>/dev/null || true ; \
    find / -name "__pycache__" -type d -exec rm -rf {} + 2>/dev/null || true ; \
    find / -name "*.pyo" -delete 2>/dev/null || true ; \
    find / -name "*.pyd" -delete 2>/dev/null || true ; \
    find / -name "*.py[co]" -delete 2>/dev/null || true ; \
    rm -rf /tmp/* /root/.cache /var/cache/* /usr/share/cache/* 2>/dev/null || true
CMD ["/bin/bash"]
