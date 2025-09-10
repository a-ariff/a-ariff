# 🚀 GitHub Repository Automation Suite

![GitHub last commit](https://img.shields.io/github/last-commit/a-ariff/a-ariff)
![GitHub issues](https://img.shields.io/github/issues/a-ariff/a-ariff)
![GitHub stars](https://img.shields.io/github/stars/a-ariff/a-ariff)
![GitHub license](https://img.shields.io/github/license/a-ariff/a-ariff)

![Security Scan](https://github.com/a-ariff/a-ariff/workflows/Security%20Scanning%20Suite/badge.svg)
![Health Check](https://github.com/a-ariff/a-ariff/workflows/Repository%20Health%20Check/badge.svg)
![Documentation](https://github.com/a-ariff/a-ariff/workflows/Documentation%20Automation/badge.svg)

> **Enterprise-grade GitHub repository automation suite for the a-ariff organization**

## 📋 Overview

This repository contains a comprehensive automation suite designed to maintain consistency, security, and quality across all repositories in the **a-ariff** organization. The automation covers security scanning, dependency management, documentation synchronization, health monitoring, and maintenance reporting.

### 🎯 Target Repositories

- **PowerShell Projects**: `intune-remediation-scripts`, `msgraph-automation-scripts`, `azure-automation-hub`
- **Docker Projects**: `rustdesk-docker`, `rust-selfhost-server`, `rustdesk-server`
- **Automation Tools**: `browser-popup-mdm-automation`, `Network-automation-MDM`, `github-automation-cli`
- **Security Projects**: `azure-device-compliance-monitor`, `intune-powerbi-dashboard`

## ✨ Features

### 🔒 Security & Compliance Automation

- **CodeQL Security Analysis**: Automated static code analysis for security vulnerabilities
- **Dependency Vulnerability Scanning**: Continuous monitoring for package vulnerabilities
- **Secret Scanning**: Detection of exposed credentials and API keys
- **Container Security**: Docker image vulnerability assessment
- **PowerShell Security**: PSScriptAnalyzer for PowerShell projects

### 📦 Dependency Management

- **Dependabot Configuration**: Automated dependency updates across all ecosystems
- **Security Patch Automation**: Immediate application of security fixes
- **Multi-Language Support**: npm, pip, cargo, docker, nuget, maven, gradle, terraform
- **Smart Grouping**: Logical dependency grouping for efficient updates

### 🔍 Repository Health Monitoring

- **Link Health Checks**: Automated validation of documentation links
- **Badge Validation**: Verification of status badges and shields
- **Structure Assessment**: Essential files and configuration validation
- **Code Quality Checks**: Language-specific quality tool configurations

### 📝 Documentation Automation

- **README Template Sync**: Consistent documentation across repositories
- **Automated Generation**: Dynamic README creation based on repository type
- **Documentation Validation**: Markdown linting and structure verification
- **Technology Detection**: Automatic detection and documentation of tech stacks

### 🛡️ Branch Protection & Governance

- **Automated Branch Protection**: Consistent protection rules across repositories
- **Pull Request Templates**: Standardized PR and issue templates
- **Security Policies**: Organization-wide security policy deployment
- **Review Requirements**: Automated enforcement of code review processes

### 📊 Reporting & Notifications

- **Monthly Maintenance Reports**: Comprehensive repository health reports
- **Organization Analysis**: Cross-repository insights and recommendations
- **Automated Issue Creation**: Proactive identification and tracking of maintenance tasks
- **Status Dashboards**: Real-time visibility into repository health

## 🚀 Quick Start

### Prerequisites

- GitHub Personal Access Token with appropriate permissions
- Python 3.8+ (for automation scripts)
- Git CLI
- GitHub CLI (gh) - optional but recommended

### Setup Instructions

1. **Clone the repository**:
   ```bash
   git clone https://github.com/a-ariff/a-ariff.git
   cd a-ariff
   ```

2. **Install dependencies**:
   ```bash
   pip install requests python-dateutil
   ```

3. **Setup repository automation**:
   ```bash
   python scripts/setup_repository_automation.py --token YOUR_GITHUB_TOKEN
   ```

4. **Configure branch protection**:
   ```bash
   python scripts/setup_branch_protection.py --token YOUR_GITHUB_TOKEN --enhanced
   ```

### Manual Deployment

For manual deployment to specific repositories:

1. Copy `.github/workflows/` to target repository
2. Copy `.github/dependabot.yml` to target repository
3. Copy `.github/SECURITY.md` and templates to target repository
4. Configure repository settings and branch protection

## 📁 Project Structure

```
.github/
├── workflows/
│   ├── security-scan.yml           # Security scanning suite
│   ├── health-check.yml            # Repository health monitoring
│   ├── documentation-sync.yml      # Documentation automation
│   ├── maintenance-report.yml      # Monthly maintenance reports
│   ├── dependency-updates.yml      # Automated dependency management
│   ├── link-check.yml              # Link validation (existing)
│   └── snake.yml                   # GitHub activity visualization
├── ISSUE_TEMPLATE/
│   ├── bug_report.yml              # Bug report template
│   ├── feature_request.yml         # Feature request template
│   ├── documentation.yml           # Documentation issue template
│   └── config.yml                  # Issue template configuration
├── config/
│   └── mlc_config.json            # Link checker configuration
├── dependabot.yml                  # Multi-ecosystem dependency configuration
├── SECURITY.md                     # Organization security policy
└── PULL_REQUEST_TEMPLATE.md        # Pull request template

scripts/
├── setup_repository_automation.py  # Repository automation deployment
└── setup_branch_protection.py      # Branch protection configuration

templates/                          # README templates and documentation
```

## ⚙️ Workflow Details

### Security Scanning Suite (`security-scan.yml`)

**Triggers**: Push, PR, Daily schedule, Manual dispatch  
**Features**:
- CodeQL analysis for multiple languages
- TruffleHog secret scanning
- Trivy vulnerability scanning
- PowerShell-specific security analysis
- Docker security validation
- Comprehensive security reporting

### Repository Health Check (`health-check.yml`)

**Triggers**: Weekly schedule, Documentation changes, Manual dispatch  
**Features**:
- Link validation with lychee and markdown-link-check
- Badge validation and security checks
- Repository structure assessment
- Security files verification
- Code quality configuration detection
- Automated issue creation on failures

### Documentation Automation (`documentation-sync.yml`)

**Triggers**: Weekly schedule, Template changes, Manual dispatch  
**Features**:
- Dynamic README generation
- Technology stack detection
- Badge automation
- Documentation structure validation
- Markdown linting
- Automated PR creation for updates

### Monthly Maintenance Report (`maintenance-report.yml`)

**Triggers**: Monthly schedule (1st of each month), Manual dispatch  
**Features**:
- Comprehensive repository analysis
- Activity and contribution metrics
- Security status assessment
- Workflow success rate analysis
- Organization-wide reporting
- Automated maintenance issue creation

### Automated Dependency Updates (`dependency-updates.yml`)

**Triggers**: Daily schedule, Manual dispatch with options  
**Features**:
- Security vulnerability prioritization
- Multi-ecosystem support
- PowerShell module updates
- Automated PR creation for security fixes
- Dependency analysis and reporting
- Update tracking and coordination

## 🔧 Configuration

### Dependabot Configuration

The automation suite includes comprehensive Dependabot configuration for:

- **GitHub Actions**: Weekly updates
- **npm**: Daily updates with grouping
- **Python (pip)**: Daily security and dependency updates
- **Docker**: Weekly base image updates
- **NuGet (.NET)**: Daily updates for PowerShell projects
- **Cargo (Rust)**: Daily updates for Rust projects
- **Terraform**: Weekly infrastructure updates

### Security Scanning

Security scanning is configured with:

- **CodeQL**: Extended security and quality queries
- **Secret Scanning**: TruffleHog integration
- **Dependency Scanning**: Trivy vulnerability assessment
- **Container Scanning**: Docker image security analysis
- **Language-Specific**: PSScriptAnalyzer for PowerShell

### Branch Protection

Standard protection includes:
- Required status checks
- Mandatory code reviews
- Conversation resolution requirements
- Force push and deletion prevention

Enhanced protection (for critical repositories):
- Two required reviewers
- Admin enforcement
- Additional status checks

## 📊 Monitoring & Reporting

### Health Metrics

The automation suite tracks and reports on:

- **Security Posture**: Vulnerability counts and resolution times
- **Dependency Health**: Update frequency and security patch application
- **Code Quality**: Workflow success rates and quality metrics
- **Documentation Quality**: Link health and content completeness
- **Activity Metrics**: Commit frequency, issue resolution, and contributor activity

### Alerting

Automated alerts are generated for:

- Security scan failures
- Health check issues
- Broken links or invalid badges
- Failed dependency updates
- Repository maintenance needs

## 🔒 Security

### Security Policy

This repository follows the organization-wide security policy documented in [`.github/SECURITY.md`](.github/SECURITY.md).

### Vulnerability Reporting

- **GitHub Security Advisories**: Preferred method
- **Email**: security@aglobaltec.com
- **Response Time**: 24-hour acknowledgment, 72-hour assessment

### Security Features

- ✅ Automated security scanning
- ✅ Secret detection and prevention
- ✅ Dependency vulnerability monitoring
- ✅ Branch protection enforcement
- ✅ Required security reviews

## 🤝 Contributing

Contributions to improve the automation suite are welcome! Please:

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

See [CONTRIBUTING.md](CONTRIBUTING.md) for detailed guidelines.

## 📚 Documentation

- **Setup Guide**: Detailed deployment instructions
- **Configuration Reference**: Complete configuration options
- **Troubleshooting**: Common issues and solutions
- **API Reference**: Script and automation documentation

## 🏆 Benefits

### For Developers

- **Reduced Manual Work**: Automated dependency updates and security scanning
- **Consistent Standards**: Uniform quality and security across all repositories
- **Early Issue Detection**: Proactive identification of security and quality issues
- **Streamlined Workflows**: Standardized development processes

### For Organization

- **Security Assurance**: Comprehensive security monitoring and compliance
- **Risk Mitigation**: Automated vulnerability detection and remediation
- **Quality Maintenance**: Consistent code quality and documentation standards
- **Operational Efficiency**: Reduced maintenance overhead and manual processes

## 📈 Metrics & KPIs

The automation suite enables tracking of:

- **MTTR (Mean Time To Resolution)**: For security vulnerabilities
- **Dependency Freshness**: Percentage of up-to-date dependencies
- **Security Coverage**: Repositories with active security scanning
- **Documentation Quality**: Completeness and accuracy metrics
- **Automation Adoption**: Workflow deployment and usage statistics

## 🔮 Future Enhancements

Planned improvements include:

- **AI-Powered Code Review**: Automated code quality suggestions
- **Advanced Analytics**: Predictive maintenance and trend analysis
- **Integration Expansion**: Additional tools and service integrations
- **Custom Policies**: Organization-specific compliance rules
- **Performance Monitoring**: Repository performance and optimization insights

## 📞 Support

- **Issues**: [GitHub Issues](https://github.com/a-ariff/a-ariff/issues)
- **Discussions**: [GitHub Discussions](https://github.com/a-ariff/a-ariff/discussions)
- **Email**: [contact@aglobaltec.com](mailto:contact@aglobaltec.com)
- **LinkedIn**: [Ariff Mohamed](https://www.linkedin.com/in/ariff-mohamed/)

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

<div align="center">

**⭐ If you find this automation suite helpful, please consider giving it a star!**

[![GitHub stars](https://img.shields.io/github/stars/a-ariff/a-ariff?style=social)](https://github.com/a-ariff/a-ariff/stargazers)

Made with ❤️ by [Ariff Mohamed](https://github.com/a-ariff)

</div>

---

*Last updated: December 2024 | Version: 1.0.0*