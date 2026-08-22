import 'package:flutter/material.dart';
import '../core/app_state.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key, required this.state});
  final AppState state;

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  int year = DateTime.now().year;
  int month = DateTime.now().month;
  List rows = [];
  final search = TextEditingController();
  late final TextEditingController yearController;

  @override
  void initState() {
    super.initState();
    yearController = TextEditingController(text: '$year');
    load();
  }

  @override
  void dispose() {
    search.dispose();
    yearController.dispose();
    super.dispose();
  }

  Future<void> load() async {
    final r = await widget.state.api.request(
      'reports/monthly',
      query: {'year': year, 'month': month, 'search': search.text},
    );
    if (mounted) setState(() => rows = (r['rows'] ?? []) as List);
  }

  @override
  Widget build(BuildContext context) {
    const statusLabels = <String, String>{
      'present': 'Geldi',
      'late_entry': 'Geç Giriş',
      'early_exit': 'Erken Çıkış',
      'absent': 'Gelmedi',
      'weekly_off': 'Hafta Tatili',
      'annual_leave': 'Yıllık İzin',
      'paid_leave': 'Ücretli İzin',
      'unpaid_leave': 'Ücretsiz İzin',
      'sick': 'Raporlu',
    };

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      keyboardType: TextInputType.number,
                      controller: yearController,
                      decoration: const InputDecoration(labelText: 'Yıl'),
                      onSubmitted: (v) {
                        year = int.tryParse(v) ?? year;
                        yearController.text = '$year';
                        load();
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      value: month,
                      decoration: const InputDecoration(labelText: 'Ay'),
                      items: List.generate(12, (i) => DropdownMenuItem(value: i + 1, child: Text('${i + 1}'))),
                      onChanged: (v) {
                        if (v == null) return;
                        setState(() => month = v);
                        load();
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TextField(
                controller: search,
                onSubmitted: (_) => load(),
                decoration: InputDecoration(
                  labelText: 'Personel ara',
                  suffixIcon: IconButton(onPressed: load, icon: const Icon(Icons.filter_alt_outlined)),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: rows.length,
            itemBuilder: (_, i) {
              final x = rows[i];
              return Card(
                margin: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                child: ExpansionTile(
                  title: Text('${x['first_name']} ${x['last_name']}', style: const TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: Text('${x['employee_no']} · Hesaplanan: ${x['calculated_days'] ?? 0} gün'),
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                      child: Wrap(
                        spacing: 7,
                        runSpacing: 7,
                        children: [
                          ...statusLabels.entries.map((e) => Chip(label: Text('${e.value}: ${x[e.key] ?? 0}'))),
                          Chip(label:Text('Vardiya: ${x['shift_names'] ?? '-'}')),
                          Chip(label:Text('Toplam Geç: ${x['late_minutes'] ?? 0} dk')),
                          Chip(label:Text('Toplam Erken: ${x['early_leave_minutes'] ?? 0} dk')),
                          Chip(label:Text('Eksik Çalışma: ${x['missing_work_minutes'] ?? 0} dk')),
                          Chip(label:Text('Fazla Çalışma: ${x['overtime_minutes'] ?? 0} dk')),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
