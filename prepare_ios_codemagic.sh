#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"
rm -rf ios
flutter create --platforms=ios --org com.mleysoft .
python3 native_config/configure_ios.py
flutter pub get

# Source-project checks BEFORE Codemagic's xcode-project use-profiles.
test -f ios/Runner/GoogleService-Info.plist || { echo "V209 ERROR: Firebase plist missing"; exit 1; }
/usr/libexec/PlistBuddy -c "Print :BUNDLE_ID" ios/Runner/GoogleService-Info.plist | grep -q '^com.mleysoft.ik$'
/usr/libexec/PlistBuddy -c "Print :aps-environment" ios/Runner/Runner.entitlements | grep -q '^production$'
grep -q '^CODE_SIGN_ENTITLEMENTS=Runner/Runner.entitlements$' ios/Flutter/Release.xcconfig
grep -q 'CODE_SIGN_ENTITLEMENTS = Runner/Runner.entitlements;' ios/Runner.xcodeproj/project.pbxproj
grep -q 'GoogleService-Info.plist in Resources' ios/Runner.xcodeproj/project.pbxproj
! /usr/libexec/PlistBuddy -c "Print :FirebaseAppDelegateProxyEnabled" ios/Runner/Info.plist >/dev/null 2>&1

echo "V209 PREBUILD OK: official Firebase plist + production APNs entitlement + Release xcconfig binding ready."
