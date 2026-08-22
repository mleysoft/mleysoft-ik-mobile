import 'package:flutter/material.dart';
import '../core/app_state.dart';
import '../widgets/common.dart';

class CompanyAdminScreen extends StatefulWidget {
  const CompanyAdminScreen({super.key, required this.state});
  final AppState state;
  @override
  State<CompanyAdminScreen> createState() => _CompanyAdminScreenState();
}

class _CompanyAdminScreenState extends State<CompanyAdminScreen> {
  List rows = [];
  final search = TextEditingController();
  bool busy = false;

  @override
  void initState() { super.initState(); load(); }
  @override
  void dispose() { search.dispose(); super.dispose(); }

  Future<void> load() async {
    setState(() => busy = true);
    try {
      final r = await widget.state.api.request('companies');
      var list = (r['companies'] ?? []) as List;
      final q = search.text.trim().toLowerCase();
      if (q.isNotEmpty) list = list.where((x) => '${x['id']} #${(int.tryParse('${x['id']}') ?? 0).toString().padLeft(4, '0')} ${x['company_name']} ${x['email']} ${x['phone']}'.toLowerCase().contains(q)).toList();
      if (mounted) setState(() => rows = list);
    } catch (e) {
      if (mounted) snack(context, '$e', error: true);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> edit(dynamic row) async {
    final r = await widget.state.api.request('company', query: {'company_id': row['id']});
    final c = Map<String, dynamic>.from(r['company']);
    final name = TextEditingController(text: '${c['company_name'] ?? ''}');
    final shortName = TextEditingController(text: '${c['short_name'] ?? ''}');
    final taxOffice = TextEditingController(text: '${c['tax_office'] ?? ''}');
    final taxNo = TextEditingController(text: '${c['tax_no'] ?? ''}');
    final phone = TextEditingController(text: '${c['phone'] ?? ''}');
    final email = TextEditingController(text: '${c['email'] ?? ''}');
    final address = TextEditingController(text: '${c['address'] ?? ''}');
    final password = TextEditingController();
    String status = '${c['status'] ?? 'active'}';
    if (!mounted) return;
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setM) => Padding(
            padding: EdgeInsets.only(left: 16, right: 16, top: 16, bottom: MediaQuery.viewInsetsOf(ctx).bottom + 16),
            child: SingleChildScrollView(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Row(children: [Expanded(child: Text('Firma Düzenle', style: Theme.of(ctx).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800))), IconButton(onPressed: () => Navigator.pop(ctx), icon: const Icon(Icons.close))]),
                const SizedBox(height: 10),
                TextField(controller: name, decoration: const InputDecoration(labelText: 'Firma Adı')),
                const SizedBox(height: 8),
                TextField(controller: shortName, decoration: const InputDecoration(labelText: 'Kısa Ad')),
                const SizedBox(height: 8),
                Row(children: [Expanded(child: TextField(controller: taxOffice, decoration: const InputDecoration(labelText: 'Vergi Dairesi'))), const SizedBox(width: 8), Expanded(child: TextField(controller: taxNo, decoration: const InputDecoration(labelText: 'Vergi No')))]),
                const SizedBox(height: 8),
                Row(children: [Expanded(child: TextField(controller: phone, decoration: const InputDecoration(labelText: 'Telefon'))), const SizedBox(width: 8), Expanded(child: TextField(controller: email, decoration: const InputDecoration(labelText: 'E-posta')))]),
                const SizedBox(height: 8),
                TextField(controller: address, maxLines: 2, decoration: const InputDecoration(labelText: 'Adres')),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(value: status, decoration: const InputDecoration(labelText: 'Durum'), items: const [DropdownMenuItem(value: 'active', child: Text('Aktif')), DropdownMenuItem(value: 'passive', child: Text('Pasif'))], onChanged: (v) => setM(() => status = v ?? 'active')),
                const SizedBox(height: 8),
                TextField(controller: password, obscureText: true, decoration: const InputDecoration(labelText: 'Yeni Firma Şifresi', helperText: 'Değiştirmeyecekseniz boş bırakın.')),
                const SizedBox(height: 14),
                SizedBox(width: double.infinity, child: FilledButton(onPressed: () async {
                  try {
                    await widget.state.api.request('company', method: 'PUT', data: {'company_id': c['id'], 'company_name': name.text.trim(), 'short_name': shortName.text.trim(), 'tax_office': taxOffice.text.trim(), 'tax_no': taxNo.text.trim(), 'phone': phone.text.trim(), 'email': email.text.trim(), 'address': address.text.trim(), 'status': status, 'new_password': password.text});
                    if (ctx.mounted) Navigator.pop(ctx);
                    await load();
                  } catch (e) { if (mounted) snack(context, '$e', error: true); }
                }, child: const Text('Firma Bilgilerini Kaydet'))),
              ]),
            ),
          )),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Firma Yönetimi')),
        body: SafeArea(
          child: Column(children: [
            Padding(padding: const EdgeInsets.all(12), child: Row(children: [Expanded(child: TextField(controller: search, onChanged: (_) => load(), decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Firma no veya firma adı ara'))), const SizedBox(width: 8), IconButton.filled(onPressed: load, icon: const Icon(Icons.filter_alt_outlined))])),
            Expanded(child: busy && rows.isEmpty ? const Center(child: CircularProgressIndicator()) : RefreshIndicator(onRefresh: load, child: ListView.builder(itemCount: rows.length, itemBuilder: (_, i) {
              final x = rows[i];
              return Card(margin: const EdgeInsets.fromLTRB(12, 0, 12, 8), child: ListTile(onTap: () => edit(x), leading: CircleAvatar(child: Text('${x['company_name']}'.isEmpty ? '?' : '${x['company_name']}'[0])), title: Text('${x['company_name']}', style: const TextStyle(fontWeight: FontWeight.w700)), subtitle: Text('Firma #${(int.tryParse('${x['id']}') ?? 0).toString().padLeft(4, '0')} · ${x['employee_count'] ?? 0} personel\n${x['admin_email'] ?? x['email'] ?? '-'}'), isThreeLine: false, trailing: Switch(value: x['status'] == 'active', onChanged: (v) async { try { await widget.state.api.request('company/status', method: 'POST', data: {'company_id': x['id'], 'status': v ? 'active' : 'passive'}); load(); } catch (e) { if (mounted) snack(context, '$e', error: true); } })));
            }))),
          ]),
        ),
      );
}
