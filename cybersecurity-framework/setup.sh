#!/bin/bash

# Advanced Cybersecurity Automation Framework Setup Script
# Author: Ariff Mohamed
# Version: 1.0.0
# Description: Complete setup and initialization script for the cybersecurity framework

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Framework information
FRAMEWORK_NAME="Advanced Cybersecurity Automation Framework"
FRAMEWORK_VERSION="1.0.0"
FRAMEWORK_AUTHOR="Ariff Mohamed"

# Directories
FRAMEWORK_DIR="cybersecurity-framework"
SCRIPTS_DIR="$FRAMEWORK_DIR/scripts"
PYTHON_DIR="$SCRIPTS_DIR/python"
POWERSHELL_DIR="$SCRIPTS_DIR/powershell"
CONFIG_DIR="$FRAMEWORK_DIR/config"
DATA_DIR="$FRAMEWORK_DIR/data"
LOGS_DIR="$FRAMEWORK_DIR/logs"
REPORTS_DIR="$FRAMEWORK_DIR/reports"

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_header() {
    echo -e "${PURPLE}================================${NC}"
    echo -e "${PURPLE}$1${NC}"
    echo -e "${PURPLE}================================${NC}"
}

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to check Python version
check_python_version() {
    if command_exists python3; then
        PYTHON_VERSION=$(python3 -c 'import sys; print(".".join(map(str, sys.version_info[:2])))')
        if python3 -c 'import sys; exit(0 if sys.version_info >= (3, 8) else 1)'; then
            print_success "Python $PYTHON_VERSION detected"
            return 0
        else
            print_error "Python 3.8+ required, found $PYTHON_VERSION"
            return 1
        fi
    else
        print_error "Python 3 not found"
        return 1
    fi
}

# Function to check PowerShell version
check_powershell_version() {
    if command_exists pwsh; then
        PWSH_VERSION=$(pwsh -c '$PSVersionTable.PSVersion.ToString()')
        print_success "PowerShell $PWSH_VERSION detected"
        return 0
    elif command_exists powershell; then
        print_warning "Windows PowerShell detected, PowerShell 7+ recommended"
        return 0
    else
        print_warning "PowerShell not found (optional for Linux/macOS)"
        return 1
    fi
}

# Function to install Python dependencies
install_python_dependencies() {
    print_status "Installing Python dependencies..."
    
    if [ -f "$FRAMEWORK_DIR/requirements.txt" ]; then
        python3 -m pip install --user --upgrade pip
        python3 -m pip install --user -r "$FRAMEWORK_DIR/requirements.txt"
        print_success "Python dependencies installed"
    else
        print_error "requirements.txt not found"
        return 1
    fi
}

