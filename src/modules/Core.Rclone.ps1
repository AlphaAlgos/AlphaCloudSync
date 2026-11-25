# ==============================================================================
# AlphaCloudSync Module: Core.Rclone (rclone Discovery, Auto-Install, Capture, Source Safety Guard)
# ==============================================================================

function Find-RcloneExe {
    $portable = Join-Path $LocalBinDir "rclone.exe"
    if (Test-Path -LiteralPath $portable) { return $portable }
    $cmd = Get-Command rclone -ErrorAction SilentlyContinue
    if ($null -ne $cmd -and (Test-Path -LiteralPath $cmd.Source)) { return $cmd.Source }
    $wingetPkg = Join-Path $env:LOCALAPPDATA "Microsoft\WinGet\Packages"
    if (Test-Path -LiteralPath $wingetPkg) {
        $found = Get-ChildItem -LiteralPath $wingetPkg -Filter "rclone.exe" -Recurse -ErrorAction SilentlyContinue |
            Select-Object -First 1 -ExpandProperty FullName
        if (-not [string]::IsNullOrWhiteSpace($found)) { return $found }
    }
    return $null
}

function Ensure-RcloneInstalledInteractive {
    $exe = Find-RcloneExe
    if ($null -ne $exe) { return $exe }

    Add-Type -AssemblyName PresentationFramework
    $res = Show-AlphaMessageBox -Message (L "msgSetupBody") -Title (L "msgSetupTitle") -Buttons "YesNo" -Icon "Information"
    if ($res -ne [System.Windows.MessageBoxResult]::Yes) { exit 0 }

    $wg = Get-Command winget -ErrorAction SilentlyContinue
    if ($null -ne $wg) {
        Start-Process -FilePath "winget" -ArgumentList "install --id Rclone.Rclone --exact --silent --accept-package-agreements --accept-source-agreements" -Wait -PassThru -WindowStyle Hidden | Out-Null
        $exe = Find-RcloneExe
        if ($null -ne $exe) { return $exe }
    }

    try {
        [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12
        $rel = Invoke-RestMethod -Uri "https://api.github.com/repos/rclone/rclone/releases/latest" -TimeoutSec 20
        $asset = $rel.assets | Where-Object { $_.name -match 'windows-amd64\.zip$' } | Select-Object -First 1
        $sumsAsset = $rel.assets | Where-Object { $_.name -eq "SHA256SUMS" } | Select-Object -First 1
        if ($null -ne $asset -and $null -ne $sumsAsset -and ($asset.browser_download_url -match '^https://') -and ($sumsAsset.browser_download_url -match '^https://')) {
            $zipTmp  = Join-Path $env:TEMP "rclone_portable_$PID.zip"
            $sumsTmp = Join-Path $env:TEMP "rclone_SHA256SUMS_$PID.txt"
            $extTmp  = Join-Path $env:TEMP "rclone_portable_ext_$PID"
            try {
                Invoke-WebRequest -Uri $asset.browser_download_url -OutFile $zipTmp -TimeoutSec 90 -UseBasicParsing
                Invoke-WebRequest -Uri $sumsAsset.browser_download_url -OutFile $sumsTmp -TimeoutSec 30 -UseBasicParsing

                $expectedHash = $null
                foreach ($line in (Get-Content -LiteralPath $sumsTmp -ErrorAction SilentlyContinue)) {
                    if ([string]::IsNullOrWhiteSpace($line)) { continue }
                    if ($line -match '^([a-fA-F0-9]{64})\s+\*?(.+)$' -and $Matches[2].Trim() -eq $asset.name) {
                        $expectedHash = $Matches[1].ToUpperInvariant()
                        break
                    }
                }
                $actualHash = (Get-FileHash -LiteralPath $zipTmp -Algorithm SHA256).Hash.ToUpperInvariant()
                if ([string]::IsNullOrWhiteSpace($expectedHash) -or ($actualHash -ne $expectedHash)) {
                    Show-AlphaMessageBox -Message (L "msgShaFailBody") -Title (L "msgShaFailTitle") -Buttons "OK" -Icon "Error" | Out-Null
                    exit 1
                }

                if (Test-Path -LiteralPath $extTmp) { Remove-Item -LiteralPath $extTmp -Recurse -Force }
                Expand-Archive -Path $zipTmp -DestinationPath $extTmp -Force
                $extractedExe = Get-ChildItem -LiteralPath $extTmp -Filter "rclone.exe" -Recurse | Select-Object -First 1 -ExpandProperty FullName
                if ($extractedExe) {
                    Copy-Item -LiteralPath $extractedExe -Destination (Join-Path $LocalBinDir "rclone.exe") -Force
                }
            } finally {
                Remove-Item -LiteralPath $zipTmp, $sumsTmp -Force -ErrorAction SilentlyContinue
                Remove-Item -LiteralPath $extTmp -Recurse -Force -ErrorAction SilentlyContinue
            }
        }
    } catch {}

    $exe = Find-RcloneExe
    if ($null -eq $exe) {
        Show-AlphaMessageBox -Message (L "msgSetupIncompleteBody") -Title (L "msgSetupIncompleteTitle") -Buttons "OK" -Icon "Error" | Out-Null
        exit 1
    }
    return $exe
}

function Invoke-RcloneCapture {
    param([string]$Arguments, [int]$TimeoutMs = 35000)
    $proc = $null
    try {
        $psi = New-Object System.Diagnostics.ProcessStartInfo
        $psi.FileName = $RcloneExe
        $psi.Arguments = $Arguments
        $psi.UseShellExecute = $false
        $psi.CreateNoWindow = $true
        $psi.RedirectStandardOutput = $true
        $psi.RedirectStandardError = $true
        $psi.StandardOutputEncoding = [System.Text.Encoding]::UTF8
        $psi.StandardErrorEncoding = [System.Text.Encoding]::UTF8
        $proc = [System.Diagnostics.Process]::Start($psi)
        $stdoutTask = $proc.StandardOutput.ReadToEndAsync()
        $stderrTask = $proc.StandardError.ReadToEndAsync()
        $exited = $proc.WaitForExit($TimeoutMs)
        if (-not $exited) {
            try { $proc.Kill() } catch {}
            return [PSCustomObject]@{ ExitCode = -1; StdOut = ""; StdErr = "Timeout" }
        }
        return [PSCustomObject]@{ ExitCode = $proc.ExitCode; StdOut = $stdoutTask.Result; StdErr = $stderrTask.Result }
    } catch {
        return [PSCustomObject]@{ ExitCode = -1; StdOut = ""; StdErr = $_.Exception.Message }
    } finally {
        if ($null -ne $proc) { try { $proc.Dispose() } catch {} }
    }
}

function Test-RcloneSourceHasIncludedFiles {
    param([Parameter(Mandatory = $true)][string]$LocalPath, [string]$ExcludeFlags = "")
    if ([string]::IsNullOrWhiteSpace($LocalPath) -or -not (Test-Path -LiteralPath $LocalPath -PathType Container)) {
        return [PSCustomObject]@{ Safe = $false; HasFiles = $false; FileCount = 0; Error = "Source folder is missing or invalid." }
    }

    # Fast shallow probe first (depth 1): returns in <200ms whenever the folder root has at least 1 included file.
    $shallowArgs = "lsf $(Format-WinArg $LocalPath) --max-depth 1 --files-only $ExcludeFlags --quiet"
    $shallowRes = Invoke-RcloneCapture -Arguments $shallowArgs -TimeoutMs 15000
    if ($null -ne $shallowRes -and $shallowRes.ExitCode -eq 0) {
        $shallowFiles = @($shallowRes.StdOut -split "`r?`n" | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
        if ($shallowFiles.Count -gt 0) {
            return [PSCustomObject]@{ Safe = $true; HasFiles = $true; FileCount = $shallowFiles.Count; Error = "" }
        }
    }

    # Early-stop streaming recursive scan: stops the INSTANT the first non-excluded file line arrives!
    # Prevents 60s timeouts on huge repositories (100k+ files) while preserving 100% fail-closed empty-source safety.
    $listArgs = "lsf $(Format-WinArg $LocalPath) --recursive --files-only $ExcludeFlags --quiet"
    $proc = $null
    try {
        $psi = New-Object System.Diagnostics.ProcessStartInfo
        $psi.FileName = $RcloneExe
        $psi.Arguments = $listArgs
        $psi.UseShellExecute = $false
        $psi.CreateNoWindow = $true
        $psi.RedirectStandardOutput = $true
        $psi.RedirectStandardError = $true
        $psi.StandardOutputEncoding = [System.Text.Encoding]::UTF8
        $psi.StandardErrorEncoding = [System.Text.Encoding]::UTF8
        $proc = [System.Diagnostics.Process]::Start($psi)
        $stderrTask = $proc.StandardError.ReadToEndAsync()
        $deadline = [datetime]::UtcNow.AddSeconds(90)
        while ([datetime]::UtcNow -lt $deadline) {
            $lineTask = $proc.StandardOutput.ReadLineAsync()
            $remMs = [int][math]::Max(50, ($deadline - [datetime]::UtcNow).TotalMilliseconds)
            if (-not $lineTask.Wait([math]::Min($remMs, 2000))) {
                if ($proc.HasExited) { break }
                continue
            }
            $ln = $lineTask.Result
            if ($null -eq $ln) { break }
            if (-not [string]::IsNullOrWhiteSpace($ln)) {
                try { if (-not $proc.HasExited) { $proc.Kill() } } catch {}
                return [PSCustomObject]@{ Safe = $true; HasFiles = $true; FileCount = 1; Error = "" }
            }
        }
        $exited = $proc.WaitForExit(3000)
        if (-not $exited) {
            try { $proc.Kill() } catch {}
            return [PSCustomObject]@{ Safe = $false; HasFiles = $false; FileCount = 0; Error = "Timeout" }
        }
        if ($proc.ExitCode -ne 0) {
            $errOut = try { $stderrTask.GetAwaiter().GetResult().Trim() } catch { "" }
            if ([string]::IsNullOrWhiteSpace($errOut)) { $errOut = "rclone source enumeration failed." }
            return [PSCustomObject]@{ Safe = $false; HasFiles = $false; FileCount = 0; Error = $errOut }
        }
        return [PSCustomObject]@{ Safe = $true; HasFiles = $false; FileCount = 0; Error = "" }
    } catch {
        return [PSCustomObject]@{ Safe = $false; HasFiles = $false; FileCount = 0; Error = $_.Exception.Message }
    } finally {
        if ($null -ne $proc) { try { $proc.Dispose() } catch {} }
    }
}


function Get-RcloneVersionString {
    $r = Invoke-RcloneCapture -Arguments "version" -TimeoutMs 8000
    if ($r.ExitCode -eq 0 -and -not [string]::IsNullOrWhiteSpace($r.StdOut)) {
        return (($r.StdOut -split "`r?`n" | Select-Object -First 1).Trim())
    }
    return "rclone (unknown)"
}
