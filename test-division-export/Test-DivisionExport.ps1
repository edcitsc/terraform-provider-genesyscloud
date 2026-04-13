<#
.SYNOPSIS
    Test script for verifying division export behavior

.DESCRIPTION
    This script helps test and analyze the tf_export behavior when exporting divisions.
    It runs the export and analyzes the results to help diagnose unexpected behavior.

.PARAMETER DivisionGuid
    Optional GUID of a specific division to test with

.EXAMPLE
    .\Test-DivisionExport.ps1
    # Runs all division exports

.EXAMPLE
    .\Test-DivisionExport.ps1 -DivisionGuid "12345678-1234-1234-1234-123456789012"
    # Tests export of specific division
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$DivisionGuid
)

$ErrorActionPreference = "Stop"

Write-Host "`n=== Division Export Test ===" -ForegroundColor Cyan

# Check if we're in the right directory
if (-not (Test-Path "main.tf")) {
    Write-Error "main.tf not found. Please run this script from the test-division-export directory."
    exit 1
}

# If a specific division GUID was provided, update the main.tf file
if ($DivisionGuid) {
    Write-Host "`nUpdating main.tf with division GUID: $DivisionGuid" -ForegroundColor Yellow
    $content = Get-Content main.tf -Raw
    $content = $content -replace 'YOUR-DIVISION-GUID-HERE', $DivisionGuid
    Set-Content main.tf $content
}

# Initialize Terraform
Write-Host "`n--- Terraform Init ---" -ForegroundColor Cyan
terraform init

function Test-Export {
    param(
        [string]$TargetResource,
        [string]$ExportDir,
        [string]$TestName
    )
    
    Write-Host "`n=== $TestName ===" -ForegroundColor Green
    Write-Host "Target: $TargetResource" -ForegroundColor Gray
    
    # Clean up previous export
    if (Test-Path $ExportDir) {
        Remove-Item $ExportDir -Recurse -Force
    }
    
    # Measure export time
    $startTime = Get-Date
    Write-Host "Starting export at: $($startTime.ToString('HH:mm:ss'))" -ForegroundColor Gray
    
    try {
        # Run terraform apply with proper quoting
        $targetArg = "-target=$TargetResource"
        & terraform apply $targetArg -auto-approve
        $exitCode = $LASTEXITCODE
        
        $endTime = Get-Date
        $duration = $endTime - $startTime
        
        if ($exitCode -eq 0) {
            Write-Host "Export completed in: $($duration.TotalSeconds) seconds" -ForegroundColor Green
        }
        else {
            Write-Host "Export failed with exit code $exitCode in: $($duration.TotalSeconds) seconds" -ForegroundColor Red
        }
        
        # Analyze results
        if (Test-Path $ExportDir) {
            Write-Host "`nAnalyzing export results..." -ForegroundColor Cyan
            
            # Find the JSON file
            $jsonFile = Get-ChildItem $ExportDir -Filter "*.tf.json" -Recurse | Select-Object -First 1
            
            if ($jsonFile) {
                $json = Get-Content $jsonFile.FullName | ConvertFrom-Json
                
                # Count resource types
                if ($json.resource) {
                    $resourceTypes = $json.resource.PSObject.Properties.Name
                    $resourceCount = 0
                    
                    Write-Host "`nResource Types Exported:" -ForegroundColor Yellow
                    foreach ($resType in $resourceTypes) {
                        $instanceCount = ($json.resource.$resType.PSObject.Properties).Count
                        $resourceCount += $instanceCount
                        Write-Host "  - $resType : $instanceCount instances" -ForegroundColor White
                    }
                    
                    Write-Host "`nTotal Resources: $resourceCount" -ForegroundColor Green
                    
                    # Check if only divisions were exported
                    if ($resourceTypes.Count -eq 1 -and $resourceTypes[0] -eq "genesyscloud_auth_division") {
                        Write-Host "✓ SUCCESS: Only divisions exported as expected!" -ForegroundColor Green
                    }
                    elseif ($resourceTypes.Count -gt 1) {
                        Write-Host "⚠ WARNING: Multiple resource types found!" -ForegroundColor Yellow
                        Write-Host "  Expected: Only genesyscloud_auth_division" -ForegroundColor Yellow
                        Write-Host "  Found: $($resourceTypes -join ', ')" -ForegroundColor Yellow
                    }
                }
                else {
                    Write-Host "⚠ No resources found in export" -ForegroundColor Yellow
                }
                
                # Show file sizes
                Write-Host "`nExported Files:" -ForegroundColor Cyan
                Get-ChildItem $ExportDir -Recurse -File | ForEach-Object {
                    $sizeKB = [math]::Round($_.Length / 1KB, 2)
                    Write-Host "  $($_.Name) - ${sizeKB} KB" -ForegroundColor Gray
                }
            }
            else {
                Write-Host "⚠ No .tf.json file found in export directory" -ForegroundColor Yellow
            }
        }
        else {
            Write-Host "⚠ Export directory not created: $ExportDir" -ForegroundColor Yellow
        }
    }
    catch {
        Write-Host "✗ ERROR during export: $_" -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Red
    }
    
    Write-Host "`n$('=' * 80)" -ForegroundColor Gray
}

