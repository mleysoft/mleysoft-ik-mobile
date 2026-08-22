import 'package:flutter/material.dart';
import '../core/theme.dart';

class NotificationPermissionScreen extends StatelessWidget {
  const NotificationPermissionScreen({
    super.key,
    required this.onAllow,
    required this.onLater,
  });

  final Future<void> Function() onAllow;
  final Future<void> Function() onLater;

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
                'Bildirimleri Açın',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 25, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 10),
              const Text(
                'Puantaj hatırlatmaları, vardiya uyarıları ve size özel bildirimleri zamanında alabilmek için MleySoft İK bildirimlerine izin verin.',
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
                  label: const Text('Bildirimlere İzin Ver'),
                ),
              ),
              const SizedBox(height: 8),
              TextButton(onPressed: onLater, child: const Text('Şimdilik Değil')),
              const Spacer(),
              const Text(
                'Bu seçim daha sonra telefonunuzun uygulama ayarlarından değiştirilebilir.',
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
