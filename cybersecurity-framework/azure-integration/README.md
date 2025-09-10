# 🔗 Azure Sentinel & Defender Integration

This directory contains integration components for Microsoft Azure security services including Sentinel, Defender, and Security Center.

## 🛠️ Integration Components

### 1. **Azure Sentinel SOAR Playbooks**
- **File**: `sentinel-soar-playbooks.json`
- **Purpose**: Security Orchestration, Automation & Response
- **Features**: Automated incident response, threat hunting, case management

### 2. **Microsoft Defender Integration**
- **File**: `defender-automation.ps1`
- **Purpose**: Advanced threat protection automation
- **Features**: Alert management, device isolation, threat remediation

### 3. **Security Center Automation**
- **File**: `security-center-config.json`
- **Purpose**: Azure Security Center configuration and monitoring
- **Features**: Policy management, compliance monitoring, security recommendations

### 4. **Log Analytics Queries**
- **Directory**: `kql-queries/`
- **Purpose**: Kusto Query Language (KQL) queries for threat hunting
- **Features**: Pre-built queries for common security scenarios

## 📋 Prerequisites

### Azure Requirements
- Azure subscription with appropriate permissions
- Microsoft Sentinel workspace
- Microsoft Defender for Cloud enabled
- Log Analytics workspace configured

### PowerShell Modules
```powershell
Install-Module Az.Accounts
Install-Module Az.SecurityInsights
Install-Module Az.Security
Install-Module Az.Monitor
Install-Module Az.OperationalInsights
```

### API Permissions
- Microsoft Graph Security permissions
- Azure Resource Manager access
- Log Analytics reader permissions
- Security administrator role

## 🚀 Quick Start

### 1. Configure Azure Connection
```powershell
# Connect to Azure
Connect-AzAccount
Set-AzContext -Subscription "your-subscription-id"

# Verify Sentinel workspace
$workspaceId = "your-workspace-id"
Get-AzOperationalInsightsWorkspace -ResourceGroupName "security-rg" -Name "sentinel-workspace"
```

### 2. Deploy SOAR Playbooks
```bash
# Deploy Logic App playbooks
az deployment group create \
  --resource-group security-rg \
  --template-file sentinel-soar-playbooks.json \
  --parameters workspaceId=$workspaceId
```

### 3. Configure Defender Automation
```powershell
# Import Defender automation module
Import-Module ./defender-automation.ps1

# Initialize Defender connection
Initialize-DefenderConnection -TenantId "your-tenant-id"

# Test automation
Test-DefenderIntegration
```

## 🔍 Threat Hunting Queries

### High-Priority Queries

#### 1. **Suspicious Login Patterns**
```kql
SigninLogs
| where TimeGenerated > ago(24h)
| where ResultType != 0
| summarize FailedAttempts = count() by UserPrincipalName, IPAddress, LocationDetails.city
| where FailedAttempts > 10
| order by FailedAttempts desc
```

#### 2. **Privilege Escalation Detection**
```kql
AuditLogs
| where TimeGenerated > ago(24h)
| where OperationName in ("Add member to role", "Update role")
| extend InitiatedBy = tostring(InitiatedBy.user.userPrincipalName)
| extend TargetUser = tostring(TargetResources[0].userPrincipalName)
| project TimeGenerated, OperationName, InitiatedBy, TargetUser, Result
```

#### 3. **Malware Detection**
```kql
DeviceEvents
| where TimeGenerated > ago(24h)
| where ActionType in ("FileCreated", "ProcessCreated")
| where FileName matches regex @".*\.(exe|scr|bat|cmd|ps1)$"
| where FolderPath contains "Temp" or FolderPath contains "Downloads"
| summarize EventCount = count() by DeviceName, FileName, SHA256
| where EventCount > 5
```

#### 4. **Network Anomalies**
```kql
DeviceNetworkEvents
| where TimeGenerated > ago(24h)
| where ActionType == "ConnectionSuccess"
| summarize ConnectionCount = count() by DeviceName, RemoteIP, RemotePort
| where ConnectionCount > 100
| join kind=leftouter (
    DeviceInfo | project DeviceName, DeviceType, OSPlatform
) on DeviceName
```

## 🤖 Automated Response Actions

### Incident Response Automation
```json
{
  "triggerCondition": "HighSeverityAlert",
  "automatedActions": [
    {
      "action": "IsolateDevice",
      "condition": "MalwareDetected",
      "timeout": "30 minutes"
    },
    {
      "action": "DisableUser",
      "condition": "SuspiciousLogin",
      "requiresApproval": true
    },
    {
      "action": "BlockIP",
      "condition": "BruteForceAttack",
      "timeout": "24 hours"
    },
    {
      "action": "CreateIncident",
      "condition": "Any",
      "assignTo": "SOC-Team"
    }
  ]
}
```

### Defender Response Actions
```powershell
# Automated device isolation
function Invoke-DeviceIsolation {
    param(
        [string]$DeviceId,
        [string]$Reason = "Automated security response"
    )
    
    $isolationRequest = @{
        comment = $Reason
        isolationType = "Full"
    }
    
    Invoke-MgGraphRequest -Uri "https://graph.microsoft.com/v1.0/security/devices/$DeviceId/isolate" `
        -Method POST -Body ($isolationRequest | ConvertTo-Json)
}

