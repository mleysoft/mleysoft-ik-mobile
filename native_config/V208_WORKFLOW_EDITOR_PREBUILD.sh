#!/usr/bin/env bash
set -euo pipefail
rm -rf ios
flutter create --platforms=ios --org com.mleysoft .
python3 native_config/configure_ios.py
flutter pub get
flutter build ios --config-only --release
B=$(grep -c "PRODUCT_BUNDLE_IDENTIFIER = com.mleysoft.ik;" ios/Runner.xcodeproj/project.pbxproj)
E=$(grep -c "CODE_SIGN_ENTITLEMENTS = Runner/Runner.entitlements;" ios/Runner.xcodeproj/project.pbxproj)
echo "Runner configs=$B entitlement bindings=$E"
test "$B" -ge 3
test "$E" -ge "$B"
/usr/libexec/PlistBuddy -c "Print :aps-environment" ios/Runner/Runner.entitlements | grep -q '^production$'
! /usr/libexec/PlistBuddy -c "Print :FirebaseAppDelegateProxyEnabled" ios/Runner/Info.plist >/dev/null 2>&1
echo "V208 PREBUILD OK: Release dahil tum Runner configleri APNs entitlement kullaniyor; Firebase swizzling enabled."
