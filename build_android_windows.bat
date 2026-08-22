@echo off
setlocal EnableExtensions
cd /d "%~dp0"

if "%API_BASE_URL%"=="" set "API_BASE_URL=https://mleysoft.com/system/ik"

echo.
echo ========================================================
echo  MleySoft IK V98 - RELEASE BUILD
echo ========================================================

call "%~dp0prepare_android_v98.bat"
if errorlevel 1 goto :fail
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0native_config\cleanup_media_permissions.ps1"
if errorlevel 1 goto :fail

set /p JAVA_HOME=<"%~dp0.mleysoft_jdk_path"
set "PATH=%JAVA_HOME%\bin;%PATH%"

if not exist "%~dp0signing\mleysoft-release-key.jks" (
    echo Release anahtari bulunamadi. Ilk kurulum baslatiliyor...
    powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0native_config\setup_playstore_signing.ps1"
    if errorlevel 1 goto :fail
)

if not exist "%~dp0signing\key.properties" (
    echo signing\key.properties bulunamadi.
    goto :fail
)

echo.
echo Flutter/Android toolchain kontrolu...
call flutter doctor -v

echo.
echo Temiz build...
call flutter clean
if errorlevel 1 goto :fail
call flutter pub get
if errorlevel 1 goto :fail

echo.
echo Google Play AAB derleniyor...
call flutter build appbundle --release --dart-define=API_BASE_URL=%API_BASE_URL%
set "FLUTTER_RC=%ERRORLEVEL%"

set "AAB=build\app\outputs\bundle\release\app-release.aab"

if not exist "%AAB%" (
    echo.
    echo Flutter build AAB olusturmadi.
    goto :fail
)

if not "%FLUTTER_RC%"=="0" (
    echo.
    echo Flutter son asamadaki native debug-symbol kontrolunde hata verdi,
    echo ancak Gradle AAB dosyasini olusturdu.
    echo AAB imzasi ve paket butunlugu ayrica kontrol edilecek...
)

if not exist "dist" mkdir "dist"
copy /Y "%AAB%" "dist\MleySoft-IK-V98-playstore.aab" >nul

echo.
echo JAR/AAB imzasi dogrulaniyor...
"%JAVA_HOME%\bin\jarsigner.exe" -verify -verbose -certs "dist\MleySoft-IK-V98-playstore.aab" > "dist\V98-signature-verify.txt" 2>&1
if errorlevel 1 (
    type "dist\V98-signature-verify.txt"
    goto :fail
)

echo.
echo AAB ZIP butunlugu kontrol ediliyor...
powershell -NoProfile -Command ^
  "Add-Type -AssemblyName System.IO.Compression.FileSystem; $z=[IO.Compression.ZipFile]::OpenRead('%CD%\dist\MleySoft-IK-V98-playstore.aab'); if($z.Entries.Count -lt 1){exit 1}; $z.Dispose(); exit 0"
if errorlevel 1 goto :fail

echo.
echo ========================================================
echo GOOGLE PLAY AAB HAZIR
echo ========================================================
echo %CD%\dist\MleySoft-IK-V98-playstore.aab
echo.
echo Paket: com.mleysoft.ik
echo Surum: 1.6.6+88
echo.
echo NOT:
echo Flutter "failed to strip debug symbols" uyarisi verse bile,
echo AAB olustuysa ve yukaridaki imza/butunluk kontrolleri gectiyse
echo bu dosya Play Console yuklemesi icin hazirlanmistir.
echo ========================================================
exit /b 0

:fail
echo.
echo Google Play AAB build basarisiz.
exit /b 1
