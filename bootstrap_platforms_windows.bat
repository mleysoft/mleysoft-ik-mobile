@echo off
setlocal
cd /d "%~dp0"

call "%~dp0prepare_android_v62.bat"
if errorlevel 1 exit /b 1

set /p JAVA_HOME=<"%~dp0.mleysoft_jdk_path"
set "PATH=%JAVA_HOME%\bin;%PATH%"

call flutter clean
if errorlevel 1 exit /b 1
call flutter pub get
if errorlevel 1 exit /b 1

echo.
echo V55 Android kurulumu tamamlandi.
exit /b 0
