@echo off
cd /d "%~dp0"

echo === WebAR Revit Viewer ===
echo.

del tunnel-url.txt 2>nul

echo 1/3 Cleaning old processes...
taskkill /f /im node.exe /fi "WINDOWTITLE eq http-server" 2>nul
for /f "tokens=5" %%a in ('netstat -ano ^| findstr :8080 ^| findstr LISTENING') do taskkill /f /pid %%a 2>nul
timeout /t 2 /nobreak >nul

echo 2/3 Starting http-server...
start "http-server" /min npx http-server . -p 8080 --cors -c-1
timeout /t 4 /nobreak >nul

netstat -ano | findstr :8080 | findstr LISTENING >nul
if errorlevel 1 (
  echo [FAIL] http-server did not start
  pause
  exit
)

echo 3/3 Creating tunnel...
start "localtunnel" /min cmd /c "npx localtunnel --port 8080 > tunnel-url.txt 2>&1"
timeout /t 8 /nobreak >nul

set URL=
for /f "delims=" %%a in ('findstr /c:"http" tunnel-url.txt 2^>nul') do (
  set LINE=%%a
  call set URL=%%LINE:*https=https%%
)
if not defined URL (
  timeout /t 10 /nobreak >nul
  for /f "delims=" %%a in ('findstr /c:"http" tunnel-url.txt 2^>nul') do (
    set LINE=%%a
    call set URL=%%LINE:*https=https%%
  )
)

cls
echo.
if not defined URL (
  echo FAILED - check tunnel-url.txt
  if exist tunnel-url.txt type tunnel-url.txt
  pause
  exit
)

echo ============================================
echo   Phone access: %URL%
echo ============================================
echo.
echo First time on phone:
echo   1. Open the URL above
echo   2. Enter IP shown on page
echo   3. Click Continue
echo   (Only once per 7 days)
echo.
echo Close this window to stop
pause
