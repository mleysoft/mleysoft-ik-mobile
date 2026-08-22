@echo off
setlocal
cd /d "%~dp0"

echo.
echo [V87] Google Play release imza kurulumu...

call "%~dp0prepare_android_v87.bat"
if errorlevel 1 goto :fail

set /p JAVA_HOME=<"%~dp0.mleysoft_jdk_path"
set "PATH=%JAVA_HOME%\bin;%PATH%"

powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0native_config\setup_playstore_signing.ps1"
if errorlevel 1 goto :fail

echo.
echo Imza kurulumu tamamlandi.
exit /b 0

:fail
echo.
echo Play Store imza kurulumu basarisiz.
exit /b 1
