#!/usr/bin/env pwsh
# Container Security Scanner Script
# Scans container images for vulnerabilities using Trivy and Grype

param(
    [Parameter(Mandatory=$true)]
    [string]$ImageName,
    
    [Parameter(Mandatory=$false)]
    [ValidateSet("LOW", "MEDIUM", "HIGH", "CRITICAL")]
    [string]$SeverityFilter = "MEDIUM",
    
    [Parameter(Mandatory=$false)]
    [ValidateSet("JSON", "TABLE", "SARIF")]
    [string]$OutputFormat = "JSON",
    
    [Parameter(Mandatory=$false)]
    [switch]$GenerateSBOM
)

# Set error action preference
$ErrorActionPreference = "Stop"

# Function to write log messages
function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Write-Host "[$timestamp] [$Level] $Message" -ForegroundColor $(
        switch ($Level) {
            "ERROR" { "Red" }
            "WARNING" { "Yellow" }
            "INFO" { "Green" }
            default { "White" }
        }
    )
}

try {
    Write-Log "Starting container security scan for image: $ImageName"
    
    # Create output directory
    $outputDir = "/lab/results/$(Get-Date -Format 'yyyyMMdd-HHmmss')-$($ImageName -replace '[/:]', '-')"
    New-Item -ItemType Directory -Path $outputDir -Force | Out-Null
    Write-Log "Created output directory: $outputDir"
    
    # Run Trivy scan
    Write-Log "Running Trivy vulnerability scan..."
    $trivyOutput = Join-Path $outputDir "trivy-scan.$($OutputFormat.ToLower())"
    
    $trivyArgs = @(
        "image"
        "--severity", "$SeverityFilter,HIGH,CRITICAL"
        "--format", $OutputFormat.ToLower()
        "--output", $trivyOutput
        $ImageName
    )
    
    & trivy @trivyArgs
    if ($LASTEXITCODE -ne 0) {
        Write-Log "Trivy scan failed with exit code: $LASTEXITCODE" "ERROR"
    } else {
        Write-Log "Trivy scan completed: $trivyOutput"
    }
    
    # Run Grype scan
    Write-Log "Running Grype vulnerability scan..."
    $grypeOutput = Join-Path $outputDir "grype-scan.$($OutputFormat.ToLower())"
    
    $grypeArgs = @(
        $ImageName
        "-o", $OutputFormat.ToLower()
        "--file", $grypeOutput
    )
    
    & grype @grypeArgs
    if ($LASTEXITCODE -ne 0) {
        Write-Log "Grype scan failed with exit code: $LASTEXITCODE" "WARNING"
    } else {
        Write-Log "Grype scan completed: $grypeOutput"
    }
    
    # Generate SBOM if requested
    if ($GenerateSBOM) {
        Write-Log "Generating Software Bill of Materials (SBOM)..."
        $sbomOutput = Join-Path $outputDir "sbom.json"
        
        & syft $ImageName -o json > $sbomOutput
        if ($LASTEXITCODE -ne 0) {
            Write-Log "SBOM generation failed with exit code: $LASTEXITCODE" "WARNING"
        } else {
            Write-Log "SBOM generated: $sbomOutput"
        }
    }
    
    # Parse Trivy results for summary
    if (Test-Path $trivyOutput) {
        try {
            if ($OutputFormat -eq "JSON") {
                $trivyResults = Get-Content $trivyOutput | ConvertFrom-Json
                $vulnerabilityCount = 0
                $criticalCount = 0
                $highCount = 0
                
                if ($trivyResults.Results) {
                    foreach ($result in $trivyResults.Results) {
                        if ($result.Vulnerabilities) {
                            $vulnerabilityCount += $result.Vulnerabilities.Count
                            $criticalCount += ($result.Vulnerabilities | Where-Object { $_.Severity -eq "CRITICAL" }).Count
                            $highCount += ($result.Vulnerabilities | Where-Object { $_.Severity -eq "HIGH" }).Count
                        }
                    }
                }
                
                Write-Log "Scan Summary:"
                Write-Log "  Total Vulnerabilities: $vulnerabilityCount"
                Write-Log "  Critical: $criticalCount"
                Write-Log "  High: $highCount"
                
                # Create summary report
                $summary = @{
                    Image = $ImageName
                    ScanTime = Get-Date -Format "o"
                    TotalVulnerabilities = $vulnerabilityCount
                    Critical = $criticalCount
                    High = $highCount
                    SeverityFilter = $SeverityFilter
                    OutputDirectory = $outputDir
                }
                
                $summaryOutput = Join-Path $outputDir "scan-summary.json"
                $summary | ConvertTo-Json -Depth 5 | Out-File -FilePath $summaryOutput -Encoding UTF8
                Write-Log "Summary report saved: $summaryOutput"
            }
        }
        catch {
            Write-Log "Failed to parse scan results: $($_.Exception.Message)" "WARNING"
        }
    }
    
    Write-Log "Container security scan completed successfully"
    Write-Log "Results saved in: $outputDir"
    
}
catch {
    Write-Log "Error during security scan: $($_.Exception.Message)" "ERROR"
    exit 1
}