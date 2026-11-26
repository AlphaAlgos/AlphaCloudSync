[CmdletBinding()]
param(
    [string]$Version = "",
    [string]$OutputPath = "",
    [string]$MirrorOutputDir = "",
    [string]$SignCertThumbprint = ""
)

$ErrorActionPreference = "Stop"
$ProjectRoot = Split-Path -Parent $PSScriptRoot
$VersionFile = Join-Path $ProjectRoot "VERSION"
if ([string]::IsNullOrWhiteSpace($Version)) {
    if (-not (Test-Path -LiteralPath $VersionFile)) { throw "Version source not found: $VersionFile" }
    $Version = (Get-Content -LiteralPath $VersionFile -Raw).Trim()
}
if ($Version -notmatch '^\d+\.\d+\.\d+$') { throw "Version must use MAJOR.MINOR.PATCH format; got '$Version'." }
$AssemblyVersion = "$Version.0"
$DistDir     = Join-Path $ProjectRoot "dist"
$IsDefaultOut = [string]::IsNullOrWhiteSpace($OutputPath)
$OutExe      = if ($IsDefaultOut) { Join-Path $DistDir "AlphaCloudSync.exe" } else { $OutputPath }
$OutDir      = Split-Path -Parent $OutExe
$CscExe      = Join-Path $env:WINDIR "Microsoft.NET\Framework64\v4.0.30319\csc.exe"
$IconFile    = Join-Path $ProjectRoot "assets\AlphaCloudSync-icon.ico"

if (-not (Test-Path -LiteralPath $CscExe)) {
    throw "Windows .NET Framework 4.x csc.exe compiler was not found at: $CscExe"
}
if (-not (Test-Path -LiteralPath $IconFile)) {
    throw "Official brand icon not found at: $IconFile"
}
if (-not (Test-Path -LiteralPath $OutDir)) {
    New-Item -ItemType Directory -Path $OutDir -Force | Out-Null
}

# SAFE NON-DESTRUCTIVE GUARD: Never force-kill a running AlphaCloudSync instance or active backup!
if ($IsDefaultOut) {
    $running = @(Get-Process -Name "AlphaCloudSync" -ErrorAction SilentlyContinue)
    if ($running.Count -gt 0) {
        $pids = ($running | Select-Object -ExpandProperty Id) -join ", "
        Write-Error "BUILD REFUSED (SAFETY GUARD): AlphaCloudSync is currently running (PID: $pids). Close AlphaCloudSync cleanly (or wait for your active sync to finish) before rebuilding dist\AlphaCloudSync.exe, or pass -OutputPath for a staging build."
        exit 1
    }
}

# Also verify target output file is not locked by another process
if (Test-Path -LiteralPath $OutExe) {
    try {
        $fs = [System.IO.File]::Open($OutExe, [System.IO.FileMode]::Open, [System.IO.FileAccess]::ReadWrite, [System.IO.FileShare]::None)
        $fs.Close()
    } catch {
        Write-Error "BUILD REFUSED (FILE LOCKED): '$OutExe' is currently in use. Close the running executable before rebuilding."
        exit 1
    }
}

