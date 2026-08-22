@echo off
setlocal
cd /d "%~dp0"

if "%API_BASE_URL%"=="" set "API_BASE_URL=https://mleysoft.com/system/ik"
if "%DEVICE_ID%"=="" set "DEVICE_ID=emulator-5554"

call "%~dp0prepare_android_v98.bat"
if errorlevel 1 goto :fail
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0native_config\cleanup_media_permissions.ps1"
if errorlevel 1 goto :fail

set /p JAVA_HOME=<"%~dp0.mleysoft_jdk_path"
set "PATH=%JAVA_HOME%\bin;%PATH%"

echo.
echo Flutter paketleri kontrol ediliyor...
call flutter pub get
if errorlevel 1 goto :fail

echo.
echo =============== AKTIF TOOLCHAIN ===============
findstr /C:"com.android.application" "android\settings.gradle.kts"
findstr /C:"org.jetbrains.kotlin.android" "android\settings.gradle.kts"
findstr /C:"distributionUrl" "android\gradle\wrapper\gradle-wrapper.properties"
findstr /C:"compileSdk = 36" "android\app\build.gradle.kts"
echo JAVA_HOME=%JAVA_HOME%
"%JAVA_HOME%\bin\java.exe" -version
echo ================================================

echo.
echo API: %API_BASE_URL%
echo Cihaz: %DEVICE_ID%
echo Eski MleySoft APK emulator uzerinden kaldiriliyor...
call adb -s %DEVICE_ID% uninstall com.mleysoft.ik >nul 2>nul
echo Uygulama derleniyor ve emulatora yukleniyor...
call flutter run -d %DEVICE_ID% --dart-define=API_BASE_URL=%API_BASE_URL%
if errorlevel 1 goto :fail
exit /b 0

:fail
echo.
echo Uygulama calistirilamadi. Yukaridaki ilk Error veya FAILURE satirlarini gonderin.
exit /b 1
