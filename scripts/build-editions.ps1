# One source, two editions. Writes the standalone file and the copy DataFlow bundles.
param([string]$DataFlowRepo = "D:\oracledataloader")
$ErrorActionPreference = 'Stop'
$src = Join-Path $PSScriptRoot "..\index.html"
$standalone = Join-Path $PSScriptRoot "..\dist\standalone"
New-Item -ItemType Directory -Force $standalone | Out-Null
Copy-Item $src (Join-Path $standalone "eam-load-builder.html") -Force
if (Test-Path $DataFlowRepo) {
    $dest = Join-Path $DataFlowRepo "builder"
    New-Item -ItemType Directory -Force $dest | Out-Null
    Copy-Item $src (Join-Path $dest "index.html") -Force
    Write-Host "DataFlow edition: $dest\index.html"
}
Write-Host "Standalone edition: $standalone\eam-load-builder.html"
