#!/usr/bin/env python3
from pathlib import Path
import sys

root = Path(__file__).resolve().parents[1]
errors=[]
expected_version='1.6.30+118'
location_text='MleySoft İK, personel giriş ve çıkışlarında QR kodunun tanımlı işyeri konumunda okutulduğunu doğrulamak için konumunuzu yalnızca uygulamayı kullanırken alır.'

pub=(root/'pubspec.yaml').read_text(encoding='utf-8')
if f'version: {expected_version}' not in pub: errors.append(f'pubspec version beklenen {expected_version} degil')
if 'geolocator:' in pub: errors.append('geolocator dependency tamamen kaldirilmali')

android=(root/'native_config/configure_android.ps1').read_text(encoding='utf-8')
for item in ['namespace = "com.mleysoft.ik"','applicationId = "com.mleysoft.ik"','android.permission.ACCESS_FINE_LOCATION','android.permission.ACCESS_COARSE_LOCATION','com.mleysoft.ik/location']:
    if item not in android: errors.append(f'Android config eksik: {item}')

ios=(root/'native_config/configure_ios.py').read_text(encoding='utf-8')
for item in ['com.mleysoft.ik','NSCameraUsageDescription','NSPhotoLibraryUsageDescription','NSLocationWhenInUseUsageDescription','NSFaceIDUsageDescription',location_text,'mleysoft_native_bridge']:
    if item not in ios: errors.append(f'iOS config eksik: {item}')
if 'info["NSLocationAlwaysAndWhenInUseUsageDescription"]' in ios: errors.append('iOS Always Location purpose string yeniden eklenmemeli')
plugin_path=root/'packages/mleysoft_native_bridge/ios/Classes/MleySoftNativeBridgePlugin.swift'
if not plugin_path.exists():
    errors.append('V119 native iOS plugin source eksik')
else:
    plugin=plugin_path.read_text(encoding='utf-8')
    for item in ['requestWhenInUseAuthorization','com.mleysoft.ik/location','com.mleysoft.ik/permissions','UNUserNotificationCenter.current().requestAuthorization']:
        if item not in plugin: errors.append(f'V119 native plugin eksik: {item}')
    if 'requestAlwaysAuthorization' in plugin: errors.append('V119 native plugin Always Location API icermemeli')
if 'mleysoft_native_bridge:' not in pub: errors.append('V119 local native plugin pubspec bagimliligi eksik')

portal=(root/'lib/screens/employee_portal.dart').read_text(encoding='utf-8')
for item in ['NativeLocationService.currentPosition','Arka planda konum takibi yapılmaz','Konum Doğrulaması']:
    if item not in portal: errors.append(f'Mobil native konum akisi eksik: {item}')
if 'Geolocator.' in portal: errors.append('employee_portal hala Geolocator kullaniyor')

main=(root/'lib/main.dart').read_text(encoding='utf-8')
state=(root/'lib/core/app_state.dart').read_text(encoding='utf-8')
if 'ForcedUpdateScreen' not in main or 'currentBuild = 118' not in state: errors.append('Zorunlu guncelleme kontrolu eksik')

# V116 Android adaptive icon: white background + inset transparent foreground.
if 'mleysoft_adaptive_foreground_safe.png' not in android: errors.append('V116 adaptive icon foreground eksik')
if '<color name="mleysoft_icon_background">#FFFFFF</color>' not in android: errors.append('V116 adaptive icon background beyaz degil')
if not (root/'assets/platform_icons/android/mleysoft_adaptive_foreground_safe.png').exists(): errors.append('V116 safe adaptive foreground dosyasi eksik')

if errors:
    print('RELEASE CONFIG ERROR:')
    for e in errors: print(' -',e)
    sys.exit(1)
print('Release config OK')
print('Package/Bundle ID: com.mleysoft.ik')
print(f'Version: {expected_version}')
print('Location: native foreground-only QR workplace verification; geolocator removed')
print('Forced update: server-controlled minimum build enabled')
