import 'package:flutter/material.dart';
import '../core/app_state.dart';
import '../core/theme.dart';
import '../widgets/common.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key, required this.state});
  final AppState state;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Map<String, dynamic>? data;
  String? error;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    try {
      final result = await widget.state.api.request('dashboard');
      if (mounted) {
        setState(() {
          data = result;
          error = null;
        });
      }
    } catch (e) {
      if (mounted) setState(() => error = '$e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (data == null) {
      return Center(
        child: error != null
            ? Padding(
                padding: const EdgeInsets.all(24),
                child: Text(error!, textAlign: TextAlign.center),
              )
            : const CircularProgressIndicator(),
      );
    }

    final stats = Map<String, dynamic>.from(data!['stats'] ?? {});
    final today = Map<String, dynamic>.from(stats['today'] ?? {});
    final birthdays = (data!['birthdays'] ?? []) as List;

    final quick = <Widget>[
      StatCard(title: 'Aktif Personel', value: '${stats['active_employees'] ?? 0}', icon: Icons.groups_outlined),
      StatCard(title: 'Bugün Geldi', value: '${today['present'] ?? 0}', icon: Icons.check_circle_outline),
      StatCard(title: 'Bugün İzinli', value: '${stats['on_leave_today'] ?? 0}', icon: Icons.beach_access_outlined),
      StatCard(title: 'Bugün Gelmedi', value: '${today['absent'] ?? 0}', icon: Icons.person_off_outlined),
      StatCard(title: 'Maaşı Eksik', value: '${stats['missing_salary'] ?? 0}', icon: Icons.warning_amber_rounded),
      StatCard(title: 'Açık Avans', value: '${stats['open_advances'] ?? 0}', icon: Icons.payments_outlined),
    ];

    return RefreshIndicator(
      onRefresh: load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 28),
        children: [
          Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Genel Bakış', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
                    SizedBox(height: 3),
                    Text('Bugünkü İK durumunuz', style: TextStyle(color: MTheme.muted, fontSize: 12)),
                  ],
                ),
              ),
              IconButton.filledTonal(onPressed: load, icon: const Icon(Icons.refresh_rounded)),
            ],
          ),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1.52,
            children: quick,
          ),
          const SizedBox(height: 18),
          _monthPanel(stats),
          const SizedBox(height: 18),
          _shiftExpiryPanel((data!['shift_expiring'] ?? []) as List),
          const SizedBox(height: 18),
          _birthdayPanel(birthdays),
        ],
      ),
    );
  }

  Widget _monthPanel(Map<String, dynamic> stats) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF131D25), Color(0xFF1A2731)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(color: Color(0x22000000), blurRadius: 18, offset: Offset(0, 8)),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              ContainerIcon(icon: Icons.calendar_month_outlined),
              SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Bu Ay', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900)),
                    SizedBox(height: 2),
                    Text('Aylık işlem özeti', style: TextStyle(color: Colors.white54, fontSize: 11)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              _monthMetric('Puantaj', '${stats['month_attendance'] ?? 0}', Icons.fact_check_outlined),
              const SizedBox(width: 8),
              _monthMetric('İzin', '${stats['month_leaves'] ?? 0}', Icons.beach_access_outlined),
              const SizedBox(width: 8),
              _monthMetric('Pasif', '${stats['passive_employees'] ?? 0}', Icons.person_off_outlined),
            ],
          ),
        ],
      ),
    );
  }

  Widget _monthMetric(String title, String value, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 13),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: .06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withValues(alpha: .08)),
        ),
        child: Column(
          children: [
            Icon(icon, color: MTheme.lime, size: 20),
            const SizedBox(height: 7),
            Text(value, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900)),
            const SizedBox(height: 2),
            Text(title, style: const TextStyle(color: Colors.white60, fontSize: 10, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }


  Widget _shiftExpiryPanel(List items) {
    if (items.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: const Color(0xFFFFF7E6), borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFFF1D18A))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children:[const Icon(Icons.schedule_outlined,color:Color(0xFF9A6700)),const SizedBox(width:9),Expanded(child:Text('Vardiya Süresi Uyarısı · ${items.length}',style:const TextStyle(fontWeight:FontWeight.w900,fontSize:15)))]),
        const SizedBox(height:6),
        const Text('Önümüzdeki 7 gün içinde vardiya süresi bitecek personeller.',style:TextStyle(fontSize:11,color:MTheme.muted)),
        const SizedBox(height:10),
        ...items.take(5).map((x)=>Container(margin:const EdgeInsets.only(top:6),padding:const EdgeInsets.all(10),decoration:BoxDecoration(color:Colors.white,borderRadius:BorderRadius.circular(12)),child:Row(children:[Expanded(child:Text('${x['person_name']} · ${x['shift_name']}',style:const TextStyle(fontWeight:FontWeight.w700,fontSize:12))),Text('${x['end_date']}',style:const TextStyle(fontSize:10,color:MTheme.muted))]))),
      ]),
    );
  }

  Widget _birthdayPanel(List birthdays) {
    final hasBirthday = birthdays.isNotEmpty;
    return Container(
      decoration: BoxDecoration(
        color: hasBirthday ? const Color(0xFFF6FBE8) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: hasBirthday ? const Color(0xFFDDEAB5) : const Color(0xFFE2E7EA)),
        boxShadow: const [
          BoxShadow(color: Color(0x10000000), blurRadius: 14, offset: Offset(0, 6)),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: hasBirthday ? MTheme.lime : const Color(0xFFF0F3F5),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(Icons.cake_outlined, color: hasBirthday ? MTheme.ink : MTheme.muted),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Bugün Doğum Günü', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 2),
                    Text(
                      hasBirthday
                          ? '${birthdays.length} personel için kutlama zamanı'
                          : 'Bugün doğum günü kaydı bulunmuyor',
                      style: const TextStyle(fontSize: 11, color: MTheme.muted),
                    ),
                  ],
                ),
              ),
              if (hasBirthday)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                  decoration: BoxDecoration(color: MTheme.ink, borderRadius: BorderRadius.circular(20)),
                  child: Text('${birthdays.length}', style: const TextStyle(color: MTheme.lime, fontWeight: FontWeight.w900)),
                ),
            ],
          ),
          if (hasBirthday) ...[
            const SizedBox(height: 12),
            ...birthdays.map(
              (x) => Container(
                margin: const EdgeInsets.only(top: 7),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(13),
                  border: Border.all(color: const Color(0xFFE4E9D4)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.celebration_outlined, size: 20, color: MTheme.ink),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Text(
                        '${x['first_name']} ${x['last_name']}',
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                    Text('${x['employee_no'] ?? ''}', style: const TextStyle(fontSize: 10, color: MTheme.muted)),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class ContainerIcon extends StatelessWidget {
  const ContainerIcon({super.key, required this.icon});
  final IconData icon;

  @override
  Widget build(BuildContext context) => Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: MTheme.lime.withValues(alpha: .12),
          borderRadius: BorderRadius.circular(11),
        ),
        child: Icon(icon, color: MTheme.lime, size: 21),
      );
}
