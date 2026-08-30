#!/usr/bin/env bash
set -euo pipefail
IPA_FILE=$(find build/ios/ipa -maxdepth 1 -name '*.ipa' | head -1)
test -n "$IPA_FILE" || { echo "V209 ERROR: IPA not found"; exit 1; }
rm -rf /tmp/v209ipa && mkdir -p /tmp/v209ipa
unzip -q "$IPA_FILE" -d /tmp/v209ipa
APP=/tmp/v209ipa/Payload/Runner.app
test -f "$APP/GoogleService-Info.plist" || { echo "V209 ERROR: GoogleService-Info.plist missing from final IPA"; exit 1; }
/usr/libexec/PlistBuddy -c 'Print :BUNDLE_ID' "$APP/GoogleService-Info.plist" | grep -q '^com.mleysoft.ik$'
codesign -d --entitlements :- "$APP" 2>/tmp/v209_entitlements.plist || true
/usr/libexec/PlistBuddy -c 'Print :aps-environment' /tmp/v209_entitlements.plist | grep -q '^production$' || { echo 'V209 ERROR: FINAL IPA aps-environment missing'; cat /tmp/v209_entitlements.plist; exit 1; }
echo 'V209 FINAL IPA VERIFY OK: aps-environment=production and Firebase plist embedded.'
