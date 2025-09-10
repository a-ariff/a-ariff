# Security Lab Health Check Script
# Validates security tools and lab environment

try {
    # Check essential security tools
    $securityTools = @(
        @{ Name = 'nmap'; Command = 'nmap --version' },
        @{ Name = 'nikto'; Command = 'nikto -Version' },
        @{ Name = 'sqlmap'; Command = 'sqlmap --version' },
        @{ Name = 'trivy'; Command = 'trivy --version' },
        @{ Name = 'grype'; Command = 'grype version' },
        @{ Name = 'docker'; Command = 'docker --version' }
    )

    foreach ($tool in $securityTools) {
        try {
            $null = Invoke-Expression $tool.Command 2>$null
            Write-Host "✅ $($tool.Name) is available" -ForegroundColor Green
        }
        catch {
            Write-Error "❌ $($tool.Name) is not available or not working"
            exit 1
        }
    }

    # Check PowerShell security modules
    $securityModules = @('Pester', 'PSScriptAnalyzer')
    foreach ($module in $securityModules) {
        if (!(Get-Module -ListAvailable -Name $module)) {
            Write-Error "Required security module '$module' is not installed"
            exit 1
        }
    }

    # Check lab directories
    $labDirectories = @('/lab/tools', '/lab/scripts', '/lab/results', '/lab/payloads')
    foreach ($dir in $labDirectories) {
        if (!(Test-Path $dir)) {
            Write-Error "Lab directory '$dir' does not exist"
            exit 1
        }
    }

    # Check network connectivity (basic test)
    try {
        $response = Test-NetConnection -ComputerName "8.8.8.8" -Port 53 -InformationLevel Quiet
        if (!$response) {
            Write-Warning "⚠️ Network connectivity test failed"
        }
    }
    catch {
        Write-Warning "⚠️ Cannot test network connectivity"
    }

    Write-Host "✅ Security lab environment is healthy" -ForegroundColor Green
    exit 0
}
catch {
    Write-Error "Security lab health check failed: $($_.Exception.Message)"
    exit 1
}