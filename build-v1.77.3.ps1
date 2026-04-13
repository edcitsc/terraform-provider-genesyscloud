#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Build Terraform Provider v1.77.3 for Windows and Linux
#>

param(
    [string]$Version = "1.77.3"
)

$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"

# Ensure we're in the right directory
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $scriptDir

Write-Host "`n================================================" -ForegroundColor Cyan
Write-Host "   Building Terraform Provider v$Version" -ForegroundColor White
Write-Host "================================================`n" -ForegroundColor Cyan

# Ensure 64-bit Go
$goVersion = go version
if ($goVersion -notlike "*amd64*") {
    Write-Host "❌ ERROR: 64-bit Go required!" -ForegroundColor Red
    Write-Host "   Current: $goVersion" -ForegroundColor Yellow
    Write-Host "   Run: .\fix-go-path.ps1" -ForegroundColor Cyan
    exit 1
}
Write-Host "✅ Using: $goVersion`n" -ForegroundColor Green

# Clean dist directory
Write-Host "Cleaning dist directory..." -ForegroundColor Yellow
if (Test-Path "dist") {
    Remove-Item -Path "dist\*" -Recurse -Force
}
New-Item -ItemType Directory -Path "dist" -Force | Out-Null

# Build Windows
Write-Host "`n[1/2] Building for Windows (amd64)..." -ForegroundColor Cyan
$env:GOOS = "windows"
$env:GOARCH = "amd64"
$env:CGO_ENABLED = "0"

$winBinary = "dist\terraform-provider-genesyscloud_v$Version.exe"
go build -o $winBinary -ldflags "-s -w -X main.version=$Version" .

if ($LASTEXITCODE -eq 0 -and (Test-Path $winBinary)) {
    $winSize = (Get-Item $winBinary).Length / 1MB
    $winHash = (Get-FileHash $winBinary -Algorithm SHA256).Hash.ToLower()
    Write-Host "      ✅ Windows binary: $([math]::Round($winSize, 2)) MB" -ForegroundColor Green
    Write-Host "         SHA256: $winHash" -ForegroundColor Gray
    
    # Create zip for Windows
    Compress-Archive -Path $winBinary -DestinationPath "dist\terraform-provider-genesyscloud_${Version}_windows_amd64.zip" -Force
    Write-Host "      ✅ Windows zip created" -ForegroundColor Green
}
else {
    Write-Host "      ❌ Windows build failed!" -ForegroundColor Red
    exit 1
}

# Build Linux
Write-Host "`n[2/2] Building for Linux (amd64)..." -ForegroundColor Cyan
$env:GOOS = "linux"
$env:GOARCH = "amd64"
$env:CGO_ENABLED = "0"

$linuxBinary = "dist\terraform-provider-genesyscloud_v$Version"
go build -o $linuxBinary -ldflags "-s -w -X main.version=$Version" .

if ($LASTEXITCODE -eq 0 -and (Test-Path $linuxBinary)) {
    $linuxSize = (Get-Item $linuxBinary).Length / 1MB
    $linuxHash = (Get-FileHash $linuxBinary -Algorithm SHA256).Hash.ToLower()
    Write-Host "      ✅ Linux binary: $([math]::Round($linuxSize, 2)) MB" -ForegroundColor Green
    Write-Host "         SHA256: $linuxHash" -ForegroundColor Gray
    
    # Create zip for Linux
    Compress-Archive -Path $linuxBinary -DestinationPath "dist\terraform-provider-genesyscloud_${Version}_linux_amd64.zip" -Force
    Write-Host "      ✅ Linux zip created" -ForegroundColor Green
    
    # Calculate zip hash for terraform
    $linuxZipHash = (Get-FileHash "dist\terraform-provider-genesyscloud_${Version}_linux_amd64.zip" -Algorithm SHA256).Hash
    $h1Hash = "h1:" + [Convert]::ToBase64String([System.Security.Cryptography.SHA256]::Create().ComputeHash([System.IO.File]::ReadAllBytes("dist\terraform-provider-genesyscloud_${Version}_linux_amd64.zip")))
    
    Write-Host "`n      📋 Update 1.77.3.json with this hash:" -ForegroundColor Yellow
    Write-Host "         $h1Hash" -ForegroundColor White
    
}
else {
    Write-Host "      ❌ Linux build failed!" -ForegroundColor Red
    exit 1
}

Write-Host "`n================================================" -ForegroundColor Cyan
Write-Host "   ✅ Build Complete!" -ForegroundColor Green
Write-Host "================================================`n" -ForegroundColor Cyan

Write-Host "Files created:" -ForegroundColor Yellow
Get-ChildItem "dist\*.zip" | ForEach-Object {
    $size = $_.Length / 1MB
    Write-Host "   📦 $($_.Name) ($([math]::Round($size, 2)) MB)" -ForegroundColor Gray
}

Write-Host "`nNext Steps:" -ForegroundColor Yellow
Write-Host "   1. Update the hash in 1.77.3.json (shown above)" -ForegroundColor Gray
Write-Host "   2. Test locally with: terraform init" -ForegroundColor Gray
Write-Host "   3. Upload to your hosting location" -ForegroundColor Gray
Write-Host ""
