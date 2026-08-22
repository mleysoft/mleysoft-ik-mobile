import 'package:flutter/material.dart';
import '../core/app_state.dart';
import '../widgets/common.dart';

class ResetPasswordScreen extends StatefulWidget{
  const ResetPasswordScreen({super.key,required this.state,required this.token});
  final AppState state; final String token;
  @override State<ResetPasswordScreen> createState()=>_S();
}
class _S extends State<ResetPasswordScreen>{
  final p1=TextEditingController(),p2=TextEditingController(); bool busy=false,hide=true;
  Future<void> save()async{
    if(p1.text.length<6){snack(context,'Şifre en az 6 karakter olmalıdır.',error:true);return;}
    if(p1.text!=p2.text){snack(context,'Şifreler eşleşmiyor.',error:true);return;}
    setState(()=>busy=true);
    try{
      await widget.state.resetPassword(widget.token,p1.text);
      if(mounted)Navigator.popUntil(context,(r)=>r.isFirst);
    }catch(e){if(mounted)snack(context,'$e',error:true);}
    finally{if(mounted)setState(()=>busy=false);}
  }
  @override Widget build(BuildContext context)=>Scaffold(
    appBar:AppBar(title:const Text('Yeni Şifre')),
    body:SafeArea(child:ListView(padding:const EdgeInsets.all(22),children:[
      const SizedBox(height:16),Image.asset('assets/images/mleysoft-logo.png',height:54),const SizedBox(height:28),
      const Text('Yeni şifrenizi belirleyin',style:TextStyle(fontSize:24,fontWeight:FontWeight.w800)),const SizedBox(height:18),
      TextField(controller:p1,obscureText:hide,decoration:InputDecoration(labelText:'Yeni Şifre',suffixIcon:IconButton(onPressed:()=>setState(()=>hide=!hide),icon:Icon(hide?Icons.visibility_outlined:Icons.visibility_off_outlined)))),
      const SizedBox(height:12),TextField(controller:p2,obscureText:hide,decoration:const InputDecoration(labelText:'Yeni Şifre Tekrar')),
      const SizedBox(height:18),SizedBox(width:double.infinity,child:FilledButton(onPressed:busy?null:save,child:Text(busy?'Güncelleniyor...':'Şifreyi Güncelle ve Giriş Yap')))
    ]))
  );
}