# Function to create configuration files
create_config_files() {
    print_status "Creating configuration files..."
    
    # Create config directory
    mkdir -p "$CONFIG_DIR"
    
    # Threat Intelligence Configuration
    cat > "$CONFIG_DIR/threat_intel_config.json" << EOF
{
  "database": "$DATA_DIR/threat_intelligence.db",
  "api_keys": {
    "virustotal": "",
    "alienvault": "",
    "abuse_ch": "",
    "shodan": ""
  },
  "sources": {
    "virustotal": true,
    "alienvault_otx": true,
    "abuse_ch": true,
    "shodan": true,
    "threat_feeds": true
  },
  "collection_intervals": {
    "daily": ["threat_feeds", "cve_updates"],
    "hourly": ["high_priority_iocs"],
    "weekly": ["comprehensive_scan"]
  }
}
EOF

    # Vulnerability Management Configuration
    cat > "$CONFIG_DIR/vuln_config.json" << EOF
{
  "database": "$DATA_DIR/vulnerabilities.db",
  "nvd_api_key": "",
  "epss_api_url": "https://api.first.org/data/v1/epss",
  "kev_catalog_url": "https://www.cisa.gov/sites/default/files/feeds/known_exploited_vulnerabilities.json",
  "cvss_thresholds": {
    "critical": 9.0,
    "high": 7.0,
    "medium": 4.0,
    "low": 0.1
  },
  "scanning": {
    "max_workers": 10,
    "timeout": 30,
    "rate_limit_delay": 1
  },
  "risk_scoring": {
    "cvss_weight": 0.4,
    "epss_weight": 0.3,
    "exploit_weight": 0.2,
    "kev_weight": 0.1
  }
}
EOF

    # Dashboard Configuration
    cat > "$CONFIG_DIR/dashboard_config.json" << EOF
{
  "output_directory": "$REPORTS_DIR",
  "data_sources": {
    "vulnerabilities_db": "$DATA_DIR/vulnerabilities.db",
    "threats_db": "$DATA_DIR/threat_intelligence.db",
    "compliance_db": "$DATA_DIR/compliance.db"
  },
  "visualization": {
    "theme": "plotly_dark",
    "color_scheme": ["#1f77b4", "#ff7f0e", "#2ca02c", "#d62728", "#9467bd"],
    "figure_size": [12, 8],
    "dpi": 300
  },
  "reporting": {
    "include_executive_summary": true,
    "include_technical_details": true,
    "include_recommendations": true,
    "generate_pdf": true,
    "generate_html": true,
    "generate_json": true
  },
  "thresholds": {
    "compliance_good": 85,
    "compliance_fair": 70,
    "vulnerability_critical": 10,
    "mttr_target": 30,
    "automation_target": 80
  }
}
EOF

    # Azure Security Configuration
    cat > "$CONFIG_DIR/azure-security-config.json" << EOF
{
  "azure": {
    "subscriptionId": "",
    "tenantId": "",
    "resourceGroups": []
  },
  "sentinel": {
    "workspaceId": "",
    "workspaceName": "",
    "resourceGroup": ""
  },
  "defender": {
    "enableAutoProvisioning": true,
    "emailNotifications": "",
    "phoneNotifications": ""
  },
  "compliance": {
    "standards": ["Azure Security Benchmark", "CIS", "PCI DSS"],
    "assessmentFrequency": "Daily"
  },
  "automation": {
    "autoRemediation": false,
    "incidentResponse": true,
    "threatHunting": true
  },
  "reporting": {
    "emailRecipients": [],
    "slackWebhook": "",
    "teamsWebhook": ""
  }
}
EOF

    print_success "Configuration files created"
}

# Function to initialize databases
initialize_databases() {
    print_status "Initializing databases..."
    
    mkdir -p "$DATA_DIR"
    
    # Initialize threat intelligence database
    python3 << EOF
import sqlite3
import os

db_path = "$DATA_DIR/threat_intelligence.db"
conn = sqlite3.connect(db_path)
cursor = conn.cursor()

cursor.execute('''
    CREATE TABLE IF NOT EXISTS threat_indicators (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        value TEXT UNIQUE NOT NULL,
        type TEXT NOT NULL,
        source TEXT NOT NULL,
        confidence INTEGER NOT NULL,
        tags TEXT,
        first_seen TIMESTAMP,
        last_seen TIMESTAMP,
        description TEXT,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    )
''')

cursor.execute('''
    CREATE TABLE IF NOT EXISTS threat_campaigns (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT UNIQUE NOT NULL,
        description TEXT,
        threat_actor TEXT,
        tactics TEXT,
        techniques TEXT,
        first_seen TIMESTAMP,
        last_seen TIMESTAMP,
        indicators TEXT,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    )
''')

conn.commit()
conn.close()
print("Threat intelligence database initialized")
EOF

    # Initialize vulnerability database
    python3 << EOF
import sqlite3
import os

db_path = "$DATA_DIR/vulnerabilities.db"
conn = sqlite3.connect(db_path)
cursor = conn.cursor()

cursor.execute('''
    CREATE TABLE IF NOT EXISTS vulnerabilities (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        cve_id TEXT UNIQUE NOT NULL,
        cvss_score REAL,
        severity TEXT,
        description TEXT,
        published_date TIMESTAMP,
        modified_date TIMESTAMP,
        affected_products TEXT,
        references TEXT,
        exploit_available BOOLEAN DEFAULT FALSE,
        patch_available BOOLEAN DEFAULT FALSE,
        in_wild_exploitation BOOLEAN DEFAULT FALSE,
        epss_score REAL DEFAULT 0.0,
        kev_catalog BOOLEAN DEFAULT FALSE,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    )
''')

cursor.execute('''
    CREATE TABLE IF NOT EXISTS assessments (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        target TEXT NOT NULL,
        scan_date TIMESTAMP,
        vulnerabilities_found INTEGER,
        critical_count INTEGER,
        high_count INTEGER,
        medium_count INTEGER,
        low_count INTEGER,
        risk_score REAL,
        compliance_status TEXT,
        recommendations TEXT,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    )
''')

conn.commit()
conn.close()
print("Vulnerability database initialized")
EOF

    print_success "Databases initialized"
}

