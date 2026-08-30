import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../core/app_state.dart';
import '../core/notification_service.dart';
import '../core/theme.dart';

class CompanyNotificationsScreen extends StatefulWidget {
  const CompanyNotificationsScreen({super.key, required this.state, this.initialNotificationId});
  final AppState state;
  final int? initialNotificationId;
  @override
  State<CompanyNotificationsScreen> createState() => _CompanyNotificationsScreenState();
}

class _CompanyNotificationsScreenState extends State<CompanyNotificationsScreen> {
  bool loading = true;
  List rows = [];
  int unread = 0;

  @override
  void initState() { super.initState(); load(openInitial: true); }

  bool _initialOpened = false;

  Future<void> load({bool openInitial = false}) async {
    try {
      final r = await widget.state.api.request('manager/company-notifications');
      if (!mounted) return;
      final count = int.tryParse('${r['unread_count'] ?? 0}') ?? 0;
      setState(() { rows = (r['notifications'] ?? []) as List; unread = count; loading = false; });
      NotificationService.instance.unreadCompanyNotificationCount.value = count;
      final initialId = widget.initialNotificationId ?? 0;
      if (openInitial && !_initialOpened && initialId > 0) {
        _initialOpened = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) open({'id': initialId});
        });
      }
    } catch (_) { if (mounted) setState(() => loading = false); }
  }

  Future<void> open(Map<String,dynamic> x) async {
    final id = int.tryParse('${x['id'] ?? 0}') ?? 0;
    if (id <= 0) return;
    try {
      final r = await widget.state.api.request('manager/company-notifications', query: {'id': '$id'});
      final n = Map<String,dynamic>.from(r['notification'] as Map);
      final count = int.tryParse('${r['unread_count'] ?? unread}') ?? unread;
      if (!mounted) return;
      setState(() {
        unread = count;
        final ix = rows.indexWhere((e) => '${(e as Map)['id']}' == '$id');
        if (ix >= 0) rows[ix] = {...Map<String,dynamic>.from(rows[ix] as Map), 'read_at': DateTime.now().toIso8601String()};
      });
      NotificationService.instance.unreadCompanyNotificationCount.value = count;
      await showDialog<void>(context: context, builder: (c) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        icon: const Icon(Icons.notifications_active_outlined, size: 40, color: MTheme.ink),
        title: Text('${n['title'] ?? 'Bildirim'}', textAlign: TextAlign.center),
        content: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 520), child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min,crossAxisAlignment: CrossAxisAlignment.start,children:[Text('${n['detail'] ?? ''}',style:const TextStyle(fontSize:15,height:1.55)),const SizedBox(height:16),Text(_date('${n['created_at'] ?? ''}'),style:const TextStyle(fontSize:11,color:MTheme.muted))]))),
        actions: [FilledButton(onPressed: () => Navigator.pop(c), child: const Text('Tamam'))],
      ));
    } catch (_) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Bildirim açılamadı.'))); }
  }

  String _date(String raw) { final d=DateTime.tryParse(raw.replaceFirst(' ','T')); return d==null?raw:DateFormat('dd.MM.yyyy HH:mm').format(d); }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Bildirimler'), actions:[if(unread>0) Padding(padding:const EdgeInsets.only(right:14),child:Center(child:Text('$unread okunmamış',style:const TextStyle(fontSize:11,fontWeight:FontWeight.w700))))]),
    body: RefreshIndicator(onRefresh:load,child:loading
      ? ListView(children:const [SizedBox(height:220),Center(child:CircularProgressIndicator())])
      : rows.isEmpty ? ListView(children:const [SizedBox(height:180),Center(child:Text('Henüz bildiriminiz bulunmuyor.'))])
      : ListView.separated(padding:const EdgeInsets.fromLTRB(14,14,14,30),itemCount:rows.length,separatorBuilder:(_,__)=>const SizedBox(height:9),itemBuilder:(_,i){
        final n=Map<String,dynamic>.from(rows[i] as Map); final isUnread=n['read_at']==null||'${n['read_at']}'.isEmpty;
        return Material(color:isUnread?const Color(0xFFF4F8DE):Colors.white,borderRadius:BorderRadius.circular(16),child:InkWell(borderRadius:BorderRadius.circular(16),onTap:()=>open(n),child:Padding(padding:const EdgeInsets.all(14),child:Row(crossAxisAlignment:CrossAxisAlignment.start,children:[
          Container(width:42,height:42,decoration:BoxDecoration(color:isUnread?MTheme.lime:const Color(0xFFF0F2F4),borderRadius:BorderRadius.circular(13)),child:Icon(isUnread?Icons.notifications_active_rounded:Icons.notifications_none_rounded,color:MTheme.ink)),const SizedBox(width:12),
          Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Row(children:[Expanded(child:Text('${n['title']??''}',style:TextStyle(fontWeight:isUnread?FontWeight.w900:FontWeight.w700,fontSize:15))),if(isUnread)Container(width:8,height:8,decoration:const BoxDecoration(color:MTheme.ink,shape:BoxShape.circle))]),const SizedBox(height:5),Text('${n['detail']??''}',maxLines:2,overflow:TextOverflow.ellipsis,style:const TextStyle(fontSize:12.5,color:MTheme.muted,height:1.35)),const SizedBox(height:7),Text(_date('${n['created_at']??''}'),style:const TextStyle(fontSize:10.5,color:MTheme.muted))]))
        ]))));
      })
    )
  );
}
