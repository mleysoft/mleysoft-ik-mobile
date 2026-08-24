import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/app_state.dart';
import 'common.dart';

class EmployeeFormSheet extends StatefulWidget {
  const EmployeeFormSheet({super.key, required this.state, this.employee});
  final AppState state;
  final Map<String, dynamic>? employee;

  static Future<bool?> open(BuildContext context, AppState state, {Map<String, dynamic>? employee}) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => EmployeeFormSheet(state: state, employee: employee),
    );
  }

  @override
  State<EmployeeFormSheet> createState() => _EmployeeFormSheetState();
}

class _EmployeeFormSheetState extends State<EmployeeFormSheet> with SingleTickerProviderStateMixin {
  late final TabController tabs;
  final formKey = GlobalKey<FormState>();
  final fields = <String, TextEditingController>{};
  List departments = [];
  List positions = [];
  List businessUnits = [];
  int? businessUnitId;
  bool busy = false;
  String gender = '';
  String marital = '';
  String blood = '';
  String disability = '0';
  String status = 'active';
  String department = '';
  String position = '';
  DateTime? birthDate;
  DateTime? startDate;
  DateTime? endDate;

  bool get editing => widget.employee != null;

  TextEditingController c(String key) => fields.putIfAbsent(key, () => TextEditingController(text: '${widget.employee?[key] ?? ''}'));

  @override
  void initState() {
    super.initState();
    tabs = TabController(length: 4, vsync: this);
    final e = widget.employee ?? {};
    gender = '${e['gender'] ?? ''}';
    marital = '${e['marital_status'] ?? ''}';
    blood = '${e['blood_type'] ?? ''}';
    disability = '${e['disability_status'] ?? 0}';
    status = '${e['status'] ?? 'active'}';
    department = '${e['department'] ?? ''}';
    position = '${e['position'] ?? ''}';
    businessUnitId = int.tryParse('${e['business_unit_id'] ?? ''}');
    birthDate = DateTime.tryParse('${e['birth_date'] ?? ''}');
    startDate = DateTime.tryParse('${e['start_date'] ?? ''}') ?? DateTime(DateTime.now().year, DateTime.now().month, 1);
    endDate = DateTime.tryParse('${e['end_date'] ?? ''}');
    loadDefinitions();
  }

  @override
  void dispose() {
    tabs.dispose();
    for (final x in fields.values) x.dispose();
    super.dispose();
  }

  Future<void> loadDefinitions() async {
    try {
      final r = await widget.state.api.request('definitions');
      if (!mounted) return;
      setState(() {
        departments = (r['departments'] ?? []) as List;
        positions = (r['positions'] ?? []) as List;
        businessUnits = (r['business_units'] ?? []) as List;
        businessUnitId ??= businessUnits.isNotEmpty ? int.tryParse('${businessUnits.first['id']}') : null;
      });
    } catch (_) {}
  }

  Future<void> chooseDate(String key) async {
    final initial = key == 'birth' ? (birthDate ?? DateTime(1990, 1, 1)) : key == 'start' ? (startDate ?? DateTime.now()) : (endDate ?? DateTime.now());
    final d = await showDatePicker(context: context, initialDate: initial, firstDate: DateTime(1940), lastDate: DateTime(2100));
    if (d == null) return;
    setState(() {
      if (key == 'birth') birthDate = d;
      if (key == 'start') startDate = d;
      if (key == 'end') endDate = d;
    });
  }

  String? date(DateTime? d) => d == null ? null : DateFormat('yyyy-MM-dd').format(d);

