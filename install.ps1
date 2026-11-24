# AlphaCloudSync -- One-Line Windows Terminal Installer (Fail-Closed SHA-256 Verified)
# Usage: irm https://raw.githubusercontent.com/AlphaAlgos/AlphaCloudSync/main/install.ps1 | iex
[CmdletBinding()]
param(
    [switch]$LoadFunctionsOnly
)

$ErrorActionPreference = "Stop"

function Assert-ReleaseChecksum {
    param(
        [Parameter(Mandatory = $true)][string]$FilePath,
        [Parameter(Mandatory = $true)][string]$SumsPath,
        [string]$AssetName = "AlphaCloudSync.exe"
    )
    if (-not (Test-Path -LiteralPath $FilePath)) {
        throw "SECURITY ABORT: Downloaded binary not found at '$FilePath'."
    }
    if (-not (Test-Path -LiteralPath $SumsPath)) {
        Remove-Item -LiteralPath $FilePath -Force -ErrorAction SilentlyContinue
        throw "SECURITY ABORT: SHA256SUMS.txt is missing. Refusing to install unverified binary (Fail-Closed)."
    }

    $lines = @(Get-Content -LiteralPath $SumsPath -ErrorAction Stop)
    $expected = $null
    $pattern = '^([a-fA-F0-9]{64})\s+\*?(.+)$'
    foreach ($ln in $lines) {
        if ([string]::IsNullOrWhiteSpace($ln)) { continue }
        if ($ln.Trim() -match $pattern) {
            $hashCandidate = $Matches[1].ToLowerInvariant()
            $nameCandidate = $Matches[2].Trim()
            if ($nameCandidate -ieq $AssetName) {
                $expected = $hashCandidate
                break
            }
        }
    }

    if ([string]::IsNullOrWhiteSpace($expected) -or ($expected -notmatch '^[a-f0-9]{64}$')) {
        Remove-Item -LiteralPath $FilePath -Force -ErrorAction SilentlyContinue
        throw "SECURITY ABORT: No valid 64-character SHA-256 entry for '$AssetName' was found in SHA256SUMS.txt (Fail-Closed)."
    }

    $actual = (Get-FileHash -LiteralPath $FilePath -Algorithm SHA256).Hash.ToLowerInvariant()
    if ($actual -ne $expected) {
        Remove-Item -LiteralPath $FilePath -Force -ErrorAction SilentlyContinue
        throw "SECURITY ABORT: SHA-256 mismatch! Expected=$expected Actual=$actual. Downloaded file removed."
    }
    return $actual
}

function Stop-RunningAlphaCloudSync {
    $runningLauncher = @(Get-Process -Name "AlphaCloudSync" -ErrorAction SilentlyContinue)
    $runningPs = @()
    try {
        $runningPs = @(Get-CimInstance Win32_Process -Filter "Name = 'powershell.exe'" -ErrorAction SilentlyContinue | Where-Object {
            $_.ProcessId -ne $PID -and $_.CommandLine -match 'AlphaCloudSync[\\/]runtime[\\/].*AlphaCloudSync\.ps1'
        })
    } catch {}

    if ($runningLauncher.Count -eq 0 -and $runningPs.Count -eq 0) { return $false }

    Write-Host "Closing running AlphaCloudSync instance for seamless update (mounted drives remain untouched)..." -ForegroundColor Yellow
    foreach ($p in $runningPs) {
        try { Stop-Process -Id ([int]$p.ProcessId) -Force -ErrorAction SilentlyContinue } catch {}
    }
    foreach ($l in $runningLauncher) {
        try { Stop-Process -Id $l.Id -Force -ErrorAction SilentlyContinue } catch {}
    }

    for ($w = 0; $w -lt 20; $w++) {
        if (@(Get-Process -Name "AlphaCloudSync" -ErrorAction SilentlyContinue).Count -eq 0) { break }
        Start-Sleep -Milliseconds 250
    }
    Start-Sleep -Milliseconds 300
    return $true
}

if ($LoadFunctionsOnly) { return }

$Repo       = "AlphaAlgos/AlphaCloudSync"
$InstallDir = Join-Path $env:LOCALAPPDATA "AlphaCloudSync\app"
$ExeDest    = Join-Path $InstallDir "AlphaCloudSync.exe"
$UpdateCmd  = Join-Path $InstallDir "alphacloudsync-update.cmd"
$ExeTmp     = Join-Path $env:TEMP "AlphaCloudSync_download_$PID.exe"
$SumsTmp    = Join-Path $env:TEMP "AlphaCloudSync_SHA256SUMS_$PID.txt"
$isUpgrade  = Test-Path -LiteralPath $ExeDest

