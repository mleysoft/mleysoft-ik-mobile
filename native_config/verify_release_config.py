#!/usr/bin/env python3
from pathlib import Path
import sys

root = Path(__file__).resolve().parents[1]
errors = []
expected_version = "1.6.17+105"
location_text = "MleySoft İK, personel giriş ve çıkışlarında QR kodunun tanımlı işyeri konumunda okutulduğunu doğrulamak için konumunuzu yalnızca uygulamayı kullanırken alır."

pub = (root / "pubspec.yaml").read_text(encoding="utf-8")
if f"version: {expected_version}" not in pub:
    errors.append(f"pubspec version beklenen {expected_version} degil")

android_cfg = (root / "native_config" / "configure_android.ps1").read_text(encoding="utf-8")
for required in [
    'namespace = "com.mleysoft.ik"',
    'applicationId = "com.mleysoft.ik"',
    'android.permission.ACCESS_FINE_LOCATION',
    'android.permission.ACCESS_COARSE_LOCATION',
    'android.permission.CAMERA',
]:
    if required not in android_cfg:
        errors.append(f"Android config eksik: {required}")

ios_cfg = (root / "native_config" / "configure_ios.py").read_text(encoding="utf-8")
for item in [
    "com.mleysoft.ik",
    "NSCameraUsageDescription",
    "NSPhotoLibraryUsageDescription",
    "NSLocationWhenInUseUsageDescription",
    "NSFaceIDUsageDescription",
    location_text,
]:
    if item not in ios_cfg:
        errors.append(f"iOS config eksik: {item}")

plist_add = (root / "native_config" / "InfoPlist.additions.xml").read_text(encoding="utf-8")
if location_text not in plist_add:
    errors.append("InfoPlist.additions.xml konum amaci QR/isyeri dogrulamasi olarak acik degil")

portal = (root / "lib" / "screens" / "employee_portal.dart").read_text(encoding="utf-8")
for item in ["Geolocator.requestPermission", "Arka planda konum takibi yapılmaz", "Konum Doğrulaması"]:
    if item not in portal:
        errors.append(f"Mobil konum izin akisi eksik: {item}")

if errors:
    print("RELEASE CONFIG ERROR:")
    for e in errors:
        print(" -", e)
    sys.exit(1)

print("Release config OK")
print("Package/Bundle ID: com.mleysoft.ik")
print(f"Version: {expected_version}")
print("Location: QR attendance workplace verification, foreground only")
