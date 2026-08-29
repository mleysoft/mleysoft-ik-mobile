import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'api.dart';
import 'biometric_service.dart';
import 'device_identity.dart';
import 'push_service.dart';
import '../widgets/branded_loading.dart';

class AppState extends ChangeNotifier {
  AppState(this.api) {
    api.onPaymentRequired = _handlePaymentRequired;
  }

  final ApiClient api;
  final BiometricService biometric = BiometricService();
  Map<String, dynamic>? user;
  Map<String, dynamic>? company;
  bool ready = false;
  bool biometricEnabled = false;
  bool locked = false;
  List<dynamic> companies = [];
  bool employeeMode = false;
  Map<String,dynamic>? employee;
  String? accessNotice;
  String? accessNoticeCode;
  String? accessPaymentUrl;
  bool paymentRequired = false;
  Map<String,dynamic>? subscription;
  int currentBuild = 0;
  String currentVersion = '';
  bool updateRequired = false;
  bool forceUpdateEnabled = false;
  int minimumRequiredBuild = 0;
  String updateStoreUrl = '';
  String updateMessage = 'MleySoft İK uygulamasının yeni bir sürümü yayınlandı. Devam etmek için uygulamayı güncellemeniz gerekiyor.';

  Future<void> _loadInstalledVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      currentVersion = info.version.trim();
      currentBuild = int.tryParse(info.buildNumber.trim()) ?? 0;
    } catch (_) {
      // Paket bilgisi okunamazsa zorunlu güncelleme asla uygulanmaz.
      currentVersion = '';
      currentBuild = 0;
    }
  }

  Future<void> _checkRequiredUpdate() async {
    final platform = Platform.isIOS ? 'ios' : 'android';

    // Eski sürümlerde secure storage'a minimum build yazılıyordu.
    // iOS Keychain uygulama silinse bile kalabildiği için bu eski değerlerin
    // App Review cihazında yanlış zorunlu güncelleme üretmesine izin vermiyoruz.
    try {
      await api.storage.delete(key: 'minimum_build_$platform');
      await api.storage.delete(key: 'store_url_$platform');
    } catch (_) {}

    // Ağ/API ulaşılamazsa kullanıcı kilitlenmez. Zorunlu güncelleme yalnızca
    // sunucudan o anda alınmış, açıkça etkin bir kural ile uygulanır.
    updateRequired = false;
    forceUpdateEnabled = false;
    minimumRequiredBuild = 0;

    if (currentBuild <= 0) return;

    try {
      final r = await api.request('app/version', query: {
        'platform': platform,
        'build': currentBuild,
      });
      minimumRequiredBuild =
          int.tryParse('${r['minimum_build'] ?? 0}') ?? 0;
      updateStoreUrl = '${r['store_url'] ?? ''}';
      updateMessage = '${r['message'] ?? updateMessage}';
      forceUpdateEnabled = r['force_enabled'] == true ||
          '${r['force_enabled'] ?? '0'}' == '1';
      updateRequired = forceUpdateEnabled &&
          minimumRequiredBuild > 0 &&
          currentBuild < minimumRequiredBuild;
    } catch (_) {
      updateRequired = false;
      forceUpdateEnabled = false;
    }
  }

  Future<void> recheckRequiredUpdate() async {
    await _checkRequiredUpdate();
    notifyListeners();
  }


  Future<void> _handlePaymentRequired(ApiException error) async {
    final wasEmployee = employeeMode || error.code == 'PAYMENT_REQUIRED_EMPLOYEE';
    if (!wasEmployee) { paymentRequired = true; subscription = error.details['subscription'] is Map ? Map<String,dynamic>.from(error.details['subscription']) : subscription; notifyListeners(); return; }
    await api.saveToken(null);
    await api.storage.delete(key: 'session_mode');
    await api.storage.delete(key: 'employee_notice_last_notified_id');
    await api.storage.delete(key: 'employee_id');
    await api.storage.delete(key: 'pending_announcement_id');
    paymentRequired = false; subscription = null;
    employeeMode = false;
    employee = null;
    user = null;
    company = null;
    companies = [];
    locked = false;
    accessNoticeCode = wasEmployee ? 'PAYMENT_REQUIRED_EMPLOYEE' : 'PAYMENT_REQUIRED_MANAGER';
    accessNotice = wasEmployee
        ? 'Lütfen Firmanız İle İletişime Geçiniz'
        : 'Lütfen paket ödeme işlemini gerçekleştiriniz.';
    accessPaymentUrl = wasEmployee ? null : (error.paymentUrl ?? 'https://mleysoft.com/system/ik/login.php');
    notifyListeners();
  }

  void clearAccessNotice() {
    accessNotice = null;
    accessNoticeCode = null;
    accessPaymentUrl = null;
    notifyListeners();
  }

  bool get loggedIn => api.token != null && (user != null || employee != null);
  bool get hasStoredSession => api.token != null;
  bool get isSuper => user?['role'] == 'super_admin';

  Future<void> bootstrap() async {
    try {
      await _loadInstalledVersion();
      await _checkRequiredUpdate();
      if (updateRequired) return;
      await api.loadToken();
      try {
        employeeMode = (await api.storage.read(key: 'session_mode')) == 'employee';
      } catch (_) {
        employeeMode = false;
      }
      biometricEnabled = employeeMode ? false : await biometric.isEnabled();
      if (api.token != null && biometricEnabled) {
        locked = true;
        return;
      }
      await _hydrate();
    } catch (_) {
      // Native storage / biyometri eklentisi cihaz özelinde hata verse bile
      // login ekranı mutlaka açılır.
      user = null;
      employee = null;
      company = null;
      employeeMode = false;
      locked = false;
    } finally {
      ready = true;
      notifyListeners();
    }
  }

  Future<void> _hydrate() async {
    if (api.token == null) return;
    try {
      if (employeeMode) {
        final r = await api.request('employee-auth/me');
        employee = Map<String, dynamic>.from(r['employee']);
        company = Map<String, dynamic>.from(r['company']);
        user = null;
        await api.storage.write(key: 'employee_id', value: '${employee?['id'] ?? ''}');

        // V168: Personel oturumu açılır açılmaz arayüz hazır hale gelir.
        // APNs/FCM kaydı arka planda yapılır; iOS APNs tokenının gecikmesi
        // splash/başlangıç ekranını artık bloke etmez.
        unawaited(
          PushService.instance.registerEmployee(
            api,
            employeeId: int.tryParse('${employee?['id'] ?? 0}'),
          ),
        );
        return;
      }

      // V158: Normal yönetici ve seçilmiş Super Admin aynı auth/me/token yolunu kullanır.
      final r = await api.request('auth/me');
      user = Map<String, dynamic>.from(r['user']);
      employee = null;
      final companyId = int.tryParse('${r['company_id'] ?? 0}') ?? 0;
      company = companyId > 0
          ? {'id': companyId, 'company_name': r['company_name']}
          : null;
      if (user?['role'] != 'super_admin' && companyId > 0) { unawaited(PushService.instance.registerManager(api)); }
      paymentRequired = r['payment_required'] == true;
      subscription = r['subscription'] is Map
          ? Map<String, dynamic>.from(r['subscription'])
          : null;
    } catch (e) {
      if (e is ApiException && e.status == 401) {
        if (api.token != null) await api.saveToken(null);
        user = null;
        employee = null;
        company = null;
      }
    }
  }

  Future<bool> unlock() async {
    if (!locked) return true;
    final ok = await biometric.authenticate();
    if (!ok) return false;
    locked = false;
    await _hydrate();
    notifyListeners();
    return true;
  }

  Future<void> setBiometricEnabled(bool enabled) async {
    if (enabled) {
      final supported = await biometric.isSupported();
      if (!supported) throw ApiException('Bu cihazda biyometrik doğrulama kullanılamıyor.', 400);
      final ok = await biometric.authenticate(reason: 'Biyometrik girişi etkinleştirin');
      if (!ok) throw ApiException('Biyometrik doğrulama tamamlanamadı.', 400);
    }
    await biometric.setEnabled(enabled);
    biometricEnabled = enabled;
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    final device = await DeviceIdentity.collect();
    final r = await api.request('auth/login', method: 'POST', data: {
      'email': email,
      'password': password,
      'device_name': 'Flutter Native V102',
      ...device,
    });
    await api.saveToken(r['token']);
    await api.storage.write(key:'session_mode',value:'admin');
    employeeMode=false;employee=null;
    user = Map<String, dynamic>.from(r['user']);
    companies = (r['companies'] ?? []) as List;
    if (user?['role'] == 'super_admin' && r['requires_company'] == true) {
      company = null;
      try {
        await api.storage.delete(key: 'super_admin_company_id');
      } catch (_) {}
    }
    if (r['company'] != null) company = Map<String, dynamic>.from(r['company']);
    paymentRequired = r['payment_required'] == true;
    subscription = r['subscription'] is Map ? Map<String,dynamic>.from(r['subscription']) : null;
    locked = false;
    notifyListeners();
    return r['requires_company'] == true;
  }

  Future<void> acceptRegistration(Map<String,dynamic> r) async {
    await api.saveToken(r['token']?.toString());
    await api.storage.write(key:'session_mode',value:'admin');
    employeeMode=false; employee=null;
    user=Map<String,dynamic>.from(r['user']); company=Map<String,dynamic>.from(r['company']);
    paymentRequired=true; subscription=null; locked=false; notifyListeners();
  }

  void updateSubscription(dynamic value){
    if(value is Map){subscription=Map<String,dynamic>.from(value);paymentRequired=subscription?['allowed']!=true;notifyListeners();}
  }

  Future<void> requestManagerDeviceTransfer(String email, String password) async {
    final device = await DeviceIdentity.collect();
    await api.request('auth/request-device-transfer', method: 'POST', data: {
      'email': email,
      'password': password,
      'device_name': 'Flutter Native V102',
      ...device,
    });
  }

  Future<bool> confirmManagerDeviceTransfer(String email, String password, String code) async {
    final device = await DeviceIdentity.collect();
    final r = await api.request('auth/confirm-device-transfer', method: 'POST', data: {
      'email': email,
      'password': password,
      'code': code,
      'device_name': 'Flutter Native V102',
      ...device,
    });
    await api.saveToken(r['token']);
    await api.storage.write(key:'session_mode',value:'admin');
    employeeMode=false;employee=null;
    user = Map<String,dynamic>.from(r['user']);
    companies = (r['companies'] ?? []) as List;
    company = r['company'] == null ? null : Map<String,dynamic>.from(r['company']);
    locked=false;
    notifyListeners();
    return r['requires_company'] == true;
  }



  Future<void> refreshEmployeePushRegistration() async {
    if (!employeeMode || api.token == null || employee == null) return;
    try {
      await PushService.instance.registerEmployee(
          api,
          employeeId: int.tryParse('${employee?['id'] ?? 0}'),
        );
    } catch (_) {}
  }

  Future<void> employeeLogin(String employeeCode) async {
    final device = await DeviceIdentity.collect();
    final r = await api.request('employee-auth/login', method: 'POST', data: {
      'employee_code': employeeCode.trim(),
      ...device,
    });
    await api.saveToken(r['token']);
    await api.storage.write(key:'session_mode', value:'employee');
    await api.storage.delete(key: 'employee_notice_last_notified_id');
    await api.storage.delete(key: 'pending_announcement_id');
    employeeMode = true;
    employee = Map<String,dynamic>.from(r['employee']);
    company = Map<String,dynamic>.from(r['company']);
    await api.storage.write(key: 'employee_id', value: '${employee?['id'] ?? ''}');
    user = null;
    locked = false;
    notifyListeners();

    // Giriş tamamlandıktan sonra push kaydı arka planda devam eder.
    unawaited(
      PushService.instance.registerEmployee(
        api,
        employeeId: int.tryParse('${employee?['id'] ?? 0}'),
      ),
    );
  }

  Future<void> resetPassword(String resetToken, String newPassword) async {
    final device = await DeviceIdentity.collect();
    final r = await api.request('auth/reset-password', method: 'POST', data: {
      'token': resetToken,
      'password': newPassword,
      'device_name': 'Flutter Native V102',
      ...device,
    });
    await api.saveToken(r['token']);
    user = Map<String, dynamic>.from(r['user']);
    companies = (r['companies'] ?? []) as List;
    company = r['company'] == null ? null : Map<String, dynamic>.from(r['company']);
    locked = false;
    notifyListeners();
  }

  Future<void> refreshCompanies() async {
    if (!isSuper || api.token == null) return;
    final r = await api.request('companies');
    companies = (r['companies'] ?? []) as List;
    notifyListeners();
  }

  Future<void> selectCompany(int id) async {
    if (!isSuper || id <= 0) {
      throw ApiException('Geçerli bir firma seçiniz.', 422);
    }

    final beforeToken = api.token;
    if (beforeToken == null || beforeToken.isEmpty) {
      throw ApiException('Yönetici oturumu bulunamadı.', 401);
    }

    final r = await api.request(
      'auth/select-company',
      method: 'POST',
      data: {'company_id': id},
    );

    final selected = r['company'];
    final activeId = int.tryParse('${r['active_company_id'] ?? 0}') ?? 0;
    if (selected is! Map || activeId != id) {
      throw ApiException('Firma oturumu doğrulanamadı.', 500);
    }

    if (api.token != beforeToken) {
      await api.saveToken(beforeToken);
    }

    company = Map<String, dynamic>.from(selected);
    await api.storage.write(key: 'super_admin_company_id', value: '$id');
    paymentRequired = false;
    subscription = null;
    locked = false;
    notifyListeners();
  }

  Future<void> selectCompanyInShell(int id) async {
    if (!isSuper || id <= 0) {
      throw ApiException('Geçerli bir firma seçiniz.', 422);
    }
    final r = await api.request(
      'auth/select-company',
      method: 'POST',
      data: {'company_id': id},
    );
    final selected = r['company'];
    final activeId = int.tryParse('${r['active_company_id'] ?? 0}') ?? 0;
    if (selected is! Map || activeId != id) {
      throw ApiException('Firma oturumu doğrulanamadı.', 500);
    }
    company = Map<String, dynamic>.from(selected);
    await api.storage.write(key: 'super_admin_company_id', value: '$id');
    paymentRequired = false;
    subscription = null;
    locked = false;
  }

  Future<void> clearCompany() async {
    if (isSuper && api.token != null) {
      try {
        await api.request('auth/clear-company', method: 'POST');
      } catch (_) {}
      try {
        await api.storage.delete(key: 'super_admin_company_id');
      } catch (_) {}
    }
    company = null;
    notifyListeners();
  }

  Future<void> logout() async {
    if (api.token != null && !employeeMode) {
      if (!isSuper) { try { await api.request('manager/push-token/revoke', method: 'POST'); } catch (_) {} }
      try { await api.request('auth/logout', method: 'POST'); } catch (_) {}
    } else if (api.token != null && employeeMode) {
      // Önce FCM cihazını bu personel oturumundan ayır.
      await PushService.instance.unregisterEmployee(api);
      try { await api.request('employee-auth/logout', method: 'POST'); } catch (_) {}
    }
    await api.saveToken(null);
    await api.storage.delete(key: 'session_mode');
    await api.storage.delete(key: 'employee_notice_last_notified_id');
    await api.storage.delete(key: 'employee_id');
    await api.storage.delete(key: 'pending_announcement_id');
    paymentRequired = false;
    subscription = null;
    employeeMode = false;
    employee = null;
    user = null;
    company = null;
    companies = [];
    locked = false;
    MleyLoadingController.instance.reset();
    notifyListeners();
  }
}
