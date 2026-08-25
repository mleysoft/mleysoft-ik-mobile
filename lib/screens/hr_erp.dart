import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../core/app_state.dart';
import '../core/api.dart';

class HrErpScreen extends StatefulWidget {
  const HrErpScreen({super.key, required this.state});
  final AppState state;

  @override
  State<HrErpScreen> createState() => _HrErpScreenState();
}

class _HrErpScreenState extends State<HrErpScreen> {
  Map<String, dynamic> counts = {};
  List<Map<String, dynamic>> employees = [];
  bool loading = true;
  String? error;

  static const labels = <String, String>{
    'documents': 'Özlük Belgeleri',
    'assets': 'Zimmet',
    'trainings': 'Eğitim',
    'performance': 'Performans',
    'onboarding': 'İşe Giriş / Çıkış',
    'discipline': 'Disiplin / Tutanak',
    'expenses': 'Masraf',
    'candidates': 'Aday Havuzu',
  };

  static const icons = <String, IconData>{
    'documents': Icons.folder_copy_outlined,
    'assets': Icons.devices_other_outlined,
    'trainings': Icons.school_outlined,
    'performance': Icons.trending_up_rounded,
    'onboarding': Icons.person_add_alt_1_outlined,
    'discipline': Icons.gavel_outlined,
    'expenses': Icons.receipt_long_outlined,
    'candidates': Icons.groups_2_outlined,
  };

  @override
  void initState() {
    super.initState();
    load();
  }

  String friendlyError(Object e) {
    if (e is ApiException) return e.message;
    return 'İşlem şu anda tamamlanamadı. Lütfen tekrar deneyin.';
  }

  Future<void> load() async {
    try {
      final results = await Future.wait([
        widget.state.api.request('hr/overview'),
        widget.state.api.request(
          'employees',
          query: {'status': 'active', 'page': '1', 'per_page': '100'},
        ),
      ]);
      if (!mounted) return;
      setState(() {
        counts = Map<String, dynamic>.from(results[0]['counts'] ?? {});
        employees = ((results[1]['employees'] ?? []) as List)
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
        loading = false;
        error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        error = friendlyError(e);
        loading = false;
      });
    }
  }

