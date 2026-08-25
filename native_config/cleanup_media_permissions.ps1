$ErrorActionPreference = 'Stop'

$projectRoot = Split-Path -Parent $PSScriptRoot
$manifest = Join-Path $projectRoot 'android\app\src\main\AndroidManifest.xml'

if (-not (Test-Path $manifest)) {
    throw "AndroidManifest.xml bulunamadi: $manifest"
}

$m = Get-Content $manifest -Raw -Encoding UTF8

$removePermissions = @(
    'android.permission.READ_MEDIA_IMAGES',
    'android.permission.READ_MEDIA_VIDEO',
    'android.permission.READ_EXTERNAL_STORAGE',
    'android.permission.WRITE_EXTERNAL_STORAGE',
    'android.permission.MANAGE_EXTERNAL_STORAGE'
)

foreach ($permission in $removePermissions) {
    $escaped = [regex]::Escape($permission)
    $m = [regex]::Replace(
        $m,
        "(?m)^\s*<uses-permission\s+android:name=`"$escaped`"\s*/>\s*\r?\n?",
        ''
    )
}

Set-Content $manifest $m -Encoding UTF8

Write-Host 'V147 Google Play dosya secimi: genis medya/depolama izinleri kaldirildi; sistem dosya secici kullaniliyor.'
