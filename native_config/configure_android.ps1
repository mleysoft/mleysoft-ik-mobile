$ErrorActionPreference = 'Stop'

$projectRoot = Split-Path -Parent $PSScriptRoot
$androidRoot = Join-Path $projectRoot 'android'
$appRoot = Join-Path $androidRoot 'app'
$settings = Join-Path $androidRoot 'settings.gradle.kts'
$wrapper = Join-Path $androidRoot 'gradle/wrapper/gradle-wrapper.properties'
$appGradle = Join-Path $appRoot 'build.gradle.kts'
$propsFile = Join-Path $androidRoot 'gradle.properties'

if (-not (Test-Path $settings)) { throw 'android/settings.gradle.kts bulunamadi.' }
if (-not (Test-Path $wrapper)) { throw 'gradle-wrapper.properties bulunamadi.' }
if (-not (Test-Path $appGradle)) { throw 'android/app/build.gradle.kts bulunamadi.' }

# Current Flutter minimums are satisfied while staying below AGP 9.
$settingsText = Get-Content $settings -Raw -Encoding UTF8
$settingsText = [regex]::Replace(
    $settingsText,
    'id\("com\.android\.application"\)\s+version\s+"[^"]+"',
    'id("com.android.application") version "8.13.2"'
)
Set-Content $settings $settingsText -Encoding UTF8

$wrapperText = Get-Content $wrapper -Raw -Encoding UTF8
$wrapperText = [regex]::Replace(
    $wrapperText,
    'distributionUrl=.*',
    'distributionUrl=https\://services.gradle.org/distributions/gradle-8.14.3-all.zip'
)
Set-Content $wrapper $wrapperText -Encoding UTF8

# Remove any AGP9 compatibility flags.
$props = ''
if (Test-Path $propsFile) {
    $props = Get-Content $propsFile -Raw -Encoding UTF8
}
$props = [regex]::Replace($props, '(?m)^\s*android\.newDsl\s*=.*\r?\n?', '')
$props = [regex]::Replace($props, '(?m)^\s*android\.builtInKotlin\s*=.*\r?\n?', '')
Set-Content $propsFile $props -Encoding UTF8

# IMPORTANT:
# Kotlin's old kotlinOptions.jvmTarget String API is now a compile error.
# Use the compilerOptions DSL from the applied org.jetbrains.kotlin.android plugin.
$appText = @'
import org.jetbrains.kotlin.gradle.dsl.JvmTarget
import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    id("dev.flutter.flutter-gradle-plugin")
}

val releaseProperties = Properties()
val releasePropertiesFile = rootProject.file("../signing/key.properties")
val releaseKeyFile = rootProject.file("../signing/mleysoft-release-key.jks")

if (releasePropertiesFile.exists()) {
    releaseProperties.load(FileInputStream(releasePropertiesFile))
}

