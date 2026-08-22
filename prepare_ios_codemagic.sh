#!/bin/sh
set -e
cd "$(dirname "$0")"
rm -rf ios
flutter create --platforms=ios --org com.mleysoft .
python3 native_config/configure_ios.py
flutter pub get
echo "V100 iOS platform hazir: com.mleysoft.ik"
