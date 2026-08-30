import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../core/native_location_service.dart';
import '../core/app_state.dart';
import '../core/notification_service.dart';
import '../core/theme.dart';
import '../widgets/common.dart';
import 'employee_notifications.dart';

class EmployeePortalScreen extends StatefulWidget {
  const EmployeePortalScreen({super.key, required this.state});
  final AppState state;

  @override
  State<EmployeePortalScreen> createState() => _EmployeePortalState();
}

class _EmployeePortalState extends State<EmployeePortalScreen> {
  Map<String, dynamic>? data;
  bool busy = false;
  bool birthdayDialogOpen = false;
  bool noticeDialogOpen = false;
  int unreadNotices = 0;
  Timer? noticeTimer;

  @override
  void initState() {
    super.initState();
    NotificationService.instance.birthdayTapMessage.addListener(_birthdayTapListener);
    NotificationService.instance.announcementTapId.addListener(_announcementTapListener);
    NotificationService.instance.unreadAnnouncementCount.addListener(_unreadListener);
    load().then((_) async { await _showPendingBirthdayMessage(); await _refreshNotices(); await _showPendingAnnouncement(); });
    noticeTimer = Timer.periodic(const Duration(seconds: 30), (_) => _refreshNotices());
  }

  @override
  void dispose() {
    noticeTimer?.cancel();
    NotificationService.instance.birthdayTapMessage.removeListener(_birthdayTapListener);
    NotificationService.instance.announcementTapId.removeListener(_announcementTapListener);
    NotificationService.instance.unreadAnnouncementCount.removeListener(_unreadListener);
    super.dispose();
  }

  void _birthdayTapListener() {
    _showPendingBirthdayMessage();
  }

  void _unreadListener() {
    if (mounted) setState(() => unreadNotices = NotificationService.instance.unreadAnnouncementCount.value);
  }

  void _announcementTapListener() {
    _showPendingAnnouncement();
  }

  Future<void> _refreshNotices() async {
    final count = await NotificationService.instance.pollEmployeeAnnouncements(showSystemNotifications: true);
    if (mounted && count != unreadNotices) setState(() => unreadNotices = count);
  }

