import 'package:flutter/material.dart';
import '../core/theme.dart';

Future<int?> showEmployeePicker(
  BuildContext context,
  List employees, {
  int? selectedId,
  String title = 'Personel Seç',
}) async {
  String q = '';
  return showModalBottomSheet<int>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setM) {
        final filtered = employees.where((e) {
          final name = '${e['first_name'] ?? ''} ${e['last_name'] ?? ''}'.toLowerCase();
          final no = '${e['employee_no'] ?? ''}'.toLowerCase();
          final s = q.trim().toLowerCase();
          return s.isEmpty || name.contains(s) || no.contains(s);
        }).toList();
        return DraggableScrollableSheet(
          initialChildSize: .78,
          minChildSize: .55,
          maxChildSize: .94,
          expand: false,
          builder: (_, controller) => Material(
            color: Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
            child: Column(children: [
              const SizedBox(height: 10),
              Container(width: 44,height: 4,decoration:BoxDecoration(color:Colors.black12,borderRadius:BorderRadius.circular(9))),
              Padding(
                padding: const EdgeInsets.fromLTRB(18,14,18,10),
                child: Row(children:[
                  Expanded(child:Text(title,style:const TextStyle(fontSize:19,fontWeight:FontWeight.w800))),
                  IconButton(onPressed:()=>Navigator.pop(ctx),icon:const Icon(Icons.close))
                ]),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(18,0,18,10),
                child: TextField(
                  autofocus: true,
                  onChanged:(v)=>setM(()=>q=v),
                  decoration: const InputDecoration(
                    hintText:'Ad soyad veya personel no ara',
                    prefixIcon:Icon(Icons.search),
                  ),
                ),
              ),
              Expanded(
                child: filtered.isEmpty
                  ? const Center(child:Text('Aramaya uygun personel bulunamadı.',style:TextStyle(color:MTheme.muted)))
                  : ListView.separated(
                      controller:controller,
                      itemCount:filtered.length,
                      separatorBuilder:(_,__)=>const Divider(height:1),
                      itemBuilder:(_,i){
                        final e=filtered[i];
                        final id=int.parse('${e['id']}');
                        return ListTile(
                          leading:CircleAvatar(child:Text('${e['first_name'] ?? '?'}'.substring(0,1).toUpperCase())),
                          title:Text('${e['first_name']} ${e['last_name']}',style:const TextStyle(fontWeight:FontWeight.w700)),
                          subtitle:Text('${e['employee_no'] ?? ''}'),
                          trailing:id==selectedId?const Icon(Icons.check_circle,color:MTheme.lime):const Icon(Icons.chevron_right),
                          onTap:()=>Navigator.pop(ctx,id),
                        );
                      }),
              )
            ]),
          ),
        );
      },
    ),
  );
}
