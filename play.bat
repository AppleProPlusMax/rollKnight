@echo off
cd /d "%~dp0"
if exist "tools\love-11.5-win64\love.exe" (
  start "" "tools\love-11.5-win64\love.exe" .
) else (
  where love >nul 2>&1
  if %errorlevel%==0 (
    start "" love .
  ) else (
    echo LOVE 11.5 not found. Please install LOVE 11.5 or place it in tools\love-11.5-win64\
    pause
  )
)
