import 'package:flutter/material.dart';
import '../core/app_state.dart';
import '../core/theme.dart';
import '../widgets/common.dart';

class BiometricLockScreen extends StatefulWidget {
  const BiometricLockScreen({super.key, required this.state});
  final AppState state;
  @override
  State<BiometricLockScreen> createState() => _BiometricLockScreenState();
}

class _BiometricLockScreenState extends State<BiometricLockScreen> {
  bool busy = false;

  Future<void> unlock() async {
    setState(() => busy = true);
    final ok = await widget.state.unlock();
    if (!ok && mounted) snack(context, 'Biyometrik doğrulama tamamlanamadı.', error: true);
    if (mounted) setState(() => busy = false);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  children: [
                    Image.asset('assets/images/mleysoft-logo.png', height: 58),
                    const SizedBox(height: 26),
                    Container(
                      width: 76,
                      height: 76,
                      decoration: BoxDecoration(color: MTheme.ink, borderRadius: BorderRadius.circular(24)),
                      child: const Icon(Icons.fingerprint, color: MTheme.lime, size: 42),
                    ),
                    const SizedBox(height: 18),
                    const Text('Uygulama Kilitli', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 8),
                    const Text('MleySoft İK çalışma alanınıza biyometrik doğrulama ile devam edin.', textAlign: TextAlign.center, style: TextStyle(color: MTheme.muted)),
                    const SizedBox(height: 22),
                    SizedBox(width: double.infinity, child: FilledButton.icon(onPressed: busy ? null : unlock, icon: const Icon(Icons.fingerprint), label: Text(busy ? 'Doğrulanıyor...' : 'Biyometrik ile Aç'))),
                    const SizedBox(height: 8),
                    TextButton(onPressed: widget.state.logout, child: const Text('Başka hesapla giriş yap')),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
}
