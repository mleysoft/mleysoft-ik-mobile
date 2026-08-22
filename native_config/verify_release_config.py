#!/usr/bin/env python3
from pathlib import Path
import re, sys

root = Path(__file__).resolve().parents[1]
errors = []

# pubspec version
pub = (root / "pubspec.yaml").read_text(encoding="utf-8")
if "version: 1.6.8+92" not in pub:
    errors.append("pubspec version beklenen 1.6.8+92 degil")

# Android generated configuration source
android_cfg = (root / "native_config" / "configure_android.ps1").read_text(encoding="utf-8")
if 'namespace = "com.mleysoft.ik"' not in android_cfg:
    errors.append("Android namespace com.mleysoft.ik degil")
if 'applicationId = "com.mleysoft.ik"' not in android_cfg:
    errors.append("Android applicationId com.mleysoft.ik degil")

# iOS configuration source
ios_cfg = (root / "native_config" / "configure_ios.py").read_text(encoding="utf-8")
required = [
    "com.mleysoft.ik",
    "NSCameraUsageDescription",
    "NSPhotoLibraryUsageDescription",
    "NSLocationWhenInUseUsageDescription",
    "NSFaceIDUsageDescription",
]
for item in required:
    if item not in ios_cfg:
        errors.append(f"iOS config eksik: {item}")

if errors:
    print("RELEASE CONFIG ERROR:")
    for e in errors:
        print(" -", e)
    sys.exit(1)

print("Release config OK")
print("Package/Bundle ID: com.mleysoft.ik")
print("Version: 1.6.8+92")
