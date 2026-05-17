@echo off
chcp 65001 >nul
cd /d "%~dp0"

echo === WebAR Revit Viewer ===
echo.

:: 清理旧进程
echo 清理旧服务...
taskkill /f /im node.exe /fi "WINDOWTITLE eq http-server" 2>nul
for /f "tokens=5" %%a in ('netstat -ano ^| findstr :8080 ^| findstr LISTENING') do taskkill /f /pid %%a 2>nul
timeout /t 2 /nobreak >nul

:: 启动 http-server
echo 启动 http-server...
start "http-server" /min npx http-server . -p 8080 --cors -c-1
timeout /t 3 /nobreak >nul

:: 检测端口
netstat -ano | findstr :8080 | findstr LISTENING >nul
if errorlevel 1 (
  echo [失败] 端口 8080 未启动，尝试直接运行...
  start "http-server" /min cmd /c "npx http-server . -p 8080 --cors -c-1"
  timeout /t 5 /nobreak >nul
)

:: 启动 localtunnel
echo.
echo 创建隧道...
echo 首次会下载 localtunnel，请稍后
echo.
start "localtunnel" /min cmd /c "npx localtunnel --port 8080 > tunnel-url.txt 2>&1"
timeout /t 8 /nobreak >nul

:: 读取 URL
set URL=
for /f "tokens=3" %%a in ('findstr "your url is" tunnel-url.txt 2^>nul') do set URL=%%a
if not defined URL (
  :: 再等一会儿
  timeout /t 10 /nobreak >nul
  for /f "tokens=3" %%a in ('findstr "your url is" tunnel-url.txt 2^>nul') do set URL=%%a
)

cls
echo.
echo ============================================
if defined URL (
  echo   部署成功！
  echo.
  echo   手机访问: %URL%
  echo.
  echo   首次手机访问会看到警告页
  echo   输入屏幕上的 IP 点 Continue 即可
  echo   （仅首次，之后 7 天免验证）
  echo.
  echo   二维码已嵌入页面，扫码即 AR
  echo ============================================
  start %URL%
) else (
  echo   隧道创建失败
  echo.
  echo   请手动运行: npx localtunnel --port 8080
  echo ============================================
  echo.
  type tunnel-url.txt 2>nul
)

echo.
echo 关闭此窗口即可停止服务
pause
