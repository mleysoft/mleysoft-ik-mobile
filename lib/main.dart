import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:app_links/app_links.dart';
import 'core/api.dart';
import 'core/app_state.dart';
import 'core/notification_service.dart';
import 'core/native_notification_permission_service.dart';
import 'core/theme.dart';
import 'screens/biometric_lock.dart';
import 'screens/employee_portal.dart';
import 'screens/login.dart';
import 'screens/billing_native.dart';
import 'widgets/connectivity_banner.dart';
import 'screens/notification_permission.dart';
import 'screens/reset_password.dart';
import 'screens/forced_update.dart';
import 'screens/shell.dart';
import 'widgets/branded_loading.dart';

final navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Uygulama arayüzü hiçbir native eklentinin başlatılmasını beklemez.
  // Bazı gerçek Android cihazlarında WorkManager / bildirim servisi üreticiye
  // özgü bir hata verirse uygulamanın açılışta kapanmasını engeller.
  runApp(const MleyApp());

  unawaited(_initializeNativeServices());
}

Future<void> _initializeNativeServices() async {
  try {
    await NotificationService.instance.initialize();
  } catch (e, st) {
    debugPrint('NotificationService startup error: $e\n$st');
  }

  try {
    await NotificationService.instance.initializeBackgroundScheduler();
  } catch (e, st) {
    debugPrint('Workmanager startup error: $e\n$st');
  }
}

class MleyApp extends StatefulWidget {
  const MleyApp({super.key});

  @override
  State<MleyApp> createState() => _MleyAppState();
}

class _MleyAppState extends State<MleyApp> {
  late final AppState state;
  final AppLinks links = AppLinks();
  StreamSubscription<Uri>? sub;
  String? pendingResetToken;
  bool notificationsConfigured = false;
  bool notificationIntroLoaded = false;
  bool notificationIntroDone = false;
  bool notificationPermissionDenied = false;
  bool accessNoticeDialogOpen = false;

  @override
  void initState() {
    super.initState();
    const apiBase = String.fromEnvironment(
      'API_BASE_URL',
      defaultValue: 'https://mleysoft.com/system/ik',
    );
    state = AppState(ApiClient(apiBase));
    state.addListener(_stateChanged);
    _links();
    state.bootstrap();
    _loadNotificationIntro();
  }


  Future<void> _loadNotificationIntro() async {
    bool shown = false;
    bool denied = false;
    try {
      if (Platform.isIOS) {
        // V118: iOS'ta secure storage/keychain reinstall sonrası kalabildiği için
        // yalnız yerel 'intro gösterildi' anahtarına güvenmiyoruz. Gerçek sistem
        // bildirim yetkisi her açılışta UNUserNotificationCenter'dan okunur.
        final status = await NativeNotificationPermissionService.status();
        switch (status) {
          case NativeNotificationAuthorizationStatus.notDetermined:
            shown = false;
            break;
          case NativeNotificationAuthorizationStatus.denied:
            shown = false;
            denied = true;
            break;
          case NativeNotificationAuthorizationStatus.authorized:
          case NativeNotificationAuthorizationStatus.provisional:
          case NativeNotificationAuthorizationStatus.ephemeral:
            shown = true;
            break;
          case NativeNotificationAuthorizationStatus.unknown:
            shown = await NotificationService.instance.hasShownPermissionIntro();
            break;
        }
      } else {
        shown = await NotificationService.instance.hasShownPermissionIntro();
      }
    } catch (_) {
      shown = false;
    }
    if (!mounted) return;
    setState(() {
      notificationPermissionDenied = denied;
      notificationIntroDone = shown;
      notificationIntroLoaded = true;
    });
  }

  Future<void> _allowNotifications() async {
    if (Platform.isIOS && notificationPermissionDenied) {
      await NativeNotificationPermissionService.openSettings();
      return;
    }
    final granted = await NotificationService.instance.requestPermission();
    if (Platform.isIOS && !granted) {
      final status = await NativeNotificationPermissionService.status();
      if (mounted) {
        setState(() => notificationPermissionDenied = status == NativeNotificationAuthorizationStatus.denied);
      }
      return;
    }
    await NotificationService.instance.markPermissionIntroShown();
    if (mounted) setState(() => notificationIntroDone = true);
  }

