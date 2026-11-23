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

    # Enumerate the effective source after filters; raw directory entries can all be excluded.
    $listArgs = "lsf $(Format-WinArg $LocalPath) --recursive --files-only $ExcludeFlags --quiet"
    $listResult = Invoke-RcloneCapture -Arguments $listArgs -TimeoutMs 60000
    if ($null -eq $listResult -or $listResult.ExitCode -ne 0) {
        $err = if ($null -ne $listResult -and -not [string]::IsNullOrWhiteSpace($listResult.StdErr)) { $listResult.StdErr.Trim() } else { "rclone source enumeration failed." }
        return [PSCustomObject]@{ Safe = $false; HasFiles = $false; FileCount = 0; Error = $err }
    }

    $includedFiles = @($listResult.StdOut -split "`r?`n" | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
    return [PSCustomObject]@{ Safe = $true; HasFiles = ($includedFiles.Count -gt 0); FileCount = $includedFiles.Count; Error = "" }
}


function Get-RcloneVersionString {
    $r = Invoke-RcloneCapture -Arguments "version" -TimeoutMs 8000
    if ($r.ExitCode -eq 0 -and -not [string]::IsNullOrWhiteSpace($r.StdOut)) {
        return (($r.StdOut -split "`r?`n" | Select-Object -First 1).Trim())
    }
    return "rclone (unknown)"
}