# Function to set up GitHub Actions workflows
setup_github_workflows() {
    print_status "Setting up GitHub Actions workflows..."
    
    if [ -d ".github/workflows" ]; then
        print_success "GitHub workflows directory exists"
        
        # Count existing security workflows
        SECURITY_WORKFLOWS=$(find .github/workflows -name "*security*" -o -name "*vuln*" -o -name "*compliance*" | wc -l)
        if [ "$SECURITY_WORKFLOWS" -gt 0 ]; then
            print_success "$SECURITY_WORKFLOWS security workflows found"
        else
            print_warning "No security workflows found - please check workflow files"
        fi
    else
        print_warning "GitHub workflows directory not found"
    fi
}

# Function to create helper scripts
create_helper_scripts() {
    print_status "Creating helper scripts..."
    
    # Create vulnerability scan script
    cat > "$PYTHON_DIR/scan_vulnerabilities.py" << 'EOF'
#!/usr/bin/env python3
"""Quick vulnerability scan script"""
import sys
import os
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

from vulnerability_manager import VulnerabilityManager

def main():
    vm = VulnerabilityManager()
    recent_cves = vm.get_recent_cves(7)
    if recent_cves:
        assessment = vm.perform_assessment("local-scan", recent_cves[:20])
        report = vm.generate_vulnerability_report(assessment)
        print(report)
    else:
        print("No recent CVEs found")

if __name__ == "__main__":
    main()
EOF

    # Create threat intelligence scan script
    cat > "$PYTHON_DIR/scan_threats.py" << 'EOF'
#!/usr/bin/env python3
"""Quick threat intelligence scan script"""
import sys
import os
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

from threat_intelligence_collector import ThreatIntelligenceCollector

def main():
    collector = ThreatIntelligenceCollector()
    indicators = collector.collect_abuse_ch_intelligence()
    
    print(f"Collected {len(indicators)} threat indicators")
    for indicator in indicators[:10]:  # Show first 10
        print(f"- {indicator.value} ({indicator.type}) - {indicator.source}")

if __name__ == "__main__":
    main()
EOF

    # Create dashboard generation script
    cat > "$PYTHON_DIR/generate_dashboard.py" << 'EOF'
#!/usr/bin/env python3
"""Quick dashboard generation script"""
import sys
import os
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

from security_dashboard_generator import SecurityDashboardGenerator

def main():
    generator = SecurityDashboardGenerator()
    results = generator.generate_comprehensive_report()
    
    print("Security dashboard generated successfully!")
    print(f"Output directory: {results['output_directory']}")
    for report_type, filename in results.items():
        if filename != results['output_directory']:
            print(f"  {report_type}: {filename}")

if __name__ == "__main__":
    main()
EOF

    # Make scripts executable
    chmod +x "$PYTHON_DIR/scan_vulnerabilities.py"
    chmod +x "$PYTHON_DIR/scan_threats.py" 
    chmod +x "$PYTHON_DIR/generate_dashboard.py"
    
    print_success "Helper scripts created"
}

# Function to run initial tests
run_initial_tests() {
    print_status "Running initial framework tests..."
    
    # Test Python imports
    python3 -c "
import sys
try:
    import requests, pandas, matplotlib, plotly
    print('✅ Core Python packages imported successfully')
except ImportError as e:
    print(f'❌ Import error: {e}')
    sys.exit(1)
"
    
    # Test database connectivity
    python3 -c "
import sqlite3
import os
try:
    conn = sqlite3.connect('$DATA_DIR/vulnerabilities.db')
    cursor = conn.cursor()
    cursor.execute('SELECT COUNT(*) FROM vulnerabilities')
    conn.close()
    print('✅ Database connectivity test passed')
except Exception as e:
    print(f'❌ Database test failed: {e}')
"
    
    print_success "Initial tests completed"
}

