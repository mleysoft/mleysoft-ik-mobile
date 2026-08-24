import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/app_state.dart';
import '../core/theme.dart';
import '../widgets/common.dart';
import '../widgets/employee_picker.dart';
import '../core/payroll_pdf.dart';

class SalariesScreen extends StatefulWidget {
  const SalariesScreen({super.key, required this.state});
  final AppState state;
  @override
  State<SalariesScreen> createState() => _SalariesScreenState();
}

class _SalariesScreenState extends State<SalariesScreen> {
  List salaries = [], advances = [], periods = [];
  int tab = 0;
  bool busy = false;
  int page=1; bool hasMore=true; bool loadingMore=false; final ScrollController listController=ScrollController();

  @override
  void initState() { super.initState(); listController.addListener((){if(listController.position.pixels>listController.position.maxScrollExtent-240&&hasMore&&!loadingMore)load(more:true);}); load(); }

  Future<void> load({bool more=false}) async {
    if(more){if(!hasMore||loadingMore)return;setState(()=>loadingMore=true);}else{page=1;hasMore=true;setState(()=>busy=true);}
    try {
      final target=more?page+1:1;
      final rs = await Future.wait([
        widget.state.api.request('salaries',query:{'page':target}),
        widget.state.api.request('advances',query:{'page':target}),
        widget.state.api.request('payroll/periods',query:{'page':target}),
      ]);
      if (mounted) setState(() {
        final s=(rs[0]['salaries']??[]) as List,a=(rs[1]['advances']??[]) as List,p=(rs[2]['periods']??[]) as List;
        if(more){salaries.addAll(s);advances.addAll(a);periods.addAll(p);page=target;}else{salaries=s;advances=a;periods=p;page=1;}
        hasMore=(rs[tab]['has_more']==true);
      });
    } catch (e) { if (mounted) snack(context, '$e', error: true); }
    finally { if (mounted) setState(() {busy=false;loadingMore=false;}); }
  }

  Future<List> employees() async => (await widget.state.api.request('employees', query:{'page':1,'per_page':100}))['employees'] as List;

  Future<List> availableSalaryEmployees(DateTime start, DateTime end, {int excludeSalaryId = 0}) async {
    final r = await widget.state.api.request('salary/available-employees', query: {
      'start_date': DateFormat('yyyy-MM-dd').format(start),
      'end_date': DateFormat('yyyy-MM-dd').format(end),
      'exclude_salary_id': excludeSalaryId,
    });
    return (r['employees'] ?? []) as List;
  }

