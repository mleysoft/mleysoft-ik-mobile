$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
& (Join-Path $PSScriptRoot 'select_jdk.ps1')
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

$outFile = Join-Path $projectRoot '.mleysoft_jdk_path'
if (-not (Test-Path $outFile)) { throw 'JDK yol dosyasi olusmadi.' }

$jdk = (Get-Content $outFile -Raw).Trim()
$java = Join-Path $jdk 'bin\java.exe'
if (-not (Test-Path $java)) { throw 'Secilen JDK icinde java.exe yok.' }

Write-Host ''
Write-Host 'JDK secim testi BASARILI.'
Write-Host "Secilen JDK: $jdk"