  Future<void> _showPendingAnnouncement() async {
    if (!mounted || noticeDialogOpen) return;
    final id = await NotificationService.instance.consumeAnnouncementTapId();
    if (!mounted || id == null || id <= 0) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EmployeeNotificationsScreen(
          state: widget.state,
          initialNotificationId: id,
        ),
      ),
    );
    await _refreshNotices();
  }

  Future<void> _openAnnouncement(int id) async {
    if (!mounted || noticeDialogOpen) return;
    try {
      final r = await widget.state.api.request('employee/notifications', query: {'id': id});
      final n = Map<String, dynamic>.from(r['notification'] as Map);
      var unread = int.tryParse('${r['unread_count'] ?? unreadNotices}') ?? unreadNotices;
      if (n['read_at'] == null) {
        final rr = await widget.state.api.request('employee/notifications/read', method: 'POST', data: {'id': id});
        unread = int.tryParse('${rr['unread_count'] ?? unread}') ?? unread;
        await NotificationService.instance.notificationReadLocally(id, unread);
      }
      if (!mounted) return;
      setState(() => unreadNotices = unread);
      noticeDialogOpen = true;
      await showDialog<void>(
        context: context,
        builder: (c) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
          icon: const Icon(Icons.notifications_active_outlined, size: 42, color: MTheme.ink),
          title: Text('${n['title'] ?? 'Bildirim'}', textAlign: TextAlign.center),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: SingleChildScrollView(child: Text('${n['detail'] ?? ''}', style: const TextStyle(fontSize: 15, height: 1.55))),
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [FilledButton(onPressed: () => Navigator.pop(c), child: const Text('Tamam'))],
        ),
      );
      noticeDialogOpen = false;
    } catch (e) {
      noticeDialogOpen = false;
      if (mounted) snack(context, '$e', error: true);
    }
  }

  Future<void> _openNotificationCenter() async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => EmployeeNotificationsScreen(state: widget.state)));
    await _refreshNotices();
  }

  Future<void> _showPendingBirthdayMessage() async {
    if (!mounted || birthdayDialogOpen) return;
    final message = await NotificationService.instance.consumeBirthdayMessage();
    if (!mounted || message == null || message.isEmpty) return;
    birthdayDialogOpen = true;
    await showDialog<void>(
      context: context,
      builder: (c) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        icon: const Icon(Icons.celebration_outlined, size: 42, color: MTheme.ink),
        title: const Text('Doğum Günün Kutlu Olsun! 🎉', textAlign: TextAlign.center),
        content: Text(message, textAlign: TextAlign.center, style: const TextStyle(height: 1.45)),
        actionsAlignment: MainAxisAlignment.center,
        actions: [FilledButton(onPressed: () => Navigator.pop(c), child: const Text('Teşekkürler'))],
      ),
    );
    birthdayDialogOpen = false;
  }

  Future<void> load() async {
    try {
      final r = await widget.state.api.request('employee/today');
      if (mounted) setState(() => data = r);
    } catch (e) {
      if (mounted) snack(context, '$e', error: true);
    }
  }

  Future<void> scan() async {
    final code = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const EmployeeQrScanner()),
    );
    if (code == null) return;

    setState(() => busy = true);
    try {
      final security = Map<String, dynamic>.from(data?['qr_security'] ?? {});
      // V120: QR ekranda değişmeden önce o anki geçerli token sunucuda tek kullanımlık
      // işlem bileti olarak kilitlenir. Konum alma uzasa bile ilk okutulan QR geçerliliğini korur.
      final locked = await widget.state.api.request(
        'employee/qr-lock',
        method: 'POST',
        data: {'qr': code},
      );
      final ticket = '${locked['ticket'] ?? ''}';
      if (ticket.isEmpty) throw Exception('QR işlem bileti oluşturulamadı. Lütfen tekrar okutun.');
      final payload = <String, dynamic>{'qr': code, 'qr_ticket': ticket};
      if (security['geofence_enabled'] == true) {
        if (!mounted) return;
        final continueWithLocation = await showDialog<bool>(
          context: context,
          builder: (c) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            icon: const Icon(Icons.location_on_outlined, size: 42, color: MTheme.ink),
            title: const Text('Konum Doğrulaması'),
            content: const Text(
              'Firmanız QR giriş/çıkış işlemlerinde işyeri konum doğrulamasını etkinleştirmiş. '
              'Konumunuz yalnızca QR kodunun tanımlı işyeri konumunda okutulduğunu doğrulamak için bu işlem sırasında alınır. '
              'Arka planda konum takibi yapılmaz.',
              style: TextStyle(height: 1.45),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Vazgeç')),
              FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('Devam Et')),
            ],
          ),
        ) ?? false;
        if (!continueWithLocation) throw Exception('Konum doğrulaması yapılmadan QR giriş/çıkış işlemi tamamlanamaz.');
        final pos = await NativeLocationService.currentPosition();
        if (pos.isMocked) throw Exception('Sahte/test konum algılandı. QR işlemi gerçek cihaz konumu ile yapılmalıdır.');
        payload.addAll({'latitude': pos.latitude, 'longitude': pos.longitude, 'accuracy': pos.accuracy, 'location_mocked': pos.isMocked});
      }
      final r = await widget.state.api.request(
        'employee/scan',
        method: 'POST',
        data: payload,
      );
      if (mounted) {
        await _showScanSuccess('${r['message'] ?? 'İşlem başarıyla tamamlandı.'}');
        await load();
      }
    } catch (e) {
      if (mounted) snack(context, '$e', error: true);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> _showScanSuccess(String message) async {
    if (!mounted) return;
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted && Navigator.of(context, rootNavigator: true).canPop()) {
        Navigator.of(context, rootNavigator: true).pop();
      }
    });
    await showGeneralDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'İşlem Tamamlandı',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 180),
      pageBuilder: (context, _, __) => Center(
        child: Material(
          color: Colors.transparent,
          child: Container(
            width: 300,
            margin: const EdgeInsets.symmetric(horizontal: 24),
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: const [BoxShadow(blurRadius: 28, color: Colors.black26)],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 92,
                  height: 92,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F7EE),
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFF20A45B), width: 3),
                  ),
                  child: const Icon(Icons.check_rounded, size: 64, color: Color(0xFF20A45B)),
                ),
                const SizedBox(height: 18),
                const Text('İşlem Tamamlandı', style: TextStyle(fontSize: 21, fontWeight: FontWeight.w900, color: MTheme.ink)),
                const SizedBox(height: 8),
                Text(message, textAlign: TextAlign.center, style: const TextStyle(fontSize: 14, height: 1.4, color: Colors.black87)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final employee = widget.state.employee ?? {};
    final attendance = data?['attendance'];
    final shift = data?['shift'];
    final leave = Map<String, dynamic>.from(data?['leave_summary'] ?? {});
    final recentLeaves = (data?['recent_leaves'] ?? []) as List;
    final currentLeave = data?['current_leave'];
    final birthdayToday = data?['birthday_today'] == true;
    final birthdayMessage = '${data?['birthday_message'] ?? ''}';
    final scanState = '${data?['scan_state'] ?? 'entry'}';

    final hasIn = attendance?['check_in_time'] != null;
    final hasOut = attendance?['check_out_time'] != null;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('MleySoft İK', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
            Text(widget.state.company?['company_name'] ?? '', style: const TextStyle(fontSize: 10, color: Colors.white70)),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Bildirimler',
            onPressed: _openNotificationCenter,
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.notifications_none_rounded),
                if (unreadNotices > 0)
                  Positioned(
                    right: -8,
                    top: -8,
                    child: Container(
                      constraints: const BoxConstraints(minWidth: 19, minHeight: 19),
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                      decoration: BoxDecoration(color: MTheme.lime, borderRadius: BorderRadius.circular(10), border: Border.all(color: MTheme.ink, width: 1.2)),
                      child: Text(unreadNotices > 99 ? '99+' : '$unreadNotices', textAlign: TextAlign.center, style: const TextStyle(color: MTheme.ink, fontSize: 9, fontWeight: FontWeight.w900)),
                    ),
                  ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Oturumu Kapat',
            onPressed: widget.state.logout,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: load,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
            children: [
              Text('Merhaba, ${employee['first_name'] ?? ''}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
              Text('${employee['employee_no'] ?? ''} · Personel', style: const TextStyle(color: MTheme.muted)),
              if (birthdayToday) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF2F8D8),
                    borderRadius: BorderRadius.circular(13),
                    border: Border.all(color: const Color(0xFFD9E89A)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.celebration_outlined, size: 18, color: MTheme.ink),
                      const SizedBox(width: 8),
                      Expanded(child: Text(birthdayMessage.isEmpty ? 'Doğum günün kutlu olsun! 🎉' : birthdayMessage, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800))),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 16),

              _attendanceCard(attendance, shift, '${data?['work_date'] ?? ''}'),

              const SizedBox(height: 14),
              if (shift == null)
                _shiftMissingBlock()
              else if (currentLeave != null)
                _todayLeaveBlock(Map<String, dynamic>.from(currentLeave))
              else ...[
                SizedBox(
                  height: 60,
                  child: FilledButton.icon(
                    onPressed: busy || scanState == 'completed' ? null : scan,
                    icon: const Icon(Icons.qr_code_scanner, size: 27),
                    label: Text(
                      busy
                          ? 'QR İşleniyor...'
                          : scanState == 'completed'
                              ? 'Bugünkü İşlemler Tamamlandı'
                              : 'Kamerayı Aç ve QR Okut',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  scanState == 'entry'
                      ? 'İlk okutma giriş olarak kaydedilir.'
                      : scanState == 'waiting_exit'
                          ? 'Girişiniz kayıtlı. Giriş saatinizden itibaren tanımlı tolerans süresi dolmadan çıkış yapılamaz. Tolerans dolduktan sonra vardiya bitimine kadar tekrar okutursanız E / Erken Çıkış, vardiya bitişinde veya sonrasında normal çıkış kaydedilir.'
                          : 'Bugünkü giriş ve çıkış kaydınız tamamlandı.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 10.5, color: MTheme.muted, height: 1.35),
                ),
              ],

              const SizedBox(height: 20),
              _leaveSummary(leave, currentLeave),

              if (recentLeaves.isNotEmpty) ...[
                const SizedBox(height: 18),
                _recentLeavesCard(recentLeaves),
              ],

              const SizedBox(height: 16),
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(14),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.phone_android_outlined),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Mobil personel kodunuzu yalnızca ilk cihaz eşleştirmesinde girersiniz. Uygulama daha sonra doğrudan bu personel ekranını açar.',
                          style: TextStyle(fontSize: 11),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _displayWorkDate(String value) {
    final d = DateTime.tryParse(value);
    if (d == null) return value;
    const months = ['Ocak','Şubat','Mart','Nisan','Mayıs','Haziran','Temmuz','Ağustos','Eylül','Ekim','Kasım','Aralık'];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }

  Widget _attendanceCard(dynamic a, dynamic sh, String workDate) => Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: MTheme.ink,
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [BoxShadow(color: Color(0x22000000), blurRadius: 18, offset: Offset(0, 8))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('BUGÜNKÜ ÇALIŞMA', style: TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.w800)),
                Text(_displayWorkDate(workDate), style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w800)),
              ],
            ),
            const SizedBox(height: 5),
            Text(
              sh == null
                  ? 'Vardiya tanımı yok'
                  : '${sh['name']} · ${('${sh['start_time']}').substring(0, 5)} - ${('${sh['end_time']}').substring(0, 5)}',
              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 15),
            Row(
              children: [
                Expanded(child: _timeBox(Icons.login_rounded, 'Giriş', a?['check_in_time'] == null ? '--:--' : '${a['check_in_time']}'.substring(0, 5))),
                const SizedBox(width: 8),
                Expanded(child: _timeBox(Icons.logout_rounded, 'Çıkış', a?['check_out_time'] == null ? '--:--' : '${a['check_out_time']}'.substring(0, 5))),
              ],
            ),
            if (a != null) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 7,
                runSpacing: 7,
                children: [
                  if (_num(a['late_minutes']) > 0) _metric('Geç Giriş', '${a['late_minutes']} dk'),
                  if (_num(a['early_leave_minutes']) > 0) _metric('Eksik Çıkış', '${a['early_leave_minutes']} dk'),
                  if (_num(a['overtime_minutes']) > 0) _metric('Fazla Çalışma', '${a['overtime_minutes']} dk'),
                ],
              ),
            ],
          ],
        ),
      );


  Widget _shiftMissingBlock() => Container(padding:const EdgeInsets.all(16),decoration:BoxDecoration(color:const Color(0xFFFFF4DF),borderRadius:BorderRadius.circular(18),border:Border.all(color:const Color(0xFFEBCB90))),child:const Row(crossAxisAlignment:CrossAxisAlignment.start,children:[Icon(Icons.schedule_outlined,color:Color(0xFF8A5D0C),size:28),SizedBox(width:12),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text('Vardiyanız Tanımlı Değil',style:TextStyle(fontSize:15,fontWeight:FontWeight.w900)),SizedBox(height:5),Text('QR giriş/çıkış işlemi yapabilmeniz için firma yöneticinizin size vardiya tanımlaması gerekir.',style:TextStyle(fontSize:10.5,color:MTheme.muted,height:1.35))]))]));

  Widget _todayLeaveBlock(Map<String, dynamic> currentLeave) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF5D9),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE8C970)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.event_busy_outlined, size: 28, color: Color(0xFF8A6300)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Bugün ${_leaveType('${currentLeave['leave_type']}')}siniz',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${currentLeave['start_date']} - ${currentLeave['end_date']}',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 7),
                  const Text(
                    'Bugünkü QR giriş/çıkış işlemleri izin/rapor kaydınız nedeniyle kapalıdır.',
                    style: TextStyle(fontSize: 10.5, color: MTheme.muted, height: 1.35),
                  ),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _recentLeavesCard(List recentLeaves) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE1E7EA)),
          boxShadow: const [BoxShadow(color: Color(0x10000000), blurRadius: 14, offset: Offset(0, 6))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.history_rounded, color: MTheme.ink),
                SizedBox(width: 9),
                Expanded(child: Text('Son İzin / Rapor Hareketlerim', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900))),
              ],
            ),
            const SizedBox(height: 10),
            ...recentLeaves.take(6).map((x) => _leaveRow(Map<String, dynamic>.from(x))),
          ],
        ),
      );

  Widget _leaveSummary(Map<String, dynamic> l, dynamic currentLeave) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE1E7EA)),
          boxShadow: const [BoxShadow(color: Color(0x10000000), blurRadius: 14, offset: Offset(0, 6))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(color: const Color(0xFFF2F7D7), borderRadius: BorderRadius.circular(13)),
                  child: const Icon(Icons.beach_access_outlined, color: MTheme.ink),
                ),
                const SizedBox(width: 11),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('İzin ve Rapor Bilgilerim', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900)),
                      SizedBox(height: 2),
                      Text('Güncel izin bakiyesi ve bu yılki kullanımlar', style: TextStyle(fontSize: 10.5, color: MTheme.muted)),
                    ],
                  ),
                ),
              ],
            ),
            if (currentLeave != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(11),
                decoration: BoxDecoration(color: const Color(0xFFFFF5D9), borderRadius: BorderRadius.circular(12)),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Bugün ${_leaveType('${currentLeave['leave_type']}')} kaydınız var (${currentLeave['start_date']} - ${currentLeave['end_date']}).',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _infoTile('Kalan Yıllık İzin', '${_fmt(l['annual_remaining'])} gün', Icons.event_available_outlined)),
                const SizedBox(width: 8),
                Expanded(child: _infoTile('Bu Yıl Kullanılan', '${_fmt(l['annual_used_this_year'])} gün', Icons.event_busy_outlined)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: _infoTile('Raporlu', '${_fmt(l['sick_days_this_year'])} gün', Icons.medical_information_outlined)),
                const SizedBox(width: 8),
                Expanded(child: _infoTile('Ücretli / Ücretsiz', '${_fmt(l['paid_leave_this_year'])} / ${_fmt(l['unpaid_leave_this_year'])} gün', Icons.event_note_outlined)),
              ],
            ),
            if (l['next_entitlement_date'] != null) ...[
              const SizedBox(height: 10),
              Text(
                'Sonraki yıllık izin hakedişi: ${l['next_entitlement_date']} · ${l['next_entitlement_right'] ?? 0} gün',
                style: const TextStyle(fontSize: 10.5, color: MTheme.muted, fontWeight: FontWeight.w600),
              ),
            ],
          ],
        ),
      );

  Widget _leaveRow(Map<String, dynamic> x) => Container(
        margin: const EdgeInsets.only(bottom: 7),
        decoration: BoxDecoration(color: const Color(0xFFF8FAFA), borderRadius: BorderRadius.circular(13)),
        child: ListTile(
          dense: true,
          leading: CircleAvatar(
            radius: 18,
            backgroundColor: const Color(0xFFF2F5F6),
            child: Icon(_leaveIcon('${x['leave_type']}'), size: 18, color: MTheme.ink),
          ),
          title: Text(_leaveType('${x['leave_type']}'), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
          subtitle: Text('${x['start_date']} - ${x['end_date']}', style: const TextStyle(fontSize: 10)),
          trailing: Text('${_fmt(x['day_count'])} gün', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800)),
        ),
      );

  Widget _timeBox(IconData icon, String title, String value) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        decoration: BoxDecoration(color: Colors.white.withValues(alpha: .07), borderRadius: BorderRadius.circular(13)),
        child: Row(
          children: [
            Icon(icon, color: MTheme.lime, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(color: Colors.white54, fontSize: 9.5)),
                  Text(value, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900)),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _metric(String name, String value) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
        decoration: BoxDecoration(color: Colors.white.withValues(alpha: .08), borderRadius: BorderRadius.circular(10)),
        child: Text('$name: $value', style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w700)),
      );

  Widget _infoTile(String title, String value, IconData icon) => Container(
        padding: const EdgeInsets.all(11),
        decoration: BoxDecoration(color: const Color(0xFFF7F9FA), borderRadius: BorderRadius.circular(13)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 18, color: MTheme.muted),
            const SizedBox(height: 7),
            Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
            const SizedBox(height: 2),
            Text(title, style: const TextStyle(fontSize: 9.5, color: MTheme.muted)),
          ],
        ),
      );

  int _num(dynamic v) => int.tryParse('$v') ?? 0;

  String _fmt(dynamic v) {
    final n = double.tryParse('$v') ?? 0;
    return n == n.roundToDouble() ? n.toInt().toString() : n.toStringAsFixed(1);
  }

  String _leaveType(String v) {
    switch (v) {
      case 'annual': return 'Yıllık İzin';
      case 'paid': return 'Ücretli İzin';
      case 'unpaid': return 'Ücretsiz İzin';
      case 'sick': return 'Rapor';
      default: return 'İzin';
    }
  }

  IconData _leaveIcon(String v) {
    switch (v) {
      case 'annual': return Icons.beach_access_outlined;
      case 'sick': return Icons.medical_information_outlined;
      default: return Icons.event_note_outlined;
    }
  }
}

class EmployeeQrScanner extends StatefulWidget {
  const EmployeeQrScanner({super.key});

  @override
  State<EmployeeQrScanner> createState() => _EmployeeQrScannerState();
}

class _EmployeeQrScannerState extends State<EmployeeQrScanner> {
  bool found = false;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Personel QR İşlemi')),
        body: Stack(
          children: [
            MobileScanner(
              onDetect: (capture) {
                if (found) return;
                for (final b in capture.barcodes) {
                  final value = b.rawValue;
                  if (value != null && value.startsWith('mleysoftik://attendance')) {
                    found = true;
                    Navigator.pop(context, value);
                    return;
                  }
                }
              },
            ),
            Center(
              child: Container(
                width: 260,
                height: 260,
                decoration: BoxDecoration(
                  border: Border.all(color: MTheme.lime, width: 4),
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
            ),
            const Positioned(
              left: 30,
              right: 30,
              bottom: 38,
              child: Text(
                'Firma QR kodunu çerçevenin içine getirin. Sistem bunun giriş mi çıkış mı olduğunu vardiya ve mevcut kaydınıza göre otomatik belirler.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
      );
}
