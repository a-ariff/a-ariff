# 🐳 Dockerfiles Documentation

This directory contains optimized, multi-stage Dockerfiles for the Docker automation suite.

## 📁 Available Images

### PowerShell Tools (`powershell-tools.Dockerfile`)
Production-ready PowerShell environment with Azure integration and security tools.

**Features:**
- PowerShell 7.4 with Azure modules
- Azure CLI integration
- Security scanning tools (Trivy)
- Docker CLI for container operations
- Health checks and monitoring

**Base Image:** `mcr.microsoft.com/powershell:7.4-ubuntu-22.04`

**Build Command:**
```bash
docker build -f powershell-tools.Dockerfile -t powershell-tools:latest .
```

### Security Lab (`security-lab.Dockerfile`)
Comprehensive security testing environment with penetration testing tools.

**Features:**
- Kali Linux base with security tools
- PowerShell integration
- Container security scanning
- Network security tools
- Vulnerability assessment tools

**Base Image:** `kalilinux/kali-rolling`

**Build Command:**
```bash
docker build -f security-lab.Dockerfile -t security-lab:latest .
```

### Development Environment (`dev-environment.Dockerfile`)
Multi-language development environment with cloud tools.

**Features:**
- Multiple language runtimes (Node.js, Python, Go, .NET)
- Cloud CLIs (Azure, AWS, Terraform)
- Kubernetes tools (kubectl, Helm)
- Development tools and IDEs
- VS Code Server

**Base Image:** `ubuntu:22.04`

**Build Command:**
```bash
docker build -f dev-environment.Dockerfile -t dev-environment:latest .
```

## 🏗️ Multi-Stage Build Optimization

All Dockerfiles use multi-stage builds to:
- Minimize final image size
- Separate build dependencies from runtime
- Enable parallel building
- Improve security by reducing attack surface

## 🔐 Security Features

- Non-root user execution
- Minimal base images
- Security scanning integration
- Health checks
- Resource limits
- Network policies

## 📊 Monitoring & Health Checks

Each image includes:
- Custom health check scripts
- Resource monitoring
- Application-specific metrics
- Log aggregation support

## 🚀 Usage Examples

### Quick Start
```bash
# Build all images
docker-compose -f ../compose/dev-environment.yml build

# Run specific environment
docker run -it powershell-tools:latest

# Run with volume mounts
docker run -it -v $(pwd):/workspace powershell-tools:latest
```

### Production Deployment
```bash
# Using Kubernetes
kubectl apply -f ../kubernetes/manifests/

# Using Helm
helm install powershell-tools ../kubernetes/helm/powershell-tools/
```

## 🔧 Customization

### Environment Variables
Each image supports various environment variables for customization:

- `WORKSPACE`: Working directory path
- `USER`: Runtime user name  
- `DOCKER_HOST`: Docker daemon connection
- `AZURE_CONFIG_DIR`: Azure configuration directory

### Volume Mounts
Recommended volume mounts:
- `/workspace`: Working directory
- `/workspace/config`: Configuration files
- `/workspace/scripts`: Custom scripts
- `/workspace/logs`: Log files

## 📋 Best Practices

1. **Always use specific tags** in production
2. **Scan images** before deployment
3. **Use multi-stage builds** for optimization
4. **Run as non-root** users
5. **Implement health checks**
6. **Set resource limits**
7. **Use secrets management** for sensitive data

## 🔄 CI/CD Integration

These Dockerfiles are designed to work with:
- GitHub Actions workflows
- Automated security scanning
- Multi-platform builds (amd64/arm64)
- Container registry publishing
- Vulnerability patching

## 📈 Metrics & Monitoring

Images expose metrics on port 8080 for:
- Application health
- Resource usage
- Custom business metrics
- Security events