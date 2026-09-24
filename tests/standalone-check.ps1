# Loads the standalone edition in headless Edge and checks the rendered page:
# the builder UI is there, and no DataFlow control is.
param([string]$File = "$PSScriptRoot\..\dist\standalone\eam-load-builder.html")
$ErrorActionPreference = 'Stop'
$edge = "${env:ProgramFiles(x86)}\Microsoft\Edge\Application\msedge.exe"
if (-not (Test-Path $File)) { throw "Missing $File - run scripts\build-editions.ps1 first" }
$url = ([Uri](Resolve-Path $File).Path).AbsoluteUri
$dom = & $edge --headless=new --disable-gpu --virtual-time-budget=5000 --dump-dom $url 2>$null | Out-String
$fail = @()
if ($dom -notmatch 'id="bUndo"') { $fail += 'builder toolbar did not render' }
if ($dom -match 'id="bLoadDF"') { $fail += 'Load selected button is present' }
if ($dom -match 'id="bUpdateDF"') { $fail += 'Update selected button is present' }
if ($dom -match 'id="bCheckDF"') { $fail += 'Check Oracle button is present' }
if ($fail) { $fail | ForEach-Object { Write-Host "FAIL: $_" }; exit 1 }
Write-Host "PASS: standalone edition renders without DataFlow controls"
