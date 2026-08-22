$ErrorActionPreference = 'Stop'

$projectRoot = Split-Path -Parent $PSScriptRoot
$outFile = Join-Path $projectRoot '.mleysoft_jdk_path'
$localJdkRoot = Join-Path $projectRoot '.jdk'

function Get-JavaMajor([string]$javaHome) {
    $javaExe = Join-Path $javaHome 'bin\java.exe'
    if (-not (Test-Path $javaExe)) { return $null }

    $tmpOut = [System.IO.Path]::GetTempFileName()
    $tmpErr = [System.IO.Path]::GetTempFileName()

    try {
        Start-Process -FilePath $javaExe `
            -ArgumentList '-version' `
            -NoNewWindow `
            -Wait `
            -RedirectStandardOutput $tmpOut `
            -RedirectStandardError $tmpErr | Out-Null

        $versionText = ''
        if (Test-Path $tmpOut) { $versionText += (Get-Content $tmpOut -Raw -ErrorAction SilentlyContinue) }
        if (Test-Path $tmpErr) { $versionText += "`n" + (Get-Content $tmpErr -Raw -ErrorAction SilentlyContinue) }

        $m = [regex]::Match($versionText, 'version\s+"([0-9]+)')
        if (-not $m.Success) {
            $m = [regex]::Match($versionText, 'openjdk\s+([0-9]+)')
        }

        if ($m.Success) { return [int]$m.Groups[1].Value }
        return $null
    }
    catch {
        return $null
    }
    finally {
        Remove-Item $tmpOut,$tmpErr -Force -ErrorAction SilentlyContinue
    }
}

function Use-CompatibleJdk([string]$javaHome) {
    if ([string]::IsNullOrWhiteSpace($javaHome)) { return $false }

    $javaExe = Join-Path $javaHome 'bin\java.exe'
    if (-not (Test-Path $javaExe)) { return $false }

    $major = Get-JavaMajor $javaHome
    if ($null -eq $major) { return $false }

    Write-Host "JDK adayi: $javaHome (Java $major)"

    if ($major -ge 17 -and $major -le 23) {
        Set-Content $outFile $javaHome -Encoding ASCII
        Write-Host "Uyumlu JDK secildi: $javaHome"
        Write-Host "Java major: $major"
        return $true
    }

    Write-Host "Atlandi: Java $major bu Android build zinciri icin uygun degil."
    return $false
}

# 1) Previously selected JDK
if (Test-Path $outFile) {
    $remembered = (Get-Content $outFile -Raw -ErrorAction SilentlyContinue).Trim()
    if ($remembered -and (Use-CompatibleJdk $remembered)) { exit 0 }
}

# 2) Search project-local JDKs first. Never delete or modify them here.
if (Test-Path $localJdkRoot) {
    $localHomes = Get-ChildItem $localJdkRoot -Directory -Recurse -ErrorAction SilentlyContinue |
        Where-Object { Test-Path (Join-Path $_.FullName 'bin\java.exe') } |
        Select-Object -ExpandProperty FullName

    foreach ($candidate in $localHomes) {
        if (Use-CompatibleJdk $candidate) { exit 0 }
    }
}

# 3) Other installed JDKs
$candidates = New-Object System.Collections.Generic.List[string]
if ($env:JAVA_HOME) { $candidates.Add($env:JAVA_HOME) }

$candidates.Add('C:\Program Files\Android\Android Studio\jbr')
$candidates.Add('C:\Program Files\Android\Android Studio\jre')
$candidates.Add('C:\Program Files\JetBrains\Android Studio\jbr')
$candidates.Add('C:\Program Files\Java\jdk-21')
$candidates.Add('C:\Program Files\Java\jdk-17')

foreach ($base in @(
    'C:\Program Files\Eclipse Adoptium',
    'C:\Program Files\Microsoft',
    'C:\Program Files\Amazon Corretto',
    'C:\Program Files\BellSoft'
)) {
    if (Test-Path $base) {
        Get-ChildItem $base -Directory -ErrorAction SilentlyContinue |
            Sort-Object Name -Descending |
            ForEach-Object { $candidates.Add($_.FullName) }
    }
}

$seen = @{}
foreach ($candidate in $candidates) {
    if ([string]::IsNullOrWhiteSpace($candidate)) { continue }
    $key = $candidate.ToLowerInvariant()
    if ($seen.ContainsKey($key)) { continue }
    $seen[$key] = $true

    if (Use-CompatibleJdk $candidate) { exit 0 }
}

# 4) No compatible JDK found. Download Temurin 21 into a NEW unique folder.
Write-Host ''
Write-Host 'Uyumlu JDK 17-23 bulunamadi.'
Write-Host 'Temurin JDK 21 proje icine yeni bir klasore indirilecek...'

New-Item -ItemType Directory -Force -Path $localJdkRoot | Out-Null

$stamp = Get-Date -Format 'yyyyMMddHHmmss'
$downloadRoot = Join-Path $localJdkRoot ("temurin21_" + $stamp)
$zipPath = Join-Path $localJdkRoot ("temurin21_" + $stamp + ".zip")

New-Item -ItemType Directory -Force -Path $downloadRoot | Out-Null

$url = 'https://api.adoptium.net/v3/binary/latest/21/ga/windows/x64/jdk/hotspot/normal/eclipse'

try {
    if (Get-Command curl.exe -ErrorAction SilentlyContinue) {
        & curl.exe -L --fail --retry 3 --connect-timeout 30 -o $zipPath $url
        if ($LASTEXITCODE -ne 0) { throw "curl indirme hatasi: $LASTEXITCODE" }
    }
    else {
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        Invoke-WebRequest -Uri $url -OutFile $zipPath -UseBasicParsing
    }

    Expand-Archive -Path $zipPath -DestinationPath $downloadRoot -Force
}
catch {
    throw "JDK 21 otomatik indirilemedi: $($_.Exception.Message)"
}
finally {
    Remove-Item $zipPath -Force -ErrorAction SilentlyContinue
}

$downloadedHome = Get-ChildItem $downloadRoot -Directory -Recurse -ErrorAction SilentlyContinue |
    Where-Object { Test-Path (Join-Path $_.FullName 'bin\java.exe') } |
    Select-Object -First 1 -ExpandProperty FullName

if (-not $downloadedHome) {
    throw 'JDK 21 indirildi ancak java.exe bulunamadi.'
}

if (-not (Use-CompatibleJdk $downloadedHome)) {
    throw 'Indirilen JDK 21 uyumluluk kontrolunden gecemedi.'
}

exit 0
