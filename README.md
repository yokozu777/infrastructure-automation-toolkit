# 🚀 Krang - Enterprise Infrastructure Automation Toolkit

[![Docker](https://img.shields.io/badge/Docker-2496ED?style=for-the-badge&logo=docker&logoColor=white)](https://hub.docker.com)
[![Alpine Linux](https://img.shields.io/badge/Alpine_Linux-0D597F?style=for-the-badge&logo=alpine-linux&logoColor=white)](https://alpinelinux.org)
[![Terraform](https://img.shields.io/badge/Terraform-7B42BC?style=for-the-badge&logo=terraform&logoColor=white)](https://terraform.io)
[![Ansible](https://img.shields.io/badge/Ansible-EE0000?style=for-the-badge&logo=ansible&logoColor=white)](https://ansible.com)
[![Kubernetes](https://img.shields.io/badge/Kubernetes-326CE5?style=for-the-badge&logo=kubernetes&logoColor=white)](https://kubernetes.io)
[![Helm](https://img.shields.io/badge/Helm-0F1689?style=for-the-badge&logo=helm&logoColor=white)](https://helm.sh)

## Description

**Krang** is a highly optimized Docker image for enterprise-level infrastructure automation. It combines powerful tools for infrastructure management: Terraform, Ansible, Kubernetes tools, and much more in a single, lightweight container.

**All components are built from source code**, giving you complete control over versions and ensuring the latest features and security patches. You can specify exact versions for each tool according to your requirements.

**Perfect for restricted environments** - when Terraform and its providers are blocked from download, this image provides a complete solution with all tools pre-compiled and ready to use.

**Curated provider selection** - includes the most commonly used Terraform providers (Proxmox, DNS, Local, Keycloak) based on real-world usage patterns. Need additional providers? Just request them and they'll be added in future updates.

## v1.0.0

### Features
- **Source-based builds** - All tools compiled from source for maximum control
- **Version flexibility** - Specify exact versions for each component
- **Offline-ready** - No internet required for Terraform provider downloads
- **Package managers included** - Full pip and apk access for additional tools
- **Highly parameterized** - Every component can be enabled/disabled via build arguments
- **Custom SSL certificates** - Support for corporate CA certificates via build args
- Multi-stage Docker build with aggressive optimization
- Conditional component installation for minimal image size

### Compatibility
- Docker BuildKit support

### Tested Platforms
The Docker image build process has been thoroughly tested and verified on:
- **Windows** with Docker Desktop - Docker image build tested
- **Linux Ubuntu 24.04** via Jenkins CI/CD - Docker image build tested
- **Oracle Linux 10** via Jenkins CI/CD - Docker image build tested

All Docker builds produce consistent, working images across different platforms and build environments.

## Quickstart

### Clone the repository:
```bash
git clone https://github.com/yokozu777/infrastructure-automation-toolkit.git
cd infrastructure-automation-toolkit
```
### Important: Configure ARG Variables First
Before building, **edit the `krang.dockerfile` file** to set the default ARG values according to your specific requirements:

**Why configure ARG variables?**
- **Consistent builds** - Same configuration every time
- **Team collaboration** - Everyone uses the same defaults
- **CI/CD integration** - No need to specify all args in pipeline
- **Documentation** - Clear record of your preferred configuration

### Basic build:
```bash
docker build -t krang:latest .
```

### Run the container:
```bash
docker run -it --rm krang:latest /bin/bash
```

## Complete ARG Variables Reference

### Base Images Configuration
```dockerfile
ARG GOLANG_BASE_IMAGE_VERSION=1.25-alpine  # Go version for building Terraform providers
ARG PYTHON_BASE_IMAGE_VERSION=3.13-alpine  # Python base image for Ansible and tools
ARG PYTHON_VERSION=3.13  # Python version for path consistency across platforms
```

### Component Enable/Disable Flags
```dockerfile
# Main Tools
ARG ADD_TERRAFORM=true  # Enable/disable Terraform infrastructure tool
ARG ANSIBLE_PACKAGE_TYPE=full  # Ansible package type: full, core, none
ARG ADD_ANSIBLE_MITOGEN=true  # Enable Mitogen for Ansible performance boost
# Git is always included by default - no ARG needed

# Kubernetes Tools
ARG ADD_KUBECTL=true  # Enable Kubernetes CLI tool
ARG ADD_HELM=true  # Enable Kubernetes package manager
ARG ADD_YQ=true  # Enable YAML processor for Kubernetes

# Terraform Providers
ARG ADD_PROXMOX_PROVIDER=true  # Enable Proxmox VE Terraform provider
ARG ADD_DNS_PROVIDER=true  # Enable DNS Terraform provider
ARG ADD_LOCAL_PROVIDER=true  # Enable Local Terraform provider
ARG ADD_KEYCLOAK_PROVIDER=true  # Enable Keycloak Terraform provider
```

### Version Configuration
```dockerfile
# Terraform
ARG TERRAFORM_VERSION=v1.13.2  # Terraform version to install

# Ansible
ARG ANSIBLE_FULL_VERSION=12.0.0  # Full Ansible package version
ARG ANSIBLE_CORE_VERSION=2.19.2  # Ansible core package version

# Mitogen
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
```

### Optional Features
```dockerfile
# System Utilities
ARG INSTALL_CUSTOM_UTILS=true  # Enable installation of custom system packages
ARG CUSTOM_UTILS_PACKAGES="jq"  # Space-separated list of custom packages to install

# Python Packages
ARG INSTALL_CUSTOM_PIP_UTILS=true  # Enable installation of custom Python packages
ARG CUSTOM_PIP_PACKAGES=""  # Space-separated list of custom pip packages

# SSL Certificates
ARG INSTALL_CUSTOM_CA_SSL_CERT=true  # Enable custom CA certificate installation
ARG CA_CERT_URL=https://ca.example.com:8443/roots.pem  # URL to custom CA certificate
```

### ARG Variables Usage Examples

#### Minimal Build (Ansible core only)
```bash
docker build \
  --build-arg ANSIBLE_PACKAGE_TYPE=core \
  --build-arg ADD_TERRAFORM=false \
  --build-arg ADD_KUBECTL=false \
  --build-arg ADD_HELM=false \
  --build-arg ADD_YQ=false \
  -t krang:minimal .
```

#### Kubernetes Focus
```bash
docker build \
  --build-arg ANSIBLE_PACKAGE_TYPE=none \
  --build-arg ADD_TERRAFORM=false \
  --build-arg ADD_KUBECTL=true \
  --build-arg ADD_HELM=true \
  --build-arg ADD_YQ=true \
  -t krang:k8s .
```

#### Custom Versions
```bash
docker build \
  --build-arg TERRAFORM_VERSION=v1.14.0 \
  --build-arg ANSIBLE_FULL_VERSION=11.0.0 \
  --build-arg KUBECTL_VERSION=v1.35.0 \
  --build-arg HELM_VERSION=v3.20.0 \
  -t krang:custom-versions .
```

#### Corporate Environment
```bash
docker build \
  --build-arg INSTALL_CUSTOM_CA_SSL_CERT=true \
  --build-arg CA_CERT_URL=https://your-ca.company.com/ca.pem \
  --build-arg CUSTOM_UTILS_PACKAGES="vim nano htop tree" \
  --build-arg CUSTOM_PIP_PACKAGES="awscli azure-cli" \
  -t krang:corporate .
```

## Package Managers and Extensibility

### Custom Package Installation
You can extend the image with additional packages during build:

```bash
# Build with custom packages
docker build \
  --build-arg CUSTOM_UTILS_PACKAGES='vim nano htop tree curl wget' \
  --build-arg CUSTOM_PIP_PACKAGES='awscli azure-cli boto3' \
  -t krang:extended .
```

### Custom SSL Certificates
Support for corporate CA certificates:

```bash
# Build with custom CA certificate
docker build \
  --build-arg INSTALL_CUSTOM_CA_SSL_CERT=true \
  --build-arg CA_CERT_URL=https://your-ca.company.com/ca.pem \
  -t krang:corporate .
```

### Provider Requests
Need additional Terraform providers? The current selection includes the most commonly used ones:
- **Proxmox** - Virtualization platform management
- **DNS** - DNS record management
- **Local** - Local file operations
- **Keycloak** - Identity and access management

**Request new providers** by creating an issue in the GitLab repository. Popular requests will be added in future updates.

### Future Enhancements
- **Multi-architecture builds** - If needed, support for additional architectures (arm64, armv7, ppc64le) can be added
- **Additional providers** - More Terraform providers based on community requests
- **Ready-to-use CI/CD files** - Pre-configured Jenkins and GitLab CI/CD pipeline files in future releases

**Need multi-architecture support?** Create an issue to request support for specific architectures.

## Key Features

### Modularity and Flexibility
- **Conditional component installation** - include only the tools you need
- **Minimal image size** - from 50MB to 400MB depending on configuration
- **Fast builds** - multi-stage build with optimized caching

### Rich Toolset
- **Terraform** with popular providers (Proxmox, DNS, Local, Keycloak) - all built from source
- **Ansible** (full version or core) with Mitogen for acceleration - compiled from source
- **Kubernetes tools** (kubectl, Helm, yq) - built from official source code
- **Git** - Version control system included by default
- **Python ecosystem** with necessary libraries - optimized for Alpine Linux

### Enterprise Readiness
- **Security** - Alpine Linux, minimal attack surface
- **Performance** - optimized layers and aggressive cleanup
- **Compatibility** - support for different architectures and platforms

### Optimization
- **Source-based compilation** - all tools optimized for Alpine Linux
- **Multi-stage builds** - separate stages for each component
- **Aggressive cleanup** - removal of caches, tests, documentation
- **Binary compression** - strip for size reduction
- **Smart caching** - optimized Docker layers

### Future CI/CD Support
**Coming in future releases:**
- **Pre-configured Jenkins file** - Ready-to-use `Jenkinsfile`
- **GitLab CI/CD templates** - Complete `.gitlab-ci.yml`

**Need specific CI/CD support?** Create an issue to request support for your preferred CI/CD platform.

## Debugging

### Check image size:
```bash
docker images krang
docker history krang:latest
```

### Analyze contents:
```bash
docker run --rm krang:latest du -h / | sort -hr | head -20
```

### Verify tool versions:
```bash
docker run --rm krang:latest terraform --version
docker run --rm krang:latest ansible --version
docker run --rm krang:latest kubectl version --client
```

## Development and Customization

### Configuration Workflow
1. **Edit `krang.dockerfile`** - Set your preferred default ARG values
2. **Build with defaults** - `docker build -t krang:latest .`
3. **Override as needed** - Use `--build-arg` for specific builds
4. **Share configuration** - Commit your ARG changes to version control

### Adding new tools:
1. Add ARG variable in configuration section
2. Create new build stage
3. Add conditional logic in final stage

### Size optimization:
- Use `--build-arg` to disable unnecessary components
- Configure `CUSTOM_UTILS_PACKAGES` for minimal utility set
- Use `ansible-core` instead of full Ansible

## Benefits

- **Source Control**: All tools built from source code, ensuring you have the exact versions you need
- **Version Flexibility**: Specify any supported version for each component during build time
- **Offline Capability**: No internet required for Terraform provider downloads - perfect for air-gapped environments
- **Package Manager Access**: Full pip and apk access for installing additional tools on-demand
- **Maximum Parameterization**: Every component, version, and feature can be controlled via build arguments
- **Custom SSL Support**: Built-in support for corporate CA certificates via build args
- **Time-Saving**: Automates infrastructure tool setup, speeding up development and deployment processes
- **Enhanced Security**: Alpine Linux base, minimal attack surface, and security-focused configuration
- **Flexibility**: Wide range of options allows you to tailor the image to specific needs
- **Convenience**: Single image with all necessary tools for infrastructure automation
- **Performance Optimization**: Source-based compilation, multi-stage builds, and aggressive cleanup improve build and runtime performance
- **Cross-Platform Reliability**: Tested on Windows, Ubuntu 24.04, and Oracle Linux 10 for consistent results

## Perfect for Restricted Environments

### When Terraform Downloads are Blocked
This image is specifically designed for environments where:
- **Terraform provider downloads are blocked** by corporate firewalls
- **Internet access is restricted** for security reasons
- **Air-gapped environments** require offline capabilities
- **Compliance requirements** prevent external downloads

### Solution Benefits
- ✅ **Pre-compiled providers** - All Terraform providers included and ready to use
- ✅ **No external downloads** - Everything works offline after image build
- ✅ **Corporate firewall friendly** - No need to whitelist Terraform registry URLs
- ✅ **Compliance ready** - All components built from source with known versions
- ✅ **Package manager access** - Install additional tools via pip/apk as needed

### Use Cases
- **Corporate environments** with strict security policies
- **Air-gapped systems** without internet access
- **Compliance-heavy industries** (finance, healthcare, government)
- **Offline development** and testing environments
- **Disaster recovery** scenarios with limited connectivity

## Perfect for DevOps, SRE, and Site Engineers

### Tailored for Different Roles
This toolkit is designed to meet the specific needs of different engineering roles:

#### **DevOps Engineers**
- **Full-stack automation** - Complete toolchain in one image
- **CI/CD integration** - Ready for GitLab CI/CD pipelines
- **Infrastructure as Code** - Terraform + Ansible combination
- **Kubernetes management** - kubectl, Helm, yq for K8s operations

#### **Site Reliability Engineers (SRE)**
- **Kubernetes-only builds** - Focus on K8s tooling without bloat
- **Offline capabilities** - Work in restricted environments

#### **Site Engineers**
- **Terraform-only builds** - Infrastructure provisioning focus
- **Ansible-only builds** - Configuration management focus
- **Custom provider support** - Add specific providers for your infrastructure
- **Corporate compliance** - Custom SSL certificates and security features

## Additional Resources

- [Terraform Documentation](https://terraform.io/docs)
- [Ansible Documentation](https://docs.ansible.com)
- [Kubernetes Documentation](https://kubernetes.io/docs)
- [Docker Best Practices](https://docs.docker.com/develop/dev-best-practices/)

## Support

For questions and suggestions, create Issues in the Github repository.

## License

MIT License - See LICENSE file for details
