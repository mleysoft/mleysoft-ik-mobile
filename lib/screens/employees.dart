import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/app_state.dart';
import '../core/theme.dart';
import '../widgets/common.dart';
import '../widgets/employee_form.dart';

class EmployeesScreen extends StatefulWidget {
  const EmployeesScreen({super.key, required this.state});
  final AppState state;
  @override
  State<EmployeesScreen> createState() => _EmployeesScreenState();
}

class _EmployeesScreenState extends State<EmployeesScreen> {
  final search = TextEditingController();
  List rows = [];
  List businessUnits = [];
  int businessUnitId = 0;
  String status = 'all';
  bool busy = false;
  int page = 1; bool hasMore = true; bool loadingMore = false;
  final ScrollController listController = ScrollController();

  @override
  void initState() { super.initState(); listController.addListener(() { if (listController.position.pixels > listController.position.maxScrollExtent - 260 && hasMore && !busy && !loadingMore) load(more:true); }); loadDefinitions(); load(); }
  @override
  void dispose() { search.dispose(); listController.dispose(); super.dispose(); }


  Future<void> loadDefinitions() async {
    try {
      final r = await widget.state.api.request('definitions');
      if (mounted) setState(() => businessUnits = (r['business_units'] ?? []) as List);
    } catch (_) {}
  }

  Future<void> load({bool more=false}) async {
    if (more) { if (!hasMore || loadingMore) return; setState(() => loadingMore=true); } else { page=1; hasMore=true; setState(() => busy=true); }
    try {
      final targetPage = more ? page + 1 : 1;
      final r = await widget.state.api.request('employees', query: {'search': search.text.trim(), 'status': status, 'business_unit_id': businessUnitId, 'page': targetPage, 'per_page': 20});
      final incoming=(r['employees'] ?? []) as List;
      if (mounted) setState(() { if(more){rows.addAll(incoming);page=targetPage;}else{rows=incoming;page=1;} hasMore=r['has_more']==true; });
    } catch (e) { if (mounted) snack(context, '$e', error: true); }
    finally { if (mounted) setState(() { busy=false; loadingMore=false; }); }
  }

  Future<void> openForm([dynamic row]) async {
    Map<String, dynamic>? employee;
    if (row != null) {
      final r = await widget.state.api.request('employee', query: {'id': row['id']});
      employee = Map<String, dynamic>.from(r['employee']);
    }
    if (!mounted) return;
    final changed = await EmployeeFormSheet.open(context, widget.state, employee: employee);
    if (changed == true) load();
  }


