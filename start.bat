@echo off
cd /d "%~dp0"

echo === WebAR Revit Viewer ===
echo.

echo 1/4 Cleaning old processes...
taskkill /f /im node.exe /fi "WINDOWTITLE eq http-server" 2>nul
for /f "tokens=5" %%a in ('netstat -ano ^| findstr :8080 ^| findstr LISTENING') do taskkill /f /pid %%a 2>nul
timeout /t 2 /nobreak >nul

echo 2/4 Starting http-server...
start "http-server" /min npx http-server . -p 8080 --cors -c-1
timeout /t 4 /nobreak >nul

netstat -ano | findstr :8080 | findstr LISTENING >nul
if errorlevel 1 (
  echo [FAIL] Port 8080 not started
  pause
  exit
)

echo 3/4 Creating tunnel...
start "localtunnel" /min cmd /c "npx localtunnel --port 8080 > tunnel-url.txt 2>&1"
timeout /t 8 /nobreak >nul

set URL=
for /f "tokens=3" %%a in ('findstr "your url is" tunnel-url.txt 2^>nul') do set URL=%%a
if not defined URL (
  timeout /t 10 /nobreak >nul
  for /f "tokens=3" %%a in ('findstr "your url is" tunnel-url.txt 2^>nul') do set URL=%%a
)

cls
echo.
if not defined URL (
  echo 4/4 TUNNEL FAILED - try running manually:
  echo     npx localtunnel --port 8080
  pause
  exit
)

echo ============================================
echo   Phone access: %URL%
echo ============================================
echo.

:: Auto-bypass warning page
echo 4/4 Auto-bypassing warning page...
curl.exe -s -c cookies.txt "%URL%" > page.htm 2>nul
for /f "tokens=5" %%a in ('findstr /i "hosted" page.htm 2^>nul') do (
  curl.exe -s -b cookies.txt -c cookies.txt -d "ip=%%a" "%URL%" >nul 2>nul
)

start %URL%

echo.
echo Phone: open the URL above
echo First time: enter IP ^& click Continue
echo.
echo Close this window to stop
pause