android {
    namespace = "com.mleysoft.ik"
    compileSdk = 36
    ndkVersion = "28.2.13676358"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        isCoreLibraryDesugaringEnabled = true
    }

    defaultConfig {
        applicationId = "com.mleysoft.ik"
        minSdk = flutter.minSdkVersion
        targetSdk = 36
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            if (!releasePropertiesFile.exists() || !releaseKeyFile.exists()) {
                throw GradleException(
                    "Play Store release imza dosyalari bulunamadi. " +
                    "Once mobile_app\\setup_playstore_signing.bat dosyasini calistirin."
                )
            }
            keyAlias = releaseProperties.getProperty("keyAlias")
            keyPassword = releaseProperties.getProperty("keyPassword")
            storeFile = releaseKeyFile
            storePassword = releaseProperties.getProperty("storePassword")
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
            isMinifyEnabled = false
            isShrinkResources = false
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget.set(JvmTarget.JVM_17)
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
'@
Set-Content $appGradle $appText -Encoding UTF8

# local_auth requires FragmentActivity.
# IMPORTANT: namespace/applicationId is com.mleysoft.ik, so MainActivity must be in the same package.
$kotlinRoot = Join-Path $appRoot 'src/main/kotlin'
$targetDir = Join-Path $kotlinRoot 'com/mleysoft/ik'
New-Item -ItemType Directory -Force -Path $targetDir | Out-Null

# Remove Flutter's generated MainActivity under com.example.* to avoid package mismatch.
Get-ChildItem $kotlinRoot -Filter 'MainActivity.kt' -Recurse -ErrorAction SilentlyContinue |
    ForEach-Object {
        if ($_.FullName -ne (Join-Path $targetDir 'MainActivity.kt')) {
            Remove-Item $_.FullName -Force -ErrorAction SilentlyContinue
        }
    }

$mainActivity = @'
package com.mleysoft.ik

import io.flutter.embedding.android.FlutterFragmentActivity

class MainActivity : FlutterFragmentActivity()
'@
Set-Content (Join-Path $targetDir 'MainActivity.kt') $mainActivity -Encoding UTF8

# Required permissions.
$manifest = Join-Path $appRoot 'src/main/AndroidManifest.xml'
if (Test-Path $manifest) {
    $m = Get-Content $manifest -Raw -Encoding UTF8
    $permissions = @(
        'android.permission.INTERNET',
        'android.permission.USE_BIOMETRIC',
        'android.permission.POST_NOTIFICATIONS',
        'android.permission.CAMERA'
    )
    foreach ($permissionName in $permissions) {
        if ($m -notmatch [regex]::Escape($permissionName)) {
            $line = '<uses-permission android:name="' + $permissionName + '" />'
            $m = $m.Replace('<application', $line + "`r`n    <application")
        }
    }
    Set-Content $manifest $m -Encoding UTF8
}



# V61 Android launcher icon and minimal native splash.
$resRoot = Join-Path $appRoot 'src/main/res'
$adaptiveForeground = Join-Path $projectRoot 'assets/platform_icons/android/play_store_appicon_icon_512.png'
$transparentSplash = Join-Path $projectRoot 'assets/images/mleysoft-transparent-splash.png'

foreach ($density in @('mdpi','hdpi','xhdpi','xxhdpi','xxxhdpi')) {
    $dir = Join-Path $resRoot ('mipmap-' + $density)
    New-Item -ItemType Directory -Force -Path $dir | Out-Null
    $source = Join-Path $projectRoot ('assets/platform_icons/android/mipmap-' + $density + '/appicon_ic_launcher.png')
    if (Test-Path $source) {
        Copy-Item $source (Join-Path $dir 'ic_launcher.png') -Force
        $roundSource = Join-Path $projectRoot ('assets/platform_icons/android/mipmap-' + $density + '/appicon_ic_launcher_round.png')
        if (Test-Path $roundSource) { Copy-Item $roundSource (Join-Path $dir 'ic_launcher_round.png') -Force } else { Copy-Item $source (Join-Path $dir 'ic_launcher_round.png') -Force }
    }
}

$drawableNoDpi = Join-Path $resRoot 'drawable-nodpi'
New-Item -ItemType Directory -Force -Path $drawableNoDpi | Out-Null
if (Test-Path $adaptiveForeground) {
    Copy-Item $adaptiveForeground (Join-Path $drawableNoDpi 'mleysoft_adaptive_foreground.png') -Force
}
if (Test-Path $transparentSplash) {
    Copy-Item $transparentSplash (Join-Path $drawableNoDpi 'mleysoft_transparent_splash.png') -Force
}

$valuesDir = Join-Path $resRoot 'values'
New-Item -ItemType Directory -Force -Path $valuesDir | Out-Null
$colorsFile = Join-Path $valuesDir 'mleysoft_colors.xml'
$colorsXml = @'
<?xml version="1.0" encoding="utf-8"?>
<resources>
    <color name="mleysoft_icon_background">#11181F</color>
</resources>
'@
Set-Content $colorsFile $colorsXml -Encoding UTF8

# Uygulama adı launcher / son uygulamalar ekranında Türkçe olarak görünsün.
$stringsFile = Join-Path $valuesDir 'mleysoft_strings.xml'
$stringsXml = @'
<?xml version="1.0" encoding="utf-8"?>
<resources>
    <string name="mleysoft_app_name">MleySoft &#304;K</string>
</resources>
'@
Set-Content $stringsFile $stringsXml -Encoding UTF8

$adaptiveDir = Join-Path $resRoot 'mipmap-anydpi-v26'
New-Item -ItemType Directory -Force -Path $adaptiveDir | Out-Null
$adaptiveXml = @'
<?xml version="1.0" encoding="utf-8"?>
<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
    <background android:drawable="@color/mleysoft_icon_background" />
    <foreground android:drawable="@drawable/mleysoft_adaptive_foreground" />
</adaptive-icon>
'@
Set-Content (Join-Path $adaptiveDir 'ic_launcher.xml') $adaptiveXml -Encoding UTF8
Set-Content (Join-Path $adaptiveDir 'ic_launcher_round.xml') $adaptiveXml -Encoding UTF8

foreach ($drawableName in @('drawable','drawable-v21')) {
    $drawableDir = Join-Path $resRoot $drawableName
    New-Item -ItemType Directory -Force -Path $drawableDir | Out-Null
    $launchXml = @'
<?xml version="1.0" encoding="utf-8"?>
<layer-list xmlns:android="http://schemas.android.com/apk/res/android">
    <item>
        <shape android:shape="rectangle">
            <solid android:color="#FFFFFF" />
        </shape>
    </item>
</layer-list>
'@
    Set-Content (Join-Path $drawableDir 'launch_background.xml') $launchXml -Encoding UTF8
}

$values31 = Join-Path $resRoot 'values-v31'
New-Item -ItemType Directory -Force -Path $values31 | Out-Null
$styles31 = @'
<?xml version="1.0" encoding="utf-8"?>
<resources>
    <style name="LaunchTheme" parent="@android:style/Theme.Light.NoTitleBar">
        <item name="android:windowSplashScreenBackground">#FFFFFF</item>
        <item name="android:windowSplashScreenAnimatedIcon">@drawable/mleysoft_transparent_splash</item>
        <item name="android:windowSplashScreenAnimationDuration">0</item>
        <item name="android:windowLightStatusBar">true</item>
        <item name="android:windowActionModeOverlay">true</item>
    </style>
    <style name="NormalTheme" parent="@android:style/Theme.Light.NoTitleBar">
        <item name="android:windowBackground">#FFFFFF</item>
    </style>
</resources>
'@
Set-Content (Join-Path $values31 'styles.xml') $styles31 -Encoding UTF8

if (Test-Path $manifest) {
    $m = Get-Content $manifest -Raw -Encoding UTF8
    if ($m -match '<application') {
        if ($m -notmatch 'android:roundIcon=') {
            $m = $m.Replace('<application','<application android:roundIcon="@mipmap/ic_launcher_round"')
        }
        Set-Content $manifest $m -Encoding UTF8
    }
}


# Uygulama etiketi ve MainActivity yolu her build öncesinde kesin olarak sabitlenir.
if (Test-Path $manifest) {
    $m = Get-Content $manifest -Raw -Encoding UTF8

    if ($m -match '<application[^>]*android:label="[^"]*"') {
        $m = [regex]::Replace($m, '(<application[^>]*android:label=")[^"]*(")', '$1@string/mleysoft_app_name$2', 1)
    }
    elseif ($m -match '<application') {
        $m = $m.Replace('<application', '<application android:label="@string/mleysoft_app_name"')
    }

    # Flutter template bazen .MainActivity üretir; namespace com.mleysoft.ik olduğundan bu yol doğrudur.
    $m = [regex]::Replace($m, 'android:name="(?:com\.example\.[^"]*MainActivity|[^"]*\.MainActivity)"', 'android:name=".MainActivity"')

    Set-Content $manifest $m -Encoding UTF8
}


# flutter_secure_storage ile şifreli veriler Google otomatik yedeğinden
# farklı cihaz/kurulum anahtarıyla geri yüklenirse bazı telefonlarda açılış
# hatasına neden olabilir. Uygulama oturum verileri yedeklenmez.
if (Test-Path $manifest) {
    $m = Get-Content $manifest -Raw -Encoding UTF8
    if ($m -match '<application[^>]*android:allowBackup="[^"]*"') {
        $m = [regex]::Replace($m, '(<application[^>]*android:allowBackup=")[^"]*(")', '$1false$2', 1)
    }
    elseif ($m -match '<application') {
        $m = $m.Replace('<application', '<application android:allowBackup="false"')
    }
    Set-Content $manifest $m -Encoding UTF8
}

# Password reset deep link.
if (Test-Path $manifest) {
    $m = Get-Content $manifest -Raw -Encoding UTF8
    if ($m -notmatch 'android:scheme="mleysoftik"') {
        $intent = @'
            <intent-filter android:autoVerify="false">
                <action android:name="android.intent.action.VIEW" />
                <category android:name="android.intent.category.DEFAULT" />
                <category android:name="android.intent.category.BROWSABLE" />
                <data android:scheme="mleysoftik" android:host="reset-password" />
            </intent-filter>
'@
        $m = $m.Replace('</activity>', $intent + '        </activity>')
        Set-Content $manifest $m -Encoding UTF8
    }
}

Write-Host 'V83 Android toolchain: AGP 8.13.2 + Gradle 8.14.3 + API 36.'
Write-Host 'Kotlin JVM 17 compilerOptions aktif; MainActivity, tam alan adaptive MleySoft IK ikon + logosuz hizli sistem splash ve sifre reset deep-link ayarlari uygulandi.'
