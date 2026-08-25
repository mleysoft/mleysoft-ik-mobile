#!/usr/bin/env python3
from pathlib import Path
import re, sys

root = Path(__file__).resolve().parents[1]
errors=[]

ios=(root/'native_config/configure_ios.py').read_text(encoding='utf-8')
required_ios=[
    'NSPhotoLibraryUsageDescription',
    'NSCameraUsageDescription',
    'NSLocationWhenInUseUsageDescription',
    'NSFaceIDUsageDescription',
]
for key in required_ios:
    if key not in ios:
        errors.append(f'iOS purpose string eksik: {key}')

android=(root/'native_config/configure_android.ps1').read_text(encoding='utf-8')
cleanup=(root/'native_config/cleanup_media_permissions.ps1').read_text(encoding='utf-8')
manifest_add=(root/'native_config/AndroidManifest.additions.xml').read_text(encoding='utf-8')

for forbidden in [
    'android.permission.READ_MEDIA_IMAGES',
    'android.permission.READ_MEDIA_VIDEO',
    'android.permission.READ_EXTERNAL_STORAGE',
    'android.permission.WRITE_EXTERNAL_STORAGE',
    'android.permission.MANAGE_EXTERNAL_STORAGE',
]:
    if forbidden in manifest_add:
        errors.append(f'Android manifest addition gereksiz izin içeriyor: {forbidden}')
    if forbidden not in cleanup:
        errors.append(f'Android cleanup bu izni temizlemiyor: {forbidden}')

pub=(root/'pubspec.yaml').read_text(encoding='utf-8')
if 'file_picker:' not in pub:
    errors.append('file_picker dependency eksik')

if errors:
    print('V147 FILE UPLOAD PERMISSION ERROR')
    for e in errors:
        print(' -',e)
    sys.exit(1)

print('V147 file upload permissions OK')
print('iOS: system document picker + Photo Library purpose text')
print('Android: Storage Access Framework; broad media/storage permission yok')
