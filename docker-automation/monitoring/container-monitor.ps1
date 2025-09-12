#!/usr/bin/env pwsh
# Container Resource Monitor Script
# Monitors container resources and generates alerts

param(
    [Parameter(Mandatory=$false)]
    [int]$IntervalSeconds = 60,
    
    [Parameter(Mandatory=$false)]
    [int]$CpuThreshold = 80,
    
    [Parameter(Mandatory=$false)]
    [int]$MemoryThreshold = 85,
    
    [Parameter(Mandatory=$false)]
    [string]$LogFile = "/workspace/logs/resource-monitor.log"
)

# Set error action preference
$ErrorActionPreference = "Continue"

# Function to write log messages
function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$Level] $Message"
    Write-Host $logEntry
    Add-Content -Path $LogFile -Value $logEntry
}

function Get-ContainerStats {
    try {
        $containers = docker ps --format "table {{.Names}}\t{{.Image}}\t{{.Status}}" | Select-Object -Skip 1
        $stats = @()
        
        foreach ($line in $containers) {
            if ([string]::IsNullOrWhiteSpace($line)) { continue }
            
            $parts = $line -split '\s{2,}'
            $containerName = $parts[0]
            $image = $parts[1]
            $status = $parts[2]
            
            # Get detailed stats
            $statsJson = docker stats --no-stream --format "{{json .}}" $containerName 2>$null
            
            if ($statsJson) {
                $statData = $statsJson | ConvertFrom-Json
                
                # Parse CPU percentage
                $cpuPercent = [double]($statData.CPUPerc -replace '%', '')
                
                # Parse memory usage
                $memoryUsage = $statData.MemUsage
                $memoryParts = $memoryUsage -split ' / '
                $usedMemory = $memoryParts[0]
                $totalMemory = $memoryParts[1]
                
                # Convert memory to MB for easier comparison
                $usedMB = switch -Regex ($usedMemory) {
                    '(\d+\.?\d*)GiB' { [math]::Round([double]$matches[1] * 1024, 2) }
                    '(\d+\.?\d*)GB' { [math]::Round([double]$matches[1] * 1000, 2) }
                    '(\d+\.?\d*)MiB' { [math]::Round([double]$matches[1], 2) }
                    '(\d+\.?\d*)MB' { [math]::Round([double]$matches[1], 2) }
                    '(\d+\.?\d*)KiB' { [math]::Round([double]$matches[1] / 1024, 2) }
                    '(\d+\.?\d*)KB' { [math]::Round([double]$matches[1] / 1000, 2) }
                    '(\d+\.?\d*)B' { [math]::Round([double]$matches[1] / 1048576, 2) }
                    default { 0 }
                }
                
                $totalMB = switch -Regex ($totalMemory) {
                    '(\d+\.?\d*)GiB' { [math]::Round([double]$matches[1] * 1024, 2) }
                    '(\d+\.?\d*)GB' { [math]::Round([double]$matches[1] * 1000, 2) }
                    '(\d+\.?\d*)MiB' { [math]::Round([double]$matches[1], 2) }
                    '(\d+\.?\d*)MB' { [math]::Round([double]$matches[1], 2) }
                    '(\d+\.?\d*)KiB' { [math]::Round([double]$matches[1] / 1024, 2) }
                    '(\d+\.?\d*)KB' { [math]::Round([double]$matches[1] / 1000, 2) }
                    '(\d+\.?\d*)B' { [math]::Round([double]$matches[1] / 1048576, 2) }
                    default { 1 }
                }
                
                $memoryPercent = if ($totalMB -gt 0) { [math]::Round(($usedMB / $totalMB) * 100, 2) } else { 0 }
                
                $stats += [PSCustomObject]@{
                    Name = $containerName
                    Image = $image
                    Status = $status
                    CPUPercent = $cpuPercent
                    MemoryUsedMB = $usedMB
                    MemoryTotalMB = $totalMB
                    MemoryPercent = $memoryPercent
                    NetworkIO = $statData.NetIO
                    DiskIO = $statData.BlockIO
                    Timestamp = Get-Date
                }
            }
        }
        
        return $stats
    }
    catch {
        Write-Log "Error getting container stats: $($_.Exception.Message)" "ERROR"
        return @()
    }
}

