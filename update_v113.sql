-- MleySoft İK V113 - Mobil zorunlu güncelleme ayarları
-- V112 mağaza build'i 111 olduğundan ilk kurulumda kilitlenmemesi için minimum 111 bırakılır.
-- V113 (build 112) mağazalarda yayınlandıktan sonra Admin > Mobil Uygulama ekranından minimum build'i 112 yapın.
INSERT INTO system_settings(setting_key,setting_value) VALUES
('mobile_min_build_android','111'),
('mobile_min_build_ios','111'),
('mobile_store_url_android','https://play.google.com/store/apps/details?id=com.mleysoft.ik'),
('mobile_store_url_ios',''),
('mobile_force_update_message','MleySoft İK uygulamasının yeni bir sürümü yayınlandı. Devam etmek için uygulamayı güncellemeniz gerekiyor.')
ON DUPLICATE KEY UPDATE setting_key=VALUES(setting_key);