# Run Test 1: No dependency resolution
Test-Export `
    -TargetResource "genesyscloud_tf_export.test_division_no_deps" `
    -ExportDir ".\export_division_no_deps" `
    -TestName "Test 1: Division Export WITHOUT Dependency Resolution"

# Run Test 2: With dependency resolution
Test-Export `
    -TargetResource "genesyscloud_tf_export.test_division_with_deps" `
    -ExportDir ".\export_division_with_deps" `
    -TestName "Test 2: Division Export WITH Dependency Resolution"

# Run Test 3: Specific division (only if GUID provided)
if ($DivisionGuid) {
    Test-Export `
        -TargetResource "genesyscloud_tf_export.test_specific_division" `
        -ExportDir ".\export_specific_division" `
        -TestName "Test 3: Specific Division Export BY ID"
}
else {
    Write-Host "`n=== Test 3: Skipped ===" -ForegroundColor Yellow
    Write-Host "Provide -DivisionGuid parameter to test specific division export" -ForegroundColor Gray
}

# Comparison
Write-Host "`n=== Comparison Summary ===" -ForegroundColor Cyan

$test1Size = 0
$test2Size = 0
$test3Size = 0

if (Test-Path ".\export_division_no_deps") {
    $test1Size = (Get-ChildItem ".\export_division_no_deps" -Recurse -File | Measure-Object -Property Length -Sum).Sum
}
if (Test-Path ".\export_division_with_deps") {
    $test2Size = (Get-ChildItem ".\export_division_with_deps" -Recurse -File | Measure-Object -Property Length -Sum).Sum
}
if (Test-Path ".\export_specific_division") {
    $test3Size = (Get-ChildItem ".\export_specific_division" -Recurse -File | Measure-Object -Property Length -Sum).Sum
}

Write-Host "`nExport Sizes:" -ForegroundColor Yellow
Write-Host "  Test 1 (No Deps):    $([math]::Round($test1Size / 1KB, 2)) KB" -ForegroundColor White
Write-Host "  Test 2 (With Deps):  $([math]::Round($test2Size / 1KB, 2)) KB" -ForegroundColor White
if ($DivisionGuid) {
    Write-Host "  Test 3 (By ID):      $([math]::Round($test3Size / 1KB, 2)) KB" -ForegroundColor White
}

Write-Host "`n✓ Test completed!" -ForegroundColor Green
Write-Host "Review the exports in their respective directories." -ForegroundColor Gray

# Provide next steps
Write-Host "`n--- Next Steps ---" -ForegroundColor Cyan
Write-Host "1. Compare the resource types in each export" -ForegroundColor Gray
Write-Host "2. If unexpected resources appear, check your filter configuration" -ForegroundColor Gray
Write-Host "3. Enable TF_LOG=DEBUG for detailed logging: `$env:TF_LOG='DEBUG'" -ForegroundColor Gray
Write-Host "4. Review the README.md for troubleshooting tips" -ForegroundColor Gray
