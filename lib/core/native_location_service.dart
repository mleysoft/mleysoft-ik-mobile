import 'package:flutter/services.dart';

class NativePosition {
  const NativePosition({required this.latitude, required this.longitude, required this.accuracy, this.isMocked = false});
  final double latitude;
  final double longitude;
  final double accuracy;
  final bool isMocked;
}

class NativeLocationService {
  static const MethodChannel _channel = MethodChannel('com.mleysoft.ik/location');

  static Future<NativePosition> currentPosition() async {
    try {
      final raw = await _channel.invokeMethod<Map<dynamic, dynamic>>('getCurrentLocation').timeout(
        const Duration(seconds: 15),
        onTimeout: () => throw Exception('Konum bilgisi zamanında alınamadı. Konum servisini kontrol edip QR kodunu tekrar okutun.'),
      );
      if (raw == null) throw Exception('Konum bilgisi alınamadı.');
      final lat = (raw['latitude'] as num?)?.toDouble();
      final lng = (raw['longitude'] as num?)?.toDouble();
      final accuracy = (raw['accuracy'] as num?)?.toDouble() ?? 0;
      final isMocked = raw['is_mocked'] == true;
      if (lat == null || lng == null) throw Exception('Konum bilgisi alınamadı.');
      return NativePosition(latitude: lat, longitude: lng, accuracy: accuracy, isMocked: isMocked);
    } on PlatformException catch (e) {
      if (e.code == 'LOCATION_PERMISSION_DENIED') throw Exception('Firmanız QR işlemlerinde işyeri konum doğrulaması kullanıyor. Giriş/çıkış için konum izni vermelisiniz.');
      if (e.code == 'LOCATION_PERMISSION_DENIED_FOREVER') throw Exception('Konum izni kapalı. Telefon ayarlarından MleySoft İK için konum iznini açmalısınız.');
      if (e.code == 'LOCATION_SERVICE_DISABLED') throw Exception('Konum servisi kapalı. QR okutmak için telefonunuzun konum servisini açın.');
      throw Exception(e.message ?? 'Konum bilgisi alınamadı.');
    }
  }
}
