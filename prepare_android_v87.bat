@echo off
setlocal
cd /d "%~dp0"

where flutter >nul 2>nul
if errorlevel 1 (
  echo Flutter PATH icinde bulunamadi.
  exit /b 1
)

echo.
echo [V87] Uyumlu Android JDK kontrol ediliyor...
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0native_config\select_jdk.ps1"
if errorlevel 1 goto :fail

set /p JAVA_HOME=<"%~dp0.mleysoft_jdk_path"
set "PATH=%JAVA_HOME%\bin;%PATH%"

echo JAVA_HOME=%JAVA_HOME%
"%JAVA_HOME%\bin\java.exe" -version

echo Flutter bu JDK'yi kullanacak sekilde ayarlaniyor...
call flutter config --jdk-dir="%JAVA_HOME%"
if errorlevel 1 goto :fail

if exist ".mleysoft_v87_android_ready" goto :patch

echo.
echo Eski Android platform dosyalari temizleniyor...
if exist "android" rmdir /s /q "android"

echo Android platformu Flutter ile sifirdan olusturuluyor...
call flutter create --platforms=android .
if errorlevel 1 goto :fail

:patch
echo.
echo V87 Android toolchain ayarlari uygulaniyor...
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0native_config\configure_android.ps1"
if errorlevel 1 goto :fail

> ".mleysoft_v87_android_ready" echo V86
echo Android V87 hazir.
exit /b 0

:fail
echo.
echo Android platform/JDK hazirlanamadi.
exit /b 1
