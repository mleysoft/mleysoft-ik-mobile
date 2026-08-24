import 'package:flutter/material.dart';
import '../core/app_state.dart';
import '../core/api.dart';
import '../core/theme.dart';
import '../widgets/common.dart';
import 'forgot_password.dart';
import 'register_company.dart';
import 'in_app_browser.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, required this.state});
  final AppState state;

  @override
  State<LoginScreen> createState() => _LoginState();
}

class _LoginState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  final email = TextEditingController();
  final pass = TextEditingController();
  bool busy = false;
  bool hide = true;
  final employeeCode = TextEditingController();
  bool employeeBusy=false;
  late final TabController tabs;

  @override
  void initState(){super.initState();tabs=TabController(length:2,vsync:this);}
  @override
  void dispose() {
    tabs.dispose();employeeCode.dispose();
    email.dispose();
    pass.dispose();
    super.dispose();
  }



  Future<void> handleManagerDeviceConflict(ApiException e) async {
    if (!mounted) return;
    final model = '${e.details['active_device_model'] ?? 'Kayıtlı telefon'}';
    final platform = '${e.details['active_platform'] ?? ''}';
    final lastSeen = '${e.details['active_last_seen'] ?? ''}';
    final proceed = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Hesap Başka Telefonda Açık'),
        content: Text(
          'Bu yönetici hesabı $model${platform.isNotEmpty ? ' ($platform)' : ''} cihazında bağlı durumda.'
          '${lastSeen.isNotEmpty ? '\n\nSon aktivite: $lastSeen' : ''}'
          '\n\nEski telefona erişiminiz varsa o cihazdan Çıkış yapın. Uygulama silindiyse veya eski telefona erişemiyorsanız e-posta doğrulamasıyla bu telefonu yetkilendirebilirsiniz.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Vazgeç')),
          FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('Eski Cihaza Erişemiyorum')),
        ],
      ),
    );
    if (proceed != true || !mounted) return;
    try {
      await widget.state.requestManagerDeviceTransfer(email.text.trim(), pass.text);
    } catch (err) {
      if (mounted) snack(context, '$err', error: true);
      return;
    }
    if (!mounted) return;
    final code = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (c) => AlertDialog(
        title: const Text('Yeni Telefonu Doğrula'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Yönetici e-posta adresinize gönderilen 6 haneli kodu girin. Kod 10 dakika geçerlidir.'),
            const SizedBox(height: 14),
            TextField(
              controller: code,
              keyboardType: TextInputType.number,
              maxLength: 6,
              autofocus: true,
              decoration: const InputDecoration(labelText: 'Doğrulama Kodu', counterText: ''),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Vazgeç')),
          FilledButton(
            onPressed: () async {
              if (code.text.replaceAll(RegExp(r'\D'), '').length != 6) return;
              try {
                final choose = await widget.state.confirmManagerDeviceTransfer(email.text.trim(), pass.text, code.text);
                if (c.mounted) Navigator.pop(c, true);
                if (choose && mounted) {
                  // Super admin için firma seçimi normal login akışında tekrar açılabilir.
                  snack(context, 'Yeni telefon doğrulandı. Firma seçiminizi yapabilirsiniz.');
                }
              } catch (err) {
                if (mounted) snack(context, '$err', error: true);
              }
            },
            child: const Text('Bu Telefonu Yetkilendir'),
          ),
        ],
      ),
    );
    code.dispose();
    if (confirmed == true && mounted) {
      snack(context, 'Eski telefonun yönetici oturumu kapatıldı. Bu telefon yetkilendirildi.');
    }
  }

  Future<void> handleLoginError(Object e) async {
    if (!mounted) return;
    if (e is ApiException && e.code == 'MANAGER_DEVICE_ACTIVE') {
      await handleManagerDeviceConflict(e);
    } else if (e is ApiException &&
        (e.code == 'PAYMENT_REQUIRED_EMPLOYEE' ||
         e.code == 'PAYMENT_REQUIRED_MANAGER' ||
         e.code == 'PAYMENT_REQUIRED')) {
      final employeePayment = e.code == 'PAYMENT_REQUIRED_EMPLOYEE';
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (c) => AlertDialog(
          title: Text(employeePayment ? 'Firma Erişimi Kapalı' : 'Paket Süresi Doldu'),
          content: Text(
            employeePayment
                ? 'Lütfen Firmanız İle İletişime Geçiniz'
                : 'Lütfen paket ödeme işlemini gerçekleştiriniz.',
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(c), child: const Text('Tamam')),
          ],
        ),
      );
    } else {
      snack(context, '$e', error: true);
    }
  }

  Future<void> go() async {
    if (busy) return;
    setState(() => busy = true);
    try {
      final choose = await widget.state.login(email.text.trim(), pass.text);
      if (choose && mounted) {
        final companySearch = TextEditingController();
        List<dynamic> visible = List<dynamic>.from(widget.state.companies);
        await showDialog<void>(
          context: context,
          barrierDismissible: false,
          builder: (dialogContext) => StatefulBuilder(
            builder: (dialogContext, setModal) => AlertDialog(
              titlePadding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
              contentPadding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
              title: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Firma Seçimi', style: TextStyle(fontWeight: FontWeight.w900)),
                  SizedBox(height: 3),
                  Text('Yönetmek istediğiniz firmayı seçin.', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w400)),
                ],
              ),
              content: SizedBox(
                width: 520,
                height: MediaQuery.sizeOf(dialogContext).height * .62,
                child: Column(
                  children: [
                    TextField(
                      controller: companySearch,
                      autofocus: true,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.search),
                        hintText: 'Firma no veya firma adı ara',
                      ),
                      onChanged: (value) {
                        final q = value.trim().toLowerCase();
                        setModal(() {
                          visible = q.isEmpty
                              ? List<dynamic>.from(widget.state.companies)
                              : widget.state.companies.where((x) {
                                  final no = '#${(int.tryParse('${x['id']}') ?? 0).toString().padLeft(4, '0')}';
                                  final text = '$no ${x['id']} ${x['company_name'] ?? ''} ${x['short_name'] ?? ''}'.toLowerCase();
                                  return text.contains(q);
                                }).toList();
                        });
                      },
                    ),
                    const SizedBox(height: 10),
                    Expanded(
                      child: visible.isEmpty
                          ? const Center(child: Text('Aramanıza uygun firma bulunamadı.'))
                          : ListView.separated(
                              itemCount: visible.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 7),
                              itemBuilder: (_, index) {
                                final x = visible[index];
                                final id = int.tryParse('${x['id']}') ?? 0;
                                final no = id.toString().padLeft(4, '0');
                                return Material(
                                  color: const Color(0xFFF7F9FA),
                                  borderRadius: BorderRadius.circular(14),
                                  child: ListTile(
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                    leading: CircleAvatar(
                                      backgroundColor: const Color(0xFF17212B),
                                      foregroundColor: const Color(0xFFC9F400),
                                      child: Text('${x['company_name'] ?? '?' }'.isEmpty ? '?' : '${x['company_name']}'[0]),
                                    ),
                                    title: Text('${x['company_name'] ?? ''}', style: const TextStyle(fontWeight: FontWeight.w800)),
                                    subtitle: Text('Firma #$no${x['employee_count'] != null ? ' · ${x['employee_count']} personel' : ''}'),
                                    trailing: const Icon(Icons.chevron_right),
                                    onTap: () async {
                                      await widget.state.selectCompany(id);
                                      if (dialogContext.mounted) Navigator.pop(dialogContext);
                                    },
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }
    } catch (e) {
      await handleLoginError(e);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }



  Future<void> openLegal(String path, String title) async {
    final url = '${widget.state.api.publicRoot}/${path.replaceFirst(RegExp(r'^/+'), '')}';
    if (!mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => InAppBrowserScreen(url: url, title: title)),
    );
  }

  Future<void> employeeGo() async {
    if(employeeBusy || employeeCode.text.trim().isEmpty) return;
    setState(()=>employeeBusy=true);
    try{await widget.state.employeeLogin(employeeCode.text.trim());}
    catch(e){await handleLoginError(e);}
    finally{if(mounted)setState(()=>employeeBusy=false);}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(22),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                children: [
                  Container(padding:const EdgeInsets.symmetric(horizontal:18,vertical:12),decoration:BoxDecoration(color:Colors.white,borderRadius:BorderRadius.circular(18),boxShadow:MTheme.softShadow),child:Image.asset('assets/images/mleysoft-logo.png', height: 56)),
                  const SizedBox(height: 10),
                  const Text('İK Yönetim Sistemi', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: -.4)),
                  const SizedBox(height: 22),
                  Container(
                    decoration:BoxDecoration(color:MTheme.ink,borderRadius:BorderRadius.circular(16),boxShadow:MTheme.softShadow),
                    child:TabBar(controller:tabs,dividerColor:Colors.transparent,labelColor:MTheme.ink,unselectedLabelColor:Colors.white70,indicatorSize:TabBarIndicatorSize.tab,indicator:BoxDecoration(color:MTheme.lime,borderRadius:BorderRadius.circular(12)),tabs:const [Tab(text:'Yönetici Girişi'),Tab(text:'Personel Girişi')]),
                  ),
                  const SizedBox(height:18),
                  SizedBox(
                    height: 330,
                    child: TabBarView(
                      controller:tabs,
                      children:[
                        Column(children:[
                          TextField(controller:email,keyboardType:TextInputType.emailAddress,decoration:const InputDecoration(labelText:'E-posta')),
                          const SizedBox(height:12),
                          TextField(controller:pass,obscureText:hide,onSubmitted:(_)=>go(),decoration:InputDecoration(labelText:'Şifre',suffixIcon:IconButton(onPressed:()=>setState(()=>hide=!hide),icon:Icon(hide?Icons.visibility_outlined:Icons.visibility_off_outlined)))),
                          Align(alignment:Alignment.centerRight,child:TextButton(onPressed:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>ForgotPasswordScreen(state:widget.state))),child:const Text('Şifremi unuttum'))),
                          SizedBox(width:double.infinity,child:FilledButton(onPressed:busy?null:go,child:busy?const SizedBox(width:20,height:20,child:CircularProgressIndicator(strokeWidth:2)):const Text('Giriş Yap'))),
                        ]),
                        Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[
                          Container(padding:const EdgeInsets.all(14),decoration:BoxDecoration(color:const Color(0xFFF6FBE8),borderRadius:BorderRadius.circular(14)),child:const Text('Size özel mobil uygulama personel kodunu yalnızca kendi telefonunuzda kullanın. İlk girişte telefon bu personele bağlanır.',style:TextStyle(fontSize:12))),
                          const SizedBox(height:14),
                          TextField(controller:employeeCode,textCapitalization:TextCapitalization.characters,onSubmitted:(_)=>employeeGo(),decoration:const InputDecoration(labelText:'Mobil Personel Kodu',prefixIcon:Icon(Icons.badge_outlined),hintText:'Örn. IK-A1B2C3D4E5')),
                          const SizedBox(height:14),
                          FilledButton.icon(onPressed:employeeBusy?null:employeeGo,icon:const Icon(Icons.login),label:Text(employeeBusy?'Cihaz Doğrulanıyor...':'Personel Girişi')),
                          const SizedBox(height:10),
                          const Text('Bu mobil personel kodu başka bir telefona bağlıysa giriş engellenir. Telefon değişiminde firma yöneticiniz cihaz bağlantısını kaldırmalıdır.',textAlign:TextAlign.center,style:TextStyle(fontSize:10,color:MTheme.muted)),
                        ])
                      ],
                    ),
                  ),
                  const Row(children:[Expanded(child:Divider()),Padding(padding:EdgeInsets.symmetric(horizontal:10),child:Text('Henüz hesabınız yok mu?',style:TextStyle(fontSize:11,color:MTheme.muted))),Expanded(child:Divider())]),
                  const SizedBox(height:12),
                  SizedBox(width:double.infinity,child:OutlinedButton.icon(onPressed:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>RegisterCompanyScreen(state:widget.state))),icon:const Icon(Icons.business_outlined,size:18),label:const Text('Yeni Firma Kaydı'))),
                  const SizedBox(height:10),
                  const Text('Firma kaydınızı ve ödeme işlemlerinizi uygulamadan çıkmadan tamamlayabilirsiniz.',textAlign:TextAlign.center,style:TextStyle(fontSize:10,color:MTheme.muted)),
                  const SizedBox(height: 14),
                  Wrap(
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 4,
                    runSpacing: 2,
                    children: [
                      TextButton(
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                          minimumSize: const Size(0, 28),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        onPressed: () => openLegal('privacy.php', 'Gizlilik Politikası'),
                        child: const Text('Gizlilik Politikası', style: TextStyle(fontSize: 9.5, color: MTheme.muted)),
                      ),
                      const Text('·', style: TextStyle(fontSize: 9, color: MTheme.muted)),
                      TextButton(
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                          minimumSize: const Size(0, 28),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        onPressed: () => openLegal('kvkk.php', 'KVKK Aydınlatma'),
                        child: const Text('KVKK', style: TextStyle(fontSize: 9.5, color: MTheme.muted)),
                      ),
                      const Text('·', style: TextStyle(fontSize: 9, color: MTheme.muted)),
                      TextButton(
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                          minimumSize: const Size(0, 28),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        onPressed: () => openLegal('terms.php', 'Kullanım Koşulları'),
                        child: const Text('Kullanım Koşulları', style: TextStyle(fontSize: 9.5, color: MTheme.muted)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