  Future<bool> _newAdvance(BuildContext parentContext, Map<String, dynamic> employee) async {
    final amount = TextEditingController();
    DateTime advanceDate = DateTime.now();
    String type = 'single';
    String method = 'salary';
    String strategy = 'parallel';
    int count = 2;
    int startYear = DateTime.now().year;
    int startMonth = DateTime.now().month;
    bool saved = false;

    await showModalBottomSheet(
      context: parentContext,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (c) => StatefulBuilder(
        builder: (c, setM) => Padding(
          padding: EdgeInsets.only(left: 16, right: 16, top: 6, bottom: MediaQuery.viewInsetsOf(c).bottom + 16),
          child: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const TechSectionHeader(title: 'Yeni Avans Ekle', subtitle: 'Personel detayından hızlı avans kaydı'),
              const SizedBox(height: 12),
              TechCard(
                child: Row(children: [
                  CircleAvatar(backgroundColor: MTheme.ink, foregroundColor: MTheme.lime, child: Text('${employee['first_name']}'.isEmpty ? '?' : '${employee['first_name']}'[0])),
                  const SizedBox(width: 10),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('${employee['first_name']} ${employee['last_name']}', style: const TextStyle(fontWeight: FontWeight.w800)),
                    Text('${employee['employee_no'] ?? ''}', style: const TextStyle(fontSize: 10.5, color: MTheme.muted)),
                  ])),
                ]),
              ),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: InkWell(
                  onTap: () async { final d = await pickDate(c, advanceDate); if (d != null) setM(() => advanceDate = d); },
                  child: InputDecorator(decoration: const InputDecoration(labelText: 'Avans Tarihi', suffixIcon: Icon(Icons.calendar_month_outlined)), child: Text(DateFormat('dd.MM.yyyy').format(advanceDate))),
                )),
                const SizedBox(width: 8),
                Expanded(child: TextField(controller: amount, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Avans Tutarı'))),
              ]),
              const SizedBox(height: 10),
              Row(children: [
                Expanded(child: DropdownButtonFormField<String>(
                  value: type,
                  decoration: const InputDecoration(labelText: 'Avans Türü'),
                  items: const [DropdownMenuItem(value: 'single', child: Text('Tek Avans')), DropdownMenuItem(value: 'installment', child: Text('Taksitli Avans'))],
                  onChanged: (v) => setM(() => type = v ?? 'single'),
                )),
                const SizedBox(width: 8),
                Expanded(child: DropdownButtonFormField<String>(
                  value: method,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Ödeme Yöntemi'),
                  items: const [DropdownMenuItem(value: 'salary', child: Text('Maaştan Kesilecek', overflow: TextOverflow.ellipsis)), DropdownMenuItem(value: 'manual', child: Text('Diğer Ödeme'))],
                  onChanged: (v) => setM(() => method = v ?? 'salary'),
                )),
              ]),
              if (type == 'installment') ...[
                const SizedBox(height: 10),
                TextFormField(initialValue: '$count', keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Taksit Sayısı'), onChanged: (v) => count = (int.tryParse(v) ?? 2).clamp(2, 120).toInt()),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: strategy,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Mevcut Taksit Varsa'),
                  items: const [
                    DropdownMenuItem(value: 'parallel', child: Text('Mevcut aylık taksite ekle')),
                    DropdownMenuItem(value: 'after_existing', child: Text('Önceki borç bittikten sonra başlat')),
                  ],
                  onChanged: (v) => setM(() => strategy = v ?? 'parallel'),
                ),
              ],
              const SizedBox(height: 10),
              InkWell(
                onTap: () async {
                  int y = startYear, m = startMonth;
                  await showDialog(
                    context: c,
                    builder: (d) => StatefulBuilder(
                      builder: (d, setD) => AlertDialog(
                        title: const Text('Kesinti Başlangıç Dönemi'),
                        content: Row(children: [
                          Expanded(child: DropdownButtonFormField<int>(
                            value: m,
                            decoration: const InputDecoration(labelText: 'Ay'),
                            items: List.generate(12, (i) => DropdownMenuItem(value: i + 1, child: Text('${i + 1}'.padLeft(2, '0')))),
                            onChanged: (v) => setD(() => m = v ?? m),
                          )),
                          const SizedBox(width: 8),
                          Expanded(child: DropdownButtonFormField<int>(
                            value: y,
                            decoration: const InputDecoration(labelText: 'Yıl'),
                            items: List.generate(8, (i) => DropdownMenuItem(value: DateTime.now().year + i, child: Text('${DateTime.now().year + i}'))),
                            onChanged: (v) => setD(() => y = v ?? y),
                          )),
                        ]),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(d), child: const Text('Vazgeç')),
                          FilledButton(onPressed: () { setM(() { startYear = y; startMonth = m; }); Navigator.pop(d); }, child: const Text('Seç')),
                        ],
                      ),
                    ),
                  );
                },
                child: InputDecorator(
                  decoration: const InputDecoration(labelText: 'Kesinti Başlangıç Dönemi', suffixIcon: Icon(Icons.date_range_outlined)),
                  child: Text('${startMonth.toString().padLeft(2, '0')}.$startYear'),
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () async {
                    if ((double.tryParse(amount.text.replaceAll(',', '.')) ?? 0) <= 0) {
                      snack(parentContext, 'Geçerli bir avans tutarı girin.', error: true);
                      return;
                    }
                    try {
                      await widget.state.api.request('advance', method: 'POST', data: {
                        'employee_id': employee['id'],
                        'advance_date': DateFormat('yyyy-MM-dd').format(advanceDate),
                        'amount': amount.text.replaceAll(',', '.'),
                        'advance_type': type,
                        'installment_count': type == 'installment' ? count : 1,
                        'payment_method': method,
                        'payment_start_year': startYear,
                        'payment_start_month': startMonth,
                        'installment_strategy': strategy,
                      });
                      saved = true;
                      if (c.mounted) Navigator.pop(c);
                      if (mounted) snack(context, 'Avans kaydı oluşturuldu.');
                    } catch (e) {
                      if (mounted) snack(context, '$e', error: true);
                    }
                  },
                  icon: const Icon(Icons.save_outlined),
                  label: const Text('Avansı Kaydet'),
                ),
              ),
            ]),
          ),
        ),
      ),
    );
    amount.dispose();
    return saved;
  }

  Future<void> detail(dynamic row) async {
    final r = await widget.state.api.request('employee', query: {'id': row['id'], 'year': DateTime.now().year, 'month': DateTime.now().month});
    if (!mounted) return;
    final e = Map<String, dynamic>.from(r['employee']);
    final a = Map<String, dynamic>.from(r['attendance_summary']);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (c) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: .84,
        maxChildSize: .96,
        builder: (_, sc) => ListView(controller: sc, padding: const EdgeInsets.all(18), children: [
          Row(children: [CircleAvatar(radius: 24, backgroundColor: MTheme.ink, foregroundColor: MTheme.lime, child: Text('${e['first_name']}'.isEmpty ? '?' : '${e['first_name']}'[0])), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('${e['first_name']} ${e['last_name']}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)), Text('${e['employee_no']} · ${e['business_unit_name'] ?? '-'} · ${e['department'] ?? '-'} / ${e['position'] ?? '-'}', style: const TextStyle(color: MTheme.muted))])), IconButton(onPressed: () async { Navigator.pop(c); await openForm(e); }, icon: const Icon(Icons.edit_outlined))]),
          const SizedBox(height: 18),
          const Text('Bu Ay Puantaj Özeti', style: TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Wrap(spacing: 8, runSpacing: 8, children: [
            _chip('Geldi', a['present']), _chip('Gelmedi', a['absent']), _chip('Hafta Tatili', a['weekly_off']), _chip('Yıllık İzin', a['annual_leave']), _chip('Ücretli İzin', a['paid_leave']), _chip('Ücretsiz İzin', a['unpaid_leave']), _chip('Raporlu', a['sick']),
          ]),
          const Divider(height: 30),
          ListTile(contentPadding: EdgeInsets.zero, leading: const Icon(Icons.payments_outlined), title: const Text('Güncel Maaş'), trailing: Text(r['salary'] == null ? 'Tanımlı değil' : money(r['salary']['salary_amount']), style: const TextStyle(fontWeight: FontWeight.w800))),
          const SizedBox(height: 8),
          Row(children: [
            const Expanded(child: Text('Açık Avanslar', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16))),
            FilledButton.tonalIcon(
              onPressed: () async {
                final saved = await _newAdvance(context, e);
                if (saved && c.mounted) {
                  Navigator.pop(c);
                  await detail(row);
                }
              },
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Yeni Avans'),
            ),
          ]),
          const SizedBox(height: 8),
          ...(r['open_advances'] as List).map((v) => TechCard(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(width: 40,height:40,decoration:BoxDecoration(color:MTheme.limeSoft,borderRadius:BorderRadius.circular(12)),child:const Icon(Icons.account_balance_wallet_outlined,color:MTheme.ink)),
              title: Text(money(v['open_amount']), style: const TextStyle(fontWeight: FontWeight.w900)),
              subtitle: Text('${v['advance_type'] == 'installment' ? 'Taksitli' : 'Tek Avans'} · ${v['payment_method'] == 'manual' ? 'Diğer ödeme' : 'Maaştan kesinti'}'),
              trailing: Text('${v['advance_date']}', style: const TextStyle(fontSize: 10, color: MTheme.muted)),
            ),
          )),
        ]),
      ),
    );
  }

  Widget _chip(String label, dynamic value) => Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8), decoration: BoxDecoration(color: Colors.white, border: Border.all(color: const Color(0xFFE0E5E8)), borderRadius: BorderRadius.circular(10)), child: Text('$label: ${value ?? 0}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700)));

  @override
  Widget build(BuildContext context) => Column(children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Column(children: [
            Row(children: [Expanded(child: TextField(controller: search, onChanged: (_) => load(), decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Ad soyad / personel no ara'))), const SizedBox(width: 8), FilledButton.icon(onPressed: () => openForm(), icon: const Icon(Icons.person_add_alt_1), label: const Text('Yeni'))]),
            const SizedBox(height: 8),
            DropdownButtonFormField<int>(
              value: businessUnitId,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Firma'),
              items: [
                const DropdownMenuItem(value: 0, child: Text('Tüm Firmalar')),
                ...businessUnits.map((x) => DropdownMenuItem<int>(value: int.tryParse('${x['id']}') ?? 0, child: Text('${x['unit_no']} · ${x['name']}'))),
              ],
              onChanged: (v) { setState(() => businessUnitId = v ?? 0); load(); },
            ),
            const SizedBox(height: 8),
            SegmentedButton<String>(segments: const [ButtonSegment(value: 'all', label: Text('Tümü')), ButtonSegment(value: 'active', label: Text('Aktif')), ButtonSegment(value: 'passive', label: Text('Pasif'))], selected: {status}, onSelectionChanged: (x) { status = x.first; load(); }),
          ]),
        ),
        Expanded(
          child: busy && rows.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: load,
                  child: ListView.builder(
                    controller: listController,
                    itemCount: rows.length + (loadingMore ? 1 : 0),
                    itemBuilder: (_, i) {
                      if(i>=rows.length)return const Padding(padding: EdgeInsets.all(18),child:Center(child:CircularProgressIndicator()));
                      final x = rows[i];
                      return Card(
                        margin: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                        child: ListTile(
                          onTap: () => detail(x),
                          leading: CircleAvatar(child: Text('${x['first_name']}'.isEmpty ? '?' : '${x['first_name']}'[0])),
                          title: Text('${x['first_name']} ${x['last_name']}', style: const TextStyle(fontWeight: FontWeight.w700)),
                          subtitle: Text('${x['employee_no']} · ${x['business_unit_name'] ?? '-'}\n${x['department'] ?? '-'} · ${x['position'] ?? '-'}${x['end_date'] != null ? '\nİşten ayrılma: ${x['end_date']}' : ''}'),
                          isThreeLine: true,
                          trailing: Switch(
                            value: x['status'] == 'active',
                            onChanged: (v) async {
                              try {
                                await widget.state.api.request('employee/status', method: 'POST', data: {'id': x['id'], 'status': v ? 'active' : 'passive'});
                                load();
                              } catch (e) {
                                if (mounted) snack(context, '$e', error: true);
                              }
                            },
                          ),
                        ),
                      );
                    },
                  ),
                ),
        ),
      ]);
}