  Future<List<Map<String, dynamic>>> _loadItems(String type) async {
    final r = await widget.state.api.request(
      'hr/list',
      query: {'type': type, 'page': '1', 'per_page': '20'},
    );
    return ((r['items'] ?? []) as List)
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  String _statusLabel(String? value) {
    const map = {
      'assigned': 'Teslim Edildi',
      'returned': 'İade Edildi',
      'lost': 'Kayıp',
      'damaged': 'Hasarlı',
      'planned': 'Planlandı',
      'ongoing': 'Devam Ediyor',
      'completed': 'Tamamlandı',
      'cancelled': 'İptal Edildi',
      'draft': 'Taslak',
      'pending': 'Bekliyor',
      'approved': 'Onaylandı',
      'rejected': 'Reddedildi',
      'paid': 'Ödendi',
      'new': 'Yeni Başvuru',
      'screening': 'Ön Değerlendirme',
      'interview': 'Mülakat',
      'offer': 'Teklif',
      'hired': 'İşe Alındı',
      'onboarding': 'İşe Giriş',
      'offboarding': 'İşten Çıkış',
    };
    return map[value] ?? (value?.isNotEmpty == true ? value! : '-');
  }

  String _title(String type, Map<String, dynamic> x) {
    switch (type) {
      case 'documents':
        return '${x['title'] ?? 'Özlük Belgesi'}';
      case 'assets':
        return '${x['name'] ?? 'Zimmet'}';
      case 'trainings':
        return '${x['title'] ?? 'Eğitim'}';
      case 'performance':
        return '${x['review_year'] ?? ''} ${x['review_period'] ?? ''}'.trim();
      case 'onboarding':
        return '${x['title'] ?? 'Görev'}';
      case 'discipline':
        return '${x['title'] ?? 'Disiplin Kaydı'}';
      case 'expenses':
        return '${x['category'] ?? 'Masraf'}';
      case 'candidates':
        return '${x['full_name'] ?? 'Aday'}';
      default:
        return 'Kayıt';
    }
  }

  String _subtitle(String type, Map<String, dynamic> x) {
    final employee = '${x['employee_name'] ?? ''}'.trim();
    switch (type) {
      case 'documents':
        return [employee, x['category'], x['expires_at'] != null ? 'Geçerlilik: ${x['expires_at']}' : null]
            .where((e) => e != null && '$e'.trim().isNotEmpty)
            .join(' • ');
      case 'assets':
        return [employee, x['asset_code'], x['serial_no']]
            .where((e) => e != null && '$e'.trim().isNotEmpty)
            .join(' • ');
      case 'trainings':
        return [employee, x['provider'], x['start_date']]
            .where((e) => e != null && '$e'.trim().isNotEmpty)
            .join(' • ');
      case 'performance':
        return [employee, x['score'] != null ? 'Puan: ${x['score']}' : null]
            .where((e) => e != null && '$e'.trim().isNotEmpty)
            .join(' • ');
      case 'onboarding':
        return [employee, _statusLabel('${x['task_type'] ?? ''}'), x['due_date']]
            .where((e) => e != null && '$e'.trim().isNotEmpty)
            .join(' • ');
      case 'discipline':
        return [employee, x['record_type'], x['event_date']]
            .where((e) => e != null && '$e'.trim().isNotEmpty)
            .join(' • ');
      case 'expenses':
        final amount = x['amount'] == null ? null : '${x['amount']} ${x['currency'] ?? 'TRY'}';
        return [employee, amount, x['expense_date']]
            .where((e) => e != null && '$e'.trim().isNotEmpty)
            .join(' • ');
      case 'candidates':
        return [x['position_name'], x['phone'], x['email']]
            .where((e) => e != null && '$e'.trim().isNotEmpty)
            .join(' • ');
      default:
        return '';
    }
  }

  String? _statusValue(String type, Map<String, dynamic> x) {
    if (type == 'candidates') return '${x['stage'] ?? ''}';
    if (type == 'onboarding') {
      return x['completed_at'] == null ? 'pending' : 'completed';
    }
    if (['assets', 'trainings', 'performance', 'expenses'].contains(type)) {
      return '${x['status'] ?? ''}';
    }
    return null;
  }

  Future<void> _openRecords(String type) async {
    try {
      var items = await _loadItems(type);
      if (!mounted) return;

      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        backgroundColor: Colors.transparent,
        builder: (sheetContext) {
          return StatefulBuilder(
            builder: (context, setSheetState) {
              Future<void> reload() async {
                final fresh = await _loadItems(type);
                if (context.mounted) setSheetState(() => items = fresh);
                await load();
              }

              return Container(
                decoration: const BoxDecoration(
                  color: Color(0xFFF7F8FA),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                ),
                child: DraggableScrollableSheet(
                  expand: false,
                  initialChildSize: .88,
                  minChildSize: .55,
                  maxChildSize: .96,
                  builder: (_, scrollController) {
                    return Column(
                      children: [
                        const SizedBox(height: 10),
                        Container(
                          width: 42,
                          height: 5,
                          decoration: BoxDecoration(
                            color: Colors.black26,
                            borderRadius: BorderRadius.circular(99),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 18, 14, 12),
                          child: Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEAF6C7),
                                  borderRadius: BorderRadius.circular(13),
                                ),
                                child: Icon(icons[type], color: const Color(0xFF4B6400)),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      labels[type] ?? 'İK Kayıtları',
                                      style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w800),
                                    ),
                                    Text(
                                      '${items.length} kayıt gösteriliyor',
                                      style: const TextStyle(color: Colors.black54, fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),
                              FilledButton.icon(
                                onPressed: () async {
                                  final changed = await _openForm(type, null);
                                  if (changed == true) await reload();
                                },
                                icon: const Icon(Icons.add_rounded, size: 18),
                                label: const Text('Yeni'),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: items.isEmpty
                              ? const Center(
                                  child: Text(
                                    'Henüz kayıt bulunmuyor.',
                                    style: TextStyle(color: Colors.black54),
                                  ),
                                )
                              : ListView.separated(
                                  controller: scrollController,
                                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                                  itemCount: items.length,
                                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                                  itemBuilder: (_, index) {
                                    final item = items[index];
                                    final status = _statusValue(type, item);
                                    return Container(
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(18),
                                        border: Border.all(color: const Color(0xFFE3E7EA)),
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.all(15),
                                        child: Row(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Container(
                                              width: 38,
                                              height: 38,
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFF0F3F5),
                                                borderRadius: BorderRadius.circular(11),
                                              ),
                                              child: Icon(icons[type], size: 20, color: const Color(0xFF53616A)),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    _title(type, item),
                                                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                                                  ),
                                                  const SizedBox(height: 5),
                                                  if (_subtitle(type, item).isNotEmpty)
                                                    Text(
                                                      _subtitle(type, item),
                                                      style: const TextStyle(
                                                        color: Color(0xFF69767E),
                                                        fontSize: 12.5,
                                                        height: 1.35,
                                                      ),
                                                    ),
                                                  if (status != null && status.isNotEmpty) ...[
                                                    const SizedBox(height: 8),
                                                    Container(
                                                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                                                      decoration: BoxDecoration(
                                                        color: const Color(0xFFEEF6D7),
                                                        borderRadius: BorderRadius.circular(99),
                                                      ),
                                                      child: Text(
                                                        _statusLabel(status),
                                                        style: const TextStyle(
                                                          color: Color(0xFF536B0E),
                                                          fontSize: 11,
                                                          fontWeight: FontWeight.w700,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ],
                                              ),
                                            ),
                                            PopupMenuButton<String>(
                                              tooltip: 'İşlemler',
                                              onSelected: (action) async {
                                                if (action == 'edit') {
                                                  final changed = await _openForm(type, item);
                                                  if (changed == true) await reload();
                                                } else if (action == 'delete') {
                                                  final ok = await showDialog<bool>(
                                                    context: context,
                                                    builder: (d) => AlertDialog(
                                                      title: const Text('Kaydı sil'),
                                                      content: const Text('Bu İK kaydı kalıcı olarak silinsin mi?'),
                                                      actions: [
                                                        TextButton(
                                                          onPressed: () => Navigator.pop(d, false),
                                                          child: const Text('Vazgeç'),
                                                        ),
                                                        FilledButton(
                                                          onPressed: () => Navigator.pop(d, true),
                                                          child: const Text('Sil'),
                                                        ),
                                                      ],
                                                    ),
                                                  );
                                                  if (ok == true) {
                                                    try {
                                                      await widget.state.api.request(
                                                        'hr/item',
                                                        method: 'DELETE',
                                                        query: {'type': type, 'id': item['id']},
                                                      );
                                                      if (context.mounted) {
                                                        ScaffoldMessenger.of(context).showSnackBar(
                                                          const SnackBar(content: Text('Kayıt silindi.')),
                                                        );
                                                      }
                                                      await reload();
                                                    } catch (e) {
                                                      if (context.mounted) {
                                                        ScaffoldMessenger.of(context).showSnackBar(
                                                          SnackBar(content: Text(friendlyError(e))),
                                                        );
                                                      }
                                                    }
                                                  }
                                                }
                                              },
                                              itemBuilder: (_) => const [
                                                PopupMenuItem(
                                                  value: 'edit',
                                                  child: ListTile(
                                                    dense: true,
                                                    contentPadding: EdgeInsets.zero,
                                                    leading: Icon(Icons.edit_outlined),
                                                    title: Text('Düzenle'),
                                                  ),
                                                ),
                                                PopupMenuItem(
                                                  value: 'delete',
                                                  child: ListTile(
                                                    dense: true,
                                                    contentPadding: EdgeInsets.zero,
                                                    leading: Icon(Icons.delete_outline, color: Colors.red),
                                                    title: Text('Sil'),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                        ),
                      ],
                    );
                  },
                ),
              );
            },
          );
        },
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(friendlyError(e))),
      );
    }
  }

  Future<bool?> _openForm(String type, Map<String, dynamic>? item) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => HrRecordFormSheet(
        state: widget.state,
        type: type,
        label: labels[type] ?? 'İK Kaydı',
        employees: employees,
        initial: item,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('İK ERP')),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.cloud_off_outlined, size: 42, color: Colors.black45),
                        const SizedBox(height: 12),
                        Text(error!, textAlign: TextAlign.center),
                        const SizedBox(height: 14),
                        FilledButton(onPressed: load, child: const Text('Tekrar Dene')),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: load,
                  child: GridView.count(
                    crossAxisCount: MediaQuery.sizeOf(context).width > 650 ? 3 : 2,
                    padding: const EdgeInsets.all(16),
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    children: labels.entries.map((e) {
                      return InkWell(
                        onTap: () => _openRecords(e.key),
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFFE2E6E9)),
                          ),
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(icons[e.key], color: const Color(0xFF536B0E)),
                              const Spacer(),
                              Text(
                                '${counts[e.key] ?? 0}',
                                style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w900),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                e.value,
                                style: const TextStyle(fontWeight: FontWeight.w700),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
    );
  }
}

class HrRecordFormSheet extends StatefulWidget {
  const HrRecordFormSheet({
    super.key,
    required this.state,
    required this.type,
    required this.label,
    required this.employees,
    this.initial,
  });

  final AppState state;
  final String type;
  final String label;
  final List<Map<String, dynamic>> employees;
  final Map<String, dynamic>? initial;

  @override
  State<HrRecordFormSheet> createState() => _HrRecordFormSheetState();
}

class _HrRecordFormSheetState extends State<HrRecordFormSheet> {
  final formKey = GlobalKey<FormState>();
  final c = <String, TextEditingController>{};
  int? employeeId;
  String status = '';
  String taskType = 'onboarding';
  String currency = 'TRY';
  String? pickedFileName;
  String? pickedBase64;
  bool saving = false;

  bool get editing => widget.initial != null;

  @override
  void initState() {
    super.initState();
    final x = widget.initial ?? {};
    employeeId = int.tryParse('${x['employee_id'] ?? ''}');
    status = _initialStatus(x);
    taskType = '${x['task_type'] ?? 'onboarding'}';
    currency = '${x['currency'] ?? 'TRY'}';
  }

  String _initialStatus(Map<String, dynamic> x) {
    if (widget.type == 'candidates') return '${x['stage'] ?? 'new'}';
    if (widget.type == 'onboarding') return x['completed_at'] == null ? 'pending' : 'completed';
    switch (widget.type) {
      case 'assets':
        return '${x['status'] ?? 'assigned'}';
      case 'trainings':
        return '${x['status'] ?? 'planned'}';
      case 'performance':
        return '${x['status'] ?? 'draft'}';
      case 'expenses':
        return '${x['status'] ?? 'pending'}';
      default:
        return '';
    }
  }

  TextEditingController controller(String key, [String fallback = '']) {
    return c.putIfAbsent(
      key,
      () => TextEditingController(text: '${widget.initial?[key] ?? fallback}'),
    );
  }

  @override
  void dispose() {
    for (final x in c.values) {
      x.dispose();
    }
    super.dispose();
  }

  Widget field(String key, String label, {bool required = false, TextInputType? keyboard, int maxLines = 1}) {
    return TextFormField(
      controller: controller(key),
      keyboardType: keyboard,
      maxLines: maxLines,
      decoration: InputDecoration(labelText: label),
      validator: required
          ? (v) => v == null || v.trim().isEmpty ? '$label zorunludur.' : null
          : null,
    );
  }

  Widget employeeField() {
    return DropdownButtonFormField<int>(
      value: employeeId,
      isExpanded: true,
      decoration: const InputDecoration(labelText: 'Personel'),
      items: widget.employees.map((e) {
        return DropdownMenuItem<int>(
          value: int.tryParse('${e['id']}'),
          child: Text(
            '${e['first_name'] ?? ''} ${e['last_name'] ?? ''} · ${e['employee_no'] ?? ''}',
            overflow: TextOverflow.ellipsis,
          ),
        );
      }).toList(),
      onChanged: (v) => setState(() => employeeId = v),
      validator: (v) => v == null ? 'Personel seçimi zorunludur.' : null,
    );
  }

  Widget dropdown(String label, String value, Map<String, String> options, ValueChanged<String> onChanged) {
    return DropdownButtonFormField<String>(
      value: options.containsKey(value) ? value : options.keys.first,
      decoration: InputDecoration(labelText: label),
      items: options.entries
          .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
          .toList(),
      onChanged: (v) {
        if (v != null) onChanged(v);
      },
    );
  }

  List<Widget> fields() {
    final out = <Widget>[];
    if (widget.type != 'candidates') {
      out.add(employeeField());
      out.add(const SizedBox(height: 12));
    }

    switch (widget.type) {
      case 'documents':
        out.addAll([
          field('category', 'Belge Kategorisi', required: true),
          const SizedBox(height: 12),
          field('title', 'Belge Başlığı', required: true),
          const SizedBox(height: 12),
          field('expires_at', 'Geçerlilik Tarihi (YYYY-AA-GG)'),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _pickFile,
            icon: const Icon(Icons.attach_file),
            label: Text(
              pickedFileName ?? (editing ? 'Dosyayı değiştirmek için seçin' : 'PDF / JPG / PNG seçin'),
            ),
          ),
        ]);
        break;
      case 'assets':
        out.addAll([
          field('asset_code', 'Zimmet Kodu', required: true),
          const SizedBox(height: 12),
          field('name', 'Demirbaş / Ekipman', required: true),
          const SizedBox(height: 12),
          field('serial_no', 'Seri No / IMEI / Plaka'),
          const SizedBox(height: 12),
          field('assigned_at', 'Teslim Tarihi (YYYY-AA-GG)'),
          const SizedBox(height: 12),
          field('returned_at', 'İade Tarihi (YYYY-AA-GG)'),
          const SizedBox(height: 12),
          dropdown('Durum', status, const {
            'assigned': 'Teslim Edildi',
            'returned': 'İade Edildi',
            'lost': 'Kayıp',
            'damaged': 'Hasarlı',
          }, (v) => setState(() => status = v)),
          const SizedBox(height: 12),
          field('notes', 'Not', maxLines: 3),
        ]);
        break;
      case 'trainings':
        out.addAll([
          field('title', 'Eğitim Adı', required: true),
          const SizedBox(height: 12),
          field('provider', 'Eğitim Sağlayıcısı'),
          const SizedBox(height: 12),
          field('start_date', 'Başlangıç Tarihi (YYYY-AA-GG)'),
          const SizedBox(height: 12),
          field('end_date', 'Bitiş Tarihi (YYYY-AA-GG)'),
          const SizedBox(height: 12),
          dropdown('Durum', status, const {
            'planned': 'Planlandı',
            'ongoing': 'Devam Ediyor',
            'completed': 'Tamamlandı',
            'cancelled': 'İptal Edildi',
          }, (v) => setState(() => status = v)),
          const SizedBox(height: 12),
          field('notes', 'Eğitim Notu', maxLines: 3),
        ]);
        break;
      case 'performance':
        out.addAll([
          field('review_year', 'Değerlendirme Yılı', required: true, keyboard: TextInputType.number),
          const SizedBox(height: 12),
          field('review_period', 'Dönem'),
          const SizedBox(height: 12),
          field('score', 'Puan (0-100)', keyboard: TextInputType.number),
          const SizedBox(height: 12),
          dropdown('Durum', status, const {
            'draft': 'Taslak',
            'completed': 'Tamamlandı',
          }, (v) => setState(() => status = v)),
          const SizedBox(height: 12),
          field('goals', 'Hedef Sonuçları', maxLines: 3),
          const SizedBox(height: 12),
          field('competencies', 'Yetkinlikler', maxLines: 3),
          const SizedBox(height: 12),
          field('manager_note', 'Yönetici Görüşü', maxLines: 3),
        ]);
        break;
      case 'onboarding':
        out.addAll([
          dropdown('Süreç', taskType, const {
            'onboarding': 'İşe Giriş',
            'offboarding': 'İşten Çıkış',
          }, (v) => setState(() => taskType = v)),
          const SizedBox(height: 12),
          field('title', 'Görev', required: true),
          const SizedBox(height: 12),
          field('due_date', 'Termin Tarihi (YYYY-AA-GG)'),
          const SizedBox(height: 12),
          dropdown('Durum', status, const {
            'pending': 'Bekliyor',
            'completed': 'Tamamlandı',
          }, (v) => setState(() => status = v)),
          const SizedBox(height: 12),
          field('notes', 'Not', maxLines: 3),
        ]);
        break;
      case 'discipline':
        out.addAll([
          field('event_date', 'Olay / Belge Tarihi (YYYY-AA-GG)', required: true),
          const SizedBox(height: 12),
          field('record_type', 'Kayıt Türü', required: true),
          const SizedBox(height: 12),
          field('title', 'Başlık', required: true),
          const SizedBox(height: 12),
          field('detail', 'Açıklama', maxLines: 4),
        ]);
        break;
      case 'expenses':
        out.addAll([
          field('expense_date', 'Masraf Tarihi (YYYY-AA-GG)', required: true),
          const SizedBox(height: 12),
          field('category', 'Kategori', required: true),
          const SizedBox(height: 12),
          field('amount', 'Tutar', required: true, keyboard: const TextInputType.numberWithOptions(decimal: true)),
          const SizedBox(height: 12),
          dropdown('Para Birimi', currency, const {
            'TRY': 'TRY',
            'USD': 'USD',
            'EUR': 'EUR',
          }, (v) => setState(() => currency = v)),
          const SizedBox(height: 12),
          dropdown('Durum', status, const {
            'pending': 'Bekliyor',
            'approved': 'Onaylandı',
            'rejected': 'Reddedildi',
            'paid': 'Ödendi',
          }, (v) => setState(() => status = v)),
          const SizedBox(height: 12),
          field('description', 'Açıklama', maxLines: 3),
        ]);
        break;
      case 'candidates':
        out.addAll([
          field('full_name', 'Ad Soyad', required: true),
          const SizedBox(height: 12),
          field('phone', 'Telefon'),
          const SizedBox(height: 12),
          field('email', 'E-posta', keyboard: TextInputType.emailAddress),
          const SizedBox(height: 12),
          field('position_name', 'Başvurduğu Pozisyon'),
          const SizedBox(height: 12),
          dropdown('Süreç Aşaması', status, const {
            'new': 'Yeni Başvuru',
            'screening': 'Ön Değerlendirme',
            'interview': 'Mülakat',
            'offer': 'Teklif',
            'hired': 'İşe Alındı',
            'rejected': 'Olumsuz',
          }, (v) => setState(() => status = v)),
          const SizedBox(height: 12),
          field('notes', 'İK Notu', maxLines: 4),
        ]);
        break;
    }
    return out;
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['pdf', 'jpg', 'jpeg', 'png'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;
    final file = result.files.first;
    if (file.bytes == null) return;
    setState(() {
      pickedFileName = file.name;
      pickedBase64 = base64Encode(file.bytes!);
    });
  }

  Map<String, dynamic> payload() {
    final data = <String, dynamic>{'type': widget.type};
    for (final entry in c.entries) {
      data[entry.key] = entry.value.text.trim();
    }
    if (widget.type != 'candidates') data['employee_id'] = employeeId;
    if (['assets', 'trainings', 'performance', 'expenses'].contains(widget.type)) {
      data['status'] = status;
    }
    if (widget.type == 'candidates') data['stage'] = status;
    if (widget.type == 'onboarding') {
      data['task_type'] = taskType;
      data['status'] = status;
    }
    if (widget.type == 'expenses') data['currency'] = currency;
    if (widget.type == 'documents' && pickedBase64 != null) {
      data['file_base64'] = pickedBase64;
      data['file_name'] = pickedFileName;
    }
    return data;
  }

  Future<void> save() async {
    if (!formKey.currentState!.validate()) return;
    if (widget.type == 'documents' && !editing && pickedBase64 == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Yeni özlük belgesi için dosya seçiniz.')),
      );
      return;
    }
    setState(() => saving = true);
    try {
      await widget.state.api.request(
        'hr/item',
        method: editing ? 'PUT' : 'POST',
        query: editing
            ? {'type': widget.type, 'id': widget.initial!['id']}
            : {'type': widget.type},
        data: payload(),
      );
      if (!mounted) return;
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(editing ? 'Kayıt güncellendi.' : 'Kayıt oluşturuldu.')),
      );
    } catch (e) {
      if (!mounted) return;
      final message = e is ApiException
          ? e.message
          : 'İşlem tamamlanamadı. Lütfen tekrar deneyin.';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFF7F8FA),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: .92,
        maxChildSize: .97,
        minChildSize: .65,
        builder: (_, scrollController) {
          return Column(
            children: [
              const SizedBox(height: 10),
              Container(
                width: 42,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.black26,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 10, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            editing ? '${widget.label} Düzenle' : 'Yeni ${widget.label}',
                            style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            editing ? 'Kayıt bilgilerini güncelleyin.' : 'Yeni kayıt bilgilerini eksiksiz girin.',
                            style: const TextStyle(color: Colors.black54, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context, false),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: Form(
                  key: formKey,
                  child: ListView(
                    controller: scrollController,
                    padding: EdgeInsets.fromLTRB(
                      20,
                      18,
                      20,
                      24 + MediaQuery.viewInsetsOf(context).bottom,
                    ),
                    children: [
                      ...fields(),
                      const SizedBox(height: 24),
                      SizedBox(
                        height: 50,
                        child: FilledButton(
                          onPressed: saving ? null : save,
                          child: saving
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : Text(editing ? 'Değişiklikleri Kaydet' : 'Kaydı Oluştur'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
