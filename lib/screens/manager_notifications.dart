import 'package:flutter/material.dart';
import '../core/app_state.dart';
import '../core/theme.dart';
import '../widgets/common.dart';

class ManagerNotificationsScreen extends StatefulWidget {
  const ManagerNotificationsScreen({super.key, required this.state});
  final AppState state;

  @override
  State<ManagerNotificationsScreen> createState() => _ManagerNotificationsScreenState();
}

class _ManagerNotificationsScreenState extends State<ManagerNotificationsScreen> {
  bool loading = true;
  bool sending = false;
  List<Map<String, dynamic>> businessUnits = [];
  List<String> departments = [];
  List<Map<String, dynamic>> employees = [];
  List<Map<String, dynamic>> history = [];
  int businessUnitId = 0;
  String department = '';
  final Set<int> selectedEmployees = {};
  final titleController = TextEditingController();
  final detailController = TextEditingController();

  @override
  void initState() {
    super.initState();
    load();
  }

  @override
  void dispose() {
    titleController.dispose();
    detailController.dispose();
    super.dispose();
  }

  int _id(dynamic v) => int.tryParse('$v') ?? 0;

  List<Map<String, dynamic>> get filteredEmployees => employees.where((e) {
        final unitOk = businessUnitId == 0 || _id(e['business_unit_id']) == businessUnitId;
        final depOk = department.isEmpty || '${e['department'] ?? ''}' == department;
        return unitOk && depOk;
      }).toList();

