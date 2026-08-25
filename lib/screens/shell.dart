import 'package:flutter/material.dart';
import '../core/app_state.dart';
import '../core/theme.dart';
import '../widgets/branded_loading.dart';
import 'account.dart';
import 'attendance.dart';
import 'company_admin.dart';
import 'dashboard.dart';
import 'employees.dart';
import 'leaves.dart';
import 'reports.dart';
import 'salaries.dart';
import 'settings.dart';
import 'hr_erp.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key, required this.state});
  final AppState state;
  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int index = 0;
  late final pages = [
    DashboardScreen(state: widget.state),
    EmployeesScreen(state: widget.state),
    AttendanceScreen(state: widget.state),
    LeavesScreen(state: widget.state),
    SalariesScreen(state: widget.state),
    ReportsScreen(state: widget.state),
    SettingsScreen(state: widget.state),
  ];
  final labels = ['Giriş', 'Personel', 'Puantaj', 'İzin', 'Maaş', 'Rapor', 'Tanımlar'];
  final icons = [
    Icons.dashboard_customize_outlined,
    Icons.badge_outlined,
    Icons.fact_check_outlined,
    Icons.event_available_outlined,
    Icons.account_balance_wallet_outlined,
    Icons.analytics_outlined,
    Icons.tune_outlined,
  ];

  final selectedIcons = [
    Icons.dashboard_customize_rounded,
    Icons.badge_rounded,
    Icons.fact_check_rounded,
    Icons.event_available_rounded,
    Icons.account_balance_wallet_rounded,
    Icons.analytics_rounded,
    Icons.tune_rounded,
  ];

  Future<void> logout() async {
    MleyLoadingController.instance.reset();
    await widget.state.logout();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          toolbarHeight: 68,
          titleSpacing: 16,
          title: Row(children: [
            Container(
              width: 40,
              height: 40,
              padding: const EdgeInsets.all(2.5),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 8, offset: Offset(0, 2))],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.asset('assets/images/mleysoft-ik-app-icon.png', fit: BoxFit.cover),
              ),
            ),
            const SizedBox(width: 11),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('MleySoft İK', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900)),
              Text(widget.state.company?['company_name'] ?? '', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 9.5, color: Colors.white60)),
            ])),
          ]),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: PopupMenuButton<String>(
                icon: Container(width: 38, height: 38, decoration: BoxDecoration(color: Colors.white.withValues(alpha: .08), borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.person_outline_rounded, size: 21)),
                onSelected: (v) async {
                  if (v == 'account' && mounted) {
                    Navigator.push(context, PageRouteBuilder(
                      transitionDuration: const Duration(milliseconds: 280),
                      pageBuilder: (_, a, __) => FadeTransition(opacity: a, child: AccountScreen(state: widget.state)),
                    ));
                  }
                  if (v == 'hr' && mounted) Navigator.push(context, MaterialPageRoute(builder: (_) => HrErpScreen(state: widget.state)));
                  if (v == 'companies' && mounted) Navigator.push(context, MaterialPageRoute(builder: (_) => CompanyAdminScreen(state: widget.state)));
                  if (v == 'logout') await logout();
                },
                itemBuilder: (_) => [
                  PopupMenuItem(enabled: false, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(widget.state.user?['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.w800)),
                    Text(widget.state.user?['role'] == 'super_admin' ? 'Sistem Yöneticisi' : 'Firma Yöneticisi', style: const TextStyle(fontSize: 10.5, color: MTheme.muted)),
                  ])),
                  const PopupMenuDivider(),
                  const PopupMenuItem(value: 'account', child: Text('Hesap ve Güvenlik')),
                  const PopupMenuItem(value: 'hr', child: Text('İK ERP')),
                  if (widget.state.isSuper) const PopupMenuItem(value: 'companies', child: Text('Firma Yönetimi')),
                  const PopupMenuItem(value: 'logout', child: Text('Çıkış Yap')),
                ],
              ),
            ),
          ],
        ),
        body: SafeArea(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            transitionBuilder: (child, animation) => FadeTransition(
              opacity: animation,
              child: SlideTransition(position: Tween<Offset>(begin: const Offset(.025, 0), end: Offset.zero).animate(animation), child: child),
            ),
            child: KeyedSubtree(key: ValueKey(index), child: pages[index]),
          ),
        ),
        bottomNavigationBar: Container(
          decoration: const BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Color(0x160A1720), blurRadius: 20, offset: Offset(0, -5))]),
          child: NavigationBar(
            selectedIndex: index,
            onDestinationSelected: (i) {
              if (i == index) return;
              MleyLoadingController.instance.transition('Sayfa hazırlanıyor...');
              setState(() => index = i);
            },
            labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
            destinations: List.generate(
              labels.length,
              (i) => NavigationDestination(
                icon: Icon(icons[i]),
                selectedIcon: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(color: MTheme.lime, borderRadius: BorderRadius.circular(11)),
                  child: Icon(selectedIcons[i], color: MTheme.ink, size: 21),
                ),
                label: labels[i],
              ),
            ),
          ),
        ),
      );
}