# Automated file quarantine
function Invoke-FileQuarantine {
    param(
        [string]$FileHash,
        [string]$Comment = "Automated quarantine"
    )
    
    $quarantineRequest = @{
        sha256 = $FileHash
        comment = $Comment
    }
    
    Invoke-MgGraphRequest -Uri "https://graph.microsoft.com/v1.0/security/fileInstances/$FileHash/quarantine" `
        -Method POST -Body ($quarantineRequest | ConvertTo-Json)
}
```

## 📊 Monitoring & Alerting

### Custom Alert Rules
```json
{
  "alertRules": [
    {
      "name": "Multiple Failed Logins",
      "query": "SigninLogs | where ResultType != 0 | summarize count() by UserPrincipalName | where count_ > 10",
      "frequency": "5m",
      "severity": "Medium",
      "action": "CreateIncident"
    },
    {
      "name": "Privilege Escalation",
      "query": "AuditLogs | where OperationName contains 'role' | where Result == 'success'",
      "frequency": "1m",
      "severity": "High",
      "action": "ImmediateAlert"
    },
    {
      "name": "Malware Execution",
      "query": "DeviceEvents | where ActionType == 'ProcessCreated' | where ProcessCommandLine contains 'powershell'",
      "frequency": "1m",
      "severity": "Critical",
      "action": "AutomaticResponse"
    }
  ]
}
```

### Performance Metrics
```kql
// Query performance monitoring
let QueryPerformance = 
    Usage
    | where TimeGenerated > ago(7d)
    | where DataType == "Query"
    | summarize 
        TotalQueries = count(),
        AvgDuration = avg(TimeGenerated),
        MaxDuration = max(TimeGenerated)
    | extend PerformanceGrade = case(
        AvgDuration < 5, "Excellent",
        AvgDuration < 15, "Good",
        AvgDuration < 30, "Fair",
        "Poor"
    );
QueryPerformance
```

## 🔧 Configuration Templates

### Sentinel Workspace Configuration
```json
{
  "workspaceSettings": {
    "dataRetention": 90,
    "dailyCapGb": 1000,
    "enableLogAccessUsingOnlyResourcePermissions": true,
    "features": [
      "Incidents",
      "Workbooks",
      "Analytics",
      "Hunting",
      "Notebooks",
      "ThreatIntelligence"
    ]
  },
  "dataConnectors": [
    "AzureActiveDirectory",
    "AzureSecurityCenter",
    "MicrosoftDefenderAdvancedThreatProtection",
    "Office365",
    "AzureActivity",
    "SecurityEvents",
    "Syslog"
  ]
}
```

### Defender Configuration
```json
{
  "defenderSettings": {
    "automaticInvestigation": "Full",
    "remediationLevel": "SemiAutomatic",
    "emailNotifications": true,
    "blockAtFirstSight": true,
    "cloudProtection": "High",
    "sampleSubmission": "Always"
  },
  "exclusions": {
    "files": [],
    "folders": [
      "C:\\Program Files\\Microsoft\\",
      "C:\\Windows\\System32\\"
    ],
    "processes": [
      "explorer.exe",
      "svchost.exe"
    ]
  }
}
```

## 📈 Compliance & Reporting

### Compliance Dashboards
```kql
// Security posture summary
let SecurityPosture = 
    SecurityRecommendation
    | where TimeGenerated > ago(1d)
    | summarize 
        TotalRecommendations = count(),
        HighSeverity = countif(RecommendationSeverity == "High"),
        MediumSeverity = countif(RecommendationSeverity == "Medium"),
        LowSeverity = countif(RecommendationSeverity == "Low")
    | extend ComplianceScore = round(100 - (HighSeverity * 10 + MediumSeverity * 5 + LowSeverity * 2), 2);
SecurityPosture
```

### Executive Reporting
```powershell
# Generate executive security report
function New-ExecutiveSecurityReport {
    param(
        [int]$Days = 7,
        [string]$OutputPath = "security-report.html"
    )
    
    $startDate = (Get-Date).AddDays(-$Days)
    
    # Collect security metrics
    $metrics = @{
        Incidents = Get-SentinelIncidents -Since $startDate
        Alerts = Get-SecurityAlerts -Since $startDate
        Recommendations = Get-SecurityRecommendations
        ComplianceScore = Get-ComplianceScore
    }
    
    # Generate HTML report
    $report = ConvertTo-ExecutiveReport -Metrics $metrics
    $report | Out-File -FilePath $OutputPath
    
    Write-Host "Executive report generated: $OutputPath"
}
```

## 🔒 Security Best Practices

### Access Control
- Use managed identities for authentication
- Implement least privilege access
- Regular access reviews and auditing
- Multi-factor authentication enforcement

### Data Protection
- Encrypt data in transit and at rest
- Implement data classification
- Regular backup and recovery testing
- Data retention policy compliance

### Monitoring
- 24/7 security monitoring
- Real-time alert correlation
- Automated response procedures
- Regular security assessments

## 📞 Support & Troubleshooting

### Common Issues
1. **Connection Failures**: Verify network connectivity and firewall rules
2. **Permission Errors**: Check Azure RBAC assignments
3. **Query Timeouts**: Optimize KQL queries and increase workspace capacity
4. **Alert Flooding**: Tune alert thresholds and correlation rules

### Diagnostic Commands
```powershell
# Test Sentinel connectivity
Test-SentinelConnection -WorkspaceId $workspaceId

# Validate Defender status
Get-DefenderStatus -Detailed

# Check Log Analytics ingestion
Test-LogAnalyticsIngestion -WorkspaceId $workspaceId
```

---

*Advanced Cybersecurity Automation Framework | Azure Integration Module*