$resources = @(
    @{ File = "src\AlphaCloudSync.ps1";          ResName = "src__AlphaCloudSync.ps1" },
    @{ File = "assets\AlphaCloudSync-icon.ico";  ResName = "assets__AlphaCloudSync-icon.ico" },
    @{ File = "assets\AlphaCloudSync-folder.ico"; ResName = "assets__AlphaCloudSync-folder.ico" },
    @{ File = "assets\AlphaCloudSync-icon.png";  ResName = "assets__AlphaCloudSync-icon.png" },
    @{ File = "assets\sounds\chime.mp3";         ResName = "assets__sounds__chime.mp3" },
    @{ File = "assets\sounds\ping.mp3";          ResName = "assets__sounds__ping.mp3" },
    @{ File = "assets\sounds\sparkle.mp3";       ResName = "assets__sounds__sparkle.mp3" },
    @{ File = "assets\sounds\notification.mp3";  ResName = "assets__sounds__notification.mp3" },
    @{ File = "assets\sounds\CREDITS.md";        ResName = "assets__sounds__CREDITS.md" },
    @{ File = "presets\developer-default.json";  ResName = "presets__developer-default.json" },
    @{ File = "presets\creative-media.json";     ResName = "presets__creative-media.json" },
    @{ File = "presets\general-backup.json";     ResName = "presets__general-backup.json" },
    @{ File = "locales\en.json";                 ResName = "locales__en.json" },
    @{ File = "locales\ar.json";                 ResName = "locales__ar.json" },
    @{ File = "locales\es.json";                 ResName = "locales__es.json" },
    @{ File = "locales\fr.json";                 ResName = "locales__fr.json" },
    @{ File = "locales\de.json";                 ResName = "locales__de.json" },
    @{ File = "locales\zh.json";                 ResName = "locales__zh.json" },
    @{ File = "locales\id.json";                 ResName = "locales__id.json" }
)

# Auto-discover and embed every modular .ps1 file under src\modules (Core, Providers, Engines, UI)
$modulesRoot = Join-Path $ProjectRoot "src\modules"
if (Test-Path -LiteralPath $modulesRoot) {
    foreach ($mf in (Get-ChildItem -LiteralPath $modulesRoot -Recurse -Filter "*.ps1" -File | Sort-Object FullName)) {
        $rel = $mf.FullName.Substring($ProjectRoot.Length + 1)
        $resN = $rel -replace '\\', '__'
        $resources += @{ File = $rel; ResName = $resN }
    }
}

$cscArgs = @(
    "/nologo",
    "/target:winexe",
    "/platform:x64",
    "/optimize+",
    "/reference:System.Windows.Forms.dll",
    "/reference:System.Drawing.dll",
    "/win32icon:`"$IconFile`"",
    "/out:`"$OutExe`""
)

