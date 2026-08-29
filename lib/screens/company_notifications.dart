import 'package:flutter/material.dart';
import '../core/app_state.dart';
import '../core/theme.dart';

class CompanyNotificationsScreen extends StatefulWidget {
  const CompanyNotificationsScreen({super.key, required this.state});
  final AppState state;
  @override State<CompanyNotificationsScreen> createState()=>_CompanyNotificationsScreenState();
}
class _CompanyNotificationsScreenState extends State<CompanyNotificationsScreen>{
  bool loading=true; List rows=[]; int unread=0;
  @override void initState(){super.initState();load();}
  Future<void> load() async {try{final r=await widget.state.api.request('manager/company-notifications');if(!mounted)return;setState((){rows=(r['notifications']??[]) as List;unread=int.tryParse('${r['unread_count']??0}')??0;loading=false;});}catch(e){if(mounted)setState(()=>loading=false);}}
  Future<void> open(Map x) async {final id=int.tryParse('${x['id']??0}')??0;if(id<=0)return;try{final r=await widget.state.api.request('manager/company-notifications',query:{'id':'$id'});final n=Map<String,dynamic>.from(r['notification'] as Map);if(mounted)showDialog(context:context,builder:(_)=>AlertDialog(title:Text('${n['title']??''}'),content:SingleChildScrollView(child:Text('${n['detail']??''}')),actions:[TextButton(onPressed:()=>Navigator.pop(context),child:const Text('Kapat'))]));load();}catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Bildirim açılamadı.')));}}
  @override Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title:const Text('Bildirimler'),actions:[if(unread>0)Padding(padding:const EdgeInsets.only(right:16),child:Center(child:Text('$unread okunmamış',style:const TextStyle(fontSize:12,fontWeight:FontWeight.w700))))]),body:RefreshIndicator(onRefresh:load,child:loading?const ListView(children:[SizedBox(height:260),Center(child:CircularProgressIndicator())]:rows.isEmpty?ListView(children:[const SizedBox(height:180),Center(child:Text('Henüz bildiriminiz yok.'))]):ListView.separated(padding:const EdgeInsets.all(16),itemCount:rows.length,separatorBuilder:(_,__)=>const SizedBox(height:8),itemBuilder:(_,i){final x=Map<String,dynamic>.from(rows[i] as Map);final unread=x['read_at']==null;return Card(child:ListTile(onTap:()=>open(x),leading:CircleAvatar(backgroundColor:unread?MTheme.limeSoft:Colors.black12,child:Icon(unread?Icons.notifications_active_outlined:Icons.notifications_none_outlined,color:MTheme.ink)),title:Text('${x['title']??''}',style:TextStyle(fontWeight:unread?FontWeight.w900:FontWeight.w600)),subtitle:Text('${x['detail']??''}',maxLines:2,overflow:TextOverflow.ellipsis),trailing:Text('${x['created_at']??''}',style:const TextStyle(fontSize:10))))}));
}
