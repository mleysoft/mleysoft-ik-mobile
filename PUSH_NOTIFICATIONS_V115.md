# V115 Bildirim Davranışı

V115, mevcut WorkManager tabanlı personel duyuru kontrolünde uygulama girişinde oluşan initialization yarışını giderir. Android'de uygulama arka planda veya son uygulamalar ekranından kapatılmış olsa bile işletim sistemi izin verdiği sürece yaklaşık 15 dakikalık periyodik kontrolde yeni duyurular yerel bildirim olarak gösterilir.

## Gerçek anlık push için gerekenler

Telefon uygulaması tamamen kapalıyken bildirimin gönderildiği saniyelerde ulaşması için sunucudan push servisi gerekir. Sadece PHP veritabanına kayıt + WorkManager polling ile Android/iOS'ta saniyesinde teslim garanti edilemez.

Kurumsal çözüm için Firebase Cloud Messaging (FCM) + Apple Push Notification service (APNs) kurulmalıdır:
- Firebase projesinde Android uygulaması: `com.mleysoft.ik`
- Firebase projesinde iOS uygulaması: `com.mleysoft.ik`
- Android Firebase uygulama yapılandırması
- iOS Push Notifications capability ve APNs key/certificate
- Sunucuda FCM HTTP v1 için service-account yetkisi
- Mobil cihaz tokenlarının MleySoft İK API'ye kaydedilmesi

Bu bilgiler sağlandığında duyuru gönderimi sırasında hedef personellerin cihaz tokenlarına gerçek push gönderimi bağlanabilir.
