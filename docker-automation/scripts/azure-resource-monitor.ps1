#!/usr/bin/env pwsh
# Azure Resource Monitor Script
# Monitors Azure resources and generates compliance reports

param(
    [Parameter(Mandatory=$false)]
    [string]$SubscriptionId,
    
    [Parameter(Mandatory=$false)]
    [string]$ResourceGroupName,
    
    [Parameter(Mandatory=$false)]
    [ValidateSet("JSON", "CSV", "HTML")]
    [string]$OutputFormat = "JSON"
)

# Set error action preference
$ErrorActionPreference = "Stop"

# Function to write log messages
function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Write-Host "[$timestamp] [$Level] $Message"
}

try {
    Write-Log "Starting Azure Resource Monitor"
    
    # Check if logged into Azure
    $context = Get-AzContext
    if (!$context) {
        Write-Log "Not logged into Azure. Please run 'Connect-AzAccount' first." "ERROR"
        exit 1
    }
    
    Write-Log "Connected to Azure subscription: $($context.Subscription.Name)"
    
    # Set subscription if provided
    if ($SubscriptionId) {
        Set-AzContext -SubscriptionId $SubscriptionId
        Write-Log "Switched to subscription: $SubscriptionId"
    }
    
    # Get resources
    if ($ResourceGroupName) {
        $resources = Get-AzResource -ResourceGroupName $ResourceGroupName
        Write-Log "Found $($resources.Count) resources in resource group: $ResourceGroupName"
    } else {
        $resources = Get-AzResource
        Write-Log "Found $($resources.Count) total resources in subscription"
    }
    
    # Analyze resources
    $analysis = $resources | Group-Object ResourceType | Sort-Object Count -Descending | Select-Object @{
        Name = "ResourceType"
        Expression = { $_.Name }
    }, @{
        Name = "Count"
        Expression = { $_.Count }
    }, @{
        Name = "Resources"
        Expression = { $_.Group | Select-Object Name, Location, ResourceGroupName }
    }
    
    # Generate report
    $report = @{
        Timestamp = Get-Date -Format "o"
        Subscription = $context.Subscription.Name
        SubscriptionId = $context.Subscription.Id
        ResourceGroup = $ResourceGroupName
        TotalResources = $resources.Count
        ResourceTypes = $analysis
    }
    
    # Output results
    $outputFile = "/workspace/logs/azure-resources-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
    
    switch ($OutputFormat) {
        "JSON" {
            $outputFile += ".json"
            $report | ConvertTo-Json -Depth 10 | Out-File -FilePath $outputFile -Encoding UTF8
        }
        "CSV" {
            $outputFile += ".csv"
            $resources | Select-Object Name, ResourceType, Location, ResourceGroupName | Export-Csv -Path $outputFile -NoTypeInformation
        }
        "HTML" {
            $outputFile += ".html"
            $html = $resources | Select-Object Name, ResourceType, Location, ResourceGroupName | ConvertTo-Html -Title "Azure Resources Report"
            $html | Out-File -FilePath $outputFile -Encoding UTF8
        }
    }
    
    Write-Log "Report saved to: $outputFile"
    Write-Log "Azure Resource Monitor completed successfully"
    
    return $report
}
catch {
    Write-Log "Error: $($_.Exception.Message)" "ERROR"
    exit 1
}