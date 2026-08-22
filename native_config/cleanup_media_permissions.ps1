$ErrorActionPreference = 'Stop'

$projectRoot = Split-Path -Parent $PSScriptRoot
$manifest = Join-Path $projectRoot 'android\app\src\main\AndroidManifest.xml'

if (-not (Test-Path $manifest)) {
    throw "AndroidManifest.xml bulunamadi: $manifest"
}

$m = Get-Content $manifest -Raw -Encoding UTF8

$removePermissions = @(
    'android.permission.READ_MEDIA_IMAGES',
    'android.permission.READ_MEDIA_VIDEO'
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

Write-Host 'Google Play medya izinleri temizlendi: READ_MEDIA_IMAGES / READ_MEDIA_VIDEO kaldirildi.'
