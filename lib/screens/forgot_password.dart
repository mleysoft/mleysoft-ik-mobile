import 'package:flutter/material.dart';
import '../core/app_state.dart';
import '../widgets/common.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key,required this.state});
  final AppState state;
  @override State<ForgotPasswordScreen> createState()=>_S();
}
class _S extends State<ForgotPasswordScreen>{
  final email=TextEditingController(); bool busy=false; bool sent=false;
  Future<void> send() async {
    if(email.text.trim().isEmpty){snack(context,'E-posta adresinizi girin.',error:true);return;}
    setState(()=>busy=true);
    try{
      await widget.state.api.request('auth/forgot-password',method:'POST',data:{'email':email.text.trim(),'source':'mobile'});
      if(mounted)setState(()=>sent=true);
    }catch(e){if(mounted)snack(context,'$e',error:true);}
    finally{if(mounted)setState(()=>busy=false);}
  }
  @override Widget build(BuildContext context)=>Scaffold(
    appBar:AppBar(title:const Text('Şifremi Unuttum')),
    body:SafeArea(child:ListView(padding:const EdgeInsets.all(22),children:[
      const SizedBox(height:18),
      Image.asset('assets/images/mleysoft-logo.png',height:54),
      const SizedBox(height:28),
      Text(sent?'E-postanızı kontrol edin':'Şifrenizi yenileyin',style:const TextStyle(fontSize:24,fontWeight:FontWeight.w800)),
      const SizedBox(height:8),
      Text(sent?'Şifre sıfırlama bağlantısı gönderildi. Bağlantıya telefondan dokunduğunuzda MleySoft İK uygulaması açılır.':'Sistemde kayıtlı e-posta adresinizi girin. Size 60 dakika geçerli bir sıfırlama bağlantısı gönderelim.'),
      const SizedBox(height:22),
      if(!sent)...[
        TextField(controller:email,keyboardType:TextInputType.emailAddress,decoration:const InputDecoration(labelText:'E-posta Adresi',prefixIcon:Icon(Icons.mail_outline))),
        const SizedBox(height:14),
        SizedBox(width:double.infinity,child:FilledButton(onPressed:busy?null:send,child:Text(busy?'Gönderiliyor...':'Sıfırlama Bağlantısı Gönder'))),
      ] else
        SizedBox(width:double.infinity,child:OutlinedButton(onPressed:()=>Navigator.pop(context),child:const Text('Giriş Ekranına Dön')))
    ]))
  );
}
