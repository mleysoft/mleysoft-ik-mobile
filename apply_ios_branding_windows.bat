@echo off
setlocal
cd /d "%~dp0"

echo.
echo ========================================================
echo  MleySoft IK V100 - iOS BRANDING / TESTFLIGHT HAZIRLIK
echo ========================================================

where flutter >nul 2>nul
if errorlevel 1 (
  echo Flutter PATH icinde bulunamadi.
  exit /b 1
)

if not exist "ios\Runner.xcodeproj\project.pbxproj" (
  echo Gercek iOS platformu olusturuluyor...
  call flutter create --platforms=ios --org com.mleysoft .
  if errorlevel 1 exit /b 1
)

echo MleySoft iOS ikon, ad, izin ve Bundle ID ayarlari uygulaniyor...
python native_config\configure_ios.py
if errorlevel 1 exit /b 1

echo.
echo Bundle ID kontrol:
findstr /i "PRODUCT_BUNDLE_IDENTIFIER = com.mleysoft.ik;" ios\Runner.xcodeproj\project.pbxproj
if errorlevel 1 (
  echo HATA: Bundle ID com.mleysoft.ik degil.
  exit /b 1
)

echo.
echo Info.plist uygulama adi kontrol:
findstr /i "MleySoft" ios\Runner\Info.plist

echo.
echo AppIcon kontrol:
if not exist "ios\Runner\Assets.xcassets\AppIcon.appiconset\Icon-App-1024x1024@1x.png" (
  echo HATA: iOS App Store ikonu bulunamadi.
  exit /b 1
)

echo.
echo V100 iOS hazir.
echo Bundle ID : com.mleysoft.ik
echo Uygulama   : MleySoft IK
echo App icon   : MleySoft ozel ikon
echo.
echo Simdi GitHub Desktop ile Commit + Push origin yapin.
exit /b 0
