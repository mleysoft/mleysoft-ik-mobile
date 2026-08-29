import Flutter
import UIKit
import CoreLocation
import UserNotifications
import FirebaseMessaging

public final class MleySoftNativeBridgePlugin: NSObject, FlutterPlugin, CLLocationManagerDelegate {
  private let locationManager = CLLocationManager()
  private var pendingLocationResult: FlutterResult?
  private var locationTimeout: DispatchWorkItem?

  public static func register(with registrar: FlutterPluginRegistrar) {
    let instance = MleySoftNativeBridgePlugin()
    let messenger = registrar.messenger()

    let locationChannel = FlutterMethodChannel(
      name: "com.mleysoft.ik/location",
      binaryMessenger: messenger
    )
    registrar.addMethodCallDelegate(instance, channel: locationChannel)

    let permissionChannel = FlutterMethodChannel(
      name: "com.mleysoft.ik/permissions",
      binaryMessenger: messenger
    )
    permissionChannel.setMethodCallHandler { [weak instance] call, result in
      instance?.handlePermissionCall(call, result: result)
    }

    let badgeChannel = FlutterMethodChannel(
      name: "com.mleysoft.ik/badge",
      binaryMessenger: messenger
    )
    UNUserNotificationCenter.current().getNotificationSettings { settings in
      if settings.authorizationStatus == .authorized ||
         settings.authorizationStatus == .provisional ||
         settings.authorizationStatus == .ephemeral {
        DispatchQueue.main.async {
          UIApplication.shared.registerForRemoteNotifications()
        }
      }
    }

    badgeChannel.setMethodCallHandler { call, result in
      if call.method == "setBadge",
         let args = call.arguments as? [String: Any],
         let count = args["count"] as? Int {
        DispatchQueue.main.async {
          UIApplication.shared.applicationIconBadgeNumber = max(0, count)
          result(true)
        }
      } else {
        result(FlutterMethodNotImplemented)
      }
    }
  }

  public override init() {
    super.init()
    locationManager.delegate = self
    locationManager.desiredAccuracy = kCLLocationAccuracyBest
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard call.method == "getCurrentLocation" else {
      result(FlutterMethodNotImplemented)
      return
    }
    DispatchQueue.main.async { [weak self] in
      self?.requestCurrentLocation(result)
    }
  }

  private func requestCurrentLocation(_ result: @escaping FlutterResult) {
    guard CLLocationManager.locationServicesEnabled() else {
      result(FlutterError(code: "LOCATION_SERVICE_DISABLED", message: "Konum servisi kapalı.", details: nil))
      return
    }
    guard pendingLocationResult == nil else {
      result(FlutterError(code: "LOCATION_BUSY", message: "Konum bilgisi alınıyor.", details: nil))
      return
    }

    pendingLocationResult = result
    locationTimeout?.cancel()
    let work = DispatchWorkItem { [weak self] in
      guard let self, self.pendingLocationResult != nil else { return }
      self.finishLocation(error: FlutterError(
        code: "LOCATION_TIMEOUT",
        message: "Konum bilgisi zamanında alınamadı. Konum servisini kontrol edip tekrar deneyin.",
        details: nil
      ))
    }
    locationTimeout = work
    DispatchQueue.main.asyncAfter(deadline: .now() + 12, execute: work)

    switch locationManager.authorizationStatus {
    case .notDetermined:
      locationManager.requestWhenInUseAuthorization()
    case .authorizedWhenInUse, .authorizedAlways:
      locationManager.requestLocation()
    case .denied, .restricted:
      finishLocation(error: FlutterError(
        code: "LOCATION_PERMISSION_DENIED_FOREVER",
        message: "Konum izni gerekli.",
        details: nil
      ))
    @unknown default:
      finishLocation(error: FlutterError(
        code: "LOCATION_PERMISSION_DENIED",
        message: "Konum izni gerekli.",
        details: nil
      ))
    }
  }

  public func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
    guard pendingLocationResult != nil else { return }
    switch manager.authorizationStatus {
    case .authorizedWhenInUse, .authorizedAlways:
      manager.requestLocation()
    case .denied, .restricted:
      finishLocation(error: FlutterError(
        code: "LOCATION_PERMISSION_DENIED",
        message: "Konum izni gerekli.",
        details: nil
      ))
    default:
      break
    }
  }

  public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
    guard let location = locations.last else {
      finishLocation(error: FlutterError(code: "LOCATION_ERROR", message: "Konum bilgisi alınamadı.", details: nil))
      return
    }
    locationTimeout?.cancel()
    locationTimeout = nil
    let callback = pendingLocationResult
    pendingLocationResult = nil
    callback?([
      "latitude": location.coordinate.latitude,
      "longitude": location.coordinate.longitude,
      "accuracy": location.horizontalAccuracy
    ])
  }

  public func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
    finishLocation(error: FlutterError(code: "LOCATION_ERROR", message: error.localizedDescription, details: nil))
  }

  private func finishLocation(error: FlutterError) {
    locationTimeout?.cancel()
    locationTimeout = nil
    let callback = pendingLocationResult
    pendingLocationResult = nil
    callback?(error)
  }

  private func handlePermissionCall(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "getNotificationAuthorizationStatus":
      UNUserNotificationCenter.current().getNotificationSettings { settings in
        let value: String
        switch settings.authorizationStatus {
        case .notDetermined: value = "notDetermined"
        case .denied: value = "denied"
        case .authorized: value = "authorized"
        case .provisional: value = "provisional"
        case .ephemeral: value = "ephemeral"
        @unknown default: value = "unknown"
        }
        DispatchQueue.main.async { result(value) }
      }

    case "requestNotificationPermission":
      UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
        DispatchQueue.main.async {
          if let error {
            result(FlutterError(code: "NOTIFICATION_PERMISSION_ERROR", message: error.localizedDescription, details: nil))
          } else {
            if granted {
              UIApplication.shared.registerForRemoteNotifications()
            }
            result(granted)
          }
        }
      }

    case "registerForRemoteNotifications":
      DispatchQueue.main.async {
        UIApplication.shared.registerForRemoteNotifications()
        result(true)
      }

    case "getNativePushTokens":
      // V197: Firebase iOS SDK'dan tokeni doğrudan native katmanda da al.
      // FlutterFire getToken gecikirse/boş dönerse aynı Firebase Messaging
      // instance'ının gerçek registration tokenı yedek yol olarak kullanılır.
      DispatchQueue.main.async {
        UIApplication.shared.registerForRemoteNotifications()
        Messaging.messaging().token { fcmToken, error in
          if let error {
            result(FlutterError(code: "FCM_TOKEN_ERROR", message: error.localizedDescription, details: nil))
            return
          }
          let apns = Messaging.messaging().apnsToken?.map { String(format: "%02x", $0) }.joined() ?? ""
          result(["fcm_token": fcmToken ?? "", "apns_token": apns])
        }
      }

    case "openNotificationSettings":
      DispatchQueue.main.async {
        guard let url = URL(string: UIApplication.openSettingsURLString) else {
          result(false)
          return
        }
        UIApplication.shared.open(url, options: [:]) { success in result(success) }
      }

    default:
      result(FlutterMethodNotImplemented)
    }
  }
}
