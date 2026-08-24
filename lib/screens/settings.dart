import 'package:flutter/material.dart';
import '../core/app_state.dart';
import '../core/theme.dart';
import '../widgets/common.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key, required this.state});
  final AppState state;
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  Map<String, dynamic>? defs;
  List shiftWorks = [];
  final dayLabels = const {1: 'Pazartesi', 2: 'Salı', 3: 'Çarşamba', 4: 'Perşembe', 5: 'Cuma', 6: 'Cumartesi', 7: 'Pazar'};

  @override
  void initState() { super.initState(); load(); }

  Future<void> load() async {
    try {
      final results = await Future.wait([
        widget.state.api.request('definitions'),
        widget.state.api.request('shift-work/list'),
      ]);
      if (mounted) {
        setState(() {
          defs = results[0];
          shiftWorks = (results[1]['works'] ?? []) as List;
        });
      }
    } catch (e) { if (mounted) snack(context, '$e', error: true); }
  }

  Future<void> editWeeklyOff() async {
    final selected = Set<int>.from(
      (defs?['weekly_off_days'] as List? ?? []).map((x) => int.parse('$x')),
    );

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setModalState) {
            return AlertDialog(
              title: const Text('Hafta Tatilleri'),
              content: SizedBox(
                width: 420,
                child: ListView(
                  shrinkWrap: true,
                  children: dayLabels.entries.map((e) {
                    return CheckboxListTile(
                      value: selected.contains(e.key),
                      title: Text(e.value),
                      onChanged: (v) {
                        setModalState(() {
                          if (v == true) {
                            selected.add(e.key);
                          } else {
                            selected.remove(e.key);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Vazgeç'),
                ),
                FilledButton(
                  onPressed: () async {
                    try {
                      await widget.state.api.request(
                        'definitions/weekly-off',
                        method: 'POST',
                        data: {'days': selected.toList()},
                      );
                      if (dialogContext.mounted) Navigator.pop(dialogContext);
                      await load();
                    } catch (e) {
                      if (mounted) snack(context, '$e', error: true);
                    }
                  },
                  child: const Text('Kaydet'),
                ),
              ],
            );
          },
        );
      },
    );
  }


  Future<void> addOrEditBusinessUnit([dynamic row]) async {
    final name = TextEditingController(text: '${row?['name'] ?? ''}');
    final shortName = TextEditingController(text: '${row?['short_name'] ?? ''}');
    final taxOffice = TextEditingController(text: '${row?['tax_office'] ?? ''}');
    final taxNo = TextEditingController(text: '${row?['tax_no'] ?? ''}');
    final phone = TextEditingController(text: '${row?['phone'] ?? ''}');
    final email = TextEditingController(text: '${row?['email'] ?? ''}');
    final address = TextEditingController(text: '${row?['address'] ?? ''}');
    String status = '${row?['status'] ?? 'active'}';
    final editing = row != null;
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (c) => StatefulBuilder(
        builder: (c, setM) => AlertDialog(
          title: Text(editing ? 'Firma Tanımını Düzenle' : 'Yeni Firma Tanımı'),
          content: SizedBox(
            width: 500,
            child: SingleChildScrollView(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                TextField(controller: name, decoration: const InputDecoration(labelText: 'Firma Adı *')),
                const SizedBox(height: 8),
                TextField(controller: shortName, decoration: const InputDecoration(labelText: 'Kısa Ad')),
                const SizedBox(height: 8),
                Row(children: [
                  Expanded(child: TextField(controller: taxOffice, decoration: const InputDecoration(labelText: 'Vergi Dairesi'))),
                  const SizedBox(width: 8),
                  Expanded(child: TextField(controller: taxNo, decoration: const InputDecoration(labelText: 'Vergi No'))),
                ]),
                const SizedBox(height: 8),
                Row(children: [
                  Expanded(child: TextField(controller: phone, decoration: const InputDecoration(labelText: 'Telefon'))),
                  const SizedBox(width: 8),
                  Expanded(child: TextField(controller: email, decoration: const InputDecoration(labelText: 'E-posta'))),
                ]),
                const SizedBox(height: 8),
                TextField(controller: address, maxLines: 2, decoration: const InputDecoration(labelText: 'Adres')),
                if (editing && '${row['is_primary']}' != '1') ...[
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: status,
                    items: const [
                      DropdownMenuItem(value: 'active', child: Text('Aktif')),
                      DropdownMenuItem(value: 'passive', child: Text('Pasif')),
                    ],
                    onChanged: (v) => setM(() => status = v ?? 'active'),
                    decoration: const InputDecoration(labelText: 'Durum'),
                  ),
                ],
              ]),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(c), child: const Text('Vazgeç')),
            FilledButton(
              onPressed: () async {
                if (name.text.trim().isEmpty) return;
                try {
                  if (editing) {
                    await widget.state.api.request(
                      'business-unit',
                      method: 'PUT',
                      query: {'id': row['id']},
                      data: {
                        'id': row['id'],
                        'name': name.text.trim(),
                        'short_name': shortName.text.trim(),
                        'tax_office': taxOffice.text.trim(),
                        'tax_no': taxNo.text.trim(),
                        'phone': phone.text.trim(),
                        'email': email.text.trim(),
                        'address': address.text.trim(),
                        'status': status,
                      },
                    );
                  } else {
                    await widget.state.api.request(
                      'business-units',
                      method: 'POST',
                      data: {
                        'name': name.text.trim(),
                        'short_name': shortName.text.trim(),
                        'tax_office': taxOffice.text.trim(),
                        'tax_no': taxNo.text.trim(),
                        'phone': phone.text.trim(),
                        'email': email.text.trim(),
                        'address': address.text.trim(),
                      },
                    );
                  }
                  if (c.mounted) Navigator.pop(c);
                  await load();
                } catch (e) {
                  if (mounted) snack(context, '$e', error: true);
                }
              },
              child: const Text('Kaydet'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> add(String type, [dynamic item]) async {
    final editing = item != null;
    final controller = TextEditingController(text: '${item?['name'] ?? ''}');
    await showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(editing
            ? (type == 'department' ? 'Departmanı Düzenle' : 'Görev / Ünvanı Düzenle')
            : (type == 'department' ? 'Departman Ekle' : 'Görev / Ünvan Ekle')),
        content: TextField(controller: controller, decoration: const InputDecoration(labelText: 'Tanım')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c), child: const Text('Vazgeç')),
          FilledButton(
            onPressed: () async {
              if (controller.text.trim().isEmpty) return;
              try {
                await widget.state.api.request(
                  'definitions/item',
                  method: editing ? 'PUT' : 'POST',
                  query: editing ? {'type': type, 'id': item['id']} : null,
                  data: {'type': type, 'id': item?['id'], 'name': controller.text.trim()},
                );
                if (c.mounted) Navigator.pop(c);
                await load();
              } catch (e) {
                if (mounted) snack(context, '$e', error: true);
              }
            },
            child: Text(editing ? 'Değişiklikleri Kaydet' : 'Kaydet'),
          ),
        ],
      ),
    );
  }

  Future<void> remove(String type, dynamic item) async {
    try {
      await widget.state.api.request('definitions/item', method: 'DELETE', data: {'type': type, 'id': item['id']}, query: {'type': type, 'id': item['id']});
      await load();
    } catch (e) { if (mounted) snack(context, '$e', error: true); }
  }


  Future<void> addShift([dynamic row]) async {
    final editing = row != null;
    final name=TextEditingController(text:'${row?['name'] ?? ''}');
    final start=TextEditingController(text:('${row?['start_time'] ?? '08:00'}').substring(0,5));
    final end=TextEditingController(text:('${row?['end_time'] ?? '17:00'}').substring(0,5));
    final tol=TextEditingController(text:'${row?['tolerance_minutes'] ?? 0}');
    await showDialog<void>(
      context:context,
      builder:(c)=>AlertDialog(
        title:Text(editing ? 'Vardiya Tanımını Düzenle' : 'Yeni Vardiya Tanımı'),
        content:SingleChildScrollView(child:Column(mainAxisSize:MainAxisSize.min,children:[
          TextField(controller:name,decoration:const InputDecoration(labelText:'Vardiya Adı')),
          const SizedBox(height:10),
          TextField(controller:start,decoration:const InputDecoration(labelText:'Başlangıç (HH:mm)')),
          const SizedBox(height:10),
          TextField(controller:end,decoration:const InputDecoration(labelText:'Bitiş (HH:mm)')),
          const SizedBox(height:10),
          TextField(controller:tol,keyboardType:TextInputType.number,decoration:const InputDecoration(labelText:'Tolerans (dk)'))
        ])),
        actions:[
          TextButton(onPressed:()=>Navigator.pop(c),child:const Text('Vazgeç')),
          FilledButton(onPressed:()async{
            try{
              await widget.state.api.request(
                'definitions/shift',
                method: editing ? 'PUT' : 'POST',
                query: editing ? {'id':row['id']} : null,
                data:{'id':row?['id'],'name':name.text.trim(),'start_time':start.text.trim(),'end_time':end.text.trim(),'tolerance_minutes':int.tryParse(tol.text)??0}
              );
              if(c.mounted)Navigator.pop(c);await load();
            }catch(e){if(mounted)snack(context,'$e',error:true);}
          },child:Text(editing ? 'Değişiklikleri Kaydet' : 'Kaydet'))
        ]
      )
    );
  }
  Future<void> removeShift(dynamic x) async {try{await widget.state.api.request('definitions/shift',method:'DELETE',query:{'id':x['id']},data:{'id':x['id']});await load();}catch(e){if(mounted)snack(context,'$e',error:true);}}
  Future<void> newShiftWork({bool temporary = false}) async {
    final shifts = List<dynamic>.from(defs?['shifts'] as List? ?? const []);
    if (shifts.isEmpty) {
      snack(context, 'Önce vardiya tanımı ekleyin.', error: true);
      return;
    }

    dynamic selected = shifts.first;
    DateTime startDate = DateTime.now();
    DateTime endDate = DateTime.now();
    List<dynamic> available = [];
    final selectedIds = <int>{};
    final search = TextEditingController();
    bool loadingEmployees = true;
    bool initialRequested = false;
    bool saving = false;
    String? inlineError;

    Future<void> fetchEmployees(StateSetter setModal) async {
      setModal(() {
        loadingEmployees = true;
        inlineError = null;
      });
      try {
        final result = await widget.state.api.request(
          'shift-work/available',
          query: {
            'shift_id': selected['id'],
            'start_date': _iso(startDate),
            'end_date': _iso(endDate),
            'assignment_type': temporary ? 'temporary' : 'regular',
          },
        );
        final rows = List<dynamic>.from(result['employees'] as List? ?? const []);
        available = temporary
            ? rows
            : rows.where((e) => '${e['blocked']}' != '1').toList();
        selectedIds.removeWhere(
          (id) => !available.any((e) => int.tryParse('${e['id']}') == id),
        );
      } catch (e) {
        available = [];
        inlineError = '$e';
      } finally {
        setModal(() => loadingEmployees = false);
      }
    }

    if (!mounted) return;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setModal) {
          // İlk frame'de personelleri dialog açıldıktan sonra getir.
          if (!initialRequested) {
            initialRequested = true;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (dialogContext.mounted) fetchEmployees(setModal);
            });
          }

          final q = search.text.trim().toLowerCase();
          final visible = available.where((e) {
            if (q.isEmpty) return true;
            final text =
                '${e['first_name']} ${e['last_name']} ${e['employee_no']} ${e['business_unit_name'] ?? ''}'
                    .toLowerCase();
            return text.contains(q);
          }).toList();

          return AlertDialog(
            insetPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 22),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
            titlePadding: EdgeInsets.zero,
            title: Container(
              padding: const EdgeInsets.fromLTRB(18, 17, 12, 15),
              decoration: const BoxDecoration(
                color: MTheme.ink,
                borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: MTheme.lime,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      temporary ? Icons.swap_horiz_rounded : Icons.groups_2_outlined,
                      color: MTheme.ink,
                    ),
                  ),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          temporary ? 'Geçici Vardiya Aktarımı' : 'Yeni Vardiya Çalışması',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          temporary
                              ? 'Personelleri belirli tarihler arasında geçici başka vardiyaya aktarın.'
                              : 'Vardiya, tarih aralığı ve personelleri seçerek çalışma planı oluşturun.',
                          style: const TextStyle(
                            color: Colors.white60,
                            fontSize: 9.5,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: saving ? null : () => Navigator.pop(dialogContext),
                    icon: const Icon(Icons.close, color: Colors.white70),
                  ),
                ],
              ),
            ),
            content: SizedBox(
              width: 560,
              height: MediaQuery.sizeOf(dialogContext).height * .66,
              child: Column(
                children: [
                  DropdownButtonFormField<dynamic>(
                    value: selected,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Vardiya *',
                      prefixIcon: Icon(Icons.schedule_outlined),
                    ),
                    items: shifts
                        .map(
                          (x) => DropdownMenuItem<dynamic>(
                            value: x,
                            child: Text(
                              '${x['name']} · '
                              '${('${x['start_time']}').substring(0, 5)} - '
                              '${('${x['end_time']}').substring(0, 5)}',
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: saving
                        ? null
                        : (v) {
                            if (v == null) return;
                            selected = v;
                            selectedIds.clear();
                            fetchEmployees(setModal);
                          },
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.event_outlined, size: 18),
                          onPressed: saving
                              ? null
                              : () async {
                                  final picked = await showDatePicker(
                                    context: dialogContext,
                                    initialDate: startDate,
                                    firstDate: DateTime(2020),
                                    lastDate: DateTime(2100),
                                  );
                                  if (picked == null) return;
                                  startDate = picked;
                                  if (endDate.isBefore(startDate)) endDate = startDate;
                                  selectedIds.clear();
                                  await fetchEmployees(setModal);
                                },
                          label: Text('Başlangıç\n${_iso(startDate)}', textAlign: TextAlign.center),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.event_available_outlined, size: 18),
                          onPressed: saving
                              ? null
                              : () async {
                                  final picked = await showDatePicker(
                                    context: dialogContext,
                                    initialDate: endDate.isBefore(startDate) ? startDate : endDate,
                                    firstDate: startDate,
                                    lastDate: DateTime(2100),
                                  );
                                  if (picked == null) return;
                                  endDate = picked;
                                  selectedIds.clear();
                                  await fetchEmployees(setModal);
                                },
                          label: Text('Bitiş\n${_iso(endDate)}', textAlign: TextAlign.center),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: search,
                    enabled: !saving,
                    onChanged: (_) => setModal(() {}),
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.search),
                      hintText: 'Personel adı, kodu veya firma ara',
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        '${selectedIds.length} personel seçildi',
                        style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800),
                      ),
                      const Spacer(),
                      if (visible.isNotEmpty)
                        TextButton(
                          onPressed: saving
                              ? null
                              : () => setModal(() {
                                    final ids = visible
                                        .map((e) => int.tryParse('${e['id']}') ?? 0)
                                        .where((id) => id > 0);
                                    final allSelected = ids.every(selectedIds.contains);
                                    if (allSelected) {
                                      selectedIds.removeAll(ids);
                                    } else {
                                      selectedIds.addAll(ids);
                                    }
                                  }),
                          child: const Text('Tümünü Seç / Kaldır'),
                        ),
                    ],
                  ),
                  if (inlineError != null)
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFEEEE),
                        borderRadius: BorderRadius.circular(11),
                        border: Border.all(color: const Color(0xFFF1BBBB)),
                      ),
                      child: Text(
                        inlineError!,
                        style: const TextStyle(fontSize: 10.5, color: Color(0xFF9E3333)),
                      ),
                    ),
                  Expanded(
                    child: loadingEmployees
                        ? const Center(child: CircularProgressIndicator())
                        : visible.isEmpty
                            ? Center(
                                child: Text(
                                  temporary
                                      ? 'Aktarılabilecek aktif personel bulunamadı.'
                                      : 'Bu tarih aralığında başka vardiyada olmayan uygun personel bulunamadı.',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(color: MTheme.muted, fontSize: 11),
                                ),
                              )
                            : ListView.separated(
                                itemCount: visible.length,
                                separatorBuilder: (_, __) => const SizedBox(height: 5),
                                itemBuilder: (_, index) {
                                  final e = visible[index];
                                  final id = int.tryParse('${e['id']}') ?? 0;
                                  final checked = selectedIds.contains(id);
                                  return Material(
                                    color: checked
                                        ? const Color(0xFFF0F7D3)
                                        : const Color(0xFFF7F9FA),
                                    borderRadius: BorderRadius.circular(13),
                                    child: CheckboxListTile(
                                      value: checked,
                                      dense: true,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(13),
                                      ),
                                      title: Text(
                                        '${e['first_name']} ${e['last_name']}',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                      subtitle: Text(
                                        '${e['employee_no']}'
                                        '${e['business_unit_name'] != null ? ' · ${e['business_unit_name']}' : ''}'
                                        '${temporary && e['current_shift_name'] != null ? '\nMevcut: ${e['current_shift_name']}' : ''}',
                                        style: const TextStyle(fontSize: 9.5),
                                      ),
                                      onChanged: saving
                                          ? null
                                          : (v) => setModal(() {
                                                if (v == true) {
                                                  selectedIds.add(id);
                                                } else {
                                                  selectedIds.remove(id);
                                                }
                                              }),
                                    ),
                                  );
                                },
                              ),
                  ),
                ],
              ),
            ),
            actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 15),
            actions: [
              TextButton(
                onPressed: saving ? null : () => Navigator.pop(dialogContext),
                child: const Text('Vazgeç'),
              ),
              FilledButton.icon(
                icon: saving
                    ? const SizedBox(
                        width: 15,
                        height: 15,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save_outlined),
                onPressed: saving || selectedIds.isEmpty
                    ? null
                    : () async {
                        setModal(() {
                          saving = true;
                          inlineError = null;
                        });
                        try {
                          final result = await widget.state.api.request(
                            'shift-work/save',
                            method: 'POST',
                            data: {
                              'shift_id': selected['id'],
                              'start_date': _iso(startDate),
                              'end_date': _iso(endDate),
                              'assignment_type':
                                  temporary ? 'temporary' : 'regular',
                              'employee_ids': selectedIds.toList(),
                            },
                          );
                          if (!dialogContext.mounted) return;
                          Navigator.pop(dialogContext);
                          if (mounted) {
                            snack(context, '${result['message']}');
                            await load();
                          }
                        } catch (e) {
                          if (dialogContext.mounted) {
                            setModal(() {
                              saving = false;
                              inlineError = '$e';
                            });
                          }
                        }
                      },
                label: Text(temporary ? 'Aktarımı Kaydet' : 'Çalışmayı Kaydet'),
              ),
            ],
          );
        },
      ),
    );

    search.dispose();
  }

  Widget _shiftWorkCard(dynamic x, {required bool temporary}) {
    final names = '${x['employee_names'] ?? ''}'.trim();
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: temporary ? const Color(0xFFFFF8E7) : const Color(0xFFF7FAFB),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: temporary ? const Color(0xFFE9D395) : const Color(0xFFE0E7EA)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Text('${x['shift_name']}', style: const TextStyle(fontWeight: FontWeight.w800))),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(9)),
            child: Text('${x['employee_count']} personel', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700)),
          ),
        ]),
        const SizedBox(height: 5),
        Text(
          '${('${x['start_time']}').substring(0, 5)} - ${('${x['end_time']}').substring(0, 5)} · ${x['start_date']} → ${x['end_date'] ?? 'Süresiz'}',
          style: const TextStyle(fontSize: 11),
        ),
        if (names.isNotEmpty) ...[
          const SizedBox(height: 5),
          Text(names, maxLines: 3, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 10, color: Color(0xFF6A747D))),
        ],
      ]),
    );
  }

  String _iso(DateTime d)=>'${d.year.toString().padLeft(4,'0')}-${d.month.toString().padLeft(2,'0')}-${d.day.toString().padLeft(2,'0')}';
  Widget _definitionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Widget child,
    Widget? trailing,
    bool expanded = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: MTheme.line),
        boxShadow: MTheme.softShadow,
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: expanded,
          tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
          childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          leading: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(color: MTheme.limeSoft, borderRadius: BorderRadius.circular(13)),
            child: Icon(icon, color: MTheme.ink, size: 21),
          ),
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
          subtitle: Text(subtitle, style: const TextStyle(fontSize: 10.5, color: MTheme.muted)),
          trailing: trailing,
          children: [child],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (defs == null) return const Center(child: CircularProgressIndicator());
    final off = (defs!['weekly_off_days'] as List).map((x) => dayLabels[int.tryParse('$x')] ?? '$x').join(', ');
    final regularWorks = shiftWorks.where((x) => x['assignment_type'] == 'regular').toList();
    final temporaryWorks = shiftWorks.where((x) => x['assignment_type'] == 'temporary').toList();

    return RefreshIndicator(
      onRefresh: load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 28),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [MTheme.ink, MTheme.ink2]),
              borderRadius: BorderRadius.circular(22),
              boxShadow: MTheme.softShadow,
            ),
            child: const Row(
              children: [
                Icon(Icons.tune_rounded, color: MTheme.lime, size: 30),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Tanım Yönetimi', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)),
                      SizedBox(height: 3),
                      Text('Firma, departman, görev, hafta tatili ve vardiya yapılandırmaları', style: TextStyle(color: Colors.white60, fontSize: 10.5)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          TechCard(
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(color: MTheme.limeSoft, borderRadius: BorderRadius.circular(13)),
                child: const Icon(Icons.calendar_view_week_outlined, color: MTheme.ink),
              ),
              title: const Text('Hafta Tatilleri', style: TextStyle(fontWeight: FontWeight.w900)),
              subtitle: Text(off.isEmpty ? 'Henüz seçim yapılmadı' : off),
              trailing: IconButton(onPressed: editWeeklyOff, icon: const Icon(Icons.edit_outlined)),
            ),
          ),
          const SizedBox(height: 12),
          _definitionCard(
            icon: Icons.apartment_rounded,
            title: 'Firma Tanımları',
            subtitle: 'Birincil ve ek firmalarınızı yönetin',
            trailing: IconButton(onPressed: () => addOrEditBusinessUnit(), icon: const Icon(Icons.add_business_rounded)),
            child: Column(
              children: [
                ...((defs!['business_units'] as List? ?? []).map((x) => Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(color: const Color(0xFFF7F9FA), borderRadius: BorderRadius.circular(14), border: Border.all(color: MTheme.line)),
                  child: ListTile(
                    leading: CircleAvatar(backgroundColor: MTheme.ink, foregroundColor: MTheme.lime, child: Text('${x['name']}'.isEmpty ? '?' : '${x['name']}'[0])),
                    title: Text('${x['name']}', style: const TextStyle(fontWeight: FontWeight.w800)),
                    subtitle: Text('${x['unit_no'] ?? ''} · ${x['status'] == 'active' ? 'Aktif' : 'Pasif'}'),
                    trailing: IconButton(icon: const Icon(Icons.edit_outlined), onPressed: () => addOrEditBusinessUnit(x)),
                  ),
                ))),
              ],
            ),
          ),
          _definitionCard(
            icon: Icons.account_tree_outlined,
            title: 'Departmanlar',
            subtitle: '${(defs!['departments'] as List).length} departman tanımlı',
            trailing: IconButton(onPressed: () => add('department'), icon: const Icon(Icons.add_circle_outline)),
            child: Column(
              children: (defs!['departments'] as List).map((x) => Container(
                margin: const EdgeInsets.only(bottom: 7),
                decoration: BoxDecoration(color: const Color(0xFFF7F9FA), borderRadius: BorderRadius.circular(12), border: Border.all(color: MTheme.line)),
                child: ListTile(dense: true, title: Text('${x['name']}', style: const TextStyle(fontWeight: FontWeight.w700)), trailing: Wrap(mainAxisSize: MainAxisSize.min, children:[IconButton(icon: const Icon(Icons.edit_outlined), onPressed: () => add('department', x)),IconButton(tooltip: x['used'] == true || '${x['used']}' == '1' ? 'Kullanılmış tanım silinemez' : 'Sil', icon: Icon(x['used'] == true || '${x['used']}' == '1' ? Icons.lock_outline : Icons.delete_outline), onPressed: x['used'] == true || '${x['used']}' == '1' ? null : () => remove('department', x))])),
              )).toList(),
            ),
          ),
          _definitionCard(
            icon: Icons.workspace_premium_outlined,
            title: 'Görev / Ünvanlar',
            subtitle: '${(defs!['positions'] as List).length} görev veya ünvan tanımlı',
            trailing: IconButton(onPressed: () => add('position'), icon: const Icon(Icons.add_circle_outline)),
            child: Column(
              children: (defs!['positions'] as List).map((x) => Container(
                margin: const EdgeInsets.only(bottom: 7),
                decoration: BoxDecoration(color: const Color(0xFFF7F9FA), borderRadius: BorderRadius.circular(12), border: Border.all(color: MTheme.line)),
                child: ListTile(dense: true, title: Text('${x['name']}', style: const TextStyle(fontWeight: FontWeight.w700)), trailing: Wrap(mainAxisSize: MainAxisSize.min, children:[IconButton(icon: const Icon(Icons.edit_outlined), onPressed: () => add('position', x)),IconButton(tooltip: x['used'] == true || '${x['used']}' == '1' ? 'Kullanılmış tanım silinemez' : 'Sil', icon: Icon(x['used'] == true || '${x['used']}' == '1' ? Icons.lock_outline : Icons.delete_outline), onPressed: x['used'] == true || '${x['used']}' == '1' ? null : () => remove('position', x))])),
              )).toList(),
            ),
          ),
          _definitionCard(
            icon: Icons.schedule_rounded,
            title: 'Vardiyalar',
            subtitle: '${(defs!['shifts'] as List? ?? []).length} vardiya tanımı',
            expanded: true,
            trailing: IconButton(onPressed: addShift, icon: const Icon(Icons.add_circle_outline)),
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(color: MTheme.limeSoft, borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFDCE9A0))),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      FilledButton.icon(onPressed: () => newShiftWork(), icon: const Icon(Icons.groups_2_outlined), label: const Text('Yeni Vardiya Çalışması')),
                      OutlinedButton.icon(onPressed: () => newShiftWork(temporary: true), icon: const Icon(Icons.swap_horiz_rounded), label: const Text('Geçici Aktar')),
                    ],
                  ),
                ),
                ...(defs!['shifts'] as List? ?? []).map((x) => Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(color: const Color(0xFFF7F9FA), borderRadius: BorderRadius.circular(13), border: Border.all(color: MTheme.line)),
                  child: ListTile(
                    leading: const Icon(Icons.schedule_outlined, color: MTheme.ink),
                    title: Text('${x['name']}', style: const TextStyle(fontWeight: FontWeight.w800)),
                    subtitle: Text('${('${x['start_time']}').substring(0, 5)} - ${('${x['end_time']}').substring(0, 5)} · ${x['tolerance_minutes']} dk tolerans'),
                    trailing: Wrap(mainAxisSize: MainAxisSize.min, children:[IconButton(icon: const Icon(Icons.edit_outlined), onPressed: () => addShift(x)),IconButton(tooltip: x['used'] == true || '${x['used']}' == '1' ? 'Kullanılmış vardiya silinemez' : 'Sil', icon: Icon(x['used'] == true || '${x['used']}' == '1' ? Icons.lock_outline : Icons.delete_outline), onPressed: x['used'] == true || '${x['used']}' == '1' ? null : () => removeShift(x))]),
                  ),
                )),
              ],
            ),
          ),
          _definitionCard(
            icon: Icons.playlist_add_check_circle_outlined,
            title: 'Aktif / Planlı Vardiya Kayıtları',
            subtitle: '${regularWorks.length} çalışma',
            expanded: true,
            child: Column(children: [
              if (regularWorks.isEmpty) const Padding(padding: EdgeInsets.all(12), child: Text('Kayıtlı vardiya çalışması bulunmuyor.', style: TextStyle(color: MTheme.muted))),
              ...regularWorks.map((x) => _shiftWorkCard(x, temporary: false)),
            ]),
          ),
          _definitionCard(
            icon: Icons.swap_horizontal_circle_outlined,
            title: 'Geçici Vardiya Aktarımları',
            subtitle: '${temporaryWorks.length} kayıt',
            child: Column(children: [
              if (temporaryWorks.isEmpty) const Padding(padding: EdgeInsets.all(12), child: Text('Geçici vardiya aktarımı bulunmuyor.', style: TextStyle(color: MTheme.muted))),
              ...temporaryWorks.map((x) => _shiftWorkCard(x, temporary: true)),
            ]),
          ),
        ],
      ),
    );
  }
}
