# MleySoft İK V105 - App Store / Google Play Konum Beyanı

## Uygulamadaki gerçek kullanım
- Konum yalnızca firma yöneticisi QR işyeri konum doğrulamasını etkinleştirmişse kullanılır.
- Personel QR giriş/çıkış kodunu okuttuktan sonra uygulama hassas konumu ve doğruluk bilgisini alır.
- Koordinat, tanımlı işyeri koordinatına mesafe kontrolü yapılması için API'ye gönderilir.
- Arka planda veya sürekli konum takibi yapılmaz.
- Android background location izni yoktur.
- iOS `NSLocationAlways*` izni yoktur; yalnızca `NSLocationWhenInUseUsageDescription` vardır.

## App Store Connect için önerilen beyan
App Privacy bölümünde uygulamanın mevcut veri akışına göre **Location > Precise Location** verisi beyan edilmelidir. Amaç **App Functionality** olarak seçilmelidir. Konum, oturum açmış personelin QR işlemiyle birlikte API'ye iletildiği için kullanıcıyla ilişkilendirilebilir niteliktedir. Tracking amacıyla kullanılmaz.

## Google Play Console için önerilen beyan
Data safety formunda **Location > Precise location** verisi, QR giriş/çıkış işyeri doğrulaması için **App functionality** amacıyla kullanılan veri olarak beyan edilmelidir. Uygulama arka planda konum istemez. `ACCESS_BACKGROUND_LOCATION` kullanılmamalıdır.

## Store inceleme notu için kısa açıklama
"MleySoft İK, firma yöneticisinin etkinleştirmesi halinde personelin QR giriş/çıkış işlemini yalnızca tanımlı işyeri konumunda yapabildiğini doğrulamak için uygulama kullanım sırasında hassas konum ister. Konum sürekli veya arka planda takip edilmez."
