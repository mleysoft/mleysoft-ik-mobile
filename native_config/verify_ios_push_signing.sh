#!/usr/bin/env bash
set -euo pipefail
PROFILE_DIR="$HOME/Library/Developer/Xcode/UserData/Provisioning Profiles"
TMP="/tmp/mleysoft_profile.plist"
FOUND=0
for P in "$PROFILE_DIR"/*.mobileprovision "$HOME/Library/MobileDevice/Provisioning Profiles"/*.mobileprovision; do
  [ -f "$P" ] || continue
  security cms -D -i "$P" > "$TMP" 2>/dev/null || continue
  APPID=$(/usr/libexec/PlistBuddy -c 'Print :Entitlements:application-identifier' "$TMP" 2>/dev/null || true)
  case "$APPID" in
    *.com.mleysoft.ik)
      FOUND=1
      APS=$(/usr/libexec/PlistBuddy -c 'Print :Entitlements:aps-environment' "$TMP" 2>/dev/null || true)
      echo "MleySoft profile: $P"
      echo "application-identifier=$APPID"
      echo "aps-environment=${APS:-MISSING}"
      [ "$APS" = "production" ] || { echo 'ERROR: Apple provisioning profile has no production aps-environment. Regenerate the App Store profile after enabling Push Notifications.'; exit 41; }
      ;;
  esac
done
[ "$FOUND" = 1 ] || { echo 'ERROR: com.mleysoft.ik provisioning profile not found.'; exit 42; }

echo 'V207 PROFILE VERIFY OK: provisioning profile contains aps-environment=production.'
