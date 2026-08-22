$ErrorActionPreference = 'Stop'

$projectRoot = Split-Path -Parent $PSScriptRoot
$signingDir = Join-Path $projectRoot 'signing'
$keyFile = Join-Path $signingDir 'mleysoft-release-key.jks'
$propsFile = Join-Path $signingDir 'key.properties'
$infoFile = Join-Path $signingDir 'PLAY_STORE_KEY_INFO.txt'

New-Item -ItemType Directory -Force -Path $signingDir | Out-Null

if ((Test-Path $keyFile) -and (Test-Path $propsFile)) {
    Write-Host ''
    Write-Host 'Play Store release anahtari zaten mevcut:' -ForegroundColor Green
    Write-Host $keyFile
    Write-Host 'Yeni anahtar olusturulmadi.'
    exit 0
}

if (-not $env:JAVA_HOME) {
    throw 'JAVA_HOME tanimli degil. Once prepare_android_v87.bat calistirin.'
}

$keytool = Join-Path $env:JAVA_HOME 'bin\keytool.exe'
if (-not (Test-Path $keytool)) {
    throw "keytool.exe bulunamadi: $keytool"
}

Write-Host ''
Write-Host '========================================================='
Write-Host ' MleySoft IK - Google Play Release Imza Anahtari Kurulumu'
Write-Host '========================================================='
Write-Host ''
Write-Host 'Bu islem sadece ILK YAYINDA bir kez yapilmalidir.'
Write-Host 'Olusacak JKS dosyasini ve sifreyi mutlaka yedekleyin.'
Write-Host ''

while ($true) {
    $secure1 = Read-Host 'Release anahtari icin en az 8 karakterli sifre girin' -AsSecureString
    $bstr1 = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($secure1)
    $password1 = [Runtime.InteropServices.Marshal]::PtrToStringBSTR($bstr1)
    [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr1)

    if ($password1.Length -lt 8) {
        Write-Host 'Sifre en az 8 karakter olmali.' -ForegroundColor Yellow
        continue
    }

    $secure2 = Read-Host 'Ayni sifreyi tekrar girin' -AsSecureString
    $bstr2 = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($secure2)
    $password2 = [Runtime.InteropServices.Marshal]::PtrToStringBSTR($bstr2)
    [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr2)

    if ($password1 -ne $password2) {
        Write-Host 'Sifreler ayni degil. Tekrar deneyin.' -ForegroundColor Yellow
        continue
    }
    break
}

$alias = 'mleysoft'
$dname = 'CN=MleySoft, OU=Software, O=MleySoft, L=Diyarbakir, ST=Diyarbakir, C=TR'

& $keytool -genkeypair -v `
    -keystore $keyFile `
    -storepass $password1 `
    -keypass $password1 `
    -alias $alias `
    -keyalg RSA `
    -keysize 2048 `
    -validity 10000 `
    -dname $dname

if ($LASTEXITCODE -ne 0) {
    throw 'Release anahtari olusturulamadi.'
}

$props = @"
storePassword=$password1
keyPassword=$password1
keyAlias=$alias
"@
[System.IO.File]::WriteAllText($propsFile, $props, [System.Text.UTF8Encoding]::new($false))

$listOutput = & $keytool -list -v -keystore $keyFile -storepass $password1 -alias $alias 2>&1
$sha1 = ($listOutput | Select-String 'SHA1:' | Select-Object -First 1).ToString().Trim()
$sha256 = ($listOutput | Select-String 'SHA256:' | Select-Object -First 1).ToString().Trim()

$info = @"
MleySoft IK - Google Play Release Signing

Package Name : com.mleysoft.ik
Key Alias    : $alias
Keystore     : signing\mleysoft-release-key.jks
$sha1
$sha256

ONEMLI:
- mleysoft-release-key.jks dosyasini guvenli bir yerde yedekleyin.
- key.properties dosyasini ve sifrelerinizi kimseyle paylasmayin.
- Bu anahtari kaybetmeyin. Sonraki uygulama guncellemelerinde gerekecektir.
"@
[System.IO.File]::WriteAllText($infoFile, $info, [System.Text.UTF8Encoding]::new($false))

$password1 = $null
$password2 = $null

Write-Host ''
Write-Host 'Release anahtari basariyla olusturuldu.' -ForegroundColor Green
Write-Host "Keystore: $keyFile"
Write-Host "Bilgi:    $infoFile"
Write-Host ''
Write-Host 'Bu dosyalari YEDEKLEYIN:' -ForegroundColor Yellow
Write-Host '  signing\mleysoft-release-key.jks'
Write-Host '  signing\key.properties'
Write-Host ''