  Future<void> load() async {
    try {
      final r = await widget.state.api.request('manager/notifications');
      if (!mounted) return;
      setState(() {
        businessUnits = ((r['business_units'] ?? []) as List).map((e) => Map<String, dynamic>.from(e)).toList();
        departments = ((r['departments'] ?? []) as List).map((e) => '$e').toList();
        employees = ((r['employees'] ?? []) as List).map((e) => Map<String, dynamic>.from(e)).toList();
        history = ((r['history'] ?? []) as List).map((e) => Map<String, dynamic>.from(e)).toList();
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => loading = false);
      snack(context, '$e', error: true);
    }
  }

  Future<bool> send() async {
    final title = titleController.text.trim();
    final detail = detailController.text.trim();
    if (title.isEmpty || detail.isEmpty) {
      snack(context, 'Bildirim başlığı ve detayı zorunludur.', error: true);
      return false;
    }
    setState(() => sending = true);
    try {
      final r = await widget.state.api.request(
        'manager/notifications',
        method: 'POST',
        data: {
          'title': title,
          'detail': detail,
          'business_unit_id': businessUnitId,
          'department': department,
          'employee_ids': selectedEmployees.toList(),
        },
      );
      if (!mounted) return false;
      snack(context, '${r['message'] ?? 'Bildirim gönderildi.'}');
      titleController.clear();
      detailController.clear();
      selectedEmployees.clear();
      await load();
      return true;
    } catch (e) {
      if (mounted) snack(context, '$e', error: true);
      return false;
    } finally {
      if (mounted) setState(() => sending = false);
    }
  }

  Future<void> openComposer() async {
    selectedEmployees.clear();
    businessUnitId = 0;
    department = '';
    titleController.clear();
    detailController.clear();
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(26))),
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, setSheetState) {
          final visible = employees.where((e) {
            final unitOk = businessUnitId == 0 || _id(e['business_unit_id']) == businessUnitId;
            final depOk = department.isEmpty || '${e['department'] ?? ''}' == department;
            return unitOk && depOk;
          }).toList();
          final visibleIds = visible.map((e) => _id(e['id'])).where((id) => id > 0).toSet();
          final allVisibleSelected = visibleIds.isNotEmpty && visibleIds.every(selectedEmployees.contains);
          return Padding(
            padding: EdgeInsets.only(left: 16, right: 16, top: 12, bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 18),
            child: SingleChildScrollView(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Center(child: Container(width: 44, height: 4, decoration: BoxDecoration(color: Colors.black12, borderRadius: BorderRadius.circular(99)))),
                const SizedBox(height: 15),
                const Text('Yeni Personel Bildirimi', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
                const SizedBox(height: 4),
                const Text('Tüm firmalara, departmana veya seçtiğiniz personele kurumsal bildirim gönderin.', style: TextStyle(fontSize: 11, color: MTheme.muted, height: 1.4)),
                const SizedBox(height: 16),
                TextField(controller: titleController, maxLength: 120, decoration: const InputDecoration(labelText: 'Bildirim Başlığı *', prefixIcon: Icon(Icons.title_rounded))),
                const SizedBox(height: 10),
                TextField(controller: detailController, minLines: 4, maxLines: 8, decoration: const InputDecoration(labelText: 'Bildirim Detayı *', alignLabelWithHint: true, prefixIcon: Icon(Icons.notes_rounded))),
                const SizedBox(height: 12),
                DropdownButtonFormField<int>(
                  value: businessUnitId,
                  decoration: const InputDecoration(labelText: 'Firma'),
                  items: [
                    const DropdownMenuItem(value: 0, child: Text('Tüm Firmalar')),
                    ...businessUnits.map((b) => DropdownMenuItem(value: _id(b['id']), child: Text('${b['unit_no'] ?? ''} · ${b['name'] ?? ''}', overflow: TextOverflow.ellipsis))),
                  ],
                  onChanged: (v) => setSheetState(() {
                    businessUnitId = v ?? 0;
                    selectedEmployees.removeWhere((id) => !employees.any((e) => _id(e['id']) == id && (businessUnitId == 0 || _id(e['business_unit_id']) == businessUnitId)));
                  }),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: department,
                  decoration: const InputDecoration(labelText: 'Departman'),
                  items: [
                    const DropdownMenuItem(value: '', child: Text('Tüm Departmanlar')),
                    ...departments.map((d) => DropdownMenuItem(value: d, child: Text(d))),
                  ],
                  onChanged: (v) => setSheetState(() {
                    department = v ?? '';
                    selectedEmployees.removeWhere((id) => !employees.any((e) => _id(e['id']) == id && (department.isEmpty || '${e['department'] ?? ''}' == department) && (businessUnitId == 0 || _id(e['business_unit_id']) == businessUnitId)));
                  }),
                ),
                const SizedBox(height: 14),
                Row(children: [
                  Expanded(child: Text('${visible.length} aktif personel hedefte · ${selectedEmployees.length} seçili', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700))),
                  TextButton(
                    onPressed: visibleIds.isEmpty ? null : () => setSheetState(() {
                      if (allVisibleSelected) {
                        selectedEmployees.removeAll(visibleIds);
                      } else {
                        selectedEmployees.addAll(visibleIds);
                      }
                    }),
                    child: Text(allVisibleSelected ? 'Seçimleri Kaldır' : 'Tümünü Seç'),
                  ),
                ]),
                Container(
                  constraints: const BoxConstraints(maxHeight: 310),
                  decoration: BoxDecoration(border: Border.all(color: const Color(0xFFE2E7EA)), borderRadius: BorderRadius.circular(16)),
                  child: visible.isEmpty
                      ? const Padding(padding: EdgeInsets.all(20), child: Center(child: Text('Filtreye uygun aktif personel yok.')))
                      : ListView.separated(
                          shrinkWrap: true,
                          itemCount: visible.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (_, i) {
                            final e = visible[i];
                            final id = _id(e['id']);
                            return CheckboxListTile(
                              dense: true,
                              value: selectedEmployees.contains(id),
                              onChanged: (v) => setSheetState(() { if (v == true) { selectedEmployees.add(id); } else { selectedEmployees.remove(id); } }),
                              title: Text('${e['first_name'] ?? ''} ${e['last_name'] ?? ''}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5)),
                              subtitle: Text('${e['employee_no'] ?? ''} · ${e['business_unit_name'] ?? '-'} · ${e['department'] ?? '-'}', style: const TextStyle(fontSize: 10)),
                              controlAffinity: ListTileControlAffinity.leading,
                            );
                          },
                        ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: FilledButton.icon(
                    onPressed: sending
                        ? null
                        : () async {
                            final ok = await send();
                            if (ok && sheetContext.mounted) Navigator.pop(sheetContext);
                          },
                    icon: const Icon(Icons.send_rounded),
                    label: Text(sending ? 'Gönderiliyor...' : 'Bildirimi Gönder', style: const TextStyle(fontWeight: FontWeight.w900)),
                  ),
                ),
              ]),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Personel Bildirimleri'),
          actions: [IconButton(onPressed: load, icon: const Icon(Icons.refresh_rounded), tooltip: 'Yenile')],
        ),
        floatingActionButton: FloatingActionButton.extended(onPressed: loading ? null : openComposer, icon: const Icon(Icons.add_alert_rounded), label: const Text('Yeni Bildirim')),
        body: RefreshIndicator(
          onRefresh: load,
          child: loading
              ? ListView(children: const [SizedBox(height: 240), Center(child: CircularProgressIndicator())])
              : ListView(
                  padding: const EdgeInsets.fromLTRB(14, 14, 14, 100),
                  children: [
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(gradient: const LinearGradient(colors: [MTheme.ink, MTheme.ink2]), borderRadius: BorderRadius.circular(22), boxShadow: MTheme.softShadow),
                      child: const Row(children: [
                        Icon(Icons.campaign_rounded, color: MTheme.lime, size: 34),
                        SizedBox(width: 13),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text('Kurumsal İletişim Merkezi', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16)),
                          SizedBox(height: 4),
                          Text('Personellere toplu, firma, departman veya kişi bazlı bildirim gönderin.', style: TextStyle(color: Colors.white70, fontSize: 10.5, height: 1.35)),
                        ])),
                      ]),
                    ),
                    const SizedBox(height: 18),
                    const TechSectionHeader(title: 'Gönderim Geçmişi', subtitle: 'Son 100 kurumsal bildirim ve okunma durumu'),
                    const SizedBox(height: 9),
                    if (history.isEmpty)
                      const TechCard(child: Padding(padding: EdgeInsets.all(18), child: Center(child: Text('Henüz bildirim gönderilmedi.'))))
                    else
                      ...history.map((r) {
                        final total = _id(r['recipient_count']);
                        final read = _id(r['read_count']);
                        final pct = total == 0 ? 0.0 : read / total;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 9),
                          child: TechCard(
                            child: Padding(
                              padding: const EdgeInsets.all(4),
                              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  Container(width: 38, height: 38, decoration: BoxDecoration(color: MTheme.limeSoft, borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.notifications_active_outlined, color: MTheme.ink, size: 20)),
                                  const SizedBox(width: 11),
                                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                    Text('${r['title'] ?? ''}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13)),
                                    const SizedBox(height: 3),
                                    Text('${r['detail'] ?? ''}', maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 10.5, color: MTheme.muted, height: 1.35)),
                                  ])),
                                ]),
                                const SizedBox(height: 10),
                                Text('${r['target_business_unit_name'] ?? 'Tüm Firmalar'} · ${r['target_department'] ?? 'Tüm Departmanlar'}', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700)),
                                const SizedBox(height: 7),
                                LinearProgressIndicator(value: pct.clamp(0.0, 1.0).toDouble(), minHeight: 6, borderRadius: BorderRadius.circular(99)),
                                const SizedBox(height: 5),
                                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                                  Text('$read / $total okundu', style: const TextStyle(fontSize: 9.5, color: MTheme.muted)),
                                  Text('${r['created_at'] ?? ''}', style: const TextStyle(fontSize: 9.5, color: MTheme.muted)),
                                ]),
                              ]),
                            ),
                          ),
                        );
                      }),
                  ],
                ),
        ),
      );
}
