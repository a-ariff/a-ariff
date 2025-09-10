#!/usr/bin/env pwsh
# Automated Vulnerability Patching Script
# Scans for vulnerabilities and applies available patches

param(
    [Parameter(Mandatory=$false)]
    [string]$ImageName,
    
    [Parameter(Mandatory=$false)]
    [ValidateSet("CRITICAL", "HIGH", "MEDIUM", "LOW")]
    [string]$MinSeverity = "HIGH",
    
    [Parameter(Mandatory=$false)]
    [switch]$DryRun,
    
    [Parameter(Mandatory=$false)]
    [switch]$AutoApprove
)

# Set error action preference
$ErrorActionPreference = "Stop"

# Function to write log messages
function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $color = switch ($Level) {
        "ERROR" { "Red" }
        "WARNING" { "Yellow" }
        "INFO" { "Green" }
        "DEBUG" { "Cyan" }
        default { "White" }
    }
    Write-Host "[$timestamp] [$Level] $Message" -ForegroundColor $color
}

function Get-VulnerabilityReport {
    param([string]$Image)
    
    Write-Log "Scanning image for vulnerabilities: $Image"
    
    # Run Trivy scan
    $trivyOutput = "/tmp/vuln-scan-$(Get-Date -Format 'yyyyMMdd-HHmmss').json"
    
    try {
        & trivy image --format json --output $trivyOutput --severity "$MinSeverity,CRITICAL" $Image
        
        if (Test-Path $trivyOutput) {
            $results = Get-Content $trivyOutput | ConvertFrom-Json
            Write-Log "Vulnerability scan completed. Results saved to: $trivyOutput"
            return $results
        } else {
            throw "Trivy scan failed - no output file generated"
        }
    }
    catch {
        Write-Log "Trivy scan failed: $($_.Exception.Message)" "ERROR"
        throw
    }
}

function Get-PatchableVulnerabilities {
    param($ScanResults)
    
    $patchableVulns = @()
    
    foreach ($result in $ScanResults.Results) {
        if ($result.Vulnerabilities) {
            foreach ($vuln in $result.Vulnerabilities) {
                if ($vuln.FixedVersion -and $vuln.FixedVersion -ne "" -and $vuln.FixedVersion -ne "None") {
                    $patchableVulns += [PSCustomObject]@{
                        VulnerabilityID = $vuln.VulnerabilityID
                        PackageName = $vuln.PkgName
                        InstalledVersion = $vuln.InstalledVersion
                        FixedVersion = $vuln.FixedVersion
                        Severity = $vuln.Severity
                        Title = $vuln.Title
                        Description = $vuln.Description
                        Target = $result.Target
                    }
                }
            }
        }
    }
    
    return $patchableVulns
}

function New-PatchDockerfile {
    param(
        [string]$BaseImage,
        [array]$PatchableVulns
    )
    
    $patchDockerfile = @"
# Auto-generated patched Dockerfile
# Base image: $BaseImage
# Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')

FROM $BaseImage

# Update package lists
RUN apt-get update

"@

    # Group vulnerabilities by package manager
    $aptPackages = $PatchableVulns | Where-Object { $_.Target -like "*ubuntu*" -or $_.Target -like "*debian*" }
    $yumPackages = $PatchableVulns | Where-Object { $_.Target -like "*centos*" -or $_.Target -like "*rhel*" }
    $alpinePackages = $PatchableVulns | Where-Object { $_.Target -like "*alpine*" }
    
    # Add APT package updates
    if ($aptPackages) {
        $patchDockerfile += "# Update APT packages`n"
        $aptUpgrades = $aptPackages | ForEach-Object { "$($_.PackageName)=$($_.FixedVersion)" }
        $patchDockerfile += "RUN apt-get install -y $($aptUpgrades -join ' ') && apt-get clean && rm -rf /var/lib/apt/lists/*`n`n"
    }
    
    # Add YUM package updates
    if ($yumPackages) {
        $patchDockerfile += "# Update YUM packages`n"
        $yumUpgrades = $yumPackages | ForEach-Object { "$($_.PackageName)-$($_.FixedVersion)" }
        $patchDockerfile += "RUN yum update -y $($yumUpgrades -join ' ') && yum clean all`n`n"
    }
    
    # Add Alpine package updates
    if ($alpinePackages) {
        $patchDockerfile += "# Update Alpine packages`n"
        $alpineUpgrades = $alpinePackages | ForEach-Object { "$($_.PackageName)=$($_.FixedVersion)" }
        $patchDockerfile += "RUN apk add --no-cache $($alpineUpgrades -join ' ')`n`n"
    }
    
    $patchDockerfile += @"
# Verify updates
RUN echo "Patch application completed at: `$(date)" > /tmp/patch-applied.txt

# Clean up
RUN apt-get autoremove -y && apt-get autoclean || true
"@
    
    return $patchDockerfile
}

