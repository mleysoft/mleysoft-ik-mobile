import 'package:flutter/material.dart';
import '../core/app_state.dart';

class HrErpScreen extends StatefulWidget {
  const HrErpScreen({super.key, required this.state});
  final AppState state;

  @override
  State<HrErpScreen> createState() => _HrErpScreenState();
}

class _HrErpScreenState extends State<HrErpScreen> {
  Map<String, dynamic> counts = {};
  bool loading = true;
  String? error;

  final Map<String, String> labels = const {
    'documents': 'Özlük Belgeleri',
    'assets': 'Zimmet',
    'trainings': 'Eğitim',
    'performance': 'Performans',
    'onboarding': 'On/Offboarding',
    'discipline': 'Disiplin / Tutanak',
    'expenses': 'Masraf',
    'candidates': 'Aday Havuzu',
  };

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    try {
      final r = await widget.state.api.request('hr/overview');
      if (!mounted) return;
      setState(() {
        counts = Map<String, dynamic>.from(r['counts'] ?? {});
        loading = false;
        error = null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        error = 'İK verileri şu anda yüklenemedi. Lütfen tekrar deneyin.';
        loading = false;
      });
    }
  }

  Future<void> openList(String type) async {
    try {
      final r = await widget.state.api.request(
        'hr/list',
        query: {'type': type, 'page': '1', 'per_page': '20'},
      );
      final items = (r['items'] ?? []) as List;
      if (!mounted) return;

      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        builder: (sheetContext) {
          return DraggableScrollableSheet(
            expand: false,
            initialChildSize: .75,
            maxChildSize: .92,
            builder: (_, scrollController) {
              return ListView(
                controller: scrollController,
                padding: const EdgeInsets.all(18),
                children: [
                  Text(
                    labels[type] ?? 'İK Kayıtları',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  if (items.isEmpty)
                    const Text('Henüz kayıt bulunmuyor.'),
                  ...items.map(
                    (raw) {
                      final x = Map<String, dynamic>.from(raw);
                      return Card(
                        child: ListTile(
                          title: Text(
                            '${x['title'] ?? x['name'] ?? x['full_name'] ?? x['category'] ?? 'Kayıt'}',
                          ),
                          subtitle: Text(_summary(x)),
                        ),
                      );
                    },
                  ),
                ],
              );
            },
          );
        },
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Kayıtlar yüklenemedi. Lütfen tekrar deneyin.'),
        ),
      );
    }
  }

  String _summary(Map<String, dynamic> x) {
    return x.entries
        .where(
          (e) =>
              !['id', 'company_id', 'storage_path'].contains(e.key) &&
              e.value != null &&
              '${e.value}'.isNotEmpty,
        )
        .take(3)
        .map((e) => '${e.key}: ${e.value}')
        .join(' • ');
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
                    child: Text(error!),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: load,
                  child: GridView.count(
                    crossAxisCount:
                        MediaQuery.sizeOf(context).width > 650 ? 3 : 2,
                    padding: const EdgeInsets.all(16),
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    children: labels.entries
                        .map(
                          (e) => InkWell(
                            onTap: () => openList(e.key),
                            borderRadius: BorderRadius.circular(18),
                            child: Card(
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      '${counts[e.key] ?? 0}',
                                      style: const TextStyle(
                                        fontSize: 30,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      e.value,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
    );
  }
}
