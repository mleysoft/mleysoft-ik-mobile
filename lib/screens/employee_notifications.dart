import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/app_state.dart';
import '../core/notification_service.dart';
import '../core/theme.dart';
import '../widgets/common.dart';

class EmployeeNotificationsScreen extends StatefulWidget {
  const EmployeeNotificationsScreen({super.key, required this.state, this.initialNotificationId});
  final AppState state;
  final int? initialNotificationId;

  @override
  State<EmployeeNotificationsScreen> createState() => _EmployeeNotificationsScreenState();
}

class _EmployeeNotificationsScreenState extends State<EmployeeNotificationsScreen> {
  List rows = [];
  int unread = 0;
  bool busy = true;

  @override
  void initState() {
    super.initState();
    load(openInitial: true);
  }

  bool _initialOpened = false;

  Future<void> load({bool openInitial = false}) async {
    try {
      final r = await widget.state.api.request('employee/notifications', query: {'limit': 100});
      if (!mounted) return;
      setState(() {
        rows = (r['notifications'] ?? []) as List;
        unread = int.tryParse('${r['unread_count'] ?? 0}') ?? 0;
        busy = false;
      });
      NotificationService.instance.unreadAnnouncementCount.value = unread;
      final initialId = widget.initialNotificationId ?? 0;
      if (openInitial && !_initialOpened && initialId > 0) {
        _initialOpened = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) openNotice({'id': initialId});
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => busy = false);
        snack(context, '$e', error: true);
      }
    }
  }

  Future<void> openNotice(Map<String, dynamic> n) async {
    final id = int.tryParse('${n['id']}') ?? 0;
    if (id <= 0) return;
    try {
      final r = await widget.state.api.request('employee/notifications', query: {'id': id});
      final detail = Map<String, dynamic>.from(r['notification'] as Map);
      final newUnread = int.tryParse('${r['unread_count'] ?? unread}') ?? unread;
      if (detail['read_at'] == null) {
        final rr = await widget.state.api.request('employee/notifications/read', method: 'POST', data: {'id': id});
        unread = int.tryParse('${rr['unread_count'] ?? newUnread}') ?? newUnread;
        NotificationService.instance.notificationReadLocally(id, unread);
      } else {
        unread = newUnread;
      }
      if (!mounted) return;
      setState(() {
        final ix = rows.indexWhere((x) => '${x['id']}' == '$id');
        if (ix >= 0) rows[ix] = {...Map<String, dynamic>.from(rows[ix] as Map), 'read_at': DateTime.now().toIso8601String()};
      });
      await showDialog<void>(
        context: context,
        builder: (c) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
          icon: const Icon(Icons.notifications_active_outlined, size: 40, color: MTheme.ink),
          title: Text('${detail['title'] ?? 'Bildirim'}', textAlign: TextAlign.center),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${detail['detail'] ?? ''}', style: const TextStyle(fontSize: 15, height: 1.55)),
                  const SizedBox(height: 16),
                  Text(_date('${detail['created_at'] ?? ''}'), style: const TextStyle(fontSize: 11, color: MTheme.muted)),
                ],
              ),
            ),
          ),
          actions: [FilledButton(onPressed: () => Navigator.pop(c), child: const Text('Tamam'))],
        ),
      );
    } catch (e) {
      if (mounted) snack(context, '$e', error: true);
    }
  }

  String _date(String raw) {
    final d = DateTime.tryParse(raw.replaceFirst(' ', 'T'));
    return d == null ? raw : DateFormat('dd.MM.yyyy HH:mm').format(d);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Bildirimler'),
          actions: [
            if (unread > 0)
              Padding(
                padding: const EdgeInsets.only(right: 14),
                child: Center(child: Text('$unread okunmamış', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700))),
              ),
          ],
        ),
        body: RefreshIndicator(
          onRefresh: load,
          child: busy
              ? ListView(children: const [SizedBox(height: 220), Center(child: CircularProgressIndicator())])
              : rows.isEmpty
                  ? ListView(children: const [SizedBox(height: 180), Center(child: Text('Henüz bildiriminiz bulunmuyor.'))])
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(14, 14, 14, 30),
                      itemCount: rows.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 9),
                      itemBuilder: (_, i) {
                        final n = Map<String, dynamic>.from(rows[i] as Map);
                        final isUnread = n['read_at'] == null || '${n['read_at']}'.isEmpty;
                        return Material(
                          color: isUnread ? const Color(0xFFF4F8DE) : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () => openNotice(n),
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Container(
                                  width: 42,
                                  height: 42,
                                  decoration: BoxDecoration(color: isUnread ? MTheme.lime : const Color(0xFFF0F2F4), borderRadius: BorderRadius.circular(13)),
                                  child: Icon(isUnread ? Icons.notifications_active_rounded : Icons.notifications_none_rounded, color: MTheme.ink),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                    Row(children: [
                                      Expanded(child: Text('${n['title'] ?? ''}', style: TextStyle(fontWeight: isUnread ? FontWeight.w900 : FontWeight.w700, fontSize: 15))),
                                      if (isUnread) Container(width: 8, height: 8, decoration: const BoxDecoration(color: MTheme.ink, shape: BoxShape.circle)),
                                    ]),
                                    const SizedBox(height: 5),
                                    Text('${n['detail'] ?? ''}', maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12.5, color: MTheme.muted, height: 1.35)),
                                    const SizedBox(height: 7),
                                    Text(_date('${n['created_at'] ?? ''}'), style: const TextStyle(fontSize: 10.5, color: MTheme.muted)),
                                  ]),
                                ),
                              ]),
                            ),
                          ),
                        );
                      },
                    ),
        ),
      );
}
