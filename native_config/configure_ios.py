#!/usr/bin/env python3
from pathlib import Path
import json, shutil, sys, plistlib

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
    modes = info.get("UIBackgroundModes", [])
    for mode in ["fetch", "processing", "remote-notification"]:
        if mode not in modes: modes.append(mode)
    info["UIBackgroundModes"] = modes
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
    info["NSPhotoLibraryUsageDescription"] = "MleySoft İK, firma yöneticisinin İK ERP içindeki özlük kayıtlarına eklemek üzere yalnızca kendisinin seçtiği fotoğraf veya belge görsellerine erişir."
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

# V119: Native channels are provided by the local Flutter plugin
# packages/mleysoft_native_bridge. Do NOT replace AppDelegate.swift here.
# Flutter's generated AppDelegate + GeneratedPluginRegistrant will register
# the plugin consistently for UIScene/TestFlight/App Store builds.
app_delegate = runner / "AppDelegate.swift"
if not app_delegate.exists():
    raise SystemExit("V119 ERROR: Flutter-generated AppDelegate.swift is missing.")

# V201: Deterministic APNs registration forwarding.
# TestFlight diagnostics proved permission is authorized but APNs token is missing.
# Disable Firebase AppDelegate swizzling and explicitly forward Apple's token.
app_delegate = runner / "AppDelegate.swift"
if not app_delegate.exists():
    raise SystemExit("V201 ERROR: Flutter-generated AppDelegate.swift is missing.")
app_delegate.write_text(r'''import Flutter
import UIKit
import UserNotifications
import FirebaseMessaging

@main
@objc class AppDelegate: FlutterAppDelegate, MessagingDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)

    // V205: Firebase swizzling kapalı olduğundan APNs kaydını native olarak
    // deterministik biçimde başlat ve FCM delegate'ini doğrudan bağla.
    Messaging.messaging().delegate = self
    Messaging.messaging().isAutoInitEnabled = true
    UserDefaults.standard.set("launch_started", forKey: "mleysoft_apns_status")
    UserDefaults.standard.set("", forKey: "mleysoft_apns_error")

    UNUserNotificationCenter.current().getNotificationSettings { settings in
      if settings.authorizationStatus == .authorized ||
         settings.authorizationStatus == .provisional ||
         settings.authorizationStatus == .ephemeral {
        DispatchQueue.main.async {
          UserDefaults.standard.set("register_requested", forKey: "mleysoft_apns_status")
          application.registerForRemoteNotifications()
        }
      }
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  override func applicationDidBecomeActive(_ application: UIApplication) {
    super.applicationDidBecomeActive(application)
    // iOS 26 / UIScene geçişlerinde ilk çağrı callback üretmezse uygulama aktif
    // olduğunda native APNs registration'ı yeniden tetikle.
    UNUserNotificationCenter.current().getNotificationSettings { settings in
      if settings.authorizationStatus == .authorized ||
         settings.authorizationStatus == .provisional ||
         settings.authorizationStatus == .ephemeral {
        DispatchQueue.main.async {
          UserDefaults.standard.set("register_requested_active", forKey: "mleysoft_apns_status")
          application.registerForRemoteNotifications()
        }
      }
    }
  }

  override func application(
    _ application: UIApplication,
    didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
  ) {
    let tokenHex = deviceToken.map { String(format: "%02x", $0) }.joined()
    UserDefaults.standard.set("success", forKey: "mleysoft_apns_status")
    UserDefaults.standard.set("", forKey: "mleysoft_apns_error")
    UserDefaults.standard.set(tokenHex, forKey: "mleysoft_apns_token")

    // FirebaseAppDelegateProxyEnabled=false: Apple tokenını Firebase'e elle aktar.
    Messaging.messaging().apnsToken = deviceToken
    Messaging.messaging().token { token, error in
      if let token = token, !token.isEmpty {
        UserDefaults.standard.set(token, forKey: "mleysoft_fcm_token")
      }
      if let error = error {
        UserDefaults.standard.set(error.localizedDescription, forKey: "mleysoft_fcm_error")
      } else {
        UserDefaults.standard.set("", forKey: "mleysoft_fcm_error")
      }
    }
    super.application(application, didRegisterForRemoteNotificationsWithDeviceToken: deviceToken)
  }

  override func application(
    _ application: UIApplication,
    didFailToRegisterForRemoteNotificationsWithError error: Error
  ) {
    UserDefaults.standard.set("failed", forKey: "mleysoft_apns_status")
    UserDefaults.standard.set(error.localizedDescription, forKey: "mleysoft_apns_error")
    UserDefaults.standard.set("", forKey: "mleysoft_apns_token")
    super.application(application, didFailToRegisterForRemoteNotificationsWithError: error)
  }

  func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
    UserDefaults.standard.set(fcmToken ?? "", forKey: "mleysoft_fcm_token")
  }
}
''', encoding="utf-8")

