# ==============================================================================
# AlphaCloudSync Windows Setup Installer Builder (Inno Setup 6.x)
# Compiles dist\AlphaCloudSync-Setup-x64.exe & updates dist\SHA256SUMS.txt
# ==============================================================================
param(
    [switch]$SkipAppBuild,
    [string]$SignCertThumbprint = "",
    [string]$Version = "",
    [string]$OutputDirectory = ""
)

$ErrorActionPreference = "Stop"
$ProjectRoot = Split-Path -Parent $PSScriptRoot
$VersionFile = Join-Path $ProjectRoot "VERSION"
if ([string]::IsNullOrWhiteSpace($Version)) {
    if (-not (Test-Path -LiteralPath $VersionFile)) { throw "Version source not found: $VersionFile" }
    $Version = (Get-Content -LiteralPath $VersionFile -Raw).Trim()
}
if ($Version -notmatch '^\d+\.\d+\.\d+$') { throw "Version must use MAJOR.MINOR.PATCH format; got '$Version'." }
$DistDir     = Join-Path $ProjectRoot "dist"
$BuildDir    = if ([string]::IsNullOrWhiteSpace($OutputDirectory)) { $DistDir } else { [System.IO.Path]::GetFullPath($OutputDirectory) }
$IsDefaultBuildDir = [string]::Equals($BuildDir, [System.IO.Path]::GetFullPath($DistDir), [System.StringComparison]::OrdinalIgnoreCase)
if (-not (Test-Path -LiteralPath $BuildDir)) { New-Item -ItemType Directory -Path $BuildDir -Force | Out-Null }
$PortableExe = Join-Path $BuildDir "AlphaCloudSync.exe"
$SetupExe    = Join-Path $BuildDir "AlphaCloudSync-Setup-x64.exe"
$IssPath     = Join-Path $PSScriptRoot "installer\AlphaCloudSync.iss"
$SumPath     = Join-Path $BuildDir "SHA256SUMS.txt"

if (-not $SkipAppBuild -or -not (Test-Path -LiteralPath $PortableExe)) {
    Write-Host "[1/3] Building AlphaCloudSync.exe via build-release.ps1..." -ForegroundColor Cyan
    if ($IsDefaultBuildDir) {
        & (Join-Path $PSScriptRoot "build-release.ps1") -Version $Version -SignCertThumbprint $SignCertThumbprint
    } else {
        & (Join-Path $PSScriptRoot "build-release.ps1") -Version $Version -OutputPath $PortableExe -SignCertThumbprint $SignCertThumbprint
    }
}

$isccCandidates = @(
    (Get-Command iscc -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Source),
    (Join-Path $env:LOCALAPPDATA "Programs\Inno Setup 6\ISCC.exe"),
    (Join-Path ${env:ProgramFiles(x86)} "Inno Setup 6\ISCC.exe"),
    (Join-Path $env:ProgramFiles "Inno Setup 6\ISCC.exe")
) | Where-Object { $_ -and (Test-Path -LiteralPath $_) } | Select-Object -First 1

if (-not $isccCandidates) {
    throw "Inno Setup 6 (ISCC.exe) not found. Install it via: winget install --id JRSoftware.InnoSetup --exact"
}

Write-Host "[2/3] Compiling Windows Setup Installer via Inno Setup..." -ForegroundColor Cyan
$proc = Start-Process -FilePath $isccCandidates -ArgumentList "/Q /DMyAppVersion=$Version /DMyAppBuildDir=`"$BuildDir`" `"$IssPath`"" -Wait -NoNewWindow -PassThru
if ($proc.ExitCode -ne 0 -or -not (Test-Path -LiteralPath $SetupExe)) {
    throw "Inno Setup compilation failed (ExitCode=$($proc.ExitCode))."
}

if (-not [string]::IsNullOrWhiteSpace($SignCertThumbprint)) {
    $cert = Get-ChildItem -Path "Cert:\CurrentUser\My\$SignCertThumbprint","Cert:\LocalMachine\My\$SignCertThumbprint" -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($null -eq $cert) { throw "Authenticode certificate '$SignCertThumbprint' not found." }
    $sig = Set-AuthenticodeSignature -FilePath $SetupExe -Certificate $cert -HashAlgorithm SHA256 -TimestampServer "http://timestamp.digicert.com"
    if ($sig.Status -ne "Valid") { throw "Authenticode signing failed: $($sig.StatusMessage)" }
    Write-Host "  -> Authenticode signed: $($cert.Subject)" -ForegroundColor Green
}

Write-Host "[3/3] Updating dist\SHA256SUMS.txt (Portable + Setup Installer)..." -ForegroundColor Cyan
$hPortable = (Get-FileHash -LiteralPath $PortableExe -Algorithm SHA256).Hash.ToLowerInvariant()
$hSetup    = (Get-FileHash -LiteralPath $SetupExe -Algorithm SHA256).Hash.ToLowerInvariant()
$sumBody   = "$hPortable  AlphaCloudSync.exe`r`n$hSetup  AlphaCloudSync-Setup-x64.exe`r`n"
[System.IO.File]::WriteAllText($SumPath, $sumBody, (New-Object System.Text.UTF8Encoding($false)))

$wingetPath = Join-Path $ProjectRoot "winget\AlphaAlgorithms.AlphaCloudSync.yaml"
if (Test-Path -LiteralPath $wingetPath) {
    $wgRaw = [System.IO.File]::ReadAllText($wingetPath, [System.Text.Encoding]::UTF8)
    $wgRaw = $wgRaw -replace '(?m)^PackageVersion:\s*.*$', "PackageVersion: $Version"
    $wgRaw = $wgRaw -replace '(?m)^(\s*InstallerUrl:\s*https://github\.com/AlphaAlgos/AlphaCloudSync/releases/download/)[^/]+(/AlphaCloudSync\.exe\s*)$', "`${1}v$Version`${2}"
    $wgRaw = $wgRaw -replace '(?m)^(\s*InstallerSha256:\s*)[A-Fa-f0-9]{64}(\r?)$', "`${1}$($hPortable.ToUpperInvariant())`$2"
    [System.IO.File]::WriteAllText($wingetPath, $wgRaw, (New-Object System.Text.UTF8Encoding($false)))
}

$szSetup = [math]::Round((Get-Item -LiteralPath $SetupExe).Length / 1KB, 1)
Write-Host ""
Write-Host "SUCCESS! Windows Setup Installer built:" -ForegroundColor Green
Write-Host "  Setup EXE:  $SetupExe ($szSetup KB)"
Write-Host "  SHA-256:    $hSetup"
Write-Host "  Checksums:  $SumPath"
