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
  late List<Widget> pages;

  @override
  void initState() {
    super.initState();
    _rebuildPages();
  }

  void _rebuildPages() {
    final companyId =
        int.tryParse('${widget.state.company?['id'] ?? 0}') ?? 0;

    // V166: Her modül seçili firmaya özel key alır.
    // Firma değiştiğinde Flutter eski StatefulWidget State'lerini yeniden
    // kullanamaz; eski firmanın dashboard/personel/puantaj cache'i anında
    // dispose edilir ve yeni ekranların initState/load() işlemleri sıfırdan başlar.
    pages = [
      DashboardScreen(
        key: ValueKey('dashboard-company-$companyId'),
        state: widget.state,
      ),
      EmployeesScreen(
        key: ValueKey('employees-company-$companyId'),
        state: widget.state,
      ),
      AttendanceScreen(
        key: ValueKey('attendance-company-$companyId'),
        state: widget.state,
      ),
      LeavesScreen(
        key: ValueKey('leaves-company-$companyId'),
        state: widget.state,
      ),
      SalariesScreen(
        key: ValueKey('salaries-company-$companyId'),
        state: widget.state,
      ),
      ReportsScreen(
        key: ValueKey('reports-company-$companyId'),
        state: widget.state,
      ),
      SettingsScreen(
        key: ValueKey('settings-company-$companyId'),
        state: widget.state,
      ),
    ];
  }
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

  Future<void> changeCompany() async {
    if (!widget.state.isSuper || !mounted) return;

    try {
      if (widget.state.companies.isEmpty) {
        await widget.state.refreshCompanies();
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e')),
      );
      return;
    }

    if (!mounted) return;

    // PopupMenu route'u tamamen kapansın. Popup'ın onSelected callback'i içinde
    // hemen yeni route açmak Flutter InheritedElement lifecycle'ı ile çakışabiliyor.
    await Future<void>.delayed(const Duration(milliseconds: 220));
    if (!mounted) return;

    final selectedId = await Navigator.of(context).push<int>(
      PageRouteBuilder<int>(
        opaque: true,
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
        pageBuilder: (_, __, ___) => _CompanySwitchScreen(
          state: widget.state,
        ),
      ),
    );

    if (selectedId == null || selectedId <= 0 || !mounted) return;

    try {
      // Seçim route'u sıfır transition ile tamamen kalktıktan sonra API context'i değişir.
      await WidgetsBinding.instance.endOfFrame;
      if (!mounted) return;

      await widget.state.selectCompanyInShell(selectedId);
      if (!mounted) return;

      // MaterialApp/AppState notify YOK. Mevcut Shell yalnız kendi child sayfalarını
      // yeni firma için yeniden üretir. Route, popup, dialog veya eski/new Shell overlap yok.
      await WidgetsBinding.instance.endOfFrame;
      if (!mounted) return;

      setState(() {
        // Önce Dashboard'a dön, ardından company-id key'leriyle tüm modül
        // widgetlarını yeniden oluştur. Dashboard'ın eski data State'i bu
        // frame'de kaldırılır; kullanıcı eski firma verisini görmez.
        index = 0;
        _rebuildPages();
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e')),
      );
    }
  }

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
                  if (v == 'companies' && mounted) {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => CompanyAdminScreen(state: widget.state)));
                  }
                  if (v == 'change_company' && mounted) {
                    // PopupMenu callback'i kendi route lifecycle'ını tamamlasın.
                    // Firma seçici ayrı async task olarak açılır.
                    Future<void>.delayed(
                      Duration.zero,
                      changeCompany,
                    );
                  }
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
                  if (widget.state.isSuper)
                    const PopupMenuItem(
                      value: 'change_company',
                      child: ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(Icons.swap_horiz_rounded),
                        title: Text('Firma Değiştir'),
                      ),
                    ),
                  if (widget.state.isSuper)
                    const PopupMenuItem(value: 'companies', child: Text('Firma Yönetimi')),
                  const PopupMenuItem(value: 'logout', child: Text('Çıkış Yap')),
                ],
              ),
            ),
          ],
        ),
        body: SafeArea(
          // V163: Firma değişiminde eski ve yeni sayfa ağacını aynı anda
          // tutmuyoruz. Böylece GlobalKey'li form/scaffold yapıların iki kopyası
          // aynı frame içinde oluşamaz.
          child: pages[index],
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


class _CompanySwitchScreen extends StatefulWidget {
  const _CompanySwitchScreen({required this.state});
  final AppState state;

  @override
  State<_CompanySwitchScreen> createState() => _CompanySwitchScreenState();
}

class _CompanySwitchScreenState extends State<_CompanySwitchScreen> {
  final TextEditingController search = TextEditingController();
  late List<dynamic> visible;

  @override
  void initState() {
    super.initState();
    visible = List<dynamic>.from(widget.state.companies);
  }

  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  void filter(String value) {
    final q = value.trim().toLowerCase();
    setState(() {
      visible = q.isEmpty
          ? List<dynamic>.from(widget.state.companies)
          : widget.state.companies.where((x) {
              final id = int.tryParse('${x['id']}') ?? 0;
              final no = '#${id.toString().padLeft(4, '0')}';
              final text =
                  '$no ${x['id']} ${x['company_name'] ?? ''} ${x['short_name'] ?? ''}'
                      .toLowerCase();
              return text.contains(q);
            }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentId =
        int.tryParse('${widget.state.company?['id'] ?? 0}') ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Firma Değiştir',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
              child: TextField(
                controller: search,
                autofocus: true,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search),
                  hintText: 'Firma no veya firma adı ara',
                ),
                onChanged: filter,
              ),
            ),
            Expanded(
              child: visible.isEmpty
                  ? const Center(
                      child: Text('Aramanıza uygun firma bulunamadı.'),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                      itemCount: visible.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: 8),
                      itemBuilder: (_, i) {
                        final x = visible[i];
                        final id = int.tryParse('${x['id']}') ?? 0;
                        final selected = id == currentId;
                        final no = id.toString().padLeft(4, '0');
                        final name = '${x['company_name'] ?? ''}';

                        return Material(
                          color: selected
                              ? const Color(0xFFF2F9D8)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          child: ListTile(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: BorderSide(
                                color: selected
                                    ? const Color(0xFFB7E000)
                                    : const Color(0xFFE4E9EC),
                              ),
                            ),
                            leading: CircleAvatar(
                              backgroundColor: selected
                                  ? MTheme.lime
                                  : const Color(0xFF17212B),
                              foregroundColor: selected
                                  ? MTheme.ink
                                  : const Color(0xFFC9F400),
                              child: Text(
                                name.isEmpty ? '?' : name[0],
                                style: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                            title: Text(
                              name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            subtitle: Text(
                              'Firma #$no'
                              '${x['employee_count'] != null ? ' · ${x['employee_count']} personel' : ''}'
                              '${selected ? ' · Aktif firma' : ''}',
                            ),
                            trailing: selected
                                ? const Icon(Icons.check_circle_rounded)
                                : const Icon(Icons.chevron_right_rounded),
                            onTap: selected
                                ? null
                                : () => Navigator.of(context).pop(id),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
