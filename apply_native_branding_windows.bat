@echo off
setlocal
cd /d "%~dp0"

echo ========================================================
echo  MleySoft IK V100 - ANDROID + IOS NATIVE BRANDING
echo ========================================================

where flutter >nul 2>nul
if errorlevel 1 (
  echo Flutter PATH icinde bulunamadi.
  exit /b 1
)

if not exist "ios\Runner.xcodeproj\project.pbxproj" (
  echo iOS platformu olusturuluyor...
  call flutter create --platforms=ios --org com.mleysoft .
  if errorlevel 1 exit /b 1
)

echo iOS ikon, uygulama adi, Face ID ve Bundle ID ayarlari uygulaniyor...
python native_config\configure_ios.py
if errorlevel 1 exit /b 1

echo Android launcher ikonu ve package ayarlari uygulaniyor...
powershell -NoProfile -ExecutionPolicy Bypass -File native_config\configure_android.ps1
if errorlevel 1 exit /b 1

echo.
echo V100 hazir.
echo Bundle ID / package : com.mleysoft.ik
echo Uygulama adi        : MleySoft IK
echo Build               : 95
echo.
echo Simdi GitHub Desktop ile Commit + Push origin yapin.
exit /b 0
