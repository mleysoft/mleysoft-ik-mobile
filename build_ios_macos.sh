#!/bin/sh
set -e
cd "$(dirname "$0")"
API_BASE_URL="${API_BASE_URL:-https://mleysoft.com/system/ik}"

if [ ! -d "ios" ]; then
  echo "iOS platformu Flutter ile olusturuluyor..."
  flutter create --platforms=ios .
fi

echo "MleySoft IK iOS ikon ve splash ayarlari uygulanıyor..."
python3 native_config/configure_ios.py

flutter clean
flutter pub get
flutter build ios --release --dart-define=API_BASE_URL="$API_BASE_URL"

echo "iOS build tamamlandi. App Store/TestFlight arsivi icin ios/Runner.xcworkspace dosyasini Xcode ile acin."
