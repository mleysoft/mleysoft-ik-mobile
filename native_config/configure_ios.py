#!/usr/bin/env python3
from pathlib import Path
import json, shutil, sys

root = Path(__file__).resolve().parents[1]
ios = root / "ios"
runner = ios / "Runner"
assets = runner / "Assets.xcassets"
appicon = assets / "AppIcon.appiconset"
launchset = assets / "LaunchImage.imageset"

if not ios.exists():
    raise SystemExit("ios klasoru bulunamadi. Once: flutter create --platforms=ios .")

appicon.mkdir(parents=True, exist_ok=True)
source_dir = root / "assets" / "ios_appicon"

for f in source_dir.glob("*.png"):
    shutil.copy2(f, appicon / f.name)


# V62: if user-provided platform icon pack exists, copy it over AppIcon.
platform_ios = root / "assets" / "platform_icons" / "ios"
if platform_ios.exists():
    mapping = {
      "appicon_Icon-20x20.png":"Icon-App-20x20@1x.png",
      "appicon_Icon-20x20_2x.png":"Icon-App-20x20@2x.png",
      "appicon_Icon-20x20_3x.png":"Icon-App-20x20@3x.png",
      "appicon_Icon-29x29.png":"Icon-App-29x29@1x.png",
      "appicon_Icon-29x29_2x.png":"Icon-App-29x29@2x.png",
      "appicon_Icon-29x29_3x.png":"Icon-App-29x29@3x.png",
      "appicon_Icon-40x40.png":"Icon-App-40x40@1x.png",
      "appicon_Icon-40x40_2x.png":"Icon-App-40x40@2x.png",
      "appicon_Icon-40x40_3x.png":"Icon-App-40x40@3x.png",
      "appicon_Icon-76x76.png":"Icon-App-76x76@1x.png",
      "appicon_Icon-76x76_2x.png":"Icon-App-76x76@2x.png",
      "appicon_Icon-83.5x83.5_2x.png":"Icon-App-83.5x83.5@2x.png",
      "appicon_Icon-1024x1024.png":"Icon-App-1024x1024@1x.png",
    }
    for src_name,dst_name in mapping.items():
        src=platform_ios/src_name
        if src.exists(): shutil.copy2(src,appicon/dst_name)

images = [
 {"size":"20x20","idiom":"iphone","filename":"Icon-App-20x20@2x.png","scale":"2x"},
 {"size":"20x20","idiom":"iphone","filename":"Icon-App-20x20@3x.png","scale":"3x"},
 {"size":"29x29","idiom":"iphone","filename":"Icon-App-29x29@2x.png","scale":"2x"},
 {"size":"29x29","idiom":"iphone","filename":"Icon-App-29x29@3x.png","scale":"3x"},
 {"size":"40x40","idiom":"iphone","filename":"Icon-App-40x40@2x.png","scale":"2x"},
 {"size":"40x40","idiom":"iphone","filename":"Icon-App-40x40@3x.png","scale":"3x"},
 {"size":"60x60","idiom":"iphone","filename":"Icon-App-60x60@2x.png","scale":"2x"},
 {"size":"60x60","idiom":"iphone","filename":"Icon-App-60x60@3x.png","scale":"3x"},
 {"size":"20x20","idiom":"ipad","filename":"Icon-App-20x20@1x.png","scale":"1x"},
 {"size":"20x20","idiom":"ipad","filename":"Icon-App-20x20@2x.png","scale":"2x"},
 {"size":"29x29","idiom":"ipad","filename":"Icon-App-29x29@1x.png","scale":"1x"},
 {"size":"29x29","idiom":"ipad","filename":"Icon-App-29x29@2x.png","scale":"2x"},
 {"size":"40x40","idiom":"ipad","filename":"Icon-App-40x40@1x.png","scale":"1x"},
 {"size":"40x40","idiom":"ipad","filename":"Icon-App-40x40@2x.png","scale":"2x"},
 {"size":"76x76","idiom":"ipad","filename":"Icon-App-76x76@1x.png","scale":"1x"},
 {"size":"76x76","idiom":"ipad","filename":"Icon-App-76x76@2x.png","scale":"2x"},
 {"size":"83.5x83.5","idiom":"ipad","filename":"Icon-App-83.5x83.5@2x.png","scale":"2x"},
 {"size":"1024x1024","idiom":"ios-marketing","filename":"Icon-App-1024x1024@1x.png","scale":"1x"}
]
(appicon/"Contents.json").write_text(json.dumps({"images":images,"info":{"author":"xcode","version":1}},indent=2),encoding="utf-8")

