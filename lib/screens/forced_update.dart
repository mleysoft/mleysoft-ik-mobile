import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/app_state.dart';
import '../core/theme.dart';

class ForcedUpdateScreen extends StatefulWidget {
  const ForcedUpdateScreen({super.key, required this.state});
  final AppState state;
  @override
  State<ForcedUpdateScreen> createState() => _ForcedUpdateScreenState();
}

class _ForcedUpdateScreenState extends State<ForcedUpdateScreen> {
  bool busy = false;

  Future<void> _openStore() async {
    final uri = Uri.tryParse(widget.state.updateStoreUrl.trim());
    if (uri != null) await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _retry() async {
    if (busy) return;
    setState(() => busy = true);
    await widget.state.recheckRequiredUpdate();
    if (mounted) setState(() => busy = false);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: const Color(0xFFF3F6F8),
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(28),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Column(
                  children: [
                    Container(width: 84, height: 84, decoration: BoxDecoration(color: MTheme.ink, borderRadius: BorderRadius.circular(24)), child: const Icon(Icons.system_update_alt_rounded, color: MTheme.lime, size: 42)),
                    const SizedBox(height: 24),
                    const Text('Güncelleme Gerekli', style: TextStyle(fontSize: 25, fontWeight: FontWeight.w900), textAlign: TextAlign.center),
                    const SizedBox(height: 10),
                    Text(widget.state.updateMessage, style: const TextStyle(fontSize: 14, height: 1.5, color: Color(0xFF52606D)), textAlign: TextAlign.center),
                    const SizedBox(height: 8),
                    Text('Yüklü sürüm: ${AppState.currentVersion} (${AppState.currentBuild})', style: const TextStyle(fontSize: 11, color: Color(0xFF7A8793))),
                    const SizedBox(height: 26),
                    SizedBox(width: double.infinity, height: 50, child: FilledButton.icon(onPressed: widget.state.updateStoreUrl.trim().isEmpty ? null : _openStore, icon: const Icon(Icons.storefront_outlined), label: const Text('Uygulamayı Güncelle'))),
                    const SizedBox(height: 10),
                    TextButton.icon(onPressed: busy ? null : _retry, icon: busy ? const SizedBox.square(dimension: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.refresh_rounded), label: const Text('Tekrar Kontrol Et')),
                    const SizedBox(height: 8),
                    const Text('Güncelleme tamamlanmadan uygulama kullanılamaz.', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF7A8793))),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
