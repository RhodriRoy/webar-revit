$port = 8080
$dir = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $dir

[Console]::OutputEncoding = [Text.Encoding]::UTF8

Write-Host "=== WebAR Revit Viewer ===" -ForegroundColor Cyan
Write-Host ""

# Kill old http-server / tunnel on port 8080
Get-NetTCPConnection -LocalPort $port -ErrorAction SilentlyContinue | ForEach-Object {
  Stop-Process -Id $_.OwningProcess -Force -ErrorAction SilentlyContinue
}
Start-Sleep 1

# Kill old serveo SSH tunnels
Get-CimInstance Win32_Process -Filter "Name='ssh.exe'" -ErrorAction SilentlyContinue | Where-Object { $_.CommandLine -match 'serveo' } | ForEach-Object {
  Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue
}

# Start http-server in background
$logFile = Join-Path $env:TEMP "http-server-log.txt"
$httpProc = Start-Process -FilePath "npx" -ArgumentList "http-server . -p $port --cors -c-1" -WindowStyle Hidden -PassThru -RedirectStandardOutput $logFile
Start-Sleep 3

# Verify it's running
$check = Get-NetTCPConnection -LocalPort $port -ErrorAction SilentlyContinue
if (-not $check) {
  Write-Host "http-server 启动失败，手动启动:" -ForegroundColor Red
  Write-Host "npx http-server . -p $port --cors -c-1" -ForegroundColor Yellow
  exit 1
}
Write-Host "OK http-server (port $port)" -ForegroundColor Green

Write-Host "创建隧道中..." -ForegroundColor Yellow

# Start serveo tunnel - uses SSH, no warning page
$tunnelFile = Join-Path $env:TEMP "serveo-url.txt"
Remove-Item $tunnelFile -ErrorAction SilentlyContinue

$tunnelProc = Start-Process -FilePath "ssh" -ArgumentList "-o StrictHostKeyChecking=no -o ServerAliveInterval=60 -R 80:localhost:$port serveo.net" -WindowStyle Hidden -PassThru -RedirectStandardOutput $tunnelFile -RedirectStandardError $tunnelFile

# Wait for URL
$url = $null
for ($i = 0; $i -lt 30 -and -not $url; $i++) {
  Start-Sleep 1
  if (Test-Path $tunnelFile) {
    $content = Get-Content $tunnelFile -ErrorAction SilentlyContinue
    foreach ($line in $content) {
      if ($line -match 'https://\S+\.serveo\.net') {
        $url = $matches[0]
        break
      }
    }
  }
}

Write-Host ""
if ($url) {
  Write-Host "===== 部署成功 =====" -ForegroundColor Green
  Write-Host "手机访问: $url" -ForegroundColor Yellow
  Write-Host "无警告页，手机直接打开" -ForegroundColor Green
  Write-Host "按任意键退出" -ForegroundColor Gray
  Start-Process $url
  $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
} else {
  Write-Host "Serveo 隧道失败，试试 localtunnel:" -ForegroundColor Red
  Write-Host "npx localtunnel --port $port" -ForegroundColor Yellow
  $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

# Cleanup
Stop-Process -Id $httpProc.Id -Force -ErrorAction SilentlyContinue
Stop-Process -Id $tunnelProc.Id -Force -ErrorAction SilentlyContinue
