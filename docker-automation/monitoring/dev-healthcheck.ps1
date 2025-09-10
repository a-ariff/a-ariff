# Development Environment Health Check Script
# Validates development tools and runtime environments

try {
    # Check development tools
    $devTools = @(
        @{ Name = 'git'; Command = 'git --version' },
        @{ Name = 'node'; Command = 'node --version' },
        @{ Name = 'npm'; Command = 'npm --version' },
        @{ Name = 'python3'; Command = 'python3 --version' },
        @{ Name = 'pip3'; Command = 'pip3 --version' },
        @{ Name = 'go'; Command = 'go version' },
        @{ Name = 'dotnet'; Command = 'dotnet --version' },
        @{ Name = 'az'; Command = 'az --version' },
        @{ Name = 'kubectl'; Command = 'kubectl version --client' },
        @{ Name = 'helm'; Command = 'helm version' },
        @{ Name = 'terraform'; Command = 'terraform --version' },
        @{ Name = 'docker'; Command = 'docker --version' }
    )

    foreach ($tool in $devTools) {
        try {
            $null = Invoke-Expression $tool.Command 2>$null
            Write-Host "✅ $($tool.Name) is available" -ForegroundColor Green
        }
        catch {
            Write-Error "❌ $($tool.Name) is not available or not working"
            exit 1
        }
    }

    # Check PowerShell development modules
    $devModules = @('Az', 'Pester', 'PSScriptAnalyzer', 'platyPS')
    foreach ($module in $devModules) {
        if (!(Get-Module -ListAvailable -Name $module)) {
            Write-Error "Required development module '$module' is not installed"
            exit 1
        }
    }

    # Check workspace directories
    $workspaceDirectories = @('/workspace/projects', '/workspace/scripts', '/workspace/config', '/workspace/logs')
    foreach ($dir in $workspaceDirectories) {
        if (!(Test-Path $dir)) {
            Write-Error "Workspace directory '$dir' does not exist"
            exit 1
        }
    }

    # Check development ports availability (basic test)
    $devPorts = @(3000, 4200, 5000, 8000, 8080)
    foreach ($port in $devPorts) {
        try {
            $socket = New-Object System.Net.Sockets.TcpClient
            $socket.ReceiveTimeout = 1000
            $socket.SendTimeout = 1000
            $result = $socket.BeginConnect('localhost', $port, $null, $null)
            $success = $result.AsyncWaitHandle.WaitOne(1000, $true)
            $socket.Close()
            
            if ($success) {
                Write-Warning "⚠️ Port $port is already in use"
            }
        }
        catch {
            # Port is available (expected)
        }
    }

    Write-Host "✅ Development environment is healthy" -ForegroundColor Green
    exit 0
}
catch {
    Write-Error "Development environment health check failed: $($_.Exception.Message)"
    exit 1
}