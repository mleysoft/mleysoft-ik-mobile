# MleySoft İK V147 — Dosya Yükleme / Store İzinleri

## iOS / App Store
İK ERP > Özlük Belgeleri ekranında PDF/JPG/PNG seçimi için sistem belge seçici kullanılır.

Info.plist üretiminde aşağıdaki açıklamalar korunur:
- NSPhotoLibraryUsageDescription:
  “MleySoft İK, firma yöneticisinin İK ERP içindeki özlük kayıtlarına eklemek üzere yalnızca kendisinin seçtiği fotoğraf veya belge görsellerine erişir.”
- NSCameraUsageDescription: QR okutma için.
- NSLocationWhenInUseUsageDescription: QR işyeri konum doğrulaması için.
- NSFaceIDUsageDescription: güvenli giriş için.

Always Location anahtarları eklenmez.

## Android / Google Play
PDF/JPG/PNG seçimi Android sistem dosya seçici (Storage Access Framework) üzerinden yapılır.
Bu nedenle dosya yükleme için aşağıdaki geniş izinler istenmez:
- READ_MEDIA_IMAGES
- READ_MEDIA_VIDEO
- READ_EXTERNAL_STORAGE
- WRITE_EXTERNAL_STORAGE
- MANAGE_EXTERNAL_STORAGE

`cleanup_media_permissions.ps1` build öncesinde bu izinler yanlışlıkla eklenmişse temizler.

Google Play medya erişim politikasında uygulama sürekli/çekirdek medya erişimi talep etmediği için geniş Fotoğraf ve Video izinleri kullanılmaz.
