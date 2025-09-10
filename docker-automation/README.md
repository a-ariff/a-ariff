# 🐳 Docker Automation & CI/CD Pipeline Suite

A comprehensive Docker automation framework designed for PowerShell automation tools, security lab environments, and development containers with production-ready configurations.

## 📋 Overview

This suite provides:

- **🏗️ Multi-stage Docker builds** with optimization for PowerShell tools
- **🛡️ Container security scanning** with Trivy and Snyk integration
- **📦 Automated publishing** to Docker Hub and GitHub Container Registry
- **🔧 Development orchestration** with Docker Compose
- **☸️ Kubernetes deployments** with Helm charts
- **📊 Resource monitoring** and health checks
- **🔄 Automated vulnerability patching** for base images
- **🔐 Secrets management** and production configurations

## 📁 Structure

```
docker-automation/
├── dockerfiles/           # Multi-stage Dockerfiles
├── compose/              # Docker Compose configurations
├── kubernetes/           # K8s manifests and Helm charts
├── security/             # Security scanning configurations
├── monitoring/           # Health checks and monitoring
├── scripts/              # Automation scripts
└── examples/             # Usage examples and templates
```

## 🚀 Quick Start

1. **Development Environment**: `docker-compose -f compose/dev-environment.yml up`
2. **Security Lab**: `docker-compose -f compose/security-lab.yml up`
3. **PowerShell Tools**: `docker-compose -f compose/powershell-tools.yml up`

## 🛠️ Build & Deploy

See individual component READMEs for detailed instructions:
- [Docker Images](dockerfiles/README.md)
- [Compose Configurations](compose/README.md)
- [Kubernetes Deployments](kubernetes/README.md)
- [Security Scanning](security/README.md)