import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/app_state.dart';
import '../core/notification_service.dart';
import '../core/theme.dart';
import '../widgets/branded_loading.dart';
import '../widgets/common.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key, required this.state});
  final AppState state;
  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  Future<void> changePassword() async {
    final old = TextEditingController(), fresh = TextEditingController();
    await showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Şifre Değiştir'),
        content: SizedBox(
          width: 430,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(controller: old, obscureText: true, decoration: const InputDecoration(labelText: 'Mevcut Şifre', prefixIcon: Icon(Icons.lock_outline))),
            const SizedBox(height: 10),
            TextField(controller: fresh, obscureText: true, decoration: const InputDecoration(labelText: 'Yeni Şifre', prefixIcon: Icon(Icons.password_outlined))),
          ]),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c), child: const Text('Vazgeç')),
          FilledButton(
            onPressed: () async {
              try {
                await widget.state.api.request('auth/change-password', method: 'POST', data: {'old_password': old.text, 'new_password': fresh.text});
                if (c.mounted) Navigator.pop(c);
                if (mounted) snack(context, 'Şifre güncellendi.');
              } catch (e) {
                if (mounted) snack(context, '$e', error: true);
              }
            },
            child: const Text('Kaydet'),
          )
        ],
      ),
    );
  }

  Future<void> openWeb(String path) async {
    final url = '${widget.state.api.publicRoot}/${path.replaceFirst(RegExp(r'^/+'), '')}';
    final ok = await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    if (!ok && mounted) snack(context, 'Bağlantı açılamadı.', error: true);
  }

  Future<void> logout() async {
    MleyLoadingController.instance.reset();
    await widget.state.logout();
    if (!mounted) return;
    Navigator.of(context, rootNavigator: true).popUntil((route) => route.isFirst);
  }

  Widget actionTile(IconData icon, String title, String subtitle, VoidCallback tap) => ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
        leading: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(color: MTheme.limeSoft, borderRadius: BorderRadius.circular(13)),
          child: Icon(icon, color: MTheme.ink),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 10.5)),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: tap,
      );

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Hesap ve Güvenlik')),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(14),
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [MTheme.ink, MTheme.ink2]),
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: MTheme.softShadow,
                ),
                child: Row(children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: MTheme.lime,
                    foregroundColor: MTheme.ink,
                    child: Text(
                      '${widget.state.user?['name'] ?? 'M'}'.trim().isEmpty ? 'M' : '${widget.state.user?['name'] ?? 'M'}'.trim()[0],
                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('${widget.state.user?['name'] ?? ''}', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
                    Text('${widget.state.user?['email'] ?? ''}', style: const TextStyle(color: Colors.white70, fontSize: 11)),
                    const SizedBox(height: 5),
                    Text('${widget.state.company?['company_name'] ?? ''}', style: const TextStyle(color: MTheme.lime, fontSize: 11, fontWeight: FontWeight.w800)),
                  ])),
                  const Icon(Icons.verified_user_outlined, color: MTheme.lime, size: 30),
                ]),
              ),
              const SizedBox(height: 16),
              const TechSectionHeader(title: 'Güvenlik', subtitle: 'Hesap ve cihaz güvenliği seçenekleri'),
              const SizedBox(height: 9),
              TechCard(child: Column(children: [
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: widget.state.biometricEnabled,
                  secondary: const Icon(Icons.fingerprint, color: MTheme.ink),
                  title: const Text('Biyometrik Giriş', style: TextStyle(fontWeight: FontWeight.w800)),
                  subtitle: const Text('Face ID / Touch ID / parmak izi'),
                  onChanged: (v) async {
                    try {
                      if (!v) {
                        await widget.state.setBiometricEnabled(false);
                        if (mounted) snack(context, 'Biyometrik giriş kapatıldı.');
                        return;
                      }
                      final supported = await widget.state.biometric.isSupported();
                      if (!supported) {
                        if (mounted) snack(context, 'Bu cihazda Face ID / Touch ID kullanılamıyor veya cihazda biyometri tanımlı değil.', error: true);
                        return;
                      }
                      await widget.state.setBiometricEnabled(true);
                      if (mounted) snack(context, 'Biyometrik giriş etkinleştirildi.');
                    } catch (e) {
                      if (mounted) snack(context, 'Biyometrik giriş açılamadı. $e', error: true);
                    }
                  },
                ),
                const Divider(),
                actionTile(Icons.lock_reset_outlined, 'Şifre Değiştir', 'Hesap parolanızı güncelleyin', changePassword),
                const Divider(),
                actionTile(Icons.notifications_active_outlined, 'Bildirim İzni', 'Uygulama bildirimlerini kontrol edin', () async {
                  final ok = await NotificationService.instance.requestPermission();
                  if (ok) {
                    final sent = await NotificationService.instance.showTest();
                    if (mounted) {
                      snack(
                        context,
                        sent ? 'Test bildirimi gönderildi.' : 'Bildirim izni açık ancak test bildirimi gösterilemedi.',
                        error: !sent,
                      );
                    }
                  } else if (mounted) {
                    snack(context, 'Bildirim izni verilmedi. iPhone Ayarlar > Bildirimler > MleySoft İK bölümünü kontrol edin.', error: true);
                  }
                }),
              ])),
              const SizedBox(height: 16),
              const TechSectionHeader(title: 'Yasal ve Gizlilik', subtitle: 'MleySoft İK yasal metinleri'),
              const SizedBox(height: 9),
              TechCard(child: Column(children: [
                actionTile(Icons.privacy_tip_outlined, 'Gizlilik Politikası', 'Veri işleme ve gizlilik politikası', () => openWeb('privacy.php')),
                const Divider(),
                actionTile(Icons.gavel_outlined, 'KVKK Aydınlatma', 'Kişisel verilerin korunması metni', () => openWeb('kvkk.php')),
                const Divider(),
                actionTile(Icons.description_outlined, 'Kullanım Koşulları', 'Uygulama kullanım şartları', () => openWeb('terms.php')),
                const Divider(),
                actionTile(Icons.delete_forever_outlined, 'Hesap Silme Sayfası', 'Web üzerinden hesap ve veri silme talebi', () => openWeb('hesap-silme.php')),
              ])),
              if (!widget.state.isSuper) ...[
                const SizedBox(height: 16),
                TechCard(child: actionTile(Icons.delete_outline, 'Hesap ve Veri Silme Talebi', 'Talep yönetim sürecine alınır', () async {
                  try {
                    await widget.state.api.request('account/delete-request', method: 'POST', data: {'note': 'Native uygulamadan oluşturuldu.'});
                    if (mounted) snack(context, 'Silme talebi oluşturuldu.');
                  } catch (e) {
                    if (mounted) snack(context, '$e', error: true);
                  }
                })),
              ],
              const SizedBox(height: 18),
              SizedBox(width: double.infinity, child: OutlinedButton.icon(onPressed: logout, icon: const Icon(Icons.logout_rounded), label: const Text('Güvenli Çıkış Yap'))),
            ],
          ),
        ),
      );
}
