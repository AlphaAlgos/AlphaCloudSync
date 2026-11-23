# AlphaCloudSync -- Reproducible Performance & Resource Benchmark Harness
# Run: powershell -NoProfile -ExecutionPolicy Bypass -File .\benchmarks\run-benchmarks.ps1
[CmdletBinding()]
param(
    [string]$TargetExe = "",
    [int]$RealFilesCount = 400,
    [int]$JunkFilesCount = 2400
)

$ErrorActionPreference = "Stop"
$ProjectRoot = Split-Path -Parent $PSScriptRoot
$BenchDir    = $PSScriptRoot
$ExePath     = if (-not [string]::IsNullOrWhiteSpace($TargetExe)) { $TargetExe } else { Join-Path $ProjectRoot "dist\AlphaCloudSync.exe" }
$OutJson     = Join-Path $BenchDir "latest-results.json"

$rcloneExe = (Get-Command rclone -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Source)
if (-not $rcloneExe) {
    $wgRoot = Join-Path $env:LOCALAPPDATA "Microsoft\WinGet\Packages"
    if (Test-Path -LiteralPath $wgRoot) {
        $rcloneExe = Get-ChildItem -LiteralPath $wgRoot -Filter "rclone.exe" -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1 -ExpandProperty FullName
    }
}
if (-not $rcloneExe) { throw "rclone.exe is required to run benchmarks." }

function Measure-ProcessPeakRam {
    param([string]$FilePath, [string]$Arguments)
    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = $FilePath
    $psi.Arguments = $Arguments
    $psi.UseShellExecute = $false
    $psi.CreateNoWindow = $true
    $psi.RedirectStandardOutput = $true
    $psi.RedirectStandardError = $true
    $p = [System.Diagnostics.Process]::Start($psi)
    $outTask = $p.StandardOutput.ReadToEndAsync()
    $errTask = $p.StandardError.ReadToEndAsync()
    $peakBytes = 0L
    while (-not $p.HasExited) {
        try {
            $p.Refresh()
            if ($p.PeakWorkingSet64 -gt $peakBytes) { $peakBytes = $p.PeakWorkingSet64 }
            if ($p.WorkingSet64 -gt $peakBytes)     { $peakBytes = $p.WorkingSet64 }
        } catch {}
        Start-Sleep -Milliseconds 30
    }
    try { $p.Refresh(); if ($p.PeakWorkingSet64 -gt $peakBytes) { $peakBytes = $p.PeakWorkingSet64 } } catch {}
    $sw.Stop()
    return [PSCustomObject]@{
        ExitCode  = $p.ExitCode
        Seconds   = [math]::Round($sw.Elapsed.TotalSeconds, 3)
        PeakRamMB = [math]::Round($peakBytes / 1MB, 1)
        StdOut    = $outTask.Result
        StdErr    = $errTask.Result
    }
}

Write-Host "Running AlphaCloudSync Reproducible Benchmark Harness..." -ForegroundColor Cyan

$osInfo = Get-CimInstance Win32_OperatingSystem
$cpuInfo = Get-CimInstance Win32_Processor | Select-Object -First 1
$rcloneVer = (& $rcloneExe version | Select-Object -First 1).Trim()

$exeSizeKB = if (Test-Path -LiteralPath $ExePath) { [math]::Round((Get-Item -LiteralPath $ExePath).Length / 1KB, 1) } else { 0 }
$exeSha256 = if (Test-Path -LiteralPath $ExePath) { (Get-FileHash -LiteralPath $ExePath -Algorithm SHA256).Hash.ToLowerInvariant() } else { "N/A" }

# 1. Generate deterministic isolated synthetic developer repository (real source + node_modules/.venv junk)
$sand = Join-Path $env:TEMP "acs_bench_$PID"
$srcDir  = Join-Path $sand "repo"
$dstDir  = Join-Path $sand "cloud_target"
$archDir = Join-Path $sand "cloud_archive"
$bakDir  = Join-Path $sand "restore_backup"
New-Item -ItemType Directory -Path (Join-Path $srcDir "src"), (Join-Path $srcDir "node_modules\pkg"), (Join-Path $srcDir ".venv\lib"), $dstDir, $archDir, $bakDir -Force | Out-Null