native_plugin = root / "packages" / "mleysoft_native_bridge" / "ios" / "Classes" / "MleySoftNativeBridgePlugin.swift"
if not native_plugin.exists():
    raise SystemExit("V201 ERROR: mleysoft_native_bridge iOS plugin source is missing.")
plugin_text = native_plugin.read_text(encoding="utf-8")
for required in [
    "com.mleysoft.ik/location", "com.mleysoft.ik/permissions",
    "requestWhenInUseAuthorization()",
    "UNUserNotificationCenter.current().requestAuthorization",
    "UIApplication.shared.registerForRemoteNotifications()",
]:
    if required not in plugin_text:
        raise SystemExit(f"V201 ERROR: native plugin missing required code: {required}")
if "requestAlwaysAuthorization" in plugin_text:
    raise SystemExit("V201 ERROR: Always Location API must not exist in native plugin.")
print("V205 VERIFY OK: Native APNs registration + explicit Firebase forwarding active.")

# V147: İK ERP belge yükleme gizlilik doğrulaması.
# file_picker iOS'ta sistem belge seçiciyi kullanır; geniş dosya sistemi izni istenmez.
# Görsel kaynağı seçildiğinde App Store için Photo Library açıklaması hazır tutulur.
if info_plist.exists():
    with info_plist.open("rb") as f:
        v147_info = plistlib.load(f)
    required_privacy = {
        "NSCameraUsageDescription": "QR",
        "NSPhotoLibraryUsageDescription": "İK ERP",
        "NSLocationWhenInUseUsageDescription": "konum",
        "NSFaceIDUsageDescription": "Face ID",
    }
    for key in required_privacy:
        if not str(v147_info.get(key, "")).strip():
            raise SystemExit(f"V147 ERROR: iOS privacy purpose string missing: {key}")
    if "NSLocationAlwaysUsageDescription" in v147_info or "NSLocationAlwaysAndWhenInUseUsageDescription" in v147_info:
        raise SystemExit("V147 ERROR: Always Location purpose string bulunmamalı.")

print("V147 VERIFY OK: iOS belge/fotoğraf seçimi privacy açıklamaları hazır; Always Location yok.")



# V149: Push Notifications capability / APNs entitlement.
# TestFlight ve App Store dağıtımları production APNs ortamını kullanır.
entitlements = runner / "Runner.entitlements"
with entitlements.open("wb") as f:
    plistlib.dump({
        "aps-environment": "production",
    }, f, sort_keys=False)

pbx = ios / "Runner.xcodeproj" / "project.pbxproj"
if pbx.exists():
    t = pbx.read_text(encoding="utf-8")
    if "CODE_SIGN_ENTITLEMENTS = Runner/Runner.entitlements;" not in t:
        t = t.replace(
            "PRODUCT_BUNDLE_IDENTIFIER = com.mleysoft.ik;",
            "PRODUCT_BUNDLE_IDENTIFIER = com.mleysoft.ik;\n\t\t\t\tCODE_SIGN_ENTITLEMENTS = Runner/Runner.entitlements;"
        )
        pbx.write_text(t, encoding="utf-8")
    verify_ent = pbx.read_text(encoding="utf-8")
    if "CODE_SIGN_ENTITLEMENTS = Runner/Runner.entitlements;" not in verify_ent:
        raise SystemExit("V149 ERROR: Runner Push Notifications entitlements Xcode projesine eklenemedi.")

print("V149 VERIFY OK: Runner.entitlements aps-environment=production ve CODE_SIGN_ENTITLEMENTS aktif.")


# V148 Firebase native iOS configuration.
# The iOS directory is regenerated by Codemagic, so copy and register the plist on every build.
fb_source = root / "native_config" / "firebase" / "GoogleService-Info.plist"
fb_dest = runner / "GoogleService-Info.plist"
if not fb_source.exists():
    raise SystemExit("V148 ERROR: GoogleService-Info.plist bulunamadi.")
shutil.copy2(fb_source, fb_dest)
with fb_dest.open("rb") as f:
    fb_info = plistlib.load(f)
if fb_info.get("BUNDLE_ID") != "com.mleysoft.ik":
    raise SystemExit("V148 ERROR: Firebase iOS BUNDLE_ID com.mleysoft.ik degil.")