function Build-PatchedImage {
    param(
        [string]$OriginalImage,
        [string]$DockerfileContent,
        [string]$PatchedTag
    )
    
    $dockerfilePath = "/tmp/Dockerfile.patched"
    $DockerfileContent | Out-File -FilePath $dockerfilePath -Encoding UTF8
    
    Write-Log "Building patched image: $PatchedTag"
    
    try {
        $buildOutput = docker build -t $PatchedTag -f $dockerfilePath . 2>&1
        
        if ($LASTEXITCODE -eq 0) {
            Write-Log "Successfully built patched image: $PatchedTag"
            return $true
        } else {
            Write-Log "Failed to build patched image. Output: $buildOutput" "ERROR"
            return $false
        }
    }
    catch {
        Write-Log "Error building patched image: $($_.Exception.Message)" "ERROR"
        return $false
    }
}

function Test-PatchedImage {
    param([string]$PatchedImage)
    
    Write-Log "Testing patched image: $PatchedImage"
    
    # Run basic functionality test
    try {
        $testOutput = docker run --rm $PatchedImage sh -c "echo 'Image test successful'" 2>&1
        
        if ($LASTEXITCODE -eq 0) {
            Write-Log "Patched image test passed"
            
            # Re-scan for vulnerabilities
            Write-Log "Re-scanning patched image for vulnerabilities..."
            $patchedResults = Get-VulnerabilityReport -Image $PatchedImage
            $remainingVulns = Get-PatchableVulnerabilities -ScanResults $patchedResults
            
            Write-Log "Remaining patchable vulnerabilities: $($remainingVulns.Count)"
            return $true
        } else {
            Write-Log "Patched image test failed. Output: $testOutput" "ERROR"
            return $false
        }
    }
    catch {
        Write-Log "Error testing patched image: $($_.Exception.Message)" "ERROR"
        return $false
    }
}

# Main execution
try {
    Write-Log "Starting automated vulnerability patching process"
    Write-Log "Target image: $ImageName"
    Write-Log "Minimum severity: $MinSeverity"
    Write-Log "Dry run: $DryRun"
    
    if (!$ImageName) {
        Write-Log "No image specified. Scanning all local images..."
        $images = docker images --format "{{.Repository}}:{{.Tag}}" | Where-Object { $_ -notmatch "<none>" }
        
        foreach ($img in $images) {
            Write-Log "Processing image: $img"
            $ImageName = $img
            break  # Process first image for demo
        }
    }
    
    if (!$ImageName) {
        throw "No image available to patch"
    }
    
    # Step 1: Scan for vulnerabilities
    $scanResults = Get-VulnerabilityReport -Image $ImageName
    
    # Step 2: Identify patchable vulnerabilities
    $patchableVulns = Get-PatchableVulnerabilities -ScanResults $scanResults
    
    Write-Log "Found $($patchableVulns.Count) patchable vulnerabilities"
    
    if ($patchableVulns.Count -eq 0) {
        Write-Log "No patchable vulnerabilities found. Exiting."
        exit 0
    }
    
    # Display vulnerabilities
    Write-Log "Patchable vulnerabilities:" "INFO"
    $patchableVulns | ForEach-Object {
        Write-Log "  - $($_.VulnerabilityID): $($_.PackageName) $($_.InstalledVersion) -> $($_.FixedVersion) ($($_.Severity))"
    }
    
    if ($DryRun) {
        Write-Log "Dry run mode - no patches will be applied"
        exit 0
    }
    
    # Step 3: Get user approval if not auto-approved
    if (!$AutoApprove) {
        $response = Read-Host "Apply patches? (y/N)"
        if ($response -ne "y" -and $response -ne "Y") {
            Write-Log "Patching cancelled by user"
            exit 0
        }
    }
    
    # Step 4: Generate patched Dockerfile
    $patchedDockerfile = New-PatchDockerfile -BaseImage $ImageName -PatchableVulns $patchableVulns
    
    # Step 5: Build patched image
    $patchedTag = "$ImageName-patched-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
    $buildSuccess = Build-PatchedImage -OriginalImage $ImageName -DockerfileContent $patchedDockerfile -PatchedTag $patchedTag
    
    if (!$buildSuccess) {
        throw "Failed to build patched image"
    }
    
    # Step 6: Test patched image
    $testSuccess = Test-PatchedImage -PatchedImage $patchedTag
    
    if ($testSuccess) {
        Write-Log "Automated vulnerability patching completed successfully!"
        Write-Log "Patched image: $patchedTag"
        Write-Log "Original image: $ImageName"
    } else {
        Write-Log "Patched image failed testing. Rolling back..." "WARNING"
        docker rmi $patchedTag 2>$null
    }
    
}
catch {
    Write-Log "Automated patching failed: $($_.Exception.Message)" "ERROR"
    exit 1
}