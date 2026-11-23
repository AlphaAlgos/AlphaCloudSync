# ==============================================================================
# AlphaCloudSync Module: Engine.Mount (WinFsp Hybrid Unified & Standalone Drives, PID Identity Guard)
# ==============================================================================

function Match-MountCommandLineForRemote {
    param([string]$CommandLine, [string]$TargetRemote)
    if ([string]::IsNullOrWhiteSpace($CommandLine) -or [string]::IsNullOrWhiteSpace($TargetRemote)) { return $null }
    if ($CommandLine -match 'vfs-cache[\\/]unified-all') { return $null }
    $esc = [regex]::Escape($TargetRemote)
    if ($CommandLine -match "\bmount\s+`"${esc}:[^`"]*`"\s+([A-Za-z]:)") { return $Matches[1].ToUpperInvariant() }
    if ($CommandLine -match "\bmount\s+${esc}:\S*\s+([A-Za-z]:)")       { return $Matches[1].ToUpperInvariant() }
    if ($CommandLine -match "\bmount\s+:combine:\s+([A-Za-z]:).*=${esc}:") { return $Matches[1].ToUpperInvariant() }
    return $null
}

function Test-MountCommandLineMatchesEntry {
    param([string]$CommandLine, [string]$TargetRemote, [string]$Letter)
    if ([string]::IsNullOrWhiteSpace($CommandLine) -or [string]::IsNullOrWhiteSpace($TargetRemote) -or [string]::IsNullOrWhiteSpace($Letter)) { return $false }
    if ($CommandLine -notmatch '\bmount\b') { return $false }
    $wantLtr = $Letter.Trim().ToUpperInvariant()
    if ($TargetRemote -eq "__UNIFIED__") {
        return (($CommandLine -match 'vfs-cache[\\/]unified-all') -and ($CommandLine -match '\bmount\s+:combine:\s+([A-Za-z]:)') -and ($Matches[1].ToUpperInvariant() -eq $wantLtr))
    }
    $matchedLtr = Match-MountCommandLineForRemote -CommandLine $CommandLine -TargetRemote $TargetRemote
    return ($null -ne $matchedLtr -and $matchedLtr -eq $wantLtr)
}

$script:RcloneProcCacheList = $null
$script:RcloneProcCacheUtc  = [datetime]::MinValue
$script:SkipWmiMountProbe   = $false

function Clear-RcloneProcessesCache {
    $script:RcloneProcCacheList = $null
    $script:RcloneProcCacheUtc  = [datetime]::MinValue
}

function Get-RcloneProcessesCached {
    param([switch]$ForceRefresh)
    $now = [datetime]::UtcNow
    if (-not $ForceRefresh -and $null -ne $script:RcloneProcCacheList -and (($now - $script:RcloneProcCacheUtc).TotalSeconds -lt 2.0)) {
        return $script:RcloneProcCacheList
    }
    try {
        $script:RcloneProcCacheList = @(Get-CimInstance Win32_Process -Filter "Name = 'rclone.exe'" -ErrorAction SilentlyContinue)
        $script:RcloneProcCacheUtc  = $now
        return $script:RcloneProcCacheList
    } catch { return @() }
}

function Test-IsExpectedMountProcess {
    param([int]$ProcessId, [string]$TargetRemote, [string]$Letter, [switch]$UseCache)
    if ($ProcessId -le 0) { return $false }
    try {
        $pObj = if ($UseCache) {
            @(Get-RcloneProcessesCached) | Where-Object { [int]$_.ProcessId -eq $ProcessId } | Select-Object -First 1
        } else {
            Get-CimInstance Win32_Process -Filter "ProcessId = $ProcessId" -ErrorAction SilentlyContinue
        }
        if ($null -eq $pObj -or $pObj.Name -ine "rclone.exe") { return $false }
        return (Test-MountCommandLineMatchesEntry -CommandLine $pObj.CommandLine -TargetRemote $TargetRemote -Letter $Letter)
    } catch { return $false }
}

function Get-MountsState {
    if (-not (Test-Path -LiteralPath $MountsFile)) { return @() }
    try {
        $raw = [System.IO.File]::ReadAllText($MountsFile, [System.Text.Encoding]::UTF8)
        if ([string]::IsNullOrWhiteSpace($raw)) { return @() }
        $arr = ConvertFrom-Json -InputObject $raw
        if ($arr -isnot [System.Array]) { $arr = @($arr) }
        if ($script:SkipWmiMountProbe) {
            $fastAlive = @()
            foreach ($m in $arr) {
                if ($null -ne $m -and -not [string]::IsNullOrWhiteSpace($m.Remote) -and -not [string]::IsNullOrWhiteSpace($m.Letter) -and (Test-Path -LiteralPath "$($m.Letter)\")) {
                    $fastAlive += $m
                }
            }
            return $fastAlive
        }
        $alive = @()
        $prunedDead = $false
        foreach ($m in $arr) {
            $procMatches = ($null -ne $m -and $m.Pid -and -not [string]::IsNullOrWhiteSpace($m.Remote) -and -not [string]::IsNullOrWhiteSpace($m.Letter) -and
                (Test-IsExpectedMountProcess -ProcessId ([int]$m.Pid) -TargetRemote $m.Remote -Letter $m.Letter -UseCache))
            if ($procMatches -and (Test-Path -LiteralPath "$($m.Letter)\")) {
                $alive += $m
            } else {
                $prunedDead = $true
                if ($procMatches -and (Test-IsExpectedMountProcess -ProcessId ([int]$m.Pid) -TargetRemote $m.Remote -Letter $m.Letter)) {
                    Stop-Process -Id ([int]$m.Pid) -Force -ErrorAction SilentlyContinue
                }
                if ($m -and -not [string]::IsNullOrWhiteSpace($m.Letter) -and (Get-Command Clear-CloudDriveExplorerIcon -ErrorAction SilentlyContinue)) {
                    Clear-CloudDriveExplorerIcon -Letter $m.Letter
                }
            }
        }
        if ($prunedDead) { Save-MountsState -List $alive }
        return $alive
    } catch { return @() }
}

function Save-MountsState {
    param([array]$List)
    Clear-RcloneProcessesCache
    [System.IO.File]::WriteAllText($MountsFile, (ConvertTo-Json -InputObject @($List) -Depth 4), (New-Object System.Text.UTF8Encoding($false)))
}

function Get-MountedLetterForRemote {
    param([string]$TargetRemote = $RemoteName)
    $tracked = @(Get-MountsState | Where-Object { $_.Remote -eq $TargetRemote })
    if ($tracked.Count -gt 0) { return $tracked[0].Letter.ToUpperInvariant() }
    if ($script:SkipWmiMountProbe) { return $null }
    try {
        $procs = @(Get-RcloneProcessesCached)
        foreach ($p in $procs) {
            $mLtr = Match-MountCommandLineForRemote -CommandLine $p.CommandLine -TargetRemote $TargetRemote
            if ($null -ne $mLtr -and (Test-Path -LiteralPath "${mLtr}\")) { return $mLtr }
        }
    } catch {}
    return $null
}

function Get-AvailableDriveLetters {
    param([string]$TargetRemote = $RemoteName, [string]$Preferred = "G:", [string[]]$ReservedLetters = @())
    $used = @([System.IO.DriveInfo]::GetDrives() | ForEach-Object { $_.Name.Substring(0, 2).ToUpperInvariant() })
    $myMounted = Get-MountedLetterForRemote -TargetRemote $TargetRemote
    return @(Select-AvailableDriveLetters -UsedLetters $used -OwnedLetter $(if ($myMounted) { $myMounted } else { "" }) -Preferred $Preferred -ReservedLetters $ReservedLetters)
}

function Get-UnifiedMountInfo {
    $tracked = @(Get-MountsState | Where-Object { $_.Remote -eq "__UNIFIED__" })
    if ($tracked.Count -gt 0) {
        $m = $tracked[0]
        $rems = if ($m.PSObject.Properties["Remotes"] -and $null -ne $m.Remotes -and @($m.Remotes).Count -gt 0) { @($m.Remotes) } else { @() }
        if ($rems.Count -eq 0 -and -not $script:SkipWmiMountProbe) {
            try {
                $pObj = @(Get-RcloneProcessesCached) | Where-Object { [int]$_.ProcessId -eq [int]$m.Pid } | Select-Object -First 1
                if ($pObj -and $pObj.CommandLine) {
                    $rems = @([regex]::Matches($pObj.CommandLine, '=([A-Za-z0-9_-]+):') | ForEach-Object { $_.Groups[1].Value } | Sort-Object -Unique)
                }
            } catch {}
        }
        return [PSCustomObject]@{ Letter = $m.Letter.ToUpperInvariant(); Remotes = $rems }
    }
    if ($script:SkipWmiMountProbe) { return $null }
    try {
        $procs = @(Get-RcloneProcessesCached |
            Where-Object { $_.CommandLine -match '\bmount\s+:combine:\s+([A-Za-z]:)' -and $_.CommandLine -match 'vfs-cache[\\/]unified-all' })
        if ($procs.Count -gt 0 -and ($procs[0].CommandLine -match '\bmount\s+:combine:\s+([A-Za-z]:)')) {
            $l = $Matches[1].ToUpperInvariant()
            if (Test-Path -LiteralPath "${l}\") {
                $rems = @([regex]::Matches($procs[0].CommandLine, '=([A-Za-z0-9_-]+):') | ForEach-Object { $_.Groups[1].Value } | Sort-Object -Unique)
                return [PSCustomObject]@{ Letter = $l; Remotes = $rems }
            }
        }
    } catch {}
    return $null
}

function Get-AutoUnifiedDriveLetter {
    $uInfo = Get-UnifiedMountInfo
    if ($null -ne $uInfo -and -not [string]::IsNullOrWhiteSpace($uInfo.Letter)) { return $uInfo.Letter }
    $cfg = Get-Settings
    $pref = if ($cfg.PSObject.Properties["UnifiedDriveLetter"] -and -not [string]::IsNullOrWhiteSpace($cfg.UnifiedDriveLetter)) {
        $cfg.UnifiedDriveLetter.ToUpperInvariant()
    } elseif (-not [string]::IsNullOrWhiteSpace($cfg.PreferredDrive)) {
        $cfg.PreferredDrive.ToUpperInvariant()
    } else { "G:" }
    $avail = @(Get-AvailableDriveLetters -TargetRemote "__UNIFIED__" -Preferred $pref)
    $picked = if ($avail.Count -gt 0) { $avail[0] } else { "G:" }
    if (-not $cfg.PSObject.Properties["UnifiedDriveLetter"] -or $cfg.UnifiedDriveLetter -ne $picked) {
        $cfg | Add-Member -NotePropertyName "UnifiedDriveLetter" -NotePropertyValue $picked -Force
        Save-Settings -Obj $cfg
    }
    return $picked
}

function Build-MountCommandArgs {
    param(
        [string]$TargetRemote,
        [string]$Letter,
        [string]$MountMode = "Stream",
        [string]$MountScope = "MyDrive",
        [string]$ComputerLabel = "My Computer",
        [string]$VfsCacheDir = "",
        [string]$VolumeDisplayName = ""
    )
    $vfsFlags = if ($MountMode -eq "Mirror") {
        "--vfs-cache-mode full --vfs-cache-max-age 720h --vfs-cache-max-size 50G --vfs-write-back 5s"
    } else {
        "--vfs-cache-mode writes --vfs-write-back 5s"
    }
    $cleanComp = (($ComputerLabel -replace '["=\\/:*?<>|]', '').Trim())
    if ([string]::IsNullOrWhiteSpace($cleanComp)) { $cleanComp = "My Computer" }
    # Individual drive shows the Account Name while staying <= 21 chars so Windows Explorer ALWAYS fits title on 1 line and shows "X TB free of Y TB"!
    $rawDisp = if (-not [string]::IsNullOrWhiteSpace($VolumeDisplayName)) { $VolumeDisplayName } else { $TargetRemote }
    $cleanDisp = (($rawDisp -replace '["=\\/:*?<>|]', '').Trim())
    if ([string]::IsNullOrWhiteSpace($cleanDisp)) { $cleanDisp = $TargetRemote }
    if ($cleanDisp.Length -le 13) {
        $volLabel = "Drive - $cleanDisp"
    } elseif ($cleanDisp.Length -le 21) {
        $volLabel = $cleanDisp
    } else {
        $volLabel = $cleanDisp.Substring(0, 19) + ".."
    }

    $sourcePart = "`"${TargetRemote}:`" $Letter"
    if ($MountScope -eq "MyComputer") {
        $sourcePart = "`"${TargetRemote}:$cleanComp`" $Letter"
    } elseif ($MountScope -eq "Both") {
        $compFolderName = if ($cleanComp -ieq "My Drive") { "$cleanComp (PC)" } else { $cleanComp }
        $upRaw = "`"My Drive=${TargetRemote}:`" `"${compFolderName}=${TargetRemote}:${cleanComp}`""
        $upEsc = $upRaw.Replace('"', '\"')
        $sourcePart = ":combine: $Letter --combine-upstreams `"$upEsc`""
    }
    return "mount $sourcePart $vfsFlags --cache-dir `"$VfsCacheDir`" --volname `"$volLabel`" --dir-cache-time 5m --poll-interval 15s"
}


function Invoke-ToggleMount {
    param([string]$TargetRemote = $RemoteName, [string]$Letter = $DriveLetter, [switch]$ForceMount, [switch]$ForceUnmount, [switch]$QuietExplorer, [switch]$SilentToast)
    $activeLetter = Get-MountedLetterForRemote -TargetRemote $TargetRemote
    if (($null -ne $activeLetter -and -not $ForceMount) -or $ForceUnmount) {
        $mounts = @(Get-MountsState)
        $remaining = @()
        $stoppedAny = $false
        $unmountedLetters = @()
        foreach ($m in $mounts) {
            if ($m.Remote -eq $TargetRemote) {
                if (Test-IsExpectedMountProcess -ProcessId ([int]$m.Pid) -TargetRemote $m.Remote -Letter $m.Letter) {
                    Stop-Process -Id $m.Pid -Force -ErrorAction SilentlyContinue
                    $stoppedAny = $true
                }
                Clear-CloudDriveExplorerIcon -Letter $m.Letter
                $unmountedLetters += $m.Letter
            } else {
                $remaining += $m
            }
        }
        if (-not [string]::IsNullOrWhiteSpace($activeLetter)) {
            Clear-CloudDriveExplorerIcon -Letter $activeLetter
            if ($unmountedLetters -notcontains $activeLetter) { $unmountedLetters += $activeLetter }
        }
        Save-MountsState -List $remaining
        if (-not $stoppedAny) {
            Get-CimInstance Win32_Process -Filter "Name = 'rclone.exe'" -ErrorAction SilentlyContinue |
                Where-Object { $null -ne (Match-MountCommandLineForRemote -CommandLine $_.CommandLine -TargetRemote $TargetRemote) } |
                ForEach-Object { Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue }
        }
        foreach ($ul in $unmountedLetters) {
            Wait-DriveLetterReleased -Letter $ul -MaxWaitMs 4000
            Refresh-WindowsExplorerSilently -DriveLetter $ul -ChangeKind "Remove"
        }
        if (-not $SilentToast -and $unmountedLetters.Count -gt 0 -and (Get-Command Show-TrayToast -ErrorAction SilentlyContinue)) {
            $dispUnm = Get-AccountDisplayLabel -TargetRemote $TargetRemote
            Show-TrayToast -Title (L "toastDriveUnmountedTitle" "Cloud Drive Disconnected") -Body (LF "toastDriveUnmountedBody" @($dispUnm, (Wrap-Ltr $unmountedLetters[0].ToUpperInvariant()))) -Category "Drive"
        }
        return $true
    }
    if ($null -ne $activeLetter -and $ForceMount) {
        $null = Invoke-ToggleMount -TargetRemote $TargetRemote -ForceUnmount -SilentToast
    }

    if (-not (Test-GDriveConfigured -TargetRemote $TargetRemote)) {
        $null = Invoke-GDriveAuth -TargetRemote $TargetRemote
        if (-not (Test-GDriveConfigured -TargetRemote $TargetRemote)) { return $false }
    }

    if (-not (Test-WinFspInstalled)) {
        if ($Action -ne "GUI") { [Console]::Error.WriteLine("ERROR: WinFsp is not installed."); return $false }
        $wg = Get-Command winget -ErrorAction SilentlyContinue
        if ($null -ne $wg) {
            $ans = Show-AlphaMessageBox -Message (L "msgWinFspBody") -Title (L "msgWinFspTitle") -Buttons "YesNo" -Icon "Question"
            if ($ans -eq [System.Windows.MessageBoxResult]::Yes) {
                Start-Process -FilePath "winget" -ArgumentList "install --id WinFsp.WinFsp --exact --silent --accept-package-agreements --accept-source-agreements" -Wait -WindowStyle Hidden
                if (-not (Test-WinFspInstalled)) { return $false }
            } else { return $false }
        } else {
            $null = Show-AlphaMessageBox -Message (L "msgWinFspBody") -Title (L "msgWinFspTitle") -Buttons "OK" -Icon "Warning"
            return $false
        }
    }

    $cfg = Get-Settings
    $modeTag = if ($cfg.MountMode -eq "Mirror") { "Mirror" } else { "Stream" }
    $mountScope = Get-AccountMountScope -TargetRemote $TargetRemote
    $compLabel = if ([string]::IsNullOrWhiteSpace($cfg.ComputerLabel)) { "My Computer" } else { $cfg.ComputerLabel.Trim() }
    $cleanComp = (($compLabel -replace '["=\\/:*?<>|]', '').Trim())
    if ([string]::IsNullOrWhiteSpace($cleanComp)) { $cleanComp = "My Computer" }
    if ($mountScope -in @("MyComputer", "Both")) {
        $null = Invoke-RcloneCapture -Arguments "mkdir $(Format-WinArg "${TargetRemote}:$cleanComp")" -TimeoutMs 15000
    }
    $vfsCacheDir = Join-Path $env:LOCALAPPDATA "AlphaCloudSync\vfs-cache\$(Get-SanitizedName $TargetRemote)"
    if (-not (Test-Path -LiteralPath $vfsCacheDir)) { New-Item -ItemType Directory -Path $vfsCacheDir -Force | Out-Null }
    Ensure-RemoteAutoNameCached -TargetRemote $TargetRemote
    $volDisp = Get-AccountDisplayLabel -TargetRemote $TargetRemote
    $mountArgs = Build-MountCommandArgs -TargetRemote $TargetRemote -Letter $Letter -MountMode $modeTag -MountScope $mountScope -ComputerLabel $cleanComp -VfsCacheDir $vfsCacheDir -VolumeDisplayName $volDisp
    if ([bool]$cfg.ShowFolderBadges) { Set-CloudDriveExplorerIcon -Letter $Letter }
    $proc = Start-Process -FilePath $RcloneExe -ArgumentList $mountArgs -PassThru -WindowStyle Hidden
    for ($w = 0; $w -lt 72; $w++) {
        Start-Sleep -Milliseconds 250
        if (Get-Command Invoke-UiPump -ErrorAction SilentlyContinue) { Invoke-UiPump }
        if (Test-Path -LiteralPath "${Letter}\") { break }
        if ($null -ne $proc -and $proc.HasExited) { break }
    }
    if (Test-Path -LiteralPath "${Letter}\") {
        $mounts = @(Get-MountsState | Where-Object { $_.Remote -ne $TargetRemote })
        $mounts += [PSCustomObject]@{ Remote = $TargetRemote; Letter = $Letter.ToUpperInvariant(); Mode = $modeTag; Scope = $mountScope; Pid = $proc.Id }
        Save-MountsState -List $mounts
        if ([bool]$cfg.ShowFolderBadges) { Set-CloudDriveExplorerIcon -Letter $Letter }
        Refresh-WindowsExplorerSilently -DriveLetter $Letter -ChangeKind "Add"
        if (Get-Command Show-TrayToast -ErrorAction SilentlyContinue) {
            Show-TrayToast -Title (L "toastDriveMountedTitle" "Cloud Drive Ready") -Body (LF "toastDriveMountedBody" @($volDisp, (Wrap-Ltr $Letter.ToUpperInvariant()))) -Category "Drive"
        }
        if (-not $QuietExplorer) { Start-Process "explorer.exe" -ArgumentList "${Letter}\" }
        return $true
    } else {
        if ($null -ne $proc -and -not $proc.HasExited) { Stop-Process -Id $proc.Id -Force -ErrorAction SilentlyContinue }
        Clear-CloudDriveExplorerIcon -Letter $Letter
        if (Get-Command Write-StudioLog -ErrorAction SilentlyContinue) {
            Write-StudioLog -Msg "[WARN] Could not mount '$volDisp' on $Letter (rclone exited or timed out)." -TargetRemote $TargetRemote
        }
        return $false
    }
}

function Build-UnifiedMountCommandArgs {
    param(
        [array]$RemotePairs,
        [string]$Letter,
        [string]$MountMode = "Stream",
        [string]$ComputerLabel = "My Computer",
        [string]$VfsCacheDir = ""
    )
    $vfsFlags = if ($MountMode -eq "Mirror") {
        "--vfs-cache-mode full --vfs-cache-max-age 720h --vfs-cache-max-size 50G --vfs-write-back 5s"
    } else {
        "--vfs-cache-mode writes --vfs-write-back 5s"
    }
    $cleanComp = (($ComputerLabel -replace '["=\\/:*?<>|]', '').Trim())
    if ([string]::IsNullOrWhiteSpace($cleanComp)) { $cleanComp = "My Computer" }

    $usedNames = @{}
    $upTokens = @()
    foreach ($rp in $RemotePairs) {
        $rem = [string]$rp.Remote
        $rawLbl = (([string]$rp.Label -replace '["=\\/:*?<>|]', '').Trim())
        if ([string]::IsNullOrWhiteSpace($rawLbl)) { $rawLbl = $rem }
        if ($rp.Scope -eq "Both") {
            foreach ($subPair in @(
                @{ Name = "$rawLbl - My Drive"; Spec = "${rem}:" },
                @{ Name = "$rawLbl - $cleanComp"; Spec = "${rem}:${cleanComp}" }
            )) {
                $fLbl = $subPair.Name; $n = 2
                while ($usedNames.ContainsKey($fLbl.ToLowerInvariant())) { $fLbl = "$($subPair.Name) ($n)"; $n++ }
                $usedNames[$fLbl.ToLowerInvariant()] = $true
                $upTokens += "`"${fLbl}=$($subPair.Spec)`""
            }
        } else {
            $finalLbl = $rawLbl
            $n = 2
            while ($usedNames.ContainsKey($finalLbl.ToLowerInvariant())) {
                $finalLbl = "$rawLbl ($n)"
                $n++
            }
            $usedNames[$finalLbl.ToLowerInvariant()] = $true
            $remSpec = if ($rp.Scope -eq "MyComputer") { "${rem}:${cleanComp}" } else { "${rem}:" }
            $upTokens += "`"${finalLbl}=${remSpec}`""
        }
    }
    $upRaw = ($upTokens -join " ")
    $upEsc = $upRaw.Replace('"', '\"')
    # Unified drive label uses the product brand 'AlphaCloudSync' (14 chars, always fits 1 line in Windows Explorer!)
    return "mount :combine: $Letter --combine-upstreams `"$upEsc`" $vfsFlags --cache-dir `"$VfsCacheDir`" --volname `"AlphaCloudSync`" --dir-cache-time 5m --poll-interval 15s"
}

function Get-UnifiedMountLetter {
    $tracked = @(Get-MountsState | Where-Object { $_.Remote -eq "__UNIFIED__" })
    if ($tracked.Count -gt 0) { return $tracked[0].Letter.ToUpperInvariant() }
    if ($script:SkipWmiMountProbe) { return $null }
    try {
        $procs = @(Get-RcloneProcessesCached |
            Where-Object { $_.CommandLine -match '\bmount\s+:combine:\s+([A-Za-z]:)' -and $_.CommandLine -match 'vfs-cache[\\/]unified-all' })
        if ($procs.Count -gt 0 -and ($procs[0].CommandLine -match '\bmount\s+:combine:\s+([A-Za-z]:)')) {
            $l = $Matches[1].ToUpperInvariant()
            if (Test-Path -LiteralPath "${l}\") { return $l }
        }
    } catch {}
    return $null
}

function Invoke-ToggleUnifiedMount {
    param([string]$Letter = "", [string[]]$TargetRemotes = $null, [switch]$ForceMount, [switch]$ForceUnmount, [switch]$QuietExplorer, [switch]$SilentToast)
    $activeUnified = Get-UnifiedMountLetter
    if (($null -ne $activeUnified -and -not $ForceMount) -or $ForceUnmount) {
        $mounts = @(Get-MountsState)
        $remaining = @()
        $stoppedAny = $false
        $unmountedLetters = @()
        foreach ($m in $mounts) {
            if ($m.Remote -eq "__UNIFIED__") {
                if (Test-IsExpectedMountProcess -ProcessId ([int]$m.Pid) -TargetRemote "__UNIFIED__" -Letter $m.Letter) {
                    Stop-Process -Id $m.Pid -Force -ErrorAction SilentlyContinue
                    $stoppedAny = $true
                }
                Clear-CloudDriveExplorerIcon -Letter $m.Letter
                $unmountedLetters += $m.Letter
            } else { $remaining += $m }
        }
        if (-not [string]::IsNullOrWhiteSpace($activeUnified)) {
            Clear-CloudDriveExplorerIcon -Letter $activeUnified
            if ($unmountedLetters -notcontains $activeUnified) { $unmountedLetters += $activeUnified }
        }
        Save-MountsState -List $remaining
        if (-not $stoppedAny) {
            Get-CimInstance Win32_Process -Filter "Name = 'rclone.exe'" -ErrorAction SilentlyContinue |
                Where-Object { $_.CommandLine -match '\bmount\s+:combine:' -and $_.CommandLine -match 'vfs-cache[\\/]unified-all' } |
                ForEach-Object { Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue }
        }
        foreach ($ul in $unmountedLetters) {
            Wait-DriveLetterReleased -Letter $ul -MaxWaitMs 4000
            Refresh-WindowsExplorerSilently -DriveLetter $ul -ChangeKind "Remove"
        }
        if (-not $SilentToast -and $unmountedLetters.Count -gt 0 -and (Get-Command Show-TrayToast -ErrorAction SilentlyContinue)) {
            Show-TrayToast -Title (L "toastDriveUnmountedTitle" "Cloud Drive Disconnected") -Body (LF "toastDriveUnmountedBody" @("AlphaCloudSync", (Wrap-Ltr $unmountedLetters[0].ToUpperInvariant()))) -Category "Drive"
        }
        return $true
    }

    $remotes = if ($null -ne $TargetRemotes -and $TargetRemotes.Count -gt 0) { @($TargetRemotes) } else { @(Get-UnifiedPoolRemotes) }
    if ($remotes.Count -eq 0) { $remotes = @(Get-ConfiguredDriveRemotes) }
    if ($remotes.Count -eq 0) { return $false }

    # Unmount any stale separate drives for remotes joining the Unified Pool, plus any old unified mount
    if ($null -ne $activeUnified) { $null = Invoke-ToggleUnifiedMount -ForceUnmount -SilentToast }
    foreach ($rem in $remotes) {
        if ($null -ne (Get-MountedLetterForRemote -TargetRemote $rem)) {
            $null = Invoke-ToggleMount -TargetRemote $rem -ForceUnmount -SilentToast
        }
    }

    if ([string]::IsNullOrWhiteSpace($Letter)) { $Letter = Get-AutoUnifiedDriveLetter }

    if (-not (Test-WinFspInstalled)) {
        if ($Action -ne "GUI") { [Console]::Error.WriteLine("ERROR: WinFsp is not installed."); return $false }
        $wg = Get-Command winget -ErrorAction SilentlyContinue
        if ($null -ne $wg) {
            $ans = Show-AlphaMessageBox -Message (L "msgWinFspBody") -Title (L "msgWinFspTitle") -Buttons "YesNo" -Icon "Question"
            if ($ans -eq [System.Windows.MessageBoxResult]::Yes) {
                Start-Process -FilePath "winget" -ArgumentList "install --id WinFsp.WinFsp --exact --silent --accept-package-agreements --accept-source-agreements" -Wait -WindowStyle Hidden
                if (-not (Test-WinFspInstalled)) { return $false }
            } else { return $false }
        } else {
            $null = Show-AlphaMessageBox -Message (L "msgWinFspBody") -Title (L "msgWinFspTitle") -Buttons "OK" -Icon "Warning"
            return $false
        }
    }

    $cfg = Get-Settings
    $modeTag = if ($cfg.MountMode -eq "Mirror") { "Mirror" } else { "Stream" }
    $compLabel = if ([string]::IsNullOrWhiteSpace($cfg.ComputerLabel)) { "My Computer" } else { $cfg.ComputerLabel.Trim() }
    $cleanComp = (($compLabel -replace '["=\\/:*?<>|]', '').Trim())
    if ([string]::IsNullOrWhiteSpace($cleanComp)) { $cleanComp = "My Computer" }

    $pairs = @()
    foreach ($rem in $remotes) {
        Ensure-RemoteAutoNameCached -TargetRemote $rem
        $sc = Get-AccountMountScope -TargetRemote $rem
        if ($sc -in @("MyComputer", "Both")) {
            $null = Invoke-RcloneCapture -Arguments "mkdir $(Format-WinArg "${rem}:$cleanComp")" -TimeoutMs 15000
        }
        $pairs += [PSCustomObject]@{ Remote = $rem; Label = (Get-AccountDisplayLabel -TargetRemote $rem); Scope = $sc }
    }
    $vfsCacheDir = Join-Path $env:LOCALAPPDATA "AlphaCloudSync\vfs-cache\unified-all"
    if (-not (Test-Path -LiteralPath $vfsCacheDir)) { New-Item -ItemType Directory -Path $vfsCacheDir -Force | Out-Null }

    $mountArgs = Build-UnifiedMountCommandArgs -RemotePairs $pairs -Letter $Letter -MountMode $modeTag -ComputerLabel $cleanComp -VfsCacheDir $vfsCacheDir
    if ([bool]$cfg.ShowFolderBadges) { Set-CloudDriveExplorerIcon -Letter $Letter }
    $proc = Start-Process -FilePath $RcloneExe -ArgumentList $mountArgs -PassThru -WindowStyle Hidden
    for ($w = 0; $w -lt 72; $w++) {
        Start-Sleep -Milliseconds 250
        if (Get-Command Invoke-UiPump -ErrorAction SilentlyContinue) { Invoke-UiPump }
        if (Test-Path -LiteralPath "${Letter}\") { break }
        if ($null -ne $proc -and $proc.HasExited) { break }
    }
    if (Test-Path -LiteralPath "${Letter}\") {
        $mounts = @(Get-MountsState | Where-Object { $_.Remote -ne "__UNIFIED__" })
        $mounts += [PSCustomObject]@{ Remote = "__UNIFIED__"; Letter = $Letter.ToUpperInvariant(); Mode = $modeTag; Scope = "Unified"; Remotes = @($remotes); Pid = $proc.Id }
        Save-MountsState -List $mounts
        if ([bool]$cfg.ShowFolderBadges) { Set-CloudDriveExplorerIcon -Letter $Letter }
        Refresh-WindowsExplorerSilently -DriveLetter $Letter -ChangeKind "Add"
        if (Get-Command Show-TrayToast -ErrorAction SilentlyContinue) {
            Show-TrayToast -Title (L "toastDriveMountedTitle" "Cloud Drive Ready") -Body (LF "toastDriveMountedBody" @("AlphaCloudSync", (Wrap-Ltr $Letter.ToUpperInvariant()))) -Category "Drive"
        }
        if (-not $QuietExplorer) { Start-Process "explorer.exe" -ArgumentList "${Letter}\" }
        return $true
    } else {
        if ($null -ne $proc -and -not $proc.HasExited) { Stop-Process -Id $proc.Id -Force -ErrorAction SilentlyContinue }
        Clear-CloudDriveExplorerIcon -Letter $Letter
        if (Get-Command Write-StudioLog -ErrorAction SilentlyContinue) {
            $logRem = if (-not [string]::IsNullOrWhiteSpace($script:ActiveRemote)) { $script:ActiveRemote } else { $RemoteName }
            Write-StudioLog -Msg "[WARN] Could not mount Unified Drive on $Letter (rclone exited or timed out)." -TargetRemote $logRem
        }
        return $false
    }
}
