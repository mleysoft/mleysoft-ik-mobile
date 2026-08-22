#!/bin/sh
set -e
cd "$(dirname "$0")"
API_BASE_URL="${API_BASE_URL:-https://mleysoft.com/system/ik/api/v1}"
sh prepare_ios_codemagic.sh
flutter clean
flutter pub get
flutter build ipa --release --dart-define=API_BASE_URL="$API_BASE_URL"
echo "IPA: build/ios/ipa/"
