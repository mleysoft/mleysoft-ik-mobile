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

# V112: geolocator yalnızca QR işlemi sırasında foreground konum kullanır.
# geolocator resmi önerisi: Always API kodunu sadece geolocator_apple target'ında derlemeden çıkar.
podfile = ios / "Podfile"
if podfile.exists():
    pod = podfile.read_text(encoding="utf-8")
    # Önce V110'un genel hedeflere eklediği bloğu temizle.
    old = "    flutter_additional_ios_build_settings(target)\n    target.build_configurations.each do |config|\n      config.build_settings['GCC_PREPROCESSOR_DEFINITIONS'] ||= ['$(inherited)']\n      config.build_settings['GCC_PREPROCESSOR_DEFINITIONS'] << 'BYPASS_PERMISSION_LOCATION_ALWAYS=1'\n    end\n"
    pod = pod.replace(old, "    flutter_additional_ios_build_settings(target)\n")
    marker = "if target.name == 'geolocator_apple'"
    if marker not in pod:
        needle = "    flutter_additional_ios_build_settings(target)\n"
        addition = "    flutter_additional_ios_build_settings(target)\n    if target.name == 'geolocator_apple'\n      target.build_configurations.each do |config|\n        config.build_settings['GCC_PREPROCESSOR_DEFINITIONS'] ||= ['$(inherited)', 'BYPASS_PERMISSION_LOCATION_ALWAYS=1']\n        unless config.build_settings['GCC_PREPROCESSOR_DEFINITIONS'].include?('BYPASS_PERMISSION_LOCATION_ALWAYS=1')\n          config.build_settings['GCC_PREPROCESSOR_DEFINITIONS'] << 'BYPASS_PERMISSION_LOCATION_ALWAYS=1'\n        end\n      end\n    end\n"
        if needle not in pod:
            raise SystemExit("V112 ERROR: Podfile post_install yapisi bulunamadi.")
        pod = pod.replace(needle, addition, 1)
    podfile.write_text(pod, encoding="utf-8")
    verify_pod = podfile.read_text(encoding="utf-8")
    if marker not in verify_pod or 'BYPASS_PERMISSION_LOCATION_ALWAYS=1' not in verify_pod:
        raise SystemExit("V112 ERROR: geolocator_apple Always permission bypass uygulanamadi.")

# Apple 90683 taraması bazı geolocator sürümlerinde binary API referansını yine de görebiliyor.
# Uygulama requestAlwaysAuthorization çağırmaz; bu purpose string sadece App Store statik taramasını
# güvenli şekilde karşılar. Kullanıcıya gösterilen gerçek izin When-In-Use iznidir.
if info_plist.exists():
    with info_plist.open("rb") as f:
        info = plistlib.load(f)
    info["NSLocationAlwaysAndWhenInUseUsageDescription"] = (
        "MleySoft İK, personel giriş ve çıkışlarında QR kodunun tanımlı işyeri konumunda "
        "okutulduğunu doğrulamak için konum bilgisini kullanır. Konum yalnızca QR doğrulaması için işlenir; "
        "uygulama arka planda sürekli konum takibi yapmaz."
    )
    with info_plist.open("wb") as f:
        plistlib.dump(info, f, sort_keys=False)

# V112: Aynı purpose string'i Xcode build setting seviyesinde de zorunlu kıl.
# Böylece archive aşamasında final Runner.app Info.plist oluşturulurken anahtar kaybolamaz.
if pbx.exists():
    t = pbx.read_text(encoding="utf-8")
    purpose_setting = 'INFOPLIST_KEY_NSLocationAlwaysAndWhenInUseUsageDescription = "MleySoft İK, personel giriş ve çıkışlarında QR kodunun tanımlı işyeri konumunda okutulduğunu doğrulamak için konum bilgisini kullanır. Konum yalnızca QR doğrulaması için işlenir; uygulama arka planda sürekli konum takibi yapmaz.";'
    if 'INFOPLIST_KEY_NSLocationAlwaysAndWhenInUseUsageDescription' not in t:
        # Runner build configuration'larının her birine Bundle ID satırının hemen ardından ekle.
        t = t.replace(
            'PRODUCT_BUNDLE_IDENTIFIER = com.mleysoft.ik;',
            'PRODUCT_BUNDLE_IDENTIFIER = com.mleysoft.ik;\n\t\t\t\t' + purpose_setting
        )
    pbx.write_text(t, encoding="utf-8")
    if 'INFOPLIST_KEY_NSLocationAlwaysAndWhenInUseUsageDescription' not in pbx.read_text(encoding="utf-8"):
        raise SystemExit("V112 ERROR: Xcode purpose-string build setting eklenemedi.")

# Kaynak Info.plist'i de build öncesi kesin doğrula.
if info_plist.exists():
    with info_plist.open("rb") as f:
        final_source_info = plistlib.load(f)
    if not final_source_info.get("NSLocationAlwaysAndWhenInUseUsageDescription"):
        raise SystemExit("V112 ERROR: NSLocationAlwaysAndWhenInUseUsageDescription kaynak Info.plist'te yok.")

print("iOS MleySoft İK V112: geolocator bypass + plist + Xcode build-setting 90683 koruması uygulandi.")


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

# V108: Native iOS application icon unread badge bridge.
app_delegate = runner / "AppDelegate.swift"
app_delegate.write_text('''import Flutter\nimport UIKit\n\n@main\n@objc class AppDelegate: FlutterAppDelegate {\n  override func application(\n    _ application: UIApplication,\n    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?\n  ) -> Bool {\n    GeneratedPluginRegistrant.register(with: self)\n    if let controller = window?.rootViewController as? FlutterViewController {\n      let badgeChannel = FlutterMethodChannel(name: "com.mleysoft.ik/badge", binaryMessenger: controller.binaryMessenger)\n      badgeChannel.setMethodCallHandler { call, result in\n        if call.method == "setBadge", let args = call.arguments as? [String: Any], let count = args["count"] as? Int {\n          application.applicationIconBadgeNumber = max(0, count)\n          result(true)\n        } else {\n          result(FlutterMethodNotImplemented)\n        }\n      }\n    }\n    return super.application(application, didFinishLaunchingWithOptions: launchOptions)\n  }\n}\n''', encoding="utf-8")
print("V108 iOS unread app badge bridge configured.")
