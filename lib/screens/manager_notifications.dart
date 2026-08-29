import 'package:flutter/material.dart';
import '../core/app_state.dart';
import '../core/theme.dart';

class ManagerNotificationsScreen extends StatefulWidget {
  const ManagerNotificationsScreen({super.key, required this.state, this.initialNotificationId});
  final AppState state;
  final int? initialNotificationId;
  @override State<ManagerNotificationsScreen> createState()=>_ManagerNotificationsScreenState();
}
class _ManagerNotificationsScreenState extends State<ManagerNotificationsScreen>{
  bool loading=true; List<Map<String,dynamic>> rows=[]; int unread=0; int page=1; bool more=false;
  @override void initState(){super.initState();load().then((_){final id=widget.initialNotificationId;if(id!=null&&id>0)open(id);});}
  int id(dynamic x)=>int.tryParse('$x')??0;
  Future<void> load({bool next=false}) async {try{final p=next?page+1:1;final r=await widget.state.api.request('manager/notifications',query:{'page':p,'limit':20});final list=((r['notifications']??[])as List).map((e)=>Map<String,dynamic>.from(e)).toList();if(!mounted)return;setState((){page=p;more=r['has_more']==true;unread=id(r['unread_count']);if(next)rows.addAll(list);else rows=list;loading=false;});}catch(e){if(mounted)setState(()=>loading=false);}}
  Future<void> open(int nid) async {try{final r=await widget.state.api.request('manager/notifications',query:{'id':nid});final n=Map<String,dynamic>.from(r['notification']??{});if(!mounted)return;showModalBottomSheet(context:context,isScrollControlled:true,showDragHandle:true,builder:(_)=>Padding(padding:EdgeInsets.fromLTRB(20,8,20,MediaQuery.of(context).viewInsets.bottom+24),child:Column(mainAxisSize:MainAxisSize.min,crossAxisAlignment:CrossAxisAlignment.start,children:[Text('${n['title']??''}',style:const TextStyle(fontSize:21,fontWeight:FontWeight.w900)),const SizedBox(height:10),Text('${n['detail']??''}',style:const TextStyle(fontSize:14,height:1.5)),const SizedBox(height:14),Text('${n['created_at']??''}',style:const TextStyle(color:MTheme.muted,fontSize:11)),const SizedBox(height:10)])));load();}catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('Bildirim açılamadı.')));}}
  @override Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title:const Text('Bildirimler'),actions:[IconButton(onPressed:load,icon:const Icon(Icons.refresh_rounded))]),body:RefreshIndicator(onRefresh:load,child:loading?ListView(children:const [SizedBox(height:240),Center(child:CircularProgressIndicator())]):ListView.builder(padding:const EdgeInsets.fromLTRB(14,14,14,30),itemCount:rows.length+(more?1:0),itemBuilder:(_,i){if(i==rows.length)return Padding(padding:const EdgeInsets.all(12),child:OutlinedButton(onPressed:()=>load(next:true),child:const Text('Daha Fazla')));final n=rows[i];final read=n['read_at']!=null;return Card(margin:const EdgeInsets.only(bottom:9),child:ListTile(onTap:()=>open(id(n['id'])),leading:CircleAvatar(backgroundColor:read?Colors.grey.shade100:MTheme.limeSoft,child:Icon(read?Icons.notifications_none_rounded:Icons.notifications_active_rounded,color:MTheme.ink)),title:Text('${n['title']??''}',style:TextStyle(fontWeight:read?FontWeight.w600:FontWeight.w900)),subtitle:Text('${n['detail']??''}',maxLines:2,overflow:TextOverflow.ellipsis),trailing:read?null:Container(width:8,height:8,decoration:const BoxDecoration(color:MTheme.lime,shape:BoxShape.circle)));})));}
}
