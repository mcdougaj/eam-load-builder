# Loads the standalone edition in headless Edge and checks the rendered page:
# the builder UI is there, and no DataFlow control is.
# Uses Edge's DevTools protocol (--dump-dom prints nothing in recent Edge versions). Works in Windows PowerShell 5.1 and 7.
param([string]$File = "$PSScriptRoot\..\dist\standalone\eam-load-builder.html", [int]$Port = 9339, [int]$WaitSeconds = 20)
$ErrorActionPreference = 'Stop'
$edge = @("${env:ProgramFiles(x86)}\Microsoft\Edge\Application\msedge.exe", "$env:ProgramFiles\Microsoft\Edge\Application\msedge.exe") |
    Where-Object { Test-Path $_ } | Select-Object -First 1
if (-not $edge) { throw "Microsoft Edge not found" }
if (-not (Test-Path $File)) { throw "Missing $File - run scripts\build-editions.ps1 first" }
$url = ([Uri](Resolve-Path $File).Path).AbsoluteUri
$profileDir = Join-Path $env:TEMP "eam-standalone-check-$PID"

$proc = Start-Process $edge -PassThru -ArgumentList @(
    '--headless=new', '--disable-gpu', '--no-first-run', "--remote-debugging-port=$Port", "--user-data-dir=$profileDir", $url)
try {
    # Find the page's DevTools socket.
    $ws = $null
    $deadline = (Get-Date).AddSeconds($WaitSeconds)
    while (-not $ws -and (Get-Date) -lt $deadline) {
        Start-Sleep -Milliseconds 300
        try {
            $ws = (Invoke-RestMethod "http://127.0.0.1:$Port/json" -TimeoutSec 2) |
                Where-Object { $_.type -eq 'page' -and $_.url -like 'file:*' } |
                Select-Object -First 1 -ExpandProperty webSocketDebuggerUrl
        } catch { }
    }
    if (-not $ws) { throw "Edge didn't open the page within $WaitSeconds s" }

    $socket = [System.Net.WebSockets.ClientWebSocket]::new()
    $socket.ConnectAsync([Uri]$ws, [Threading.CancellationToken]::None).Wait()
    $id = 0
    function Invoke-Cdp([string]$expr) {
        $script:id++
        $msg = @{ id = $script:id; method = 'Runtime.evaluate'; params = @{ expression = $expr; returnByValue = $true } } | ConvertTo-Json -Compress -Depth 5
        $bytes = [Text.Encoding]::UTF8.GetBytes($msg)
        $socket.SendAsync([ArraySegment[byte]]::new($bytes), 'Text', $true, [Threading.CancellationToken]::None).Wait()
        while ($true) {
            $buf = New-Object byte[] 1048576; $sb = [Text.StringBuilder]::new()
            do {
                $r = $socket.ReceiveAsync([ArraySegment[byte]]::new($buf), [Threading.CancellationToken]::None).Result
                [void]$sb.Append([Text.Encoding]::UTF8.GetString($buf, 0, $r.Count))
            } until ($r.EndOfMessage)
            $reply = $sb.ToString() | ConvertFrom-Json
            if ($reply.id -eq $script:id) { return $reply.result.result.value }
        }
    }

    # Wait for the page to finish loading: the DataFlow buttons are in the HTML and the startup script removes them.
    $probe = "JSON.stringify({ready:document.readyState==='complete',toolbar:!!document.getElementById('bUndo'),load:!!document.getElementById('bLoadDF'),update:!!document.getElementById('bUpdateDF'),check:!!document.getElementById('bCheckDF')})"
    $state = $null
    while ((Get-Date) -lt $deadline) {
        $state = (Invoke-Cdp $probe) | ConvertFrom-Json
        if ($state.ready -and $state.toolbar) { Start-Sleep -Milliseconds 500; $state = (Invoke-Cdp $probe) | ConvertFrom-Json; break }
        Start-Sleep -Milliseconds 300
    }
    $socket.Dispose()
}
finally {
    if (-not $proc.HasExited) { Stop-Process -Id $proc.Id -Force -ErrorAction SilentlyContinue }
    Get-CimInstance Win32_Process -Filter "Name='msedge.exe'" |
        Where-Object { $_.CommandLine -like "*$profileDir*" } |
        ForEach-Object { Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue }
    Start-Sleep -Milliseconds 500
    Remove-Item $profileDir -Recurse -Force -ErrorAction SilentlyContinue
}

$fail = @()
if (-not $state -or -not $state.toolbar) { $fail += 'builder toolbar did not render' }
if ($state.load) { $fail += 'Load selected button is present' }
if ($state.update) { $fail += 'Update selected button is present' }
if ($state.check) { $fail += 'Check Oracle button is present' }
if ($fail) { $fail | ForEach-Object { Write-Host "FAIL: $_" }; exit 1 }
Write-Host "PASS: standalone edition renders without DataFlow controls"
