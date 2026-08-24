import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/app_state.dart';
import '../core/leave_pdf.dart';
import '../core/theme.dart';
import '../widgets/common.dart';
import '../widgets/employee_picker.dart';

class LeavesScreen extends StatefulWidget {
  const LeavesScreen({super.key, required this.state});
  final AppState state;
  @override
  State<LeavesScreen> createState() => _LeavesScreenState();
}

class _LeavesScreenState extends State<LeavesScreen> {
  int year = DateTime.now().year;
  final search = TextEditingController();
  List people = [];
  bool busy = false;
  int page=1; bool hasMore=true; bool loadingMore=false; final ScrollController listController=ScrollController();

  @override
  void initState() { super.initState(); listController.addListener((){if(listController.position.pixels>listController.position.maxScrollExtent-240&&hasMore&&!loadingMore)load(more:true);}); load(); }
  @override
  void dispose() { search.dispose(); super.dispose(); }

  Future<void> load({bool more=false}) async {
    if(more){if(!hasMore||loadingMore)return;setState(()=>loadingMore=true);}else{page=1;hasMore=true;setState(()=>busy=true);}
    try {
      final r = await widget.state.api.request('leaves/people', query: {'year': year, 'search': search.text, 'page': more?page+1:1, 'per_page':20});
      final incoming=(r['people'] ?? []) as List; if(mounted)setState((){if(more){people.addAll(incoming);page++;}else{people=incoming;page=1;}hasMore=r['has_more']==true;});
    } catch (e) {
      if (mounted) snack(context, '$e', error: true);
    } finally {
      if (mounted) setState(() {busy=false;loadingMore=false;});
    }
  }

