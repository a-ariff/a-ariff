# Multi-stage Dockerfile for Security Lab Environment
# Includes penetration testing tools, vulnerability scanners, and security automation

# Stage 1: Base security tools
FROM kalilinux/kali-rolling AS base
LABEL maintainer="Ariff Mohamed <ariff@example.com>"
LABEL description="Security lab environment with PowerShell integration"
LABEL version="1.0.0"

# Update and install core tools
RUN apt-get update && apt-get install -y \
    curl \
    wget \
    git \
    vim \
    nano \
    unzip \
    python3 \
    python3-pip \
    nodejs \
    npm \
    golang-go \
    && rm -rf /var/lib/apt/lists/*

# Install PowerShell on Kali
RUN wget -q https://github.com/PowerShell/PowerShell/releases/download/v7.4.0/powershell_7.4.0-1.deb_amd64.deb
RUN dpkg -i powershell_7.4.0-1.deb_amd64.deb || apt-get install -f -y
RUN rm powershell_7.4.0-1.deb_amd64.deb

# Stage 2: Security tools installation
FROM base AS security-tools

# Install security tools from Kali repositories
RUN apt-get update && apt-get install -y \
    nmap \
    nikto \
    sqlmap \
    metasploit-framework \
    burpsuite \
    dirb \
    gobuster \
    hydra \
    john \
    hashcat \
    aircrack-ng \
    wireshark \
    tcpdump \
    netcat-traditional \
    socat \
    && rm -rf /var/lib/apt/lists/*

# Install additional security tools via pip
RUN pip3 install \
    requests \
    beautifulsoup4 \
    scapy \
    impacket \
    pwntools \
    paramiko \
    colorama

# Install security-focused Node.js tools
RUN npm install -g \
    @angular/cli \
    express-generator \
    retire \
    nsp

# Stage 3: Container security tools
FROM security-tools AS container-security

# Install Docker CLI
RUN curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
RUN echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/debian bullseye stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
RUN apt-get update && apt-get install -y docker-ce-cli && rm -rf /var/lib/apt/lists/*

# Install Trivy for container vulnerability scanning
RUN curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | sh -s -- -b /usr/local/bin

# Install Grype for additional vulnerability scanning
RUN curl -sSfL https://raw.githubusercontent.com/anchore/grype/main/install.sh | sh -s -- -b /usr/local/bin

# Install Syft for SBOM generation
RUN curl -sSfL https://raw.githubusercontent.com/anchore/syft/main/install.sh | sh -s -- -b /usr/local/bin

# Stage 4: PowerShell security modules
FROM container-security AS powershell-security
SHELL ["pwsh", "-Command"]

# Install PowerShell security modules
RUN Install-Module -Name PowerSploit -Force -Scope AllUsers -AllowClobber
RUN Install-Module -Name Nishang -Force -Scope AllUsers -AllowClobber
RUN Install-Module -Name Empire -Force -Scope AllUsers -AllowClobber || Write-Warning "Empire module not available"
RUN Install-Module -Name Pester -Force -Scope AllUsers -AllowClobber
RUN Install-Module -Name PSScriptAnalyzer -Force -Scope AllUsers -AllowClobber

# Stage 5: Final security lab image
FROM powershell-security AS production

# Create security lab user
RUN useradd -m -s /bin/bash seclab && \
    usermod -aG docker seclab

# Create lab directories
RUN mkdir -p /lab/{tools,scripts,results,payloads,wordlists}
RUN chown -R seclab:seclab /lab

# Copy lab scripts and configurations
COPY scripts/security/ /lab/scripts/
COPY config/security/ /lab/config/
RUN chmod +x /lab/scripts/*.sh /lab/scripts/*.ps1

# Download common wordlists
RUN wget -O /lab/wordlists/rockyou.txt.gz https://github.com/brannondorsey/naive-hashcat/releases/download/data/rockyou.txt && \
    gunzip /lab/wordlists/rockyou.txt.gz || true

# Set up health check for security lab
COPY monitoring/security-healthcheck.ps1 /usr/local/bin/
RUN chmod +x /usr/local/bin/security-healthcheck.ps1

# Configure environment
ENV PATH="/lab/scripts:${PATH}"
ENV LAB_HOME="/lab"

# Switch to lab user
USER seclab
WORKDIR /lab

# Health check
HEALTHCHECK --interval=60s --timeout=15s --start-period=10s --retries=3 \
  CMD pwsh -File /usr/local/bin/security-healthcheck.ps1

# Default command - start in interactive mode
CMD ["/bin/bash"]

# Labels for metadata
LABEL org.opencontainers.image.title="Security Lab Environment"
LABEL org.opencontainers.image.description="Comprehensive security testing environment with PowerShell integration"
LABEL org.opencontainers.image.vendor="Ariff Mohamed"
LABEL org.opencontainers.image.licenses="MIT"
LABEL org.opencontainers.image.source="https://github.com/a-ariff/a-ariff"