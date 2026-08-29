import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:app_links/app_links.dart';
import 'core/api.dart';
import 'core/app_state.dart';
import 'core/notification_service.dart';
import 'core/native_notification_permission_service.dart';
import 'core/push_service.dart';
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

  // FCM background handler uygulama ayağa kalkmadan kaydedilir.
  // Firebase yapılandırmasında sorun olsa bile bootstrap kendi içinde hatayı yutar
  // ve login ekranının açılmasını engellemez.
  await PushService.instance.bootstrapForBackground();

  runApp(const MleyApp());
  unawaited(_initializeNativeServices());
}

Future<void> _initializeNativeServices() async {
  try { await PushService.instance.initialize(); } catch (_) {}
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

class _MleyAppState extends State<MleyApp> with WidgetsBindingObserver {
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
    WidgetsBinding.instance.addObserver(this);
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
    bool done = false;
    bool denied = false;

    try {
      // V167: İlk kurulumda izin akışının tek sahibi burasıdır.
      // 1) Sistem izni zaten açıksa MleySoft açıklama ekranı gösterilmez.
      // 2) Sistem henüz sormadıysa doğrudan native izin penceresi açılır.
      // 3) Kullanıcı reddederse ancak o zaman açıklamalı "Bildirimleri Açın"
      //    ekranı gösterilir ve kullanıcı "Daha Sonra" diyebilir.
      final alreadyGranted =
          await NotificationService.instance.isPermissionGranted();

      if (alreadyGranted) {
        await NotificationService.instance.markPermissionIntroShown();
        done = true;
      } else if (Platform.isIOS) {
        final status = await NativeNotificationPermissionService.status();
        if (status == NativeNotificationAuthorizationStatus.notDetermined) {
          final granted =
              await NotificationService.instance.requestPermission();
          if (granted) {
            await NotificationService.instance.markPermissionIntroShown();
            await NativeNotificationPermissionService
                .ensureRemoteRegistration();
            done = true;
          } else {
            denied = true;
            done = false;
          }
        } else {
          denied =
              status == NativeNotificationAuthorizationStatus.denied;
          done = false;
        }
      } else {
        // Android 13+ ilk açılış native POST_NOTIFICATIONS izni.
        // Kabul edilirse ikinci uygulama ekranı kesinlikle gösterilmez.
        final introWasHandled =
            await NotificationService.instance.hasShownPermissionIntro();
        if (!introWasHandled) {
          final granted =
              await NotificationService.instance.requestPermission();
          if (granted) {
            await NotificationService.instance.markPermissionIntroShown();
            done = true;
          } else {
            denied = true;
            done = false;
          }
        } else {
          // Kullanıcı daha önce "Daha Sonra" dedi; uygulamayı engelleme.
          done = true;
          denied = true;
        }
      }
    } catch (_) {
      // İzin altyapısındaki bir hata login ekranını engellemez.
      done = true;
    }

    if (!mounted) return;
    setState(() {
      notificationPermissionDenied = denied;
      notificationIntroDone = done;
      notificationIntroLoaded = true;
    });
  }

  Future<void> _allowNotifications() async {
    if (Platform.isIOS && notificationPermissionDenied) {
      await NativeNotificationPermissionService.openSettings();
      return;
    }

    final granted = await NotificationService.instance.requestPermission();
    if (!granted) {
      if (mounted) {
        setState(() => notificationPermissionDenied = true);
      }
      return;
    }

    await NotificationService.instance.markPermissionIntroShown();
    if (Platform.isIOS) {
      await NativeNotificationPermissionService.ensureRemoteRegistration();
    }
    if (state.employeeMode && state.loggedIn) {
      unawaited(state.refreshEmployeePushRegistration());
    }
    if (mounted) {
      setState(() {
        notificationPermissionDenied = false;
        notificationIntroDone = true;
      });
    }
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

  Future<void> _refreshNotificationPermissionAfterResume() async {
    try {
      final granted =
          await NotificationService.instance.isPermissionGranted();
      if (!granted || !mounted) return;
      await NotificationService.instance.markPermissionIntroShown();
      if (Platform.isIOS) {
        await NativeNotificationPermissionService.ensureRemoteRegistration();
      }
      if (state.employeeMode && state.loggedIn) {
        await state.refreshEmployeePushRegistration();
      } else if (state.loggedIn) {
        // V185: iOS APNs/FCM tokenı uygulama resume olduğunda firma oturumunda da tazelenir.
        await state.refreshManagerPushRegistration();
      }
      if (mounted) {
        setState(() {
          notificationPermissionDenied = false;
          notificationIntroDone = true;
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    state.removeListener(_stateChanged);
    sub?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState lifecycleState) {
    if (lifecycleState == AppLifecycleState.resumed) {
      unawaited(state.validateSessionOnResume());
      // Tek bir resume zinciri izin/APNs/push durumunu arka planda kontrol eder.
      // Önceki sürümde aynı anda iki registerEmployee çağrısı başlayabiliyordu.
      unawaited(_refreshNotificationPermissionAfterResume());
    }
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
