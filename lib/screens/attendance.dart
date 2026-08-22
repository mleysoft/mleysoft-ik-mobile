import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/app_state.dart';
import '../core/theme.dart';
import '../widgets/common.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key, required this.state});
  final AppState state;
  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  DateTime day = DateTime.now();
  List rows = [];
  List allRows = [];
  List missing = [];
  List businessUnits = [];
  int businessUnitId = 0;
  Map statuses = {};
  bool locked = false;
  bool busy = false;
  final search = TextEditingController();

  String get ds => DateFormat('yyyy-MM-dd').format(day);

  @override
  void initState() { super.initState(); loadDefinitions(); load(); checkMissing(); }
  @override
  void dispose() { search.dispose(); super.dispose(); }


  Future<void> loadDefinitions() async {
    try {
      final r = await widget.state.api.request('definitions');
      if (mounted) setState(() => businessUnits = (r['business_units'] ?? []) as List);
    } catch (_) {}
  }

  Future<void> load() async {
    setState(() => busy = true);
    try {
      final r = await widget.state.api.request('attendance/day', query: {'date': ds, 'business_unit_id': businessUnitId});
      final list = (r['employees'] ?? []) as List;
      if (mounted) {
        setState(() {
          allRows = List.from(list);
          statuses = Map.from(r['statuses'] ?? {});
          locked = r['locked'] == true;
        });
        _filterRows(search.text);
      }
    } catch (e) { if (mounted) snack(context, '$e', error: true); }
    finally { if (mounted) setState(() => busy = false); }
  }


  void _filterRows(String value) {
    final q = value.trim().toLowerCase();
    if (!mounted) return;
    setState(() {
      rows = q.isEmpty
          ? List.from(allRows)
          : allRows.where((x) {
              final haystack =
                  '${x['first_name'] ?? ''} ${x['last_name'] ?? ''} ${x['employee_no'] ?? ''} ${x['business_unit_name'] ?? ''}'.toLowerCase();
              return haystack.contains(q);
            }).toList();
    });
  }

  Future<void> checkMissing() async {
    final now = DateTime.now();
    final yesterday = now.subtract(const Duration(days: 1));
    if (yesterday.day < 1) return;
    try {
      final r = await widget.state.api.request('attendance/missing', query: {'from': DateFormat('yyyy-MM-01').format(now), 'to': DateFormat('yyyy-MM-dd').format(yesterday), 'business_unit_id': businessUnitId});
      if (mounted) setState(() => missing = (r['missing'] ?? []) as List);
    } catch (_) {}
  }

  Future<void> setStatus(dynamic employee, String value) async {
    if ('${employee['has_shift']}' != '1') { snack(context, 'Bu personelin vardiyası tanımlı değil. Lütfen önce vardiya tanımlayın.', error: true); return; }
    String? time;
    if (value == 'late_entry' || value == 'early_exit') {
      TimeOfDay initial = TimeOfDay.now();
      final existing = value == 'late_entry' ? '${employee['check_in_time'] ?? ''}' : '${employee['check_out_time'] ?? ''}';
      if (existing.length >= 5) {
        final parts = existing.substring(0, 5).split(':');
        final h = int.tryParse(parts[0]);
        final m = int.tryParse(parts[1]);
        if (h != null && m != null) initial = TimeOfDay(hour: h, minute: m);
      }

      final picked = await showTimePicker(
        context: context,
        initialTime: initial,
        helpText: value == 'late_entry' ? 'GEÇ GİRİŞ SAATİ' : 'ERKEN ÇIKIŞ SAATİ',
        hourLabelText: 'Saat',
        minuteLabelText: 'Dakika',
        cancelText: 'Vazgeç',
        confirmText: 'Saati Kaydet',
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: child!,
        ),
      );
      if (picked == null) return;
      time = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
    }

    try {
      final result = await widget.state.api.request('attendance/day', method: 'POST', data: {
        'date': ds,
        'employee_id': employee['id'],
        'status': value,
        if (time != null) 'time': time,
      });
      if (mounted) {
        final detail = value == 'late_entry'
            ? ' · Giriş $time${(result['late_minutes'] ?? 0) != 0 ? ' · ${result['late_minutes']} dk geç' : ''}'
            : value == 'early_exit'
                ? ' · Çıkış $time${(result['early_leave_minutes'] ?? 0) != 0 ? ' · ${result['early_leave_minutes']} dk erken' : ''}'
                : '';
        snack(context, '${employee['first_name']} ${employee['last_name']} için ${statuses[value]} kaydedildi$detail.');
      }
      await load();
    } catch (e) {
      if (mounted) snack(context, '$e', error: true);
    }
  }

  Future<void> bulk() async {
    String? value;
    await showDialog(context: context, builder: (c) => AlertDialog(
      title: const Text('Toplu Puantaj'),
      content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Yalnızca seçili tarihte puantajı yapılmamış personeller etkilenecek.', style: TextStyle(fontSize: 11, color: MTheme.muted)),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(items: statuses.entries.map<DropdownMenuItem<String>>((x) => DropdownMenuItem(value: '${x.key}', child: Text('${x.value}'))).toList(), onChanged: (x) => value = x, decoration: const InputDecoration(labelText: 'Uygulanacak işlem')),
      ]),
      actions: [TextButton(onPressed: () => Navigator.pop(c), child: const Text('Vazgeç')), FilledButton(onPressed: () async { if (value == null) return; try { final r = await widget.state.api.request('attendance/bulk', method: 'POST', data: {'date': ds, 'status': value, 'business_unit_id': businessUnitId}); if (c.mounted) Navigator.pop(c); if (mounted) snack(context, '${r['updated']} personelin puantajı işlendi.'); await load(); } catch (e) { if (mounted) snack(context, '$e', error: true); } }, child: const Text('Uygula'))],
    ));
  }

  Future<void> employeeDetail(dynamic employee) async {
    final r = await widget.state.api.request('employee', query: {'id': employee['id'], 'year': day.year, 'month': day.month});
    if (!mounted) return;
    final summary = Map<String, dynamic>.from(r['attendance_summary'] ?? {});
    showModalBottomSheet(context: context, isScrollControlled: true, useSafeArea: true, builder: (c) => DraggableScrollableSheet(expand: false, initialChildSize: .72, maxChildSize: .9, builder: (_, sc) => ListView(controller: sc, padding: const EdgeInsets.all(16), children: [
      Text('${employee['first_name']} ${employee['last_name']}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
      Text('${employee['employee_no']}', style: const TextStyle(color: MTheme.muted)),
      const SizedBox(height: 16),
      const Text('Aylık Puantaj Özeti', style: TextStyle(fontWeight: FontWeight.w800)),
      const SizedBox(height: 8),
      Wrap(spacing: 8, runSpacing: 8, children: [_tag('Geldi', summary['present']), _tag('Geç Giriş', summary['late_entry']), _tag('Erken Çıkış', summary['early_exit']), _tag('Gelmedi', summary['absent']), _tag('Hafta Tatili', summary['weekly_off']), _tag('Yıllık İzin', summary['annual_leave']), _tag('Ücretli İzin', summary['paid_leave']), _tag('Ücretsiz İzin', summary['unpaid_leave']), _tag('Raporlu', summary['sick'])]),
      const Divider(height: 28),
      ListTile(contentPadding: EdgeInsets.zero, leading: const Icon(Icons.payments_outlined), title: const Text('Güncel Maaş'), trailing: Text(r['salary'] == null ? 'Tanımlı değil' : money(r['salary']['salary_amount']), style: const TextStyle(fontWeight: FontWeight.w800))),
      const Text('Açık Avanslar', style: TextStyle(fontWeight: FontWeight.w800)),
      ...(r['open_advances'] as List).map((x) => ListTile(contentPadding: EdgeInsets.zero, title: Text('${x['advance_type'] == 'installment' ? 'Taksitli Avans' : 'Tek Avans'} · ${money(x['open_amount'])}'), subtitle: Text('${x['advance_date']}'))),
    ])));
  }

  Widget _tag(String label, dynamic value) => Chip(label: Text('$label: ${value ?? 0} gün'));

  @override
  Widget build(BuildContext context) => Column(children: [
    Padding(padding: const EdgeInsets.all(12), child: Column(children: [
      Row(children: [Expanded(child: OutlinedButton.icon(onPressed: () async { final x = await pickDate(context, day); if (x != null) { setState(() => day = x); load(); } }, icon: const Icon(Icons.calendar_month), label: Text(DateFormat('dd.MM.yyyy').format(day)))), const SizedBox(width: 8), FilledButton.icon(onPressed: locked ? null : bulk, icon: const Icon(Icons.done_all), label: const Text('Toplu İşlem'))]),
      const SizedBox(height: 8),
      DropdownButtonFormField<int>(
        value: businessUnitId,
        isExpanded: true,
        decoration: const InputDecoration(labelText: 'Firma'),
        items: [
          const DropdownMenuItem(value: 0, child: Text('Tüm Firmalar')),
          ...businessUnits.map((x) => DropdownMenuItem<int>(value: int.tryParse('${x['id']}') ?? 0, child: Text('${x['unit_no']} · ${x['name']}'))),
        ],
        onChanged: (v) { setState(() => businessUnitId = v ?? 0); load(); checkMissing(); },
      ),
      const SizedBox(height: 8),
      TextField(controller: search, onChanged: _filterRows, decoration: InputDecoration(prefixIcon: const Icon(Icons.search), hintText: 'Ad soyad veya personel no ara', suffixIcon: search.text.isEmpty ? null : IconButton(onPressed: () { search.clear(); _filterRows(''); }, icon: const Icon(Icons.close)))),
    ])),
    if (locked) const Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: Card(child: ListTile(leading: Icon(Icons.lock_outline), title: Text('Bu ayın dönem maaşı oluşturuldu. Puantaj kilitli.')))),
    if (missing.isNotEmpty)
      Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
        child: Card(
          color: const Color(0xFFFFF7E6),
          child: ListTile(
            leading: const Icon(Icons.warning_amber_rounded),
            title: Text('${missing.length} eksik puantaj kaydı var'),
            subtitle: Text('${missing.first['work_date']} tarihinden başlayan eksikler bulunuyor.'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => showModalBottomSheet(
              context: context,
              useSafeArea: true,
              isScrollControlled: true,
              builder: (c) => DraggableScrollableSheet(
                expand: false,
                initialChildSize: .7,
                maxChildSize: .9,
                builder: (_, sc) => ListView.builder(
                  controller: sc,
                  itemCount: missing.length,
                  itemBuilder: (_, i) {
                    final x = missing[i];
                    return ListTile(
                      title: Text('${x['first_name']} ${x['last_name']}'),
                      subtitle: Text('${x['work_date']}'),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    Expanded(child: busy && rows.isEmpty ? const Center(child: CircularProgressIndicator()) : RefreshIndicator(onRefresh: load, child: ListView.builder(itemCount: rows.length, itemBuilder: (_, i) {
      final e = rows[i];
      return Card(margin: const EdgeInsets.fromLTRB(12, 0, 12, 8), child: Padding(padding: const EdgeInsets.all(12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        InkWell(onTap: () => employeeDetail(e), child: Row(children: [Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('${e['first_name']} ${e['last_name']}', style: const TextStyle(fontWeight: FontWeight.w800)), Text('${e['employee_no']} · ${e['business_unit_name'] ?? '-'}', style: const TextStyle(fontSize: 11, color: MTheme.muted))])), const Icon(Icons.info_outline, size: 19)])),
        const SizedBox(height: 10),
        Wrap(spacing: 6, runSpacing: 6, children: statuses.entries.map((x) => ChoiceChip(label: Text('${x.value}', style: const TextStyle(fontSize: 11)), selected: e['status'] == x.key, onSelected: locked ? null : (_) => setStatus(e, '${x.key}'))).toList()),
      ])));
    }))),
  ]);
}
