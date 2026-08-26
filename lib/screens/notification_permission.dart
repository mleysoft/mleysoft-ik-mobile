import 'package:flutter/material.dart';
import '../core/theme.dart';

class NotificationPermissionScreen extends StatelessWidget {
  const NotificationPermissionScreen({
    super.key,
    required this.onAllow,
    required this.onLater,
    this.permissionDenied = false,
  });

  final Future<void> Function() onAllow;
  final Future<void> Function() onLater;
  final bool permissionDenied;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Spacer(),
              Container(
                width: 94,
                height: 94,
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F8D8),
                  borderRadius: BorderRadius.circular(28),
                ),
                child: const Icon(Icons.notifications_active_outlined, size: 48, color: MTheme.ink),
              ),
              const SizedBox(height: 24),
              const Text(
                'Bildirimleri Açık Tutun',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 25, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 10),
              Text(
                permissionDenied
                    ? 'Bildirim izni verilmedi. MleySoft İK bildirimleri yalnızca oturum açtığınız hesaba ait önemli İK bilgilerini zamanında ulaştırmak için kullanılır. Firma duyuruları, vardiya ve puantaj bildirimleri, izin/rapor bilgilendirmeleri ve size özel uyarıları uygulamayı açmadan görebilmeniz için bildirimleri açmanızı öneririz.'
                    : 'Firma duyuruları, vardiya ve puantaj bildirimleri, izin/rapor bilgilendirmeleri ve size özel önemli İK uyarılarını zamanında alabilmek için bildirimlere izin verin.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: MTheme.muted, height: 1.45),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: FilledButton.icon(
                  onPressed: onAllow,
                  icon: const Icon(Icons.notifications_outlined),
                  label: Text(permissionDenied ? 'Bildirimleri Aç' : 'Bildirimlere İzin Ver'),
                ),
              ),
              const SizedBox(height: 8),
              TextButton(onPressed: onLater, child: const Text('Daha Sonra')),
              const Spacer(),
              const Text(
                'Daha sonra uygulama ayarlarından bildirim iznini yeniden açabilirsiniz.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 10, color: MTheme.muted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