pbx = ios / "Runner.xcodeproj" / "project.pbxproj"
if pbx.exists():
    t = pbx.read_text(encoding="utf-8")
    file_id = "F14800000000000000000001"
    build_id = "F14800000000000000000002"
    if "GoogleService-Info.plist in Resources" not in t:
        t = t.replace("/* Begin PBXBuildFile section */", "/* Begin PBXBuildFile section */\n\t\t%s /* GoogleService-Info.plist in Resources */ = {isa = PBXBuildFile; fileRef = %s /* GoogleService-Info.plist */; };" % (build_id,file_id), 1)
        t = t.replace("/* Begin PBXFileReference section */", "/* Begin PBXFileReference section */\n\t\t%s /* GoogleService-Info.plist */ = {isa = PBXFileReference; lastKnownFileType = text.plist.xml; path = \"GoogleService-Info.plist\"; sourceTree = \"<group>\"; };" % file_id, 1)
        appdelegate_line = next((line for line in t.splitlines() if "AppDelegate.swift /* AppDelegate.swift */," in line), None)
        if appdelegate_line:
            t = t.replace(appdelegate_line, appdelegate_line + "\n\t\t\t\t%s /* GoogleService-Info.plist */," % file_id, 1)
        else:
            raise SystemExit("V148 ERROR: Runner PBXGroup insertion point bulunamadi.")
        launch_line = next((line for line in t.splitlines() if "LaunchScreen.storyboard in Resources */," in line), None)
        if launch_line:
            t = t.replace(launch_line, launch_line + "\n\t\t\t\t%s /* GoogleService-Info.plist in Resources */," % build_id, 1)
        else:
            raise SystemExit("V148 ERROR: PBXResourcesBuildPhase insertion point bulunamadi.")
        pbx.write_text(t, encoding="utf-8")
    verify_pbx = pbx.read_text(encoding="utf-8")
    if "GoogleService-Info.plist in Resources" not in verify_pbx:
        raise SystemExit("V148 ERROR: Firebase plist Runner Resources'a eklenemedi.")
print("V148 VERIFY OK: Firebase iOS plist copied and registered in Runner resources.")


# V201: Explicit APNs forwarding; disable Firebase swizzling to avoid duplicate interception.
if info_plist.exists():
    with info_plist.open("rb") as f:
        v201_info = plistlib.load(f)
    v201_info["FirebaseAppDelegateProxyEnabled"] = False
    with info_plist.open("wb") as f:
        plistlib.dump(v201_info, f, sort_keys=False)

app_delegate = runner / "AppDelegate.swift"
app_delegate_text = app_delegate.read_text(encoding="utf-8")
for required in [
    "import FirebaseMessaging",
    "didRegisterForRemoteNotificationsWithDeviceToken",
    "Messaging.messaging().apnsToken = deviceToken",
    "super.application(application, didRegisterForRemoteNotificationsWithDeviceToken: deviceToken)",
]:
    if required not in app_delegate_text:
        raise SystemExit(f"V201 ERROR: AppDelegate missing APNs forwarding code: {required}")
print("V205 VERIFY OK: Firebase proxy disabled; native APNs -> Firebase forwarding active.")


# V207: Force Push Notifications capability into the generated Xcode target.
# Runner.entitlements alone is not enough if the generated target drops the capability metadata.
pbx = ios / "Runner.xcodeproj" / "project.pbxproj"
if not pbx.exists():
    raise SystemExit("V207 ERROR: Runner.xcodeproj bulunamadi.")
t = pbx.read_text(encoding="utf-8")

# Ensure every Runner build configuration that has our bundle id also points at Runner.entitlements.
needle = "PRODUCT_BUNDLE_IDENTIFIER = com.mleysoft.ik;"
replacement = needle + "\n\t\t\t\tCODE_SIGN_ENTITLEMENTS = Runner/Runner.entitlements;"
for _ in range(10):
    # Only replace occurrences not already followed by CODE_SIGN_ENTITLEMENTS.
    pos = t.find(needle)
    if pos < 0:
        break
    after = t[pos:pos+220]
    if "CODE_SIGN_ENTITLEMENTS = Runner/Runner.entitlements;" not in after:
        t = t[:pos] + replacement + t[pos+len(needle):]
    # move past this occurrence by temporarily marking it
    t = t[:pos] + t[pos:].replace(needle, "PRODUCT_BUNDLE_IDENTIFIER = com.mleysoft.ik; /* V207_SEEN */", 1)
t = t.replace("PRODUCT_BUNDLE_IDENTIFIER = com.mleysoft.ik; /* V207_SEEN */", needle)

# Add Xcode Push Notifications SystemCapability to Runner target attributes when absent.
if "com.apple.Push =" not in t:
    marker = "CreatedOnToolsVersion ="
    idx = t.find(marker)
    if idx < 0:
        raise SystemExit("V207 ERROR: Xcode TargetAttributes bolumu bulunamadi.")
    line_end = t.find(";", idx) + 1
    capability = "\n\t\t\t\t\t\tSystemCapabilities = {\n\t\t\t\t\t\t\tcom.apple.Push = {\n\t\t\t\t\t\t\t\tenabled = 1;\n\t\t\t\t\t\t\t};\n\t\t\t\t\t\t};"
    t = t[:line_end] + capability + t[line_end:]

pbx.write_text(t, encoding="utf-8")
verify = pbx.read_text(encoding="utf-8")
if "CODE_SIGN_ENTITLEMENTS = Runner/Runner.entitlements;" not in verify:
    raise SystemExit("V207 ERROR: CODE_SIGN_ENTITLEMENTS Runner targetina baglanamadi.")
if "com.apple.Push =" not in verify:
    raise SystemExit("V207 ERROR: Push Notifications SystemCapability eklenemedi.")
print("V207 VERIFY OK: Runner target has Push capability + Runner.entitlements binding.")
