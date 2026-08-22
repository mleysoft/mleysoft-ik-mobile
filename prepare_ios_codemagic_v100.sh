#!/bin/sh
set -e
cd "$(dirname "$0")"
rm -rf ios
flutter create --platforms=ios --org com.mleysoft .
python3 native_config/configure_ios.py
grep -q "PRODUCT_NAME = Runner;" ios/Runner.xcodeproj/project.pbxproj
grep -q "PRODUCT_BUNDLE_IDENTIFIER = com.mleysoft.ik;" ios/Runner.xcodeproj/project.pbxproj
echo "V100 iOS ready: Runner.app / com.mleysoft.ik / MleySoft İK display name"