launchset.mkdir(parents=True, exist_ok=True)
src = root / "assets" / "images" / "mleysoft-ios-launch.png"
for scale, name in [("1x","LaunchImage.png"),("2x","LaunchImage@2x.png"),("3x","LaunchImage@3x.png")]:
    shutil.copy2(src, launchset/name)
(launchset/"Contents.json").write_text(json.dumps({
  "images":[
    {"idiom":"universal","filename":"LaunchImage.png","scale":"1x"},
    {"idiom":"universal","filename":"LaunchImage@2x.png","scale":"2x"},
    {"idiom":"universal","filename":"LaunchImage@3x.png","scale":"3x"}
  ],
  "info":{"version":1,"author":"xcode"}
},indent=2),encoding="utf-8")

storyboard = runner / "Base.lproj" / "LaunchScreen.storyboard"
storyboard.parent.mkdir(parents=True, exist_ok=True)
storyboard.write_text("""<?xml version="1.0" encoding="UTF-8"?>
<document type="com.apple.InterfaceBuilder3.CocoaTouch.Storyboard.XIB" version="3.0" toolsVersion="21762" targetRuntime="iOS.CocoaTouch" useAutolayout="YES" launchScreen="YES">
    <device id="retina6_12" orientation="portrait" appearance="light"/>
    <scenes>
        <scene sceneID="EHf-IW-A2E">
            <objects>
                <viewController id="01J-lp-oVM" sceneMemberID="viewController">
                    <view key="view" contentMode="scaleToFill" id="Ze5-6b-2t3">
                        <rect key="frame" x="0.0" y="0.0" width="393" height="852"/>
                        <color key="backgroundColor" white="1" alpha="1" colorSpace="custom" customColorSpace="genericGamma22GrayColorSpace"/>
                    </view>
                </viewController>
                <placeholder placeholderIdentifier="IBFirstResponder" id="iYj-Kq-Ea1" userLabel="First Responder" sceneMemberID="firstResponder"/>
            </objects>
        </scene>
    </scenes>
</document>
""",encoding="utf-8")


# V82: iOS ana ekran / uygulama adı.
info_plist = runner / "Info.plist"
if info_plist.exists():
    import plistlib
    with info_plist.open("rb") as f:
        info = plistlib.load(f)
    info["CFBundleDisplayName"] = "MleySoft \u0130K"
    info["CFBundleName"] = "Runner"
    with info_plist.open("wb") as f:
        plistlib.dump(info, f, sort_keys=False)


# V94: App Store Bundle ID.
# Flutter create --org com.mleysoft may generate com.mleysoft.mleysoftIk.
# Runner app MUST always be com.mleysoft.ik. Test targets keep a unique .RunnerTests suffix.
pbx = ios / "Runner.xcodeproj" / "project.pbxproj"
if pbx.exists():
    t = pbx.read_text(encoding="utf-8")
    import re

    # First preserve/fix test bundle identifiers.
    t = re.sub(
        r"PRODUCT_BUNDLE_IDENTIFIER = [^;]*RunnerTests;",
        "PRODUCT_BUNDLE_IDENTIFIER = com.mleysoft.ik.RunnerTests;",
        t,
    )

    # Replace known Flutter-created app identifiers.
    t = t.replace("PRODUCT_BUNDLE_IDENTIFIER = com.mleysoft.mleysoftIk;",
                  "PRODUCT_BUNDLE_IDENTIFIER = com.mleysoft.ik;")
    t = t.replace("PRODUCT_BUNDLE_IDENTIFIER = com.example.mleysoftIk;",
                  "PRODUCT_BUNDLE_IDENTIFIER = com.mleysoft.ik;")
    t = t.replace("PRODUCT_BUNDLE_IDENTIFIER = com.example.mleysoft_ik;",
                  "PRODUCT_BUNDLE_IDENTIFIER = com.mleysoft.ik;")

    # V100: Signed product name MUST remain Runner.
    # Older builds accidentally changed PRODUCT_NAME to "MleySoft İK", which caused
    # Payload/MleySoft İK.app and App Store ITMS-90034 signature rejection.
    # Force every build configuration back to Runner while keeping the user-visible
    # home-screen name in CFBundleDisplayName.
    t = re.sub(r'PRODUCT_NAME = [^;]+;', 'PRODUCT_NAME = Runner;', t)
    if 'INFOPLIST_KEY_CFBundleDisplayName' in t:
        t = re.sub(r'INFOPLIST_KEY_CFBundleDisplayName = [^;]+;', 'INFOPLIST_KEY_CFBundleDisplayName = "MleySoft İK";', t)

    pbx.write_text(t, encoding="utf-8")
    verify = pbx.read_text(encoding="utf-8")
    if "PRODUCT_BUNDLE_IDENTIFIER = com.mleysoft.ik;" not in verify:
        raise SystemExit("iOS Runner Bundle ID com.mleysoft.ik olarak ayarlanamadi.")
    if "PRODUCT_BUNDLE_IDENTIFIER = com.mleysoft.mleysoftIk;" in verify:
        raise SystemExit("Eski iOS Bundle ID hala mevcut: com.mleysoft.mleysoftIk")