# Function to display setup summary
display_summary() {
    print_header "Setup Complete!"
    
    echo -e "${GREEN}${FRAMEWORK_NAME} v${FRAMEWORK_VERSION}${NC}"
    echo -e "${GREEN}by ${FRAMEWORK_AUTHOR}${NC}"
    echo ""
    echo -e "${CYAN}📁 Framework Structure:${NC}"
    echo "  ├── cybersecurity-framework/"
    echo "  │   ├── scripts/python/     # Python analysis tools"
    echo "  │   ├── scripts/powershell/ # PowerShell automation"
    echo "  │   ├── config/             # Configuration files"
    echo "  │   ├── data/               # Databases and data files"
    echo "  │   ├── reports/            # Generated reports"
    echo "  │   └── docs/               # Documentation"
    echo "  └── .github/workflows/      # Security automation workflows"
    echo ""
    echo -e "${CYAN}🚀 Quick Start Commands:${NC}"
    echo -e "  ${YELLOW}# Scan for vulnerabilities${NC}"
    echo "  python3 $PYTHON_DIR/scan_vulnerabilities.py"
    echo ""
    echo -e "  ${YELLOW}# Collect threat intelligence${NC}"
    echo "  python3 $PYTHON_DIR/scan_threats.py"
    echo ""
    echo -e "  ${YELLOW}# Generate security dashboard${NC}"
    echo "  python3 $PYTHON_DIR/generate_dashboard.py"
    echo ""
    echo -e "  ${YELLOW}# Run Azure security assessment${NC}"
    echo "  pwsh $POWERSHELL_DIR/Azure-Security-Automation.ps1 -Operation SecurityAssessment"
    echo ""
    echo -e "${CYAN}📚 Next Steps:${NC}"
    echo "1. Configure API keys in $CONFIG_DIR/*.json files"
    echo "2. Set up GitHub repository secrets for automation"
    echo "3. Configure Azure credentials for cloud integration"
    echo "4. Review and customize security workflows"
    echo "5. Schedule automated scans and reports"
    echo ""
    echo -e "${CYAN}📖 Documentation:${NC}"
    echo "- Framework Overview: $FRAMEWORK_DIR/README.md"
    echo "- Technical Documentation: $FRAMEWORK_DIR/docs/README.md"
    echo "- Incident Response: $FRAMEWORK_DIR/incident-response/README.md"
    echo "- Azure Integration: $FRAMEWORK_DIR/azure-integration/README.md"
    echo ""
    echo -e "${GREEN}✅ Advanced Cybersecurity Automation Framework is ready!${NC}"
}

# Main setup function
main() {
    clear
    print_header "Advanced Cybersecurity Automation Framework Setup"
    
    echo -e "${CYAN}Version:${NC} $FRAMEWORK_VERSION"
    echo -e "${CYAN}Author:${NC} $FRAMEWORK_AUTHOR"
    echo -e "${CYAN}Description:${NC} Research-grade cybersecurity automation for enterprise environments"
    echo ""
    
    # Check prerequisites
    print_status "Checking prerequisites..."
    
    if ! check_python_version; then
        print_error "Python 3.8+ is required for this framework"
        exit 1
    fi
    
    check_powershell_version  # Optional, continue even if not found
    
    if ! command_exists git; then
        print_warning "Git not found - some features may not work"
    fi
    
    # Create directory structure
    print_status "Creating directory structure..."
    mkdir -p "$CONFIG_DIR" "$DATA_DIR" "$LOGS_DIR" "$REPORTS_DIR"
    print_success "Directory structure created"
    
    # Install dependencies
    if ! install_python_dependencies; then
        print_error "Failed to install Python dependencies"
        exit 1
    fi
    
    # Create configuration files
    create_config_files
    
    # Initialize databases
    initialize_databases
    
    # Set up GitHub workflows
    setup_github_workflows
    
    # Create helper scripts
    create_helper_scripts
    
    # Run initial tests
    run_initial_tests
    
    # Display summary
    display_summary
}

# Check if running as root (warn user)
if [ "$EUID" -eq 0 ]; then
    print_warning "Running as root is not recommended for security reasons"
    read -p "Continue anyway? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# Run main setup
main "$@"