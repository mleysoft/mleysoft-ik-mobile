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
  final icons = [Icons.dashboard_outlined, Icons.badge_outlined, Icons.fact_check_outlined, Icons.beach_access_outlined, Icons.payments_outlined, Icons.assessment_outlined, Icons.tune_outlined];

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('MleySoft İK', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)), Text(widget.state.company?['company_name'] ?? '', style: const TextStyle(fontSize: 10, color: Colors.white70))]),
          actions: [
            PopupMenuButton<String>(
              icon: const Icon(Icons.account_circle_outlined),
              onSelected: (v) async {
                if (v == 'account') Navigator.push(context, MaterialPageRoute(builder: (_) => AccountScreen(state: widget.state)));
                if (v == 'companies') Navigator.push(context, MaterialPageRoute(builder: (_) => CompanyAdminScreen(state: widget.state)));
                if (v == 'logout') widget.state.logout();
              },
              itemBuilder: (_) => [
                PopupMenuItem(enabled: false, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(widget.state.user?['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.w700)), Text(widget.state.user?['role'] == 'super_admin' ? 'Sistem Yöneticisi' : 'Firma Yöneticisi', style: const TextStyle(fontSize: 11))])),
                const PopupMenuItem(value: 'account', child: Text('Hesap ve Güvenlik')),
                if (widget.state.isSuper) const PopupMenuItem(value: 'companies', child: Text('Firma Yönetimi')),
                const PopupMenuItem(value: 'logout', child: Text('Çıkış Yap')),
              ],
            ),
          ],
        ),
        body: SafeArea(child: AnimatedSwitcher(duration: const Duration(milliseconds: 260), switchInCurve: Curves.easeOutCubic, switchOutCurve: Curves.easeInCubic, child: KeyedSubtree(key: ValueKey(index), child: pages[index]))),
        bottomNavigationBar: NavigationBar(
          height: 72,
          selectedIndex: index,
          onDestinationSelected: (i) { if(i==index)return; MleyLoadingController.instance.transition('Sayfa hazırlanıyor...'); setState(() => index = i); },
          indicatorColor: MTheme.lime,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          destinations: List.generate(labels.length, (i) => NavigationDestination(icon: Icon(icons[i]), label: labels[i])),
        ),
      );
}
