$port = 8080
$dir = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $dir

Write-Host "=== WebAR Revit Viewer - Local Tunnel ===" -ForegroundColor Cyan
Write-Host ""

# Kill old processes on port
$old = Get-NetTCPConnection -LocalPort $port -ErrorAction SilentlyContinue
if ($old) {
  $old.OwningProcess | ForEach-Object { Stop-Process -Id $_ -Force -ErrorAction SilentlyContinue }
  Start-Sleep 1
}

# Start http-server
$serverJob = Start-Job -ScriptBlock {
  param($d, $p)
  Set-Location $d
  npx http-server . -p $p --cors -c-1
} -ArgumentList $dir, $port

Start-Sleep 2

# Start localtunnel, capture output
$tunnelFile = Join-Path $env:TEMP "localtunnel-url.txt"
Remove-Item $tunnelFile -ErrorAction SilentlyContinue

$tunnelJob = Start-Job -ScriptBlock {
  param($p, $f)
  npx localtunnel --port $p 2>&1 | ForEach-Object {
    $_ | Out-File -FilePath $f -Append
    Write-Host $_
  }
} -ArgumentList $port, $tunnelFile

# Wait for URL
$url = $null
$timeout = 30
$elapsed = 0
while ($elapsed -lt $timeout -and -not $url) {
  Start-Sleep 1
  $elapsed++
  if (Test-Path $tunnelFile) {
    $content = Get-Content $tunnelFile
    foreach ($line in $content) {
      if ($line -match 'your url is:\s*(https?://\S+)') {
        $url = $matches[1]
        break
      }
    }
  }
}

Write-Host ""
if ($url) {
  Write-Host "=== 部署成功 ===" -ForegroundColor Green
  Write-Host "手机访问: " -NoNewline; Write-Host $url -ForegroundColor Yellow
  Write-Host "二维码已嵌入页面，扫码即可" -ForegroundColor Green
  Write-Host "按 Ctrl+C 退出隧道" -ForegroundColor Gray
} else {
  Write-Host "=== 隧道启动失败 ===" -ForegroundColor Red
  Write-Host "请手动运行: npx localtunnel --port $port" -ForegroundColor Yellow
}

# Keep script alive
while ($tunnelJob.State -eq 'Running') { Start-Sleep 2 }

# Cleanup
Stop-Job $serverJob -ErrorAction SilentlyContinue
Remove-Job $serverJob -ErrorAction SilentlyContinue
Remove-Job $tunnelJob -ErrorAction SilentlyContinue