  Future<void> save() async {
    if (!(formKey.currentState?.validate() ?? false)) return;
    setState(() => busy = true);
    final data = <String, dynamic>{
      'business_unit_id': businessUnitId,
      'first_name': c('first_name').text.trim(),
      'last_name': c('last_name').text.trim(),
      'national_id': c('national_id').text.trim(),
      'birth_date': date(birthDate),
      'birth_place': c('birth_place').text.trim(),
      'gender': gender.isEmpty ? null : gender,
      'marital_status': marital.isEmpty ? null : marital,
      'blood_type': blood.isEmpty ? null : blood,
      'disability_status': disability == '1' ? 1 : 0,
      'disability_rate': disability == '1' ? c('disability_rate').text.trim() : null,
      'phone': c('phone').text.trim(),
      'email': c('email').text.trim(),
      'address': c('address').text.trim(),
      'emergency_contact_name': c('emergency_contact_name').text.trim(),
      'emergency_contact_phone': c('emergency_contact_phone').text.trim(),
      'department': department.isEmpty ? null : department,
      'position': position.isEmpty ? null : position,
      'start_date': date(startDate),
      'end_date': date(endDate),
      'status': status,
      'education': c('education').text.trim(),
      'bank_iban': c('bank_iban').text.trim(),
      'notes': c('notes').text.trim(),
    };
    try {
      if (editing) {
        data['id'] = widget.employee!['id'];
        await widget.state.api.request('employee', method: 'PUT', query: {'id': widget.employee!['id']}, data: data);
      } else {
        data['start_date_changed'] = false;
        await widget.state.api.request('employees', method: 'POST', data: data);
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) snack(context, '$e', error: true);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Widget textField(String key, String label, {bool required = false, TextInputType? keyboard, int maxLines = 1}) => TextFormField(
        controller: c(key),
        keyboardType: keyboard,
        maxLines: maxLines,
        validator: required ? (v) => (v ?? '').trim().isEmpty ? '$label zorunludur.' : null : null,
        decoration: InputDecoration(labelText: label),
      );

  Widget dateTile(String label, DateTime? value, String key, {bool clearable = false}) => InkWell(
        onTap: () => chooseDate(key),
        borderRadius: BorderRadius.circular(12),
        child: InputDecorator(
          decoration: InputDecoration(labelText: label, suffixIcon: Row(mainAxisSize: MainAxisSize.min, children: [if (clearable && value != null) IconButton(onPressed: () => setState(() { if (key == 'end') endDate = null; }), icon: const Icon(Icons.close, size: 18)), const Icon(Icons.calendar_month_outlined)])),
          child: Text(value == null ? 'Seçiniz' : DateFormat('dd.MM.yyyy').format(value)),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final no = '${widget.employee?['employee_no'] ?? 'Otomatik oluşturulacak'}';
    return Container(
      height: MediaQuery.sizeOf(context).height * .92,
      decoration: const BoxDecoration(color: Color(0xFFF5F7F8), borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      child: SafeArea(
        top: false,
        child: Form(
          key: formKey,
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.fromLTRB(18, 14, 10, 10),
                decoration: const BoxDecoration(color: Color(0xFF17212B), borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
                child: Row(children: [
                  const CircleAvatar(backgroundColor: Color(0xFFC9F400), foregroundColor: Color(0xFF17212B), child: Icon(Icons.badge_outlined)),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(editing ? 'Personel Bilgilerini Düzenle' : 'Yeni Personel Kaydı', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)), Text('Sicil / Personel No: $no', style: const TextStyle(color: Colors.white60, fontSize: 11))])),
                  IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close, color: Colors.white)),
                ]),
              ),
              Material(
                color: Colors.white,
                child: TabBar(
                  controller: tabs,
                  isScrollable: true,
                  tabAlignment: TabAlignment.start,
                  tabs: const [Tab(text: 'Temel Bilgiler'), Tab(text: 'Kişisel / İletişim'), Tab(text: 'Çalışma'), Tab(text: 'Diğer')],
                ),
              ),
              Expanded(
                child: TabBarView(
                  controller: tabs,
                  children: [
                    _scroll([
                      textField('first_name', 'Ad', required: true),
                      textField('last_name', 'Soyad', required: true),
                      textField('national_id', 'T.C. Kimlik No', keyboard: TextInputType.number),
                      dateTile('Doğum Tarihi', birthDate, 'birth'),
                      DropdownButtonFormField<String>(value: gender, decoration: const InputDecoration(labelText: 'Cinsiyet'), items: const [DropdownMenuItem(value: '', child: Text('Seçiniz')), DropdownMenuItem(value: 'male', child: Text('Erkek')), DropdownMenuItem(value: 'female', child: Text('Kadın')), DropdownMenuItem(value: 'other', child: Text('Diğer'))], onChanged: (v) => setState(() => gender = v ?? '')),
                      DropdownButtonFormField<String>(value: marital, decoration: const InputDecoration(labelText: 'Medeni Durum'), items: const [DropdownMenuItem(value: '', child: Text('Seçiniz')), DropdownMenuItem(value: 'single', child: Text('Bekar')), DropdownMenuItem(value: 'married', child: Text('Evli')), DropdownMenuItem(value: 'other', child: Text('Diğer'))], onChanged: (v) => setState(() => marital = v ?? '')),
                      dateTile('İşe Giriş Tarihi', startDate, 'start'),
                      dateTile('İşten Ayrılma Tarihi', endDate, 'end', clearable: true),
                    ]),
                    _scroll([
                      textField('birth_place', 'Doğum Yeri'),
                      DropdownButtonFormField<String>(value: blood, decoration: const InputDecoration(labelText: 'Kan Grubu'), items: ['', 'A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', '0+', '0-'].map((x) => DropdownMenuItem(value: x, child: Text(x.isEmpty ? 'Seçiniz' : x))).toList(), onChanged: (v) => setState(() => blood = v ?? '')),
                      DropdownButtonFormField<String>(value: disability, decoration: const InputDecoration(labelText: 'Engelli Durumu'), items: const [DropdownMenuItem(value: '0', child: Text('Hayır')), DropdownMenuItem(value: '1', child: Text('Evet'))], onChanged: (v) => setState(() => disability = v ?? '0')),
                      if (disability == '1') textField('disability_rate', 'Engel Oranı (%)', keyboard: TextInputType.number),
                      textField('phone', 'Telefon', keyboard: TextInputType.phone),
                      textField('email', 'E-posta', keyboard: TextInputType.emailAddress),
                      textField('address', 'Adres', maxLines: 2),
                      textField('emergency_contact_name', 'Acil Durum Kişisi'),
                      textField('emergency_contact_phone', 'Acil Durum Telefonu', keyboard: TextInputType.phone),
                    ]),
                    _scroll([
                      DropdownButtonFormField<int>(
                        value: businessUnitId,
                        decoration: const InputDecoration(labelText: 'Firma *'),
                        isExpanded: true,
                        items: businessUnits.map<DropdownMenuItem<int>>((x) => DropdownMenuItem(value: int.tryParse('${x['id']}'), child: Text('${x['unit_no']} · ${x['name']}'))).toList(),
                        onChanged: (v) => setState(() => businessUnitId = v),
                        validator: (v) => v == null ? 'Firma seçiniz.' : null,
                      ),
                      DropdownButtonFormField<String>(value: department.isEmpty ? null : department, decoration: const InputDecoration(labelText: 'Departman *'), isExpanded: true, items: departments.map<DropdownMenuItem<String>>((x) => DropdownMenuItem(value: '${x['name']}', child: Text('${x['name']}'))).toList(), onChanged: (v) => setState(() => department = v ?? ''), validator: (v) => (v ?? '').trim().isEmpty ? 'Departman seçiniz.' : null),
                      DropdownButtonFormField<String>(value: position.isEmpty ? null : position, decoration: const InputDecoration(labelText: 'Görev / Ünvan'), isExpanded: true, items: positions.map<DropdownMenuItem<String>>((x) => DropdownMenuItem(value: '${x['name']}', child: Text('${x['name']}'))).toList(), onChanged: (v) => setState(() => position = v ?? '')),
                      DropdownButtonFormField<String>(value: status, decoration: const InputDecoration(labelText: 'Personel Durumu'), items: const [DropdownMenuItem(value: 'active', child: Text('Aktif')), DropdownMenuItem(value: 'passive', child: Text('Pasif'))], onChanged: (v) => setState(() => status = v ?? 'active')),
                      textField('education', 'Eğitim Durumu'),
                    ]),
                    _scroll([
                      textField('bank_iban', 'IBAN'),
                      textField('notes', 'Notlar', maxLines: 5),
                    ]),
                  ],
                ),
              ),
              Container(
                color: Colors.white,
                padding: EdgeInsets.fromLTRB(16, 10, 16, MediaQuery.paddingOf(context).bottom + 10),
                child: Row(children: [Expanded(child: OutlinedButton(onPressed: busy ? null : () => Navigator.pop(context), child: const Text('Vazgeç'))), const SizedBox(width: 10), Expanded(flex: 2, child: FilledButton(onPressed: busy ? null : save, child: Text(busy ? 'Kaydediliyor...' : editing ? 'Değişiklikleri Kaydet' : 'Personeli Kaydet')))]),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _scroll(List<Widget> children) => SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(16, 16, 16, MediaQuery.viewInsetsOf(context).bottom + 20),
        child: LayoutBuilder(builder: (_, c) {
          final two = c.maxWidth > 620;
          if (!two) return Column(children: children.map((x) => Padding(padding: const EdgeInsets.only(bottom: 12), child: x)).toList());
          return Wrap(spacing: 12, runSpacing: 12, children: children.map((x) => SizedBox(width: (c.maxWidth - 12) / 2, child: x)).toList());
        }),
      );
}