function Test-ResourceThresholds {
    param([array]$Stats)
    
    $alerts = @()
    
    foreach ($stat in $Stats) {
        # CPU threshold check
        if ($stat.CPUPercent -gt $CpuThreshold) {
            $alerts += [PSCustomObject]@{
                Type = "CPU_HIGH"
                Container = $stat.Name
                Image = $stat.Image
                Value = $stat.CPUPercent
                Threshold = $CpuThreshold
                Message = "High CPU usage detected: $($stat.CPUPercent)% (threshold: $CpuThreshold%)"
                Severity = if ($stat.CPUPercent -gt 90) { "CRITICAL" } else { "WARNING" }
                Timestamp = $stat.Timestamp
            }
        }
        
        # Memory threshold check
        if ($stat.MemoryPercent -gt $MemoryThreshold) {
            $alerts += [PSCustomObject]@{
                Type = "MEMORY_HIGH"
                Container = $stat.Name
                Image = $stat.Image
                Value = $stat.MemoryPercent
                Threshold = $MemoryThreshold
                Message = "High memory usage detected: $($stat.MemoryPercent)% (threshold: $MemoryThreshold%)"
                Severity = if ($stat.MemoryPercent -gt 95) { "CRITICAL" } else { "WARNING" }
                Timestamp = $stat.Timestamp
            }
        }
        
        # Container health check
        if ($stat.Status -notmatch "Up") {
            $alerts += [PSCustomObject]@{
                Type = "CONTAINER_DOWN"
                Container = $stat.Name
                Image = $stat.Image
                Value = $stat.Status
                Threshold = "Up"
                Message = "Container is not running: $($stat.Status)"
                Severity = "CRITICAL"
                Timestamp = $stat.Timestamp
            }
        }
    }
    
    return $alerts
}

function Send-AlertNotification {
    param([array]$Alerts)
    
    if ($Alerts.Count -eq 0) { return }
    
    Write-Log "Processing $($Alerts.Count) alerts"
    
    foreach ($alert in $Alerts) {
        $logLevel = switch ($alert.Severity) {
            "CRITICAL" { "ERROR" }
            "WARNING" { "WARNING" }
            default { "INFO" }
        }
        
        Write-Log "ALERT [$($alert.Severity)] $($alert.Message)" $logLevel
        
        # Here you could add integration with external alerting systems
        # Example: Slack, Teams, PagerDuty, etc.
        
        # Create metrics file for Prometheus
        $metricsFile = "/tmp/container_alerts.prom"
        $metricLine = "container_alert{container=`"$($alert.Container)`",type=`"$($alert.Type)`",severity=`"$($alert.Severity)`"} 1"
        Add-Content -Path $metricsFile -Value $metricLine
    }
}

function Export-PrometheusMetrics {
    param([array]$Stats)
    
    $metricsFile = "/tmp/container_metrics.prom"
    $metrics = @()
    
    foreach ($stat in $Stats) {
        $containerLabel = $stat.Name -replace '[^a-zA-Z0-9_]', '_'
        $imageLabel = $stat.Image -replace '[^a-zA-Z0-9_:]', '_'
        
        $metrics += "container_cpu_usage_percent{container=`"$($stat.Name)`",image=`"$($stat.Image)`"} $($stat.CPUPercent)"
        $metrics += "container_memory_usage_percent{container=`"$($stat.Name)`",image=`"$($stat.Image)`"} $($stat.MemoryPercent)"
        $metrics += "container_memory_usage_mb{container=`"$($stat.Name)`",image=`"$($stat.Image)`"} $($stat.MemoryUsedMB)"
        $metrics += "container_memory_total_mb{container=`"$($stat.Name)`",image=`"$($stat.Image)`"} $($stat.MemoryTotalMB)"
        $metrics += "container_up{container=`"$($stat.Name)`",image=`"$($stat.Image)`"} $(if ($stat.Status -match 'Up') { 1 } else { 0 })"
    }
    
    $metrics | Out-File -FilePath $metricsFile -Encoding UTF8
    Write-Log "Exported metrics to $metricsFile"
}

# Main monitoring loop
try {
    Write-Log "Starting container resource monitor"
    Write-Log "CPU Threshold: $CpuThreshold%"
    Write-Log "Memory Threshold: $MemoryThreshold%"
    Write-Log "Check Interval: $IntervalSeconds seconds"
    
    # Create log directory if it doesn't exist
    $logDir = Split-Path $LogFile -Parent
    if (!(Test-Path $logDir)) {
        New-Item -ItemType Directory -Path $logDir -Force | Out-Null
    }
    
    while ($true) {
        Write-Log "Collecting container statistics..."
        
        # Get current container stats
        $stats = Get-ContainerStats
        
        if ($stats.Count -gt 0) {
            Write-Log "Monitoring $($stats.Count) containers"
            
            # Check thresholds and generate alerts
            $alerts = Test-ResourceThresholds -Stats $stats
            
            # Send notifications for alerts
            if ($alerts.Count -gt 0) {
                Send-AlertNotification -Alerts $alerts
            } else {
                Write-Log "All containers within normal resource limits"
            }
            
            # Export metrics for Prometheus
            Export-PrometheusMetrics -Stats $stats
            
            # Log summary
            $avgCpu = [math]::Round(($stats | Measure-Object CPUPercent -Average).Average, 2)
            $avgMemory = [math]::Round(($stats | Measure-Object MemoryPercent -Average).Average, 2)
            Write-Log "Average CPU: $avgCpu%, Average Memory: $avgMemory%"
        } else {
            Write-Log "No containers found or error collecting stats"
        }
        
        # Wait for next check
        Start-Sleep -Seconds $IntervalSeconds
    }
}
catch {
    Write-Log "Container monitor error: $($_.Exception.Message)" "ERROR"
    exit 1
}