foreach ($r in $resources) {
    $full = Join-Path $ProjectRoot $r.File
    if (-not (Test-Path -LiteralPath $full)) {
        throw "Required embedded resource missing: $full"
    }
    $cscArgs += "/resource:`"$full`",$($r.ResName)"
}

$cscArgs += "`"$ProjectRoot\src\AlphaCloudSyncLauncher.cs`""
$AssemblyInfoPath = Join-Path ([System.IO.Path]::GetTempPath()) ("AlphaCloudSync.AssemblyInfo.{0}.cs" -f [guid]::NewGuid().ToString("N"))
$AssemblyInfoSource = @"
using System.Reflection;
[assembly: AssemblyVersion("$AssemblyVersion")]
[assembly: AssemblyFileVersion("$AssemblyVersion")]
[assembly: AssemblyInformationalVersion("$Version")]
"@

Write-Host "Building standalone native Windows executable: $OutExe ..." -ForegroundColor Cyan
try {
    [System.IO.File]::WriteAllText($AssemblyInfoPath, $AssemblyInfoSource, (New-Object System.Text.UTF8Encoding($false)))
    $cscArgs += "`"$AssemblyInfoPath`""
    $argLine = $cscArgs -join " "
    $p = Start-Process -FilePath $CscExe -ArgumentList $argLine -NoNewWindow -Wait -PassThru
    if ($p.ExitCode -ne 0 -or -not (Test-Path -LiteralPath $OutExe)) {
        throw "csc.exe build failed with ExitCode=$($p.ExitCode)"
    }
} finally {
    Remove-Item -LiteralPath $AssemblyInfoPath -Force -ErrorAction SilentlyContinue
}

# Optional Authenticode Code Signing (when certificate thumbprint is provided via parameter or env var)
$certThumb = if (-not [string]::IsNullOrWhiteSpace($SignCertThumbprint)) { $SignCertThumbprint } else { $env:ALPHACLOUDSYNC_CERT_THUMBPRINT }
$signedStatus = "Unsigned (Open-Source Community Build -- SHA-256 Verified)"
if (-not [string]::IsNullOrWhiteSpace($certThumb)) {
    $signTool = Get-ChildItem -Path "C:\Program Files (x86)\Windows Kits\10\bin" -Filter "signtool.exe" -Recurse -ErrorAction SilentlyContinue |
        Where-Object { $_.FullName -match '\\x64\\signtool\.exe$' } | Select-Object -First 1 -ExpandProperty FullName
    if ($signTool) {
        & $signTool sign /fd SHA256 /sha1 $certThumb /tr "http://timestamp.digicert.com" /td SHA256 $OutExe
        if ($LASTEXITCODE -eq 0) {
            $signedStatus = "Authenticode Signed (SHA-256 + RFC3161 Timestamp)"
        } else {
            throw "signtool.exe failed with ExitCode=$LASTEXITCODE"
        }
    } else {
        Write-Warning "ALPHACLOUDSYNC_CERT_THUMBPRINT was specified but signtool.exe was not found."
    }
}

$exeInfo = Get-Item -LiteralPath $OutExe
$hash    = (Get-FileHash -LiteralPath $OutExe -Algorithm SHA256).Hash.ToLowerInvariant()
$exeName = Split-Path -Leaf $OutExe
$sumsPath = Join-Path $OutDir "SHA256SUMS.txt"
[System.IO.File]::WriteAllText($sumsPath, "$hash  $exeName`r`n", (New-Object System.Text.UTF8Encoding($false)))

# Keep WinGet manifest SHA-256 synchronized automatically on default release builds
$mirroredDir = $null
if ($IsDefaultOut) {
    $wingetPath = Join-Path $ProjectRoot "winget\AlphaAlgorithms.AlphaCloudSync.yaml"
    if (Test-Path -LiteralPath $wingetPath) {
        $wgRaw = [System.IO.File]::ReadAllText($wingetPath, [System.Text.Encoding]::UTF8)
        $wgRaw = $wgRaw -replace '(?m)^PackageVersion:\s*.*$', "PackageVersion: $Version"
        $wgRaw = $wgRaw -replace '(?m)^(\s*InstallerUrl:\s*https://github\.com/AlphaAlgos/AlphaCloudSync/releases/download/)[^/]+(/AlphaCloudSync\.exe\s*)$', "`${1}v$Version`${2}"
        $wgNew = $wgRaw -replace '(?m)^(\s*InstallerSha256:\s*)[A-Fa-f0-9]{64}(\r?)$', "`${1}$($hash.ToUpperInvariant())`$2"
        [System.IO.File]::WriteAllText($wingetPath, $wgNew, (New-Object System.Text.UTF8Encoding($false)))
    }

    $targetMirror = if (-not [string]::IsNullOrWhiteSpace($MirrorOutputDir)) { $MirrorOutputDir } else { $env:ALPHACLOUDSYNC_MIRROR_OUTPUT_DIR }
    if (-not [string]::IsNullOrWhiteSpace($targetMirror)) {
        if (-not (Test-Path -LiteralPath $targetMirror)) { New-Item -ItemType Directory -Path $targetMirror -Force | Out-Null }
        Copy-Item -LiteralPath $OutExe -Destination (Join-Path $targetMirror $exeName) -Force
        Copy-Item -LiteralPath $sumsPath -Destination (Join-Path $targetMirror "SHA256SUMS.txt") -Force
        $mirroredDir = $targetMirror
    }
}

Write-Host "========================================================================" -ForegroundColor Green
Write-Host " BUILD SUCCEEDED -- AlphaCloudSync v$Version" -ForegroundColor Green
Write-Host " Executable : $OutExe"
if ($mirroredDir) { Write-Host " Mirrored   : $mirroredDir\$exeName" }
Write-Host " Size       : $([math]::Round($exeInfo.Length / 1KB, 1)) KB (Self-Contained, $($resources.Count) Embedded Resources)"
Write-Host " Signature  : $signedStatus"
Write-Host " SHA-256    : $hash"
Write-Host "========================================================================" -ForegroundColor Green
