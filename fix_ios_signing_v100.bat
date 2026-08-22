@echo off
setlocal
cd /d "%~dp0"

echo ===============================================
echo  MleySoft IK V100 - iOS SIGNING PRODUCT FIX
echo ===============================================

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

echo Runner product name, Bundle ID, app icon ve izinler duzeltiliyor...
python native_config\configure_ios.py
if errorlevel 1 exit /b 1

echo.
echo Kontrol:
findstr /C:"PRODUCT_NAME = Runner;" ios\Runner.xcodeproj\project.pbxproj
findstr /C:"PRODUCT_BUNDLE_IDENTIFIER = com.mleysoft.ik;" ios\Runner.xcodeproj\project.pbxproj

echo.
echo TAMAM. GitHub Desktop ile ios klasoru dahil Commit + Push yapin.
exit /b 0