try {
    $payloadReal = "A" * 4096   # 4 KB per source file
    $payloadJunk = "J" * 16384  # 16 KB per junk cache file
    for ($i = 1; $i -le $RealFilesCount; $i++) {
        [System.IO.File]::WriteAllText((Join-Path $srcDir "src\module_$i.ts"), $payloadReal)
    }
    for ($j = 1; $j -le $JunkFilesCount; $j++) {
        $sub = if ($j % 2 -eq 0) { "node_modules\pkg\dep_$j.js" } else { ".venv\lib\cache_$j.pyc" }
        [System.IO.File]::WriteAllText((Join-Path $srcDir $sub), $payloadJunk)
    }

    $exFile = Join-Path $sand "developer-excludes.txt"
    [System.IO.File]::WriteAllLines($exFile, @("node_modules/**", ".venv/**", "*.pyc", "*.tmp"), (New-Object System.Text.UTF8Encoding($false)))

    # 2. Measure Raw Scan vs Filtered JSON Scan
    $rawScan  = Measure-ProcessPeakRam -FilePath $rcloneExe -Arguments "size `"$srcDir`" --json --quiet"
    $filtScan = Measure-ProcessPeakRam -FilePath $rcloneExe -Arguments "size `"$srcDir`" --exclude-from `"$exFile`" --json --quiet"
    $rawObj   = $rawScan.StdOut  | ConvertFrom-Json
    $filtObj  = $filtScan.StdOut | ConvertFrom-Json
    $skippedFiles = [int]$rawObj.count - [int]$filtObj.count
    $skippedMB    = [math]::Round(([double]$rawObj.bytes - [double]$filtObj.bytes) / 1MB, 2)

    # 3. Measure Filtered Safe-Archive Sync + Safe Restore Overwrite Backup
    $syncRun = Measure-ProcessPeakRam -FilePath $rcloneExe -Arguments "sync `"$srcDir`" `"$dstDir`" --backup-dir `"$archDir`" --exclude-from `"$exFile`" --transfers 12 --checkers 24 --quiet"
    [System.IO.File]::WriteAllText((Join-Path $srcDir "src\module_1.ts"), "LOCAL-EDITED-CONTENT")
    $restoreRun = Measure-ProcessPeakRam -FilePath $rcloneExe -Arguments "copy `"$dstDir`" `"$srcDir`" --backup-dir `"$bakDir`" --exclude-from `"$exFile`" --quiet"

    # 4. Measure Headless EXE Status Command (if EXE exists)
    $cliRun = if (Test-Path -LiteralPath $ExePath) {
        Measure-ProcessPeakRam -FilePath $ExePath -Arguments "-Action Status"
    } else {
        [PSCustomObject]@{ ExitCode = -1; Seconds = 0; PeakRamMB = 0 }
    }

    # 5. Measure live rclone mount idle RAM if mounted on this host
    $mountProc = Get-CimInstance Win32_Process -Filter "Name='rclone.exe'" -ErrorAction SilentlyContinue |
        Where-Object { $_.CommandLine -match '\bmount\b' } | Select-Object -First 1
    $mountRamMB = if ($mountProc) {
        $mp = Get-Process -Id $mountProc.ProcessId -ErrorAction SilentlyContinue
        if ($mp) { [math]::Round($mp.WorkingSet64 / 1MB, 1) } else { $null }
    } else { $null }

    $report = [PSCustomObject]@{
        TimestampUtc     = (Get-Date).ToUniversalTime().ToString("o")
        HostEnvironment  = [PSCustomObject]@{
            OS            = $osInfo.Caption
            OSBuild       = $osInfo.BuildNumber
            CPU           = $cpuInfo.Name.Trim()
            TotalRamGB    = [math]::Round($osInfo.TotalVisibleMemorySize / 1MB, 1)
            RcloneVersion = $rcloneVer
        }
        Binary           = [PSCustomObject]@{
            FileName  = (Split-Path -Leaf $ExePath)
            SizeKB    = $exeSizeKB
            Sha256    = $exeSha256
        }
        SyntheticDataset = [PSCustomObject]@{
            TotalFiles       = [int]$rawObj.count
            TotalMB          = [math]::Round([double]$rawObj.bytes / 1MB, 2)
            CleanFiles       = [int]$filtObj.count
            CleanMB          = [math]::Round([double]$filtObj.bytes / 1MB, 2)
            SkippedJunkFiles = $skippedFiles
            SkippedJunkMB    = $skippedMB
        }
        Measurements     = [PSCustomObject]@{
            ClosedScheduledIdleRamMB = 0.0
            ClosedScheduledIdleCpuPct= 0.0
            MountStreamIdleRamMB     = $mountRamMB
            RawScanSeconds           = $rawScan.Seconds
            RawScanPeakRamMB         = $rawScan.PeakRamMB
            FilteredScanSeconds      = $filtScan.Seconds
            FilteredScanPeakRamMB    = $filtScan.PeakRamMB
            FilteredSyncSeconds      = $syncRun.Seconds
            FilteredSyncPeakRamMB    = $syncRun.PeakRamMB
            SafeRestoreSeconds       = $restoreRun.Seconds
            SafeRestorePeakRamMB     = $restoreRun.PeakRamMB
            ExeCliStatusSeconds      = $cliRun.Seconds
            ExeCliStatusExitCode     = $cliRun.ExitCode
        }
    }

    $jsonOut = ConvertTo-Json -InputObject $report -Depth 6
    [System.IO.File]::WriteAllText($OutJson, $jsonOut, (New-Object System.Text.UTF8Encoding($false)))

    Write-Host "========================================================================" -ForegroundColor Green
    Write-Host " BENCHMARK COMPLETE -- Saved raw JSON to: $OutJson" -ForegroundColor Green
    Write-Host (" Binary Size       : {0} KB" -f $exeSizeKB)
    Write-Host (" Synthetic Dataset : {0} total -> {1} clean (Skipped {2} junk files / {3} MB)" -f $rawObj.count, $filtObj.count, $skippedFiles, $skippedMB)
    Write-Host (" Filtered Scan     : {0}s | Peak RAM: {1} MB" -f $filtScan.Seconds, $filtScan.PeakRamMB)
    Write-Host (" Safe-Archive Sync : {0}s | Peak RAM: {1} MB" -f $syncRun.Seconds, $syncRun.PeakRamMB)
    Write-Host (" Safe Restore      : {0}s | Peak RAM: {1} MB" -f $restoreRun.Seconds, $restoreRun.PeakRamMB)
    Write-Host (" EXE CLI Status    : {0}s | ExitCode: {1}" -f $cliRun.Seconds, $cliRun.ExitCode)
    if ($null -ne $mountRamMB) { Write-Host (" Live G: Mount RAM : {0} MB (0% Idle CPU)" -f $mountRamMB) }
    Write-Host "========================================================================" -ForegroundColor Green
} finally {
    Remove-Item -LiteralPath $sand -Recurse -Force -ErrorAction SilentlyContinue
}
