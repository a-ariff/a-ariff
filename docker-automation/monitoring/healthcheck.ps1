# PowerShell Health Check Script
# Validates PowerShell modules and Azure connectivity

try {
    # Check PowerShell version
    $psVersion = $PSVersionTable.PSVersion
    if ($psVersion.Major -lt 7) {
        Write-Error "PowerShell version $psVersion is not supported. Requires PowerShell 7+"
        exit 1
    }

    # Check essential modules
    $requiredModules = @('Az', 'Microsoft.Graph', 'Pester', 'PSScriptAnalyzer')
    foreach ($module in $requiredModules) {
        if (!(Get-Module -ListAvailable -Name $module)) {
            Write-Error "Required module '$module' is not installed"
            exit 1
        }
    }

    # Check Azure CLI availability
    $azureCliVersion = az --version 2>$null
    if (!$azureCliVersion) {
        Write-Error "Azure CLI is not available"
        exit 1
    }

    # Check Docker CLI availability
    $dockerVersion = docker --version 2>$null
    if (!$dockerVersion) {
        Write-Error "Docker CLI is not available"
        exit 1
    }

    # Check workspace directories
    $workspaceDirectories = @('/workspace/scripts', '/workspace/logs', '/workspace/config')
    foreach ($dir in $workspaceDirectories) {
        if (!(Test-Path $dir)) {
            Write-Error "Workspace directory '$dir' does not exist"
            exit 1
        }
    }

    Write-Host "✅ PowerShell automation environment is healthy" -ForegroundColor Green
    exit 0
}
catch {
    Write-Error "Health check failed: $($_.Exception.Message)"
    exit 1
}