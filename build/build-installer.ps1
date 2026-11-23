# ==============================================================================
# AlphaCloudSync Windows Setup Installer Builder (Inno Setup 6.x)
# Compiles dist\AlphaCloudSync-Setup-x64.exe & updates dist\SHA256SUMS.txt
# ==============================================================================
param(
    [switch]$SkipAppBuild,
    [string]$SignCertThumbprint = ""
)

$ErrorActionPreference = "Stop"
$ProjectRoot = Split-Path -Parent $PSScriptRoot
$DistDir     = Join-Path $ProjectRoot "dist"
$PortableExe = Join-Path $DistDir "AlphaCloudSync.exe"
$SetupExe    = Join-Path $DistDir "AlphaCloudSync-Setup-x64.exe"
$IssPath     = Join-Path $PSScriptRoot "installer\AlphaCloudSync.iss"
$SumPath     = Join-Path $DistDir "SHA256SUMS.txt"

if (-not $SkipAppBuild -or -not (Test-Path -LiteralPath $PortableExe)) {
    Write-Host "[1/3] Building AlphaCloudSync.exe via build-release.ps1..." -ForegroundColor Cyan
    & (Join-Path $PSScriptRoot "build-release.ps1") -SignCertThumbprint $SignCertThumbprint
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
$proc = Start-Process -FilePath $isccCandidates -ArgumentList "/Q `"$IssPath`"" -Wait -NoNewWindow -PassThru
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

$szSetup = [math]::Round((Get-Item -LiteralPath $SetupExe).Length / 1KB, 1)
Write-Host ""
Write-Host "SUCCESS! Windows Setup Installer built:" -ForegroundColor Green
Write-Host "  Setup EXE:  $SetupExe ($szSetup KB)"
Write-Host "  SHA-256:    $hSetup"
Write-Host "  Checksums:  $SumPath"