Write-Host ($(if ($isUpgrade) { "Updating AlphaCloudSync to the latest release..." } else { "Installing AlphaCloudSync by Alpha Algorithms Company..." })) -ForegroundColor Cyan
New-Item -ItemType Directory -Path $InstallDir -Force | Out-Null

[Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12
$release   = Invoke-RestMethod -Uri "https://api.github.com/repos/$Repo/releases/latest" -TimeoutSec 20
$exeAsset  = $release.assets | Where-Object { $_.name -eq "AlphaCloudSync.exe" } | Select-Object -First 1
$sumsAsset = $release.assets | Where-Object { $_.name -eq "SHA256SUMS.txt" }     | Select-Object -First 1

if ($null -eq $exeAsset) {
    throw "AlphaCloudSync.exe was not found in the latest GitHub release ($($release.tag_name))."
}
if ($null -eq $sumsAsset) {
    throw "SECURITY ABORT: SHA256SUMS.txt was not found in GitHub release ($($release.tag_name)). Installation aborted (Fail-Closed)."
}
if (($exeAsset.browser_download_url -notmatch '^https://') -or ($sumsAsset.browser_download_url -notmatch '^https://')) {
    throw "SECURITY ABORT: Release asset URLs must use HTTPS."
}

try {
    Write-Host "Downloading $($release.tag_name) and SHA256SUMS.txt ..." -ForegroundColor Cyan
    Invoke-WebRequest -Uri $exeAsset.browser_download_url  -OutFile $ExeTmp  -TimeoutSec 90 -UseBasicParsing
    Invoke-WebRequest -Uri $sumsAsset.browser_download_url -OutFile $SumsTmp -TimeoutSec 30 -UseBasicParsing

    $verifiedHash = Assert-ReleaseChecksum -FilePath $ExeTmp -SumsPath $SumsTmp -AssetName "AlphaCloudSync.exe"
    Write-Host "SHA-256 checksum verified (Fail-Closed): $verifiedHash" -ForegroundColor Green

    $null = Stop-RunningAlphaCloudSync
    Move-Item -LiteralPath $ExeTmp -Destination $ExeDest -Force
} finally {
    Remove-Item -LiteralPath $ExeTmp, $SumsTmp -Force -ErrorAction SilentlyContinue
}

# Create quick CLI updater command (alphacloudsync-update) in install folder
try {
    $cmdBody = "@echo off`r`npowershell.exe -NoProfile -ExecutionPolicy Bypass -Command `"irm https://raw.githubusercontent.com/AlphaAlgos/AlphaCloudSync/main/install.ps1 | iex`"`r`n"
    [System.IO.File]::WriteAllText($UpdateCmd, $cmdBody, (New-Object System.Text.UTF8Encoding($false)))
} catch {}

# Create Desktop & Start Menu shortcuts (icon automatically comes from AlphaCloudSync.exe Win32 icon)
try {
    $wsh = New-Object -ComObject WScript.Shell
    foreach ($lnkTarget in @(
        (Join-Path ([Environment]::GetFolderPath("Desktop")) "AlphaCloudSync.lnk"),
        (Join-Path ([Environment]::GetFolderPath("Programs")) "AlphaCloudSync.lnk")
    )) {
        try {
            $sc = $wsh.CreateShortcut($lnkTarget)
            $sc.TargetPath = $ExeDest
            $sc.WorkingDirectory = $InstallDir
            $sc.Description = "AlphaCloudSync -- Smart Cloud Backup, Safe Restore & Persistent Explorer Virtual Drive"
            $sc.Save()
        } catch {}
    }
} catch {}

# Add install directory to user PATH (exact segment deduplication)
$userPath = [Environment]::GetEnvironmentVariable("Path", "User")
$pathEntries = @()
if (-not [string]::IsNullOrWhiteSpace($userPath)) {
    $pathEntries = @($userPath -split ';' | ForEach-Object { $_.Trim() } | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
}
$normInstall = $InstallDir.TrimEnd('\')
$alreadyInPath = @($pathEntries | Where-Object { $_.TrimEnd('\') -ieq $normInstall }).Count -gt 0
if (-not $alreadyInPath) {
    $pathEntries += $InstallDir
    [Environment]::SetEnvironmentVariable("Path", ($pathEntries -join ';'), "User")
}

Write-Host ""
Write-Host "[OK] AlphaCloudSync installed and SHA-256 verified! Launching now..." -ForegroundColor Green
$psiLaunch = New-Object System.Diagnostics.ProcessStartInfo
$psiLaunch.FileName = $ExeDest
$psiLaunch.WorkingDirectory = $InstallDir
$psiLaunch.UseShellExecute = $true
[void][System.Diagnostics.Process]::Start($psiLaunch)