  Future<void> addLeave({dynamic employee, Map<String, dynamic>? edit}) async {
    final er = await widget.state.api.request('employees', query:{'page':1,'per_page':100});
    final emps = er['employees'] as List;
    int? eid = employee == null ? null : int.tryParse('${employee['id']}');
    String type = '${edit?['leave_type'] ?? 'annual'}';
    DateTime start = DateTime.tryParse('${edit?['start_date'] ?? ''}') ?? DateTime.now();
    DateTime end = DateTime.tryParse('${edit?['end_date'] ?? ''}') ?? start;
    final description = TextEditingController(text: '${edit?['description'] ?? ''}');
    if (!mounted) return;
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (c) => StatefulBuilder(builder: (c, setM) => Padding(
            padding: EdgeInsets.only(left: 16, right: 16, top: 16, bottom: MediaQuery.viewInsetsOf(c).bottom + 18),
            child: SingleChildScrollView(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Row(children: [Expanded(child: Text(edit == null ? 'Yeni İzin Kaydı' : 'İzin Kaydını Düzenle', style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800))), IconButton(onPressed: () => Navigator.pop(c), icon: const Icon(Icons.close))]),
                const SizedBox(height: 10),
                InkWell(
                  onTap: edit == null
                      ? () async {
                          final value = await showEmployeePicker(c, emps, selectedId: eid, title: 'İzin İçin Personel Seç');
                          if (value != null) setM(() => eid = value);
                        }
                      : null,
                  borderRadius: BorderRadius.circular(12),
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Personel',
                      suffixIcon: Icon(Icons.search),
                    ),
                    child: Text(
                      eid == null
                          ? 'Ad soyad veya personel no ara'
                          : (() {
                              final e = emps.firstWhere((x) => int.parse('${x['id']}') == eid);
                              return '${e['first_name']} ${e['last_name']}';
                            })(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: type,
                  decoration: const InputDecoration(labelText: 'İzin Türü'),
                  items: const [DropdownMenuItem(value: 'annual', child: Text('Yıllık İzin')), DropdownMenuItem(value: 'paid', child: Text('Ücretli İzin')), DropdownMenuItem(value: 'unpaid', child: Text('Ücretsiz İzin')), DropdownMenuItem(value: 'sick', child: Text('Raporlu'))],
                  onChanged: (v) => setM(() => type = v ?? 'annual'),
                ),
                const SizedBox(height: 10),
                Row(children: [
                  Expanded(child: _dateBox(c, 'Başlangıç', start, () async { final d = await pickDate(c, start); if (d != null) setM(() { start = d; if (end.isBefore(start)) end = start; }); })),
                  const SizedBox(width: 8),
                  Expanded(child: _dateBox(c, 'Bitiş', end, () async { final d = await pickDate(c, end); if (d != null) setM(() => end = d); })),
                ]),
                if (type == 'annual') const Padding(padding: EdgeInsets.only(top: 8), child: Align(alignment: Alignment.centerLeft, child: Text('Tanımlı hafta tatilleri yıllık izin gününden düşülmez.', style: TextStyle(fontSize: 11, color: MTheme.muted)))),
                const SizedBox(height: 10),
                TextField(controller: description, maxLines: 3, decoration: const InputDecoration(labelText: 'Açıklama')),
                const SizedBox(height: 14),
                SizedBox(width: double.infinity, child: FilledButton(onPressed: () async {
                  if (eid == null) { snack(context, 'Personel seçin.', error: true); return; }
                  dynamic selectedEmployee;
                  for (final x in emps) {
                    if (int.tryParse('${x['id']}') == eid) { selectedEmployee = x; break; }
                  }
                  if (selectedEmployee != null) {
                    final employmentStart = DateTime.tryParse('${selectedEmployee['start_date'] ?? ''}');
                    final employmentEnd = DateTime.tryParse('${selectedEmployee['end_date'] ?? ''}');
                    final dStart = DateTime(start.year, start.month, start.day);
                    final dEnd = DateTime(end.year, end.month, end.day);
                    if (employmentStart != null && dStart.isBefore(DateTime(employmentStart.year, employmentStart.month, employmentStart.day))) {
                      snack(context, 'İzin başlangıcı personelin işe başlama tarihinden önce olamaz.', error: true); return;
                    }
                    if (employmentEnd != null && dEnd.isAfter(DateTime(employmentEnd.year, employmentEnd.month, employmentEnd.day))) {
                      snack(context, 'İzin bitişi personelin işten ayrılma tarihinden sonra olamaz.', error: true); return;
                    }
                  }
                  try {
                    final data = {'id': edit?['id'], 'employee_id': eid, 'leave_type': type, 'start_date': DateFormat('yyyy-MM-dd').format(start), 'end_date': DateFormat('yyyy-MM-dd').format(end), 'description': description.text.trim()};
                    await widget.state.api.request('leave', method: edit == null ? 'POST' : 'PUT', data: data, query: edit == null ? null : {'id': edit!['id']});
                    if (c.mounted) Navigator.pop(c);
                    await load();
                  } catch (e) { if (mounted) snack(context, '$e', error: true); }
                }, child: Text(edit == null ? 'İzni Kaydet' : 'Değişiklikleri Kaydet'))),
              ]),
            ),
          )),
    );
  }

  Widget _dateBox(BuildContext context, String label, DateTime date, VoidCallback onTap) => InkWell(onTap: onTap, child: InputDecorator(decoration: InputDecoration(labelText: label, suffixIcon: const Icon(Icons.calendar_month_outlined)), child: Text(DateFormat('dd.MM.yyyy').format(date))));

  Future<void> editOpening(dynamic person) async {
    final controller = TextEditingController(text: '${person['opening_days'] ?? 0}');
    await showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(person['opening_set'] == true ? 'Başlangıç Bakiyesini Düzenle' : 'İlk Yıllık İzin Bakiyesi'),
        content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('${person['first_name']} ${person['last_name']}'),
          const SizedBox(height: 12),
          TextField(controller: controller, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Mevcut yıllık izin bakiyesi (gün)')),
          const SizedBox(height: 10),
          const Text('İlk yıllık izin kaydı oluşana kadar başlangıç bakiyesi değiştirilebilir. Yıllık izin hareketi oluştuğunda kilitlenir.', style: TextStyle(fontSize: 11, color: MTheme.muted)),
        ]),
        actions: [TextButton(onPressed: () => Navigator.pop(c), child: const Text('Vazgeç')), FilledButton(onPressed: () async {
          try {
            await widget.state.api.request('leave/opening', method: 'POST', data: {'employee_id': person['id'], 'opening_days': controller.text, 'tracking_start': person['tracking_start'] ?? DateFormat('yyyy-MM-dd').format(DateTime.now())});
            if (c.mounted) Navigator.pop(c);
            await load();
          } catch (e) { if (mounted) snack(context, '$e', error: true); }
        }, child: const Text('Kaydet'))],
      ),
    );
  }

  Future<void> detail(dynamic person) async {
    DateTime from = DateTime(year, 1, 1), to = DateTime(year, 12, 31);
    List movements = [];
    bool movementsLoaded = false;
    Future<void> getMovements(StateSetter setSheet) async {
      final r = await widget.state.api.request('leaves', query: {'employee_id': person['id'], 'from': DateFormat('yyyy-MM-dd').format(from), 'to': DateFormat('yyyy-MM-dd').format(to)});
      setSheet(() { movements = (r['leaves'] ?? []) as List; movementsLoaded = true; });
    }
    if (!mounted) return;
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (c) => DefaultTabController(
        length: 2,
        child: StatefulBuilder(builder: (c, setSheet) {
          if (!movementsLoaded) WidgetsBinding.instance.addPostFrameCallback((_) { if (c.mounted && !movementsLoaded) getMovements(setSheet); });
          final usage = Map<String, dynamic>.from(person['year_usage'] ?? {});
          return DraggableScrollableSheet(
            expand: false,
            initialChildSize: .9,
            maxChildSize: .97,
            builder: (_, sc) => Column(children: [
              Padding(padding: const EdgeInsets.fromLTRB(16, 12, 8, 6), child: Row(children: [Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('${person['first_name']} ${person['last_name']}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)), Text('${person['employee_no']} · İşe giriş: ${person['start_date'] ?? '-'}', style: const TextStyle(fontSize: 11, color: MTheme.muted))])), IconButton(onPressed: () => Navigator.pop(c), icon: const Icon(Icons.close))])),
              const TabBar(tabs: [Tab(text: 'Özet'), Tab(text: 'İzin Hareketleri')]),
              Expanded(child: TabBarView(children: [
                ListView(controller: sc, padding: const EdgeInsets.all(16), children: [
                  GridView.count(crossAxisCount: 2, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), childAspectRatio: 1.75, crossAxisSpacing: 8, mainAxisSpacing: 8, children: [
                    _summaryCard('Toplam Hakediş', '${person['entitled'] ?? 0} gün'),
                    _summaryCard('Kullanılan Yıllık', '${person['used_annual_total'] ?? 0} gün'),
                    _summaryCard('Kalan Yıllık İzin', '${person['remaining'] ?? 0} gün', accent: true),
                    _summaryCard('Yeni Hakediş', person['next_days'] == null ? '-' : '${person['next_days']} gün kaldı'),
                  ]),
                  const SizedBox(height: 16),
                  Row(children: [Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('Başlangıç Yıllık İzin Bakiyesi', style: TextStyle(fontWeight: FontWeight.w800)), Text('${person['opening_days'] ?? 0} gün · Takip başlangıcı: ${person['tracking_start'] ?? '-'}', style: const TextStyle(fontSize: 11, color: MTheme.muted))])), if (person['opening_locked'] != true) OutlinedButton.icon(onPressed: () async { Navigator.pop(c); await editOpening(person); }, icon: const Icon(Icons.edit_outlined), label: Text(person['opening_set'] == true ? 'Düzenle' : 'İlk Bakiye')) else const Chip(avatar: Icon(Icons.lock_outline, size: 16), label: Text('Kilitli'))]),
                  const Divider(height: 28),
                  Text('$year İzin Özeti', style: const TextStyle(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 8),
                  Wrap(spacing: 8, runSpacing: 8, children: [_usage('Yıllık İzin', usage['annual']), _usage('Ücretli İzin', usage['paid']), _usage('Ücretsiz İzin', usage['unpaid']), _usage('Raporlu', usage['sick'])]),
                ]),
                Column(children: [
                  Padding(padding: const EdgeInsets.all(12), child: Row(children: [Expanded(child: _dateBox(c, 'Başlangıç', from, () async { final d = await pickDate(c, from); if (d != null) { from = d; await getMovements(setSheet); } })), const SizedBox(width: 8), Expanded(child: _dateBox(c, 'Bitiş', to, () async { final d = await pickDate(c, to); if (d != null) { to = d; await getMovements(setSheet); } }))])),
                  Expanded(child: movements.isEmpty ? const Center(child: Text('Seçilen tarih aralığında izin hareketi yok.')) : ListView.builder(itemCount: movements.length, itemBuilder: (_, i) {
                    final x = movements[i];
                    final manual = x['source'] == 'manual';
                    final annual = x['leave_type'] == 'annual';
                    return Card(margin: const EdgeInsets.fromLTRB(12, 0, 12, 8), child: ListTile(
                      title: Text('${_leaveLabel(x['leave_type'])} · ${_dayText(x['day_count'])} gün', style: const TextStyle(fontWeight: FontWeight.w700)),
                      subtitle: Text('${x['start_date']} - ${x['end_date']}\nKaynak: ${manual ? 'İzin Takibi' : 'Günlük Puantaj'}'),
                      isThreeLine: true,
                      trailing: PopupMenuButton<String>(
                        onSelected: (v) async {
                          if (v == 'print') await LeavePdf.printLeave(leave: Map<String, dynamic>.from(x), employee: Map<String, dynamic>.from(person), companyName: '${widget.state.company?['company_name'] ?? 'MleySoft'}');
                          if (v == 'share') await LeavePdf.shareLeave(leave: Map<String, dynamic>.from(x), employee: Map<String, dynamic>.from(person), companyName: '${widget.state.company?['company_name'] ?? 'MleySoft'}');
                          if (v == 'edit') { Navigator.pop(c); await addLeave(employee: person, edit: Map<String, dynamic>.from(x)); }
                          if (v == 'delete') { try { await widget.state.api.request('leave', method: 'DELETE', data: {'id': x['id']}, query: {'id': x['id']}); await getMovements(setSheet); await load(); } catch (e) { if (mounted) snack(context, '$e', error: true); } }
                        },
                        itemBuilder: (_) => [if (annual) const PopupMenuItem(value: 'print', child: Text('Yazdır')), if (annual) const PopupMenuItem(value: 'share', child: Text('PDF Paylaş')), if (manual) const PopupMenuItem(value: 'edit', child: Text('Düzenle')), if (manual) const PopupMenuItem(value: 'delete', child: Text('Sil'))],
                      ),
                    ));
                  })),
                ]),
              ])),
            ]),
          );
        }),
      ),
    );
  }

  String _leaveLabel(dynamic v) => {'annual': 'Yıllık İzin', 'paid': 'Ücretli İzin', 'unpaid': 'Ücretsiz İzin', 'sick': 'Raporlu'}['$v'] ?? '$v';
  String _dayText(dynamic v) { final n = double.tryParse('$v') ?? 0; return n == n.roundToDouble() ? '${n.toInt()}' : n.toStringAsFixed(1).replaceAll('.', ','); }
  Widget _summaryCard(String title, String value, {bool accent = false}) => Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: accent ? MTheme.ink : Colors.white, border: Border.all(color: const Color(0xFFE1E6E9)), borderRadius: BorderRadius.circular(13)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [Text(title, style: TextStyle(fontSize: 10, color: accent ? Colors.white60 : MTheme.muted)), const SizedBox(height: 4), Text(value, style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: accent ? MTheme.lime : MTheme.ink))]));
  Widget _usage(String title, dynamic value) => Chip(label: Text('$title: ${_dayText(value)} gün'));

  @override
  Widget build(BuildContext context) => Column(children: [
        Padding(padding: const EdgeInsets.all(12), child: Column(children: [
          Row(children: [SizedBox(width: 110, child: TextField(keyboardType: TextInputType.number, controller: TextEditingController(text: '$year'), decoration: const InputDecoration(labelText: 'Yıl'), onSubmitted: (v) { year = int.tryParse(v) ?? year; load(); })), const SizedBox(width: 8), Expanded(child: TextField(controller: search, onSubmitted: (_) => load(), decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Personel ara'))), const SizedBox(width: 8), IconButton.filled(onPressed: load, icon: const Icon(Icons.filter_alt_outlined))]),
          const SizedBox(height: 8),
          SizedBox(width: double.infinity, child: FilledButton.icon(onPressed: () => addLeave(), icon: const Icon(Icons.add), label: const Text('Yeni İzin Kaydı'))),
        ])),
        Expanded(child: busy && people.isEmpty ? const Center(child: CircularProgressIndicator()) : RefreshIndicator(onRefresh: load, child: ListView.builder(controller:listController,itemCount: people.length+(loadingMore?1:0), itemBuilder: (_, i) {
          if(i>=people.length)return const Padding(padding:EdgeInsets.all(18),child:Center(child:CircularProgressIndicator()));
          final p = people[i];
          return Card(margin: const EdgeInsets.fromLTRB(12, 0, 12, 8), child: ListTile(onTap: () => detail(p), leading: CircleAvatar(child: Text('${p['first_name']}'.isEmpty ? '?' : '${p['first_name']}'[0])), title: Text('${p['first_name']} ${p['last_name']}', style: const TextStyle(fontWeight: FontWeight.w700)), subtitle: Text('${p['employee_no']} · Yeni hakedişe ${p['next_days'] ?? '-'} gün'), trailing: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Text(_dayText(p['remaining']), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)), const Text('kalan gün', style: TextStyle(fontSize: 9))])));
        }))),
      ]);
}
