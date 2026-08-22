import 'package:flutter/foundation.dart';
import 'api.dart';
import 'biometric_service.dart';
import 'device_identity.dart';
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


  Future<void> _handlePaymentRequired(ApiException error) async {
    final wasEmployee = employeeMode || error.code == 'PAYMENT_REQUIRED_EMPLOYEE';
    await api.saveToken(null);
    await api.storage.delete(key: 'session_mode');
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
      if(employeeMode){
        final r = await api.request('employee-auth/me');
        employee = Map<String,dynamic>.from(r['employee']);
        company = Map<String,dynamic>.from(r['company']);
        user = null;
        return;
      }
      final r = await api.request('auth/me');
      user = Map<String, dynamic>.from(r['user']);
      employee = null;
      final companyId = int.tryParse('${r['company_id'] ?? 0}') ?? 0;
      company = companyId > 0 ? {'id': companyId, 'company_name': r['company_name']} : null;
    } catch (_) {
      if (api.token != null) await api.saveToken(null);
      user = null;
      employee = null;
      company = null;
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
    final r = await api.request('auth/login', method: 'POST', data: {
      'email': email,
      'password': password,
      'device_name': 'Flutter Native V99',
    });
    await api.saveToken(r['token']);
    await api.storage.write(key:'session_mode',value:'admin');
    employeeMode=false;employee=null;
    user = Map<String, dynamic>.from(r['user']);
    companies = (r['companies'] ?? []) as List;
    if (r['company'] != null) company = Map<String, dynamic>.from(r['company']);
    locked = false;
    notifyListeners();
    return r['requires_company'] == true;
  }



  Future<void> employeeLogin(String employeeCode) async {
    final device = await DeviceIdentity.collect();
    final r = await api.request('employee-auth/login', method: 'POST', data: {
      'employee_code': employeeCode.trim(),
      ...device,
    });
    await api.saveToken(r['token']);
    await api.storage.write(key:'session_mode', value:'employee');
    employeeMode = true;
    employee = Map<String,dynamic>.from(r['employee']);
    company = Map<String,dynamic>.from(r['company']);
    user = null;
    locked = false;
    notifyListeners();
  }

  Future<void> resetPassword(String resetToken, String newPassword) async {
    final r = await api.request('auth/reset-password', method: 'POST', data: {
      'token': resetToken,
      'password': newPassword,
      'device_name': 'Flutter Native V99',
    });
    await api.saveToken(r['token']);
    user = Map<String, dynamic>.from(r['user']);
    companies = (r['companies'] ?? []) as List;
    company = r['company'] == null ? null : Map<String, dynamic>.from(r['company']);
    locked = false;
    notifyListeners();
  }

  Future<void> selectCompany(int id) async {
    final r = await api.request('auth/select-company', method: 'POST', data: {'company_id': id});
    company = Map<String, dynamic>.from(r['company']);
    notifyListeners();
  }

  Future<void> clearCompany() async {
    company = null;
    notifyListeners();
  }

  Future<void> logout() async {
    await api.saveToken(null);
    await api.storage.delete(key: 'session_mode');
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