if info_plist.exists():
    with info_plist.open("rb") as f:
        info = plistlib.load(f)
    info["NSCameraUsageDescription"] = "MleySoft İK, personel giriş ve çıkış işlemlerinde QR kodlarını okutmak ve kamera gerektiren işlemleri gerçekleştirmek için kamerayı kullanır."
    info["NSPhotoLibraryUsageDescription"] = "MleySoft İK, kullanıcı tarafından seçilen profil, belge veya görselleri uygulamaya eklemek için fotoğraf arşivine erişir."
    info["NSLocationWhenInUseUsageDescription"] = "MleySoft İK, personel giriş ve çıkışlarında QR kodunun tanımlı işyeri konumunda okutulduğunu doğrulamak için konumunuzu yalnızca uygulamayı kullanırken alır."
    # V112: Eski Always açıklamalarını temizle; aşağıda App Store statik taraması için kontrollü açıklama yeniden yazılır.
    info.pop("NSLocationAlwaysUsageDescription", None)
    info.pop("NSLocationAlwaysAndWhenInUseUsageDescription", None)
    info["NSFaceIDUsageDescription"] = "MleySoft İK hesabınıza güvenli ve hızlı giriş için Face ID kullanılabilir."
    info["CFBundleDisplayName"] = "MleySoft İK"
    info["CFBundleName"] = "Runner"
    with info_plist.open("wb") as f:
        plistlib.dump(info, f, sort_keys=False)

# V113: iOS konumu yalnızca native CoreLocation + requestWhenInUseAuthorization ile alınır.
# geolocator_apple tamamen kaldırılmıştır; Always Location API binary içinde bulunmamalıdır.
if info_plist.exists():
    with info_plist.open("rb") as f:
        info = plistlib.load(f)
    info["NSLocationWhenInUseUsageDescription"] = (
        "MleySoft İK, personel giriş ve çıkışlarında QR kodunun tanımlı işyeri konumunda "
        "okutulduğunu doğrulamak için konumunuzu yalnızca uygulamayı kullanırken alır."
    )
    info.pop("NSLocationAlwaysUsageDescription", None)
    info.pop("NSLocationAlwaysAndWhenInUseUsageDescription", None)
    with info_plist.open("wb") as f:
        plistlib.dump(info, f, sort_keys=False)

print("iOS MleySoft İK V113: native When-In-Use CoreLocation yapılandırıldı; Always Location kaldırıldı.")


# V94 hard verification: App Store branding must not fall back to Flutter defaults.
required_icon = appicon / "Icon-App-1024x1024@1x.png"
if not required_icon.exists() or required_icon.stat().st_size < 1000:
    raise SystemExit("V96 ERROR: iOS App Store icon could not be installed.")

if info_plist.exists():
    with info_plist.open("rb") as f:
        verify_info = plistlib.load(f)
    if verify_info.get("CFBundleDisplayName") != "MleySoft İK":
        raise SystemExit("V96 ERROR: CFBundleDisplayName is not MleySoft İK.")
    if verify_info.get("CFBundleName") != "Runner":
        raise SystemExit("V100 ERROR: CFBundleName is not Runner.")

print("V100 VERIFY OK: Runner product name + MleySoft İK display name + bundle id configured.")

