# Multi-stage Dockerfile for PowerShell Automation Tools
# Optimized for security scanning, automation, and Azure integration

# Stage 1: Base dependencies
FROM mcr.microsoft.com/powershell:7.4-ubuntu-22.04 AS base
LABEL maintainer="Ariff Mohamed <ariff@example.com>"
LABEL description="PowerShell automation tools with Azure and security modules"
LABEL version="1.0.0"

# Install system dependencies
RUN apt-get update && apt-get install -y \
    curl \
    wget \
    git \
    unzip \
    ca-certificates \
    gnupg \
    lsb-release \
    jq \
    && rm -rf /var/lib/apt/lists/*

# Install Azure CLI
RUN curl -sL https://aka.ms/InstallAzureCLIDeb | bash

# Stage 2: PowerShell modules installation
FROM base AS modules
SHELL ["pwsh", "-Command"]

# Install essential PowerShell modules
RUN Install-Module -Name Az -Force -Scope AllUsers -AllowClobber
RUN Install-Module -Name Microsoft.Graph -Force -Scope AllUsers -AllowClobber
RUN Install-Module -Name ExchangeOnlineManagement -Force -Scope AllUsers -AllowClobber
RUN Install-Module -Name MicrosoftTeams -Force -Scope AllUsers -AllowClobber
RUN Install-Module -Name Microsoft.Online.SharePoint.PowerShell -Force -Scope AllUsers -AllowClobber
RUN Install-Module -Name MSOnline -Force -Scope AllUsers -AllowClobber
RUN Install-Module -Name AzureAD -Force -Scope AllUsers -AllowClobber
RUN Install-Module -Name Pester -Force -Scope AllUsers -AllowClobber
RUN Install-Module -Name PSScriptAnalyzer -Force -Scope AllUsers -AllowClobber
RUN Install-Module -Name ImportExcel -Force -Scope AllUsers -AllowClobber

# Stage 3: Security and monitoring tools
FROM modules AS security
SHELL ["/bin/bash", "-c"]

# Install Trivy for vulnerability scanning
RUN curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | sh -s -- -b /usr/local/bin

# Install Docker CLI for container operations
RUN curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
RUN echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
RUN apt-get update && apt-get install -y docker-ce-cli && rm -rf /var/lib/apt/lists/*

# Stage 4: Final production image
FROM security AS production

# Create non-root user
RUN useradd -m -s /bin/bash psuser && \
    usermod -aG docker psuser

# Create workspace directories
RUN mkdir -p /workspace/scripts /workspace/logs /workspace/config
RUN chown -R psuser:psuser /workspace

# Copy automation scripts
COPY scripts/ /workspace/scripts/
RUN chmod +x /workspace/scripts/*.ps1

# Set up health check script
COPY monitoring/healthcheck.ps1 /usr/local/bin/
RUN chmod +x /usr/local/bin/healthcheck.ps1

# Configure PowerShell profile
COPY config/Microsoft.PowerShell_profile.ps1 /home/psuser/.config/powershell/

# Switch to non-root user
USER psuser
WORKDIR /workspace

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
  CMD pwsh -File /usr/local/bin/healthcheck.ps1

# Default command
CMD ["pwsh", "-NoExit"]

# Labels for metadata
LABEL org.opencontainers.image.title="PowerShell Automation Tools"
LABEL org.opencontainers.image.description="Production-ready PowerShell container with Azure modules and security tools"
LABEL org.opencontainers.image.vendor="Ariff Mohamed"
LABEL org.opencontainers.image.licenses="MIT"
LABEL org.opencontainers.image.source="https://github.com/a-ariff/a-ariff"