  Future<void> salaryForm({Map<String, dynamic>? edit}) async {
    int? eid = edit == null ? null : int.tryParse('${edit['employee_id']}');
    final amount = TextEditingController(text: '${edit?['salary_amount'] ?? ''}');
    DateTime start = DateTime.tryParse('${edit?['start_date'] ?? ''}') ?? DateTime(DateTime.now().year, 1, 1);
    DateTime end = DateTime.tryParse('${edit?['end_date'] ?? ''}') ?? DateTime(DateTime.now().year, 12, 31);
    List es = await availableSalaryEmployees(start, end, excludeSalaryId: int.tryParse('${edit?['id'] ?? 0}') ?? 0);
    if (!mounted) return;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (c) => StatefulBuilder(builder: (c, setM) {
        Future<void> refreshEmployees() async {
          try {
            final rows = await availableSalaryEmployees(start, end, excludeSalaryId: int.tryParse('${edit?['id'] ?? 0}') ?? 0);
            if (!c.mounted) return;
            setM(() {
              es = rows;
              if (eid != null && !es.any((x) => int.tryParse('${x['id']}') == eid)) eid = null;
            });
          } catch (e) {
            if (mounted) snack(context, '$e', error: true);
          }
        }

        String selectedName() {
          if (eid == null) return 'Personel ara ve seç';
          final matches = es.where((x) => int.tryParse('${x['id']}') == eid).toList();
          if (matches.isEmpty && edit != null) return '${edit['first_name']} ${edit['last_name']}';
          if (matches.isEmpty) return 'Personel ara ve seç';
          final x = matches.first;
          return '${x['first_name']} ${x['last_name']} · ${x['business_unit_name'] ?? ''}';
        }

        return Padding(
          padding: EdgeInsets.only(left: 16, right: 16, top: 16, bottom: MediaQuery.viewInsetsOf(c).bottom + 16),
          child: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Row(children: [
                Expanded(child: Text(edit == null ? 'Maaş Tanımı Ekle' : 'Maaş Tanımını Düzenle', style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800))),
                IconButton(onPressed: () => Navigator.pop(c), icon: const Icon(Icons.close)),
              ]),
              const SizedBox(height: 6),
              const Text('Önce tarih aralığını seçin. Bu aralıkta maaş tanımı bulunan personeller listede gösterilmez.', style: TextStyle(fontSize: 12, color: MTheme.muted)),
              const SizedBox(height: 14),
              Row(children: [
                Expanded(child: _dateField(c, 'Başlangıç', start, () async {
                  final d = await pickDate(c, start);
                  if (d != null) {
                    setM(() => start = d);
                    if (end.isBefore(start)) setM(() => end = start);
                    await refreshEmployees();
                  }
                })),
                const SizedBox(width: 8),
                Expanded(child: _dateField(c, 'Bitiş', end, () async {
                  final d = await pickDate(c, end);
                  if (d != null) {
                    setM(() => end = d.isBefore(start) ? start : d);
                    await refreshEmployees();
                  }
                })),
              ]),
              const SizedBox(height: 10),
              InkWell(
                onTap: edit == null ? () async {
                  final v = await showEmployeePicker(c, es, selectedId: eid);
                  if (v != null) setM(() => eid = v);
                } : null,
                borderRadius: BorderRadius.circular(12),
                child: InputDecorator(
                  decoration: InputDecoration(labelText: 'Personel *', suffixIcon: edit == null ? const Icon(Icons.search) : const Icon(Icons.lock_outline)),
                  child: Text(selectedName()),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 5, left: 4),
                child: Text('${es.length} uygun personel', style: const TextStyle(fontSize: 11, color: MTheme.muted)),
              ),
              const SizedBox(height: 10),
              TextField(controller: amount, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Aylık Maaş *')),
              const SizedBox(height: 16),
              Row(children: [
                Expanded(child: OutlinedButton(onPressed: () => Navigator.pop(c), child: const Text('Vazgeç'))),
                const SizedBox(width: 8),
                Expanded(child: FilledButton(onPressed: () async {
                  if (eid == null) { snack(context, 'Personel seçin.', error: true); return; }
                  try {
                    final data = {'id': edit?['id'], 'employee_id': eid, 'salary_amount': amount.text, 'start_date': DateFormat('yyyy-MM-dd').format(start), 'end_date': DateFormat('yyyy-MM-dd').format(end)};
                    if (edit == null) {
                      await widget.state.api.request('salary', method: 'POST', data: data);
                    } else {
                      await widget.state.api.request('salary/manage', method: 'PUT', data: data, query: {'id': edit!['id']});
                    }
                    if (c.mounted) Navigator.pop(c);
                    await load();
                  } catch (e) { if (mounted) snack(context, '$e', error: true); }
                }, child: Text(edit == null ? 'Maaşı Kaydet' : 'Kaydet'))),
              ]),
            ]),
          ),
        );
      }),
    );
  }

  Future<void> advanceForm({Map<String, dynamic>? edit}) async {
    final es = await employees();
    int? eid = edit == null ? null : int.tryParse('${edit['employee_id']}');
    final amount = TextEditingController(text: '${edit?['amount'] ?? ''}');
    DateTime advanceDate = DateTime.tryParse('${edit?['advance_date'] ?? ''}') ?? DateTime.now();
    String type = '${edit?['advance_type'] ?? 'single'}';
    String method = '${edit?['payment_method'] ?? 'salary'}';
    String strategy = '${edit?['installment_strategy'] ?? 'parallel'}';
    int count = int.tryParse('${edit?['installment_count'] ?? 2}') ?? 2;
    int startYear = int.tryParse('${edit?['payment_start_year'] ?? DateTime.now().year}') ?? DateTime.now().year;
    int startMonth = int.tryParse('${edit?['payment_start_month'] ?? DateTime.now().month}') ?? DateTime.now().month;
    if (!mounted) return;
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (c) => StatefulBuilder(builder: (c, setM) => Padding(
            padding: EdgeInsets.only(left: 16, right: 16, top: 16, bottom: MediaQuery.viewInsetsOf(c).bottom + 16),
            child: SingleChildScrollView(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Row(children: [Expanded(child: Text(edit == null ? 'Yeni Avans Ekle' : 'Avans Planını Düzenle', style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800))), IconButton(onPressed: () => Navigator.pop(c), icon: const Icon(Icons.close))]),
                const SizedBox(height: 10),
                InkWell(onTap: edit == null ? () async { final v=await showEmployeePicker(c,es,selectedId:eid); if(v!=null)setM(()=>eid=v); } : null, borderRadius:BorderRadius.circular(12), child:InputDecorator(decoration:const InputDecoration(labelText:'Personel',suffixIcon:Icon(Icons.search)), child:Text(eid==null?'Personel ara ve seç':((){final e=es.firstWhere((x)=>int.parse('${x['id']}')==eid);return '${e['first_name']} ${e['last_name']}';})()))),
                const SizedBox(height: 10),
                Row(children: [Expanded(child: _dateField(c, 'Avans Tarihi', advanceDate, () async { final d = await pickDate(c, advanceDate); if (d != null) setM(() => advanceDate = d); })), const SizedBox(width: 8), Expanded(child: TextField(controller: amount, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Avans Tutarı')))]),
                const SizedBox(height: 10),
                Row(children: [
                  Expanded(child: DropdownButtonFormField<String>(value: type, decoration: const InputDecoration(labelText: 'Avans Türü'), items: const [DropdownMenuItem(value: 'single', child: Text('Tek Avans')), DropdownMenuItem(value: 'installment', child: Text('Taksitli Avans'))], onChanged: (v) => setM(() => type = v ?? 'single'))),
                  const SizedBox(width: 8),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: method,
                      isExpanded: true,
                      decoration: const InputDecoration(labelText: 'Ödeme Yöntemi'),
                      selectedItemBuilder: (_) => const [
                        Align(alignment: Alignment.centerLeft, child: Text('Maaştan Kesilecek', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 13))),
                        Align(alignment: Alignment.centerLeft, child: Text('Diğer Ödeme', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 13))),
                      ],
                      items: const [
                        DropdownMenuItem(value: 'salary', child: Text('Maaştan Kesilecek', overflow: TextOverflow.ellipsis)),
                        DropdownMenuItem(value: 'manual', child: Text('Diğer Ödeme')),
                      ],
                      onChanged: (v) => setM(() => method = v ?? 'salary'),
                    ),
                  ),
                ]),
                if (type == 'installment') ...[
                  const SizedBox(height: 10),
                  TextFormField(initialValue: '$count', keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Taksit Sayısı'), onChanged: (v) => count = (int.tryParse(v) ?? 2).clamp(2, 120).toInt()),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(value: strategy, decoration: const InputDecoration(labelText: 'Mevcut Taksit Varsa'), items: const [DropdownMenuItem(value: 'parallel', child: Text('Yeni taksiti mevcut aylık taksite ekle')), DropdownMenuItem(value: 'after_existing', child: Text('Önceki borç bittikten sonra başlat'))], onChanged: (v) => setM(() => strategy = v ?? 'parallel')),
                ],
                const SizedBox(height: 10),
                _periodPicker(c, startYear, startMonth, (y, m) => setM(() { startYear = y; startMonth = m; })),
                const SizedBox(height: 8),
                Container(width: double.infinity, padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: const Color(0xFFF2F5F6), borderRadius: BorderRadius.circular(10)), child: Text(method == 'salary' ? 'Vadesi gelen taksit dönem maaşı oluşturulurken otomatik düşülür.' : 'İK personeli ödeme yapıldıkça taksitleri manuel olarak “Ödendi” işaretler.', style: const TextStyle(fontSize: 11, color: MTheme.muted))),
                const SizedBox(height: 14),
                SizedBox(width: double.infinity, child: FilledButton(onPressed: () async {
                  if (eid == null) { snack(context, 'Personel seçin.', error: true); return; }
                  try {
                    final data = {'id': edit?['id'], 'employee_id': eid, 'advance_date': DateFormat('yyyy-MM-dd').format(advanceDate), 'amount': amount.text, 'advance_type': type, 'installment_count': type == 'installment' ? count : 1, 'payment_method': method, 'payment_start_year': startYear, 'payment_start_month': startMonth, 'installment_strategy': strategy};
                    if (edit == null) {
                      await widget.state.api.request('advance', method: 'POST', data: data);
                    } else {
                      await widget.state.api.request('advance/manage', method: 'PUT', data: data, query: {'id': edit!['id']});
                    }
                    if (c.mounted) Navigator.pop(c);
                    await load();
                  } catch (e) { if (mounted) snack(context, '$e', error: true); }
                }, child: Text(edit == null ? 'Avansı Kaydet' : 'Avans Planını Kaydet'))),
              ]),
            ),
          )),
    );
  }

  Widget _dateField(BuildContext c, String label, DateTime date, VoidCallback tap) => InkWell(onTap: tap, child: InputDecorator(decoration: InputDecoration(labelText: label, suffixIcon: const Icon(Icons.calendar_month_outlined)), child: Text(DateFormat('dd.MM.yyyy').format(date))));

  Widget _periodPicker(BuildContext c, int year, int month, void Function(int, int) setPeriod) => InkWell(
        onTap: () async {
          int y = year, m = month;
          final result = await showModalBottomSheet<List<int>>(context: c, useSafeArea: true, builder: (x) => StatefulBuilder(builder: (x, setM) => Padding(padding: const EdgeInsets.all(18), child: Column(mainAxisSize: MainAxisSize.min, children: [const Text('Ödeme Başlangıç Dönemi', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)), const SizedBox(height: 14), Row(children: [Expanded(child: DropdownButtonFormField<int>(value: m, decoration: const InputDecoration(labelText: 'Ay'), items: List.generate(12, (i) => DropdownMenuItem(value: i + 1, child: Text(const ['Ocak','Şubat','Mart','Nisan','Mayıs','Haziran','Temmuz','Ağustos','Eylül','Ekim','Kasım','Aralık'][i]))), onChanged: (v) => setM(() => m = v ?? m))), const SizedBox(width: 8), Expanded(child: DropdownButtonFormField<int>(value: y, decoration: const InputDecoration(labelText: 'Yıl'), items: List.generate(8, (i) => DropdownMenuItem(value: DateTime.now().year + i, child: Text('${DateTime.now().year + i}'))), onChanged: (v) => setM(() => y = v ?? y)))]), const SizedBox(height: 14), SizedBox(width: double.infinity, child: FilledButton(onPressed: () => Navigator.pop(x, [y, m]), child: const Text('Dönemi Seç')))]))));
          if (result != null) setPeriod(result[0], result[1]);
        },
        child: InputDecorator(decoration: const InputDecoration(labelText: 'Ödeme Başlangıç Dönemi', suffixIcon: Icon(Icons.calendar_view_month_outlined)), child: Text('${month.toString().padLeft(2, '0')}.$year')),
      );

  Future<void> installmentDetail(dynamic advance) async {
    final r = await widget.state.api.request('advance/installments', query: {'advance_id': advance['id']});
    final installments = (r['installments'] ?? []) as List;
    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (c) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: .82,
        maxChildSize: .95,
        builder: (_, sc) => Column(children: [
          Padding(padding: const EdgeInsets.fromLTRB(16, 12, 8, 8), child: Row(children: [Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('${advance['first_name']} ${advance['last_name']}', style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800)), Text('${advance['advance_type'] == 'installment' ? 'Taksitli Avans' : 'Tek Avans'} · ${money(advance['amount'])}', style: const TextStyle(color: MTheme.muted))])), IconButton(onPressed: () => Navigator.pop(c), icon: const Icon(Icons.close))])),
          if (advance['payment_method'] == 'manual' && installments.any((x) => x['status'] == 'open')) Padding(padding: const EdgeInsets.symmetric(horizontal: 12), child: SizedBox(width: double.infinity, child: OutlinedButton.icon(onPressed: () async { try { await widget.state.api.request('advance/close-all', method: 'POST', data: {'advance_id': advance['id']}); if (c.mounted) Navigator.pop(c); await load(); } catch (e) { if (mounted) snack(context, '$e', error: true); } }, icon: const Icon(Icons.done_all), label: const Text('Kalan Tüm Taksitleri Kapat')))),
          Expanded(child: ListView.builder(controller: sc, itemCount: installments.length, itemBuilder: (_, i) {
            final x = installments[i];
            final paid = x['status'] == 'paid';
            return Card(margin: const EdgeInsets.fromLTRB(12, 8, 12, 0), child: ListTile(leading: CircleAvatar(backgroundColor: paid ? Colors.green.shade50 : Colors.orange.shade50, child: Icon(paid ? Icons.check : Icons.schedule, color: paid ? Colors.green : Colors.orange)), title: Text('${x['installment_no']}. Taksit · ${money(x['amount'])}', style: const TextStyle(fontWeight: FontWeight.w700)), subtitle: Text('${x['due_month'].toString().padLeft(2, '0')}.${x['due_year']} · ${paid ? 'Ödendi' : 'Ödenmedi'}'), trailing: !paid && advance['payment_method'] == 'manual' ? FilledButton.tonal(onPressed: () async { try { await widget.state.api.request('advance/installment-paid', method: 'POST', data: {'installment_id': x['id']}); if (c.mounted) Navigator.pop(c); await load(); } catch (e) { if (mounted) snack(context, '$e', error: true); } }, child: const Text('Ödendi')) : null));
          })),
        ]),
      ),
    );
  }

  Future<void> payrollDialog() async {
    int year = DateTime.now().year, month = DateTime.now().month, unitId = 0;
    List units = [];
    try {
      final r = await widget.state.api.request('business-units');
      units = (r['business_units'] ?? []) as List;
    } catch (e) {
      if (mounted) snack(context, '$e', error: true);
      return;
    }
    if (!mounted) return;
    await showDialog(
      context: context,
      builder: (c) => StatefulBuilder(
        builder: (c, setM) => AlertDialog(
          title: const Text('Dönem Maaşı Oluştur'),
          content: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<int>(
                  value: unitId,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Firma *'),
                  items: [
                    const DropdownMenuItem(value: 0, child: Text('Tüm Firmalar')),
                    ...units.map((u) => DropdownMenuItem(value: int.tryParse('${u['id']}') ?? 0, child: Text('${u['name']}'))),
                  ],
                  onChanged: (v) => setM(() => unitId = v ?? 0),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<int>(
                  value: month,
                  decoration: const InputDecoration(labelText: 'Ay'),
                  items: List.generate(12, (i) => DropdownMenuItem(value: i + 1, child: Text('${i + 1}. Ay'))),
                  onChanged: (v) => setM(() => month = v ?? month),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  initialValue: '$year',
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Yıl'),
                  onChanged: (v) => year = int.tryParse(v) ?? year,
                ),
                const SizedBox(height: 10),
                const Text(
                  'Tüm Firmalar seçildiğinde dönem maaşları her firma için ayrı kayıt olarak oluşturulur.',
                  style: TextStyle(fontSize: 11, color: MTheme.muted),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(c), child: const Text('Vazgeç')),
            FilledButton(
              onPressed: () async {
                try {
                  final r = await widget.state.api.request(
                    'payroll/create',
                    method: 'POST',
                    data: {'year': year, 'month': month, 'business_unit_id': unitId},
                  );
                  if (c.mounted) Navigator.pop(c);
                  if (mounted) snack(context, '${r['message'] ?? 'Dönem maaşları oluşturuldu.'}');
                  await load();
                } catch (e) {
                  if (mounted) snack(context, '$e', error: true);
                }
              },
              child: const Text('Oluştur'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> payrollItems(dynamic period) async {
    final r = await widget.state.api.request(
      'payroll/items',
      query: {'period_id': period['id']},
    );
    final items = (r['items'] ?? []) as List;
    final periodInfo = Map<String, dynamic>.from((r['period'] ?? period) as Map);
    if (!mounted) return;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (sheetContext) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: .9,
          maxChildSize: .98,
          builder: (_, scrollController) {
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 8, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(
                            '${periodInfo['business_unit_name'] ?? 'Firma'} · ${periodInfo['period_month']}.${periodInfo['period_year']}',
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                          ),
                          Text('${items.length} personel · Net ${money(periodInfo['total_net'])}', style: const TextStyle(fontSize: 11, color: MTheme.muted)),
                        ]),
                      ),
                      IconButton(onPressed: () => Navigator.pop(sheetContext), icon: const Icon(Icons.close)),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: items.isEmpty ? null : () async {
                        try {
                          await PayrollPdf.share(period: periodInfo, items: items);
                        } catch (e) {
                          if (mounted) snack(context, 'Bordro PDF oluşturulamadı: $e', error: true);
                        }
                      },
                      icon: const Icon(Icons.picture_as_pdf_outlined),
                      label: const Text('Toplu Bordro PDF'),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: SingleChildScrollView(
                    controller: scrollController,
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        headingRowHeight: 44,
                        dataRowMinHeight: 52,
                        dataRowMaxHeight: 62,
                        columns: const [
                          DataColumn(label: Text('Personel')),
                          DataColumn(label: Text('Aylık Maaş')),
                          DataColumn(label: Text('Geldi')),
                          DataColumn(label: Text('Hafta Tatili')),
                          DataColumn(label: Text('Yıllık İzin')),
                          DataColumn(label: Text('Ücretli İzin')),
                          DataColumn(label: Text('Ücretsiz İzin')),
                          DataColumn(label: Text('Rapor')),
                          DataColumn(label: Text('Gelmedi')),
                          DataColumn(label: Text('Hesaplanan')),
                          DataColumn(label: Text('Hakediş')),
                          DataColumn(label: Text('Avans')),
                          DataColumn(label: Text('Net')),
                        ],
                        rows: items.map<DataRow>((raw) {
                          final x = Map<String, dynamic>.from(raw as Map);
                          return DataRow(cells: [
                            DataCell(SizedBox(width: 150, child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text('${x['first_name']} ${x['last_name']}', overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700)),
                              Text('${x['employee_no'] ?? ''}', style: const TextStyle(fontSize: 10, color: MTheme.muted)),
                            ]))),
                            DataCell(Text(money(x['monthly_salary']))),
                            DataCell(Text('${x['present_days'] ?? 0}')),
                            DataCell(Text('${x['weekly_off_days'] ?? 0}')),
                            DataCell(Text('${x['annual_leave_days'] ?? 0}')),
                            DataCell(Text('${x['paid_leave_days'] ?? 0}')),
                            DataCell(Text('${x['unpaid_leave_days'] ?? 0}')),
                            DataCell(Text('${x['sick_days'] ?? 0}')),
                            DataCell(Text('${x['absent_days'] ?? 0}', style: const TextStyle(fontWeight: FontWeight.w700))),
                            DataCell(Text('${x['calculated_days'] ?? 0}/${x['calendar_days'] ?? 0}')),
                            DataCell(Text(money(x['gross_salary']))),
                            DataCell(Text(money(x['advance_total']))),
                            DataCell(Text(money(x['net_salary']), style: const TextStyle(fontWeight: FontWeight.w800))),
                          ]);
                        }).toList(),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        try {
                          await widget.state.api.request(
                            'payroll/cancel',
                            method: 'POST',
                            data: {'period_id': periodInfo['id']},
                          );
                          if (sheetContext.mounted) Navigator.pop(sheetContext);
                          await load();
                        } catch (e) {
                          if (mounted) snack(context, '$e', error: true);
                        }
                      },
                      icon: const Icon(Icons.undo),
                      label: const Text('Bu Firma Dönemini İptal Et'),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final lists = [salaries, advances, periods];
    return Column(children: [
      Padding(padding: const EdgeInsets.all(12), child: Column(children: [
        SegmentedButton<int>(segments: const [ButtonSegment(value: 0, label: Text('Maaş')), ButtonSegment(value: 1, label: Text('Avans')), ButtonSegment(value: 2, label: Text('Dönem'))], selected: {tab}, onSelectionChanged: (s) { setState(() {tab=s.first;page=1;hasMore=true;}); load(); }),
        const SizedBox(height: 8),
        SizedBox(width: double.infinity, child: FilledButton.icon(onPressed: tab == 0 ? () => salaryForm() : tab == 1 ? () => advanceForm() : payrollDialog, icon: Icon(tab == 2 ? Icons.calculate_outlined : Icons.add), label: Text(tab == 0 ? 'Maaş Tanımı Ekle' : tab == 1 ? 'Avans Ekle' : 'Dönem Maaşı Oluştur'))),
      ])),
      Expanded(child: busy && lists[tab].isEmpty ? const Center(child: CircularProgressIndicator()) : RefreshIndicator(onRefresh: load, child: ListView.builder(controller:listController,itemCount: lists[tab].length+(loadingMore?1:0), itemBuilder: (_, i) {
        if(i>=lists[tab].length)return const Padding(padding:EdgeInsets.all(18),child:Center(child:CircularProgressIndicator()));
        final x = lists[tab][i];
        if (tab == 0) return Card(margin: const EdgeInsets.fromLTRB(12, 0, 12, 8), child: ListTile(onTap: () => salaryForm(edit: Map<String, dynamic>.from(x)), title: Text('${x['first_name']} ${x['last_name']}', style: const TextStyle(fontWeight: FontWeight.w700)), subtitle: Text('${x['start_date']} - ${x['end_date']}'), trailing: Text(money(x['salary_amount']), style: const TextStyle(fontWeight: FontWeight.w800))));
        if (tab == 1) return Card(margin: const EdgeInsets.fromLTRB(12, 0, 12, 8), child: ListTile(onTap: () => installmentDetail(x), title: Text('${x['first_name']} ${x['last_name']}', style: const TextStyle(fontWeight: FontWeight.w700)), subtitle: Text('${x['advance_type'] == 'installment' ? 'Taksitli Avans' : 'Tek Avans'} · ${x['payment_method'] == 'manual' ? 'Diğer ödeme' : 'Maaştan kesinti'}\n${x['paid_installments'] ?? 0} ödendi · ${x['open_installments'] ?? 0} kaldı'), isThreeLine: true, trailing: PopupMenuButton<String>(onSelected: (v) async { if (v == 'detail') installmentDetail(x); if (v == 'edit') { final r = await widget.state.api.request('advance/manage', query: {'id': x['id']}); if (mounted) advanceForm(edit: Map<String, dynamic>.from(r['advance'])); } if (v == 'delete') { try { await widget.state.api.request('advance/manage', method: 'DELETE', data: {'id': x['id']}, query: {'id': x['id']}); load(); } catch (e) { if (mounted) snack(context, '$e', error: true); } } }, itemBuilder: (_) => [const PopupMenuItem(value: 'detail', child: Text('Taksit Detayları')), const PopupMenuItem(value: 'edit', child: Text('Düzenle')), const PopupMenuItem(value: 'delete', child: Text('Sil'))])));
        return Card(margin: const EdgeInsets.fromLTRB(12, 0, 12, 8), child: ListTile(onTap: () => payrollItems(x), leading: const CircleAvatar(child: Icon(Icons.receipt_long_outlined)), title: Text('${x['business_unit_name'] ?? 'Firma'} · ${x['period_month']}.${x['period_year']}', style: const TextStyle(fontWeight: FontWeight.w700)), subtitle: Text('Dönem Maaşı · Brüt: ${money(x['total_salary'])} · Avans: ${money(x['total_advance'])}'), trailing: Text(money(x['total_net']), style: const TextStyle(fontWeight: FontWeight.w800))));
      }))),
    ]);
  }
}
