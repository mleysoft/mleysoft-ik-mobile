import 'package:flutter/material.dart';
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
          const Text('Açık Avanslar', style: TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          ...(r['open_advances'] as List).map((v) => Card(child: ListTile(title: Text(money(v['open_amount'])), subtitle: Text('${v['advance_type'] == 'installment' ? 'Taksitli' : 'Tek Avans'} · ${v['payment_method'] == 'manual' ? 'Diğer ödeme' : 'Maaştan kesinti'}'), trailing: Text('${v['advance_date']}')))),
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