# V113: iOS badge + native foreground-only CoreLocation bridge.
# DİKKAT: requestAlwaysAuthorization bilinçli olarak kullanılmaz.
app_delegate = runner / "AppDelegate.swift"
app_delegate.write_text(r"""import Flutter
import UIKit
import CoreLocation

final class MleyLocationBridge: NSObject, CLLocationManagerDelegate {
  private let manager = CLLocationManager()
  private var pending: FlutterResult?
  private var timeoutWorkItem: DispatchWorkItem?

  override init() {
    super.init()
    manager.delegate = self
    manager.desiredAccuracy = kCLLocationAccuracyBest
  }

  func getCurrentLocation(_ result: @escaping FlutterResult) {
    guard CLLocationManager.locationServicesEnabled() else {
      result(FlutterError(code: "LOCATION_SERVICE_DISABLED", message: "Konum servisi kapalı.", details: nil))
      return
    }
    if pending != nil {
      result(FlutterError(code: "LOCATION_BUSY", message: "Konum bilgisi alınıyor.", details: nil))
      return
    }
    pending = result
    timeoutWorkItem?.cancel()
    let timeout = DispatchWorkItem { [weak self] in
      guard let self = self, self.pending != nil else { return }
      self.finish(error: FlutterError(code: "LOCATION_TIMEOUT", message: "Konum bilgisi zamanında alınamadı. Konum servisini kontrol edip tekrar deneyin.", details: nil))
    }
    timeoutWorkItem = timeout
    DispatchQueue.main.asyncAfter(deadline: .now() + 12, execute: timeout)
    switch manager.authorizationStatus {
    case .notDetermined:
      manager.requestWhenInUseAuthorization()
    case .authorizedWhenInUse, .authorizedAlways:
      manager.requestLocation()
    case .denied, .restricted:
      finish(error: FlutterError(code: "LOCATION_PERMISSION_DENIED_FOREVER", message: "Konum izni gerekli.", details: nil))
    @unknown default:
      finish(error: FlutterError(code: "LOCATION_PERMISSION_DENIED", message: "Konum izni gerekli.", details: nil))
    }
  }

  func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
    guard pending != nil else { return }
    switch manager.authorizationStatus {
    case .authorizedWhenInUse, .authorizedAlways:
      manager.requestLocation()
    case .denied, .restricted:
      finish(error: FlutterError(code: "LOCATION_PERMISSION_DENIED", message: "Konum izni gerekli.", details: nil))
    default:
      break
    }
  }

  func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
    guard let location = locations.last else {
      finish(error: FlutterError(code: "LOCATION_ERROR", message: "Konum bilgisi alınamadı.", details: nil))
      return
    }
    timeoutWorkItem?.cancel()
    timeoutWorkItem = nil
    let result = pending
    pending = nil
    result?(["latitude": location.coordinate.latitude, "longitude": location.coordinate.longitude, "accuracy": location.horizontalAccuracy])
  }

  func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
    finish(error: FlutterError(code: "LOCATION_ERROR", message: error.localizedDescription, details: nil))
  }

  private func finish(error: FlutterError) {
    timeoutWorkItem?.cancel()
    timeoutWorkItem = nil
    let result = pending
    pending = nil
    result?(error)
  }
}

@main
@objc class AppDelegate: FlutterAppDelegate {
  private var locationBridge: MleyLocationBridge?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    if let controller = window?.rootViewController as? FlutterViewController {
      let badgeChannel = FlutterMethodChannel(name: "com.mleysoft.ik/badge", binaryMessenger: controller.binaryMessenger)
      badgeChannel.setMethodCallHandler { call, result in
        if call.method == "setBadge", let args = call.arguments as? [String: Any], let count = args["count"] as? Int {
          application.applicationIconBadgeNumber = max(0, count)
          result(true)
        } else {
          result(FlutterMethodNotImplemented)
        }
      }

      let bridge = MleyLocationBridge()
      locationBridge = bridge
      let locationChannel = FlutterMethodChannel(name: "com.mleysoft.ik/location", binaryMessenger: controller.binaryMessenger)
      locationChannel.setMethodCallHandler { call, result in
        if call.method == "getCurrentLocation" {
          bridge.getCurrentLocation(result)
        } else {
          result(FlutterMethodNotImplemented)
        }
      }
    }
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
""", encoding="utf-8")
print("V113 iOS native foreground location + unread app badge bridge configured.")
