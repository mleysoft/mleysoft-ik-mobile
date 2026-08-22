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
    info["CFBundleName"] = "MleySoft \u0130K"
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

    # PRODUCT_NAME is intentionally left as Runner. App name comes from Info.plist.
    # Keeping the generated Xcode product name avoids altering the signed bundle product.
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
    info["NSLocationWhenInUseUsageDescription"] = "MleySoft İK, konum gerektiren özelliklerde konum bilginizi yalnızca uygulamayı kullanırken kullanır."
    info["NSFaceIDUsageDescription"] = "MleySoft İK hesabınıza güvenli ve hızlı giriş için Face ID kullanılabilir."
    info["CFBundleDisplayName"] = "MleySoft İK"
    info["CFBundleName"] = "MleySoft İK"
    with info_plist.open("wb") as f:
        plistlib.dump(info, f, sort_keys=False)

print("iOS MleySoft İK V94: com.mleysoft.ik + App Store privacy izinleri + ikon/splash ayarlari uygulandi.")


# V94 hard verification: App Store branding must not fall back to Flutter defaults.
required_icon = appicon / "Icon-App-1024x1024@1x.png"
if not required_icon.exists() or required_icon.stat().st_size < 1000:
    raise SystemExit("V96 ERROR: iOS App Store icon could not be installed.")

if info_plist.exists():
    with info_plist.open("rb") as f:
        verify_info = plistlib.load(f)
    if verify_info.get("CFBundleDisplayName") != "MleySoft İK":
        raise SystemExit("V96 ERROR: CFBundleDisplayName is not MleySoft İK.")
    if verify_info.get("CFBundleName") != "MleySoft İK":
        raise SystemExit("V96 ERROR: CFBundleName is not MleySoft İK.")

print("V99 VERIFY OK: iOS icon + display name + bundle id configured; PRODUCT_NAME preserved for signing.")
