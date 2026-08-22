import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/app_state.dart';
import '../core/notification_service.dart';
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
    await showDialog(context: context, builder: (c) => AlertDialog(title: const Text('Şifre Değiştir'), content: Column(mainAxisSize: MainAxisSize.min, children: [TextField(controller: old, obscureText: true, decoration: const InputDecoration(labelText: 'Mevcut Şifre')), const SizedBox(height: 8), TextField(controller: fresh, obscureText: true, decoration: const InputDecoration(labelText: 'Yeni Şifre'))]), actions: [TextButton(onPressed: () => Navigator.pop(c), child: const Text('Vazgeç')), FilledButton(onPressed: () async { try { await widget.state.api.request('auth/change-password', method: 'POST', data: {'old_password': old.text, 'new_password': fresh.text}); if (c.mounted) Navigator.pop(c); if (mounted) snack(context, 'Şifre güncellendi.'); } catch (e) { if (mounted) snack(context, '$e', error: true); } }, child: const Text('Kaydet'))]));
  }

  Future<void> openWeb(String path) async {
    final base = widget.state.api.baseUrl.replaceAll(RegExp(r'/$'), '');
    await launchUrl(Uri.parse('$base/$path'), mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Hesap ve Güvenlik')),
        body: SafeArea(
          child: ListView(padding: const EdgeInsets.all(12), children: [
            Card(child: ListTile(leading: const CircleAvatar(child: Icon(Icons.person_outline)), title: Text('${widget.state.user?['name'] ?? ''}', style: const TextStyle(fontWeight: FontWeight.w800)), subtitle: Text('${widget.state.user?['email'] ?? ''}\n${widget.state.company?['company_name'] ?? ''}'), isThreeLine: true)),
            Card(child: Column(children: [
              SwitchListTile(value: widget.state.biometricEnabled, secondary: const Icon(Icons.fingerprint), title: const Text('Biyometrik Giriş'), subtitle: const Text('Face ID / Touch ID / parmak izi ile uygulamayı aç.'), onChanged: (v) async { try { await widget.state.setBiometricEnabled(v); if (mounted) snack(context, v ? 'Biyometrik giriş etkinleştirildi.' : 'Biyometrik giriş kapatıldı.'); } catch (e) { if (mounted) snack(context, '$e', error: true); } }),
              ListTile(leading: const Icon(Icons.lock_outline), title: const Text('Şifre Değiştir'), trailing: const Icon(Icons.chevron_right), onTap: changePassword),
              ListTile(leading: const Icon(Icons.notifications_outlined), title: const Text('Bildirim İzni'), subtitle: const Text('Native İK bildirimlerini etkinleştir ve test et.'), trailing: const Icon(Icons.chevron_right), onTap: () async { final ok = await NotificationService.instance.requestPermission(); if (ok) { await NotificationService.instance.showTest(); if (mounted) snack(context, 'Bildirim izni hazır. Test bildirimi gönderildi.'); } else if (mounted) snack(context, 'Bildirim izni verilmedi.', error: true); }),
            ])),
            Card(child: Column(children: [
              ListTile(leading: const Icon(Icons.privacy_tip_outlined), title: const Text('Gizlilik Politikası'), onTap: () => openWeb('privacy.php')),
              ListTile(leading: const Icon(Icons.gavel_outlined), title: const Text('KVKK Aydınlatma'), onTap: () => openWeb('kvkk.php')),
              ListTile(leading: const Icon(Icons.description_outlined), title: const Text('Kullanım Koşulları'), onTap: () => openWeb('terms.php')),
            ])),
            if (!widget.state.isSuper) Card(child: ListTile(leading: const Icon(Icons.delete_outline, color: Colors.red), title: const Text('Hesap ve Veri Silme Talebi'), subtitle: const Text('Talep yönetim sürecine alınır.'), onTap: () async { try { await widget.state.api.request('account/delete-request', method: 'POST', data: {'note': 'Native uygulamadan oluşturuldu.'}); if (mounted) snack(context, 'Silme talebi oluşturuldu.'); } catch (e) { if (mounted) snack(context, '$e', error: true); } })),
            const SizedBox(height: 8),
            OutlinedButton.icon(onPressed: widget.state.logout, icon: const Icon(Icons.logout), label: const Text('Çıkış Yap')),
          ]),
        ),
      );
}
