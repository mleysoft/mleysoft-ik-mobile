#!/bin/sh
set -eu
cd "$(dirname "$0")"
rm -rf ios
flutter create --platforms=ios --org com.mleysoft .
python3 native_config/configure_ios.py
flutter pub get

test -f ios/Runner/GoogleService-Info.plist || { echo "ERROR: GoogleService-Info.plist missing before build"; exit 1; }
grep -q "GoogleService-Info.plist in Resources" ios/Runner.xcodeproj/project.pbxproj || { echo "ERROR: Firebase plist not in Runner resources"; exit 1; }
grep -q "registrar.addApplicationDelegate(instance)" packages/mleysoft_native_bridge/ios/Classes/MleySoftNativeBridgePlugin.swift || { echo "ERROR: V206 APNs application delegate bridge missing"; exit 1; }
grep -q "didRegisterForRemoteNotificationsWithDeviceToken" packages/mleysoft_native_bridge/ios/Classes/MleySoftNativeBridgePlugin.swift || { echo "ERROR: V206 APNs success callback missing"; exit 1; }
grep -q "didFailToRegisterForRemoteNotificationsWithError" packages/mleysoft_native_bridge/ios/Classes/MleySoftNativeBridgePlugin.swift || { echo "ERROR: V206 APNs failure callback missing"; exit 1; }
echo "V206 iOS ready: Firebase resource + compiled plugin APNs delegate verified."
