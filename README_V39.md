# MleySoft İK Native Mobil V39

Bu klasör WebView değildir. Flutter arayüzü REST API üzerinden PHP backend ile konuşur.

## V39'da genişletilen native modüller

- Personel ekleme/düzenleme: 4 sekmeli tam özlük kartı
- Personel aktif/pasif switch, detay, maaş ve açık avans özeti
- Günlük puantaj: arama, otomatik kayıt, toplu işlem, eksik puantaj uyarıları, personel detay özeti
- İzin takibi: hakediş/bakiye özeti, ilk bakiye, kilit mantığı, tarih filtreli izin hareketleri, izin düzenleme/silme, native yıllık izin PDF yazdırma/paylaşma
- Maaş: tanım ekleme/düzenleme, dönem oluşturma/iptal, dönem personel detayları
- Avans: tek/taksitli, maaştan kesinti/diğer ödeme, başlangıç dönemi, paralel/önceki borç sonrası plan, taksit listesi, manuel taksit ödeme ve tüm kalan taksitleri kapatma
- Tanım yönetimi: hafta tatili, departman ve görev/ünvan ekle-sil
- Süper admin: firma listesi, aktif/pasif, firma bilgileri ve firma giriş şifresi düzenleme
- Biyometrik uygulama kilidi: Face ID / Touch ID / Android biometric
- Native yerel bildirim izni ve test bildirimi
- Hesap/güvenlik, KVKK/Gizlilik/Kullanım Koşulları bağlantıları

## Windows'ta Android test

1. Flutter SDK kurun ve `flutter doctor` çalıştırın.
2. Android Studio + Android SDK + Emulator kurun veya USB hata ayıklama açık Android telefon bağlayın.
3. PowerShell/CMD:

```bat
set API_BASE_URL=https://domaininiz.com
run_android_windows.bat
```

Release APK/AAB:

```bat
set API_BASE_URL=https://domaininiz.com
build_android_windows.bat
```

## iOS test

Flutter kaynaklarını Windows'ta geliştirebilirsiniz ancak iOS derleme/simulator için macOS + Xcode zorunludur.
Mac üzerinde:

```sh
export API_BASE_URL=https://domaininiz.com
./build_ios_macos.sh
```

Gerçek Face ID, iOS safe-area, native print ve TestFlight testi gerçek iPhone veya Xcode Simulator ile yapılmalıdır.

## Not

`local_auth`, `flutter_local_notifications` ve `printing/pdf` paketleri V39'da kullanılır. İlk kez platform klasörleri oluşturulacaksa Flutter SDK bulunan bilgisayarda proje kökünde `flutter create .` çalıştırılıp `native_config` içindeki ek izinler AndroidManifest.xml ve Info.plist'e uygulanmalıdır.
