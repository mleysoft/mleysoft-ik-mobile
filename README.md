# MleySoft İK Native Mobil Uygulama – V38

Bu klasör PHP panelinin WebView kopyası değildir. Flutter ile yazılmış native mobil istemcidir ve `api/v1` REST API üzerinden aynı MySQL veritabanını kullanır.

## İlk kurulum
1. Flutter 3.24+ ve Android Studio/Xcode kurulu makinede bu klasöre girin.
2. `flutter create . --platforms=android,ios --org com.mleysoft` komutunu bir kez çalıştırın. Mevcut `lib/` ve `pubspec.yaml` dosyalarını koruyun.
3. `flutter pub get`
4. API adresini build sırasında verin:
   `flutter run --dart-define=API_BASE_URL=https://ik.siteniz.com`
5. Android: `android/app/src/main/AndroidManifest.xml` içine INTERNET ve biyometrik izinleri ekleyin. iOS: `Info.plist` içine Face ID açıklamasını ekleyin. `native_config` klasöründeki örnekleri kullanın.

## Üretim build
Android: `flutter build appbundle --release --dart-define=API_BASE_URL=https://ik.siteniz.com`
iOS: `flutter build ipa --release --dart-define=API_BASE_URL=https://ik.siteniz.com`

## Güvenlik
- MySQL'e doğrudan mobil bağlantı yoktur.
- Bearer tokenlar sunucuda SHA-256 hash olarak tutulur, cihazda `flutter_secure_storage` kullanılır.
- Token ömrü 30 gündür ve logout/revoke desteklenir.
- API ve uygulama yalnız HTTPS üretim adresiyle kullanılmalıdır.

## Hazır native ekranlar
Login/firma seçimi, Dashboard, Personeller, Günlük/Toplu Puantaj, İzin Takibi, Maaş Tanımları, Avans/Taksitli Avans, Dönem Maaşları, Aylık Puantaj Raporu, Tanım Yönetimi ve Hesap/Veri işlemleri.
