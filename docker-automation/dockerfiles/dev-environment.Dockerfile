# Multi-stage Dockerfile for Development Environment
# Includes development tools, IDEs, and automation frameworks

# Stage 1: Base development environment
FROM ubuntu:22.04 AS base
LABEL maintainer="Ariff Mohamed <ariff@example.com>"
LABEL description="Development environment with multiple language support"
LABEL version="1.0.0"

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=UTC

# Install base development tools
RUN apt-get update && apt-get install -y \
    curl \
    wget \
    git \
    vim \
    nano \
    build-essential \
    software-properties-common \
    apt-transport-https \
    ca-certificates \
    gnupg \
    lsb-release \
    unzip \
    zip \
    jq \
    tree \
    htop \
    net-tools \
    telnet \
    openssh-client \
    && rm -rf /var/lib/apt/lists/*

# Stage 2: Language runtimes
FROM base AS runtimes

# Install Node.js and npm
RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
RUN apt-get install -y nodejs

# Install Python 3 and pip
RUN apt-get update && apt-get install -y \
    python3 \
    python3-pip \
    python3-venv \
    && rm -rf /var/lib/apt/lists/*

# Install Go
RUN wget https://go.dev/dl/go1.21.5.linux-amd64.tar.gz
RUN tar -C /usr/local -xzf go1.21.5.linux-amd64.tar.gz
RUN rm go1.21.5.linux-amd64.tar.gz
ENV PATH="/usr/local/go/bin:${PATH}"

# Install .NET
RUN wget https://packages.microsoft.com/config/ubuntu/22.04/packages-microsoft-prod.deb -O packages-microsoft-prod.deb
RUN dpkg -i packages-microsoft-prod.deb
RUN rm packages-microsoft-prod.deb
RUN apt-get update && apt-get install -y dotnet-sdk-8.0 && rm -rf /var/lib/apt/lists/*

# Install PowerShell
RUN wget -q https://github.com/PowerShell/PowerShell/releases/download/v7.4.0/powershell_7.4.0-1.deb_amd64.deb
RUN dpkg -i powershell_7.4.0-1.deb_amd64.deb || apt-get install -f -y
RUN rm powershell_7.4.0-1.deb_amd64.deb

# Stage 3: Development tools and CLIs
FROM runtimes AS dev-tools

# Install Azure CLI
RUN curl -sL https://aka.ms/InstallAzureCLIDeb | bash

# Install AWS CLI
RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
RUN unzip awscliv2.zip && ./aws/install && rm -rf aws awscliv2.zip

# Install Terraform
RUN wget -O- https://apt.releases.hashicorp.com/gpg | gpg --dearmor | tee /usr/share/keyrings/hashicorp-archive-keyring.gpg
RUN echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | tee /etc/apt/sources.list.d/hashicorp.list
RUN apt-get update && apt-get install -y terraform && rm -rf /var/lib/apt/lists/*

# Install kubectl
RUN curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
RUN install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

# Install Helm
RUN curl https://baltocdn.com/helm/signing.asc | gpg --dearmor | tee /usr/share/keyrings/helm.gpg > /dev/null
RUN echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/helm.gpg] https://baltocdn.com/helm/stable/debian/ all main" | tee /etc/apt/sources.list.d/helm-stable-debian.list
RUN apt-get update && apt-get install -y helm && rm -rf /var/lib/apt/lists/*

# Install Docker CLI
RUN curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
RUN echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
RUN apt-get update && apt-get install -y docker-ce-cli && rm -rf /var/lib/apt/lists/*

# Stage 4: Development packages and modules
FROM dev-tools AS packages

# Install Python development packages
RUN pip3 install \
    requests \
    flask \
    django \
    fastapi \
    jupyter \
    pandas \
    numpy \
    matplotlib \
    seaborn \
    pytest \
    black \
    flake8 \
    mypy

# Install Node.js development packages
RUN npm install -g \
    @angular/cli \
    @vue/cli \
    create-react-app \
    express-generator \
    typescript \
    ts-node \
    eslint \
    prettier \
    jest \
    webpack \
    webpack-cli

# Install PowerShell modules for development
SHELL ["pwsh", "-Command"]
RUN Install-Module -Name Az -Force -Scope AllUsers -AllowClobber
RUN Install-Module -Name Pester -Force -Scope AllUsers -AllowClobber
RUN Install-Module -Name PSScriptAnalyzer -Force -Scope AllUsers -AllowClobber
RUN Install-Module -Name platyPS -Force -Scope AllUsers -AllowClobber
RUN Install-Module -Name InvokeBuild -Force -Scope AllUsers -AllowClobber

# Stage 5: Final development image
FROM packages AS production

# Create development user
RUN useradd -m -s /bin/bash developer && \
    usermod -aG docker developer && \
    echo "developer ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# Create development directories
RUN mkdir -p /workspace/{projects,scripts,config,logs}
RUN chown -R developer:developer /workspace

# Install VS Code Server (code-server)
RUN curl -fsSL https://code-server.dev/install.sh | sh

# Copy development configurations
COPY config/dev/ /workspace/config/
COPY scripts/dev/ /workspace/scripts/
RUN chmod +x /workspace/scripts/*.sh /workspace/scripts/*.ps1

# Set up environment
ENV WORKSPACE="/workspace"
ENV PATH="/workspace/scripts:${PATH}"

# Configure Git (will be overridden by user)
RUN git config --global user.name "Developer" && \
    git config --global user.email "developer@example.com"

# Set up health check
COPY monitoring/dev-healthcheck.ps1 /usr/local/bin/
RUN chmod +x /usr/local/bin/dev-healthcheck.ps1

# Switch to developer user
USER developer
WORKDIR /workspace

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
  CMD pwsh -File /usr/local/bin/dev-healthcheck.ps1

# Expose common development ports
EXPOSE 3000 4200 5000 8000 8080 8443

# Default command
CMD ["/bin/bash"]

# Labels for metadata
LABEL org.opencontainers.image.title="Development Environment"
LABEL org.opencontainers.image.description="Multi-language development environment with cloud tools"
LABEL org.opencontainers.image.vendor="Ariff Mohamed"
LABEL org.opencontainers.image.licenses="MIT"
LABEL org.opencontainers.image.source="https://github.com/a-ariff/a-ariff"