  Future<void> _skipNotifications() async {
    await NotificationService.instance.markPermissionIntroShown();
    if (mounted) setState(() => notificationIntroDone = true);
  }

  void _stateChanged() {
    if (mounted) setState(() {});
    if (state.accessNotice != null && !accessNoticeDialogOpen) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _showAccessNotice());
    }
    final hasCompany = state.loggedIn && state.company?['id'] != null;
    if (hasCompany && !notificationsConfigured) {
      notificationsConfigured = true;
      NotificationService.instance.configureDailyChecks(employeeMode: state.employeeMode);
    } else if (!hasCompany && notificationsConfigured) {
      notificationsConfigured = false;
      NotificationService.instance.cancelDailyChecks();
    }
  }


  Future<void> _showAccessNotice() async {
    if (!mounted || accessNoticeDialogOpen || state.accessNotice == null) return;
    accessNoticeDialogOpen = true;
    final employeeBlocked = state.accessNoticeCode == 'PAYMENT_REQUIRED_EMPLOYEE';
    final message = state.accessNotice!;
    await showDialog<void>(
      context: navigatorKey.currentContext!,
      barrierDismissible: false,
      builder: (c) => AlertDialog(
        title: Text(employeeBlocked ? 'Firma Erişimi Kapalı' : 'Paket Süresi Doldu'),
        content: Text(message),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c), child: const Text('Tamam')),
        ],
      ),
    );
    state.clearAccessNotice();
    accessNoticeDialogOpen = false;
  }

  Future<void> _links() async {
    try {
      final initial = await links.getInitialLink();
      if (initial != null) _handle(initial);
    } catch (_) {}
    sub = links.uriLinkStream.listen(_handle);
  }

  void _handle(Uri uri) {
    if (uri.scheme == 'mleysoftik' && uri.host == 'reset-password') {
      final token = uri.queryParameters['token'];
      if (token != null && token.isNotEmpty) {
        pendingResetToken = token;
        WidgetsBinding.instance.addPostFrameCallback((_) {
      _openReset();
      if (state.accessNotice != null && !accessNoticeDialogOpen) _showAccessNotice();
    });
      }
    }
  }

  void _openReset() {
    if (!state.ready || pendingResetToken == null || navigatorKey.currentContext == null) return;
    final token = pendingResetToken!;
    pendingResetToken = null;
    navigatorKey.currentState!.push(
      MaterialPageRoute(builder: (_) => ResetPasswordScreen(state: state, token: token)),
    );
  }

  @override
  void dispose() {
    state.removeListener(_stateChanged);
    sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget home;
    if (!state.ready || !notificationIntroLoaded) {
      home = const MleySplashScreen();
    } else if (state.updateRequired) {
      home = ForcedUpdateScreen(state: state);
    } else if (!notificationIntroDone) {
      home = NotificationPermissionScreen(onAllow: _allowNotifications, onLater: _skipNotifications, permissionDenied: notificationPermissionDenied);
    } else if (state.locked && state.hasStoredSession) {
      home = BiometricLockScreen(state: state);
    } else if (state.paymentRequired && state.loggedIn && !state.employeeMode) {
      home = BillingNativeScreen(state: state);
    } else if (state.employeeMode && state.loggedIn) {
      home = EmployeePortalScreen(state: state);
    } else if (state.loggedIn && state.company?['id'] != null) {
      home = AppShell(state: state);
    } else {
      home = LoginScreen(state: state);
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _openReset();
      if (state.accessNotice != null && !accessNoticeDialogOpen) _showAccessNotice();
    });

    return MaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      title: 'MleySoft İK',
      theme: MTheme.light,
      builder: (context, child) => state.ready
          ? ConnectivityBanner(child: MleyGlobalLoadingOverlay(child: child ?? const SizedBox.shrink()))
          : (child ?? const SizedBox.shrink()),
      home: home,
    );
  }
}
