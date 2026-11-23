# ==============================================================================
# AlphaCloudSync Module: Engine.Headless (CLI Batch Sync, Safe Restore, Status & Mount Dispatch)
# ==============================================================================

function Invoke-HeadlessBatch {
    param([switch]$DryRun, [switch]$Restore, [string]$SingleFolder = "")
    if (-not (Test-GDriveConfigured -TargetRemote $RemoteName)) {
        Write-Output "ERROR: Profile '$RemoteName' is not signed in."
        Save-BackupHealth -Mode "Headless" -Status "FAIL" -ExitCode 1 -FoldersProcessed 0 -Summary "Profile '$RemoteName' is not signed in."
        return 1
    }
    $cfg = Get-Settings
    $folders = @(Get-SyncFolders -TargetRemote $RemoteName)
    if (-not [string]::IsNullOrWhiteSpace($SingleFolder)) {
        $folders = @($folders | Where-Object { $_.Name -ieq $SingleFolder })
    } else {
        $folders = @($folders | Where-Object { $_.Enabled -ne $false })
    }
    if ($folders.Count -eq 0) {
        Write-Output "WARN: No enabled folders configured for profile '$RemoteName'."
        Save-BackupHealth -Mode "Headless" -Status "WARN" -ExitCode 0 -FoldersProcessed 0 -Summary "No enabled folders."
        return 0
    }

    $dateStamp = (Get-Date).ToString("yyyy-MM-dd_HH-mm-ss")
    $runLog    = Join-Path $LocalLogsDir "headless-$dateStamp.log"
    $exInfo    = Build-SafeExcludeFile -TargetRemote $RemoteName
    if (-not $exInfo.Valid) {
        $err = "Invalid exclusion rules; sync was blocked to prevent unintended uploads. $($exInfo.Error)"
        Write-Output "ERROR: $err"
        Save-BackupHealth -Mode "Headless" -Status "FAIL" -ExitCode 5 -FoldersProcessed 0 -Summary $err -TargetRemote $RemoteName
        return 5
    }
    $exFlag    = if ($exInfo.Enabled -and $exInfo.FilterFile) { "--exclude-from `"$($exInfo.FilterFile)`"" } else { "" }
    if ([bool]$cfg.ShowFolderBadges) { $exFlag = ("$exFlag --exclude `"desktop.ini`"").Trim() }
    $spdFlags  = Get-SpeedFlagsString -Preset $cfg.SpeedPreset
    $resilient = "--retries 10 --low-level-retries 20 --retries-sleep 5s --modify-window 1s"

    $overallExit = 0; $failedFolders = @(); $processedCount = 0
    foreach ($f in $folders) {
        $effRemote = Resolve-EffectiveRemotePath -FolderItem $f
        $locArg = Format-WinArg $f.LocalPath
        $remArg = Format-WinArg "${RemoteName}:$effRemote"
        if ($Restore) {
            if (-not (Test-Path -LiteralPath $f.LocalPath)) { New-Item -ItemType Directory -Path $f.LocalPath -Force | Out-Null }
            $localBak = Join-Path $RestoreBkDir "$(Get-SanitizedName $f.Name)\$dateStamp"
            New-Item -ItemType Directory -Path $localBak -Force | Out-Null
            $dryFlag = if ($DryRun) { "--dry-run" } else { "" }
            $args = "copy $remArg $locArg --backup-dir $(Format-WinArg $localBak) $spdFlags $resilient $dryFlag $exFlag --stats 5s --stats-one-line --log-file $(Format-WinArg $runLog)"
            $pRes = Invoke-SilentProcess -FilePath $RcloneExe -Arguments $args -TimeoutMs 0
            $processedCount++
            if ($pRes.ExitCode -ne 0) { $overallExit = $pRes.ExitCode; $failedFolders += "$($f.Name)(Exit=$($pRes.ExitCode))" }
        } else {
            if (-not (Test-Path -LiteralPath $f.LocalPath)) { $overallExit = 3; $failedFolders += "$($f.Name)(Missing)"; continue }
            $sourceCheck = Test-RcloneSourceHasIncludedFiles -LocalPath $f.LocalPath -ExcludeFlags $exFlag
            if (-not $sourceCheck.Safe) { $overallExit = 5; $failedFolders += "$($f.Name)(SourceCheckFailed)"; Write-Output "ERROR: Source safety check failed for '$($f.Name)': $($sourceCheck.Error)"; continue }
            if (-not $sourceCheck.HasFiles) { $overallExit = 4; $failedFolders += "$($f.Name)(NoIncludedFiles)"; Write-Output "WARN: No files remain after exclusion rules for '$($f.Name)'; remote data was left untouched."; continue }
            $dryFlag = if ($DryRun) { "--dry-run" } else { "" }
            if ($cfg.DeletePolicy -eq "Copy-Only") {
                $args = "copy $locArg $remArg $spdFlags $resilient $dryFlag $exFlag --stats 5s --stats-one-line --log-file $(Format-WinArg $runLog)"
            } elseif ($cfg.DeletePolicy -eq "Strict Mirror") {
                $args = "sync $locArg $remArg --drive-use-trash=true --max-delete 200 $spdFlags $resilient $dryFlag $exFlag --stats 5s --stats-one-line --log-file $(Format-WinArg $runLog)"
            } else {
                $trash = "${RemoteName}:_CloudSync_Trash_Archive/$dateStamp/$effRemote"
                $args = "sync $locArg $remArg --backup-dir $(Format-WinArg $trash) --drive-use-trash=true --max-delete 200 $spdFlags $resilient $dryFlag $exFlag --stats 5s --stats-one-line --log-file $(Format-WinArg $runLog)"
            }
            $pRes = Invoke-SilentProcess -FilePath $RcloneExe -Arguments $args -TimeoutMs 0
            $processedCount++
            if ($pRes.ExitCode -ne 0) { $overallExit = $pRes.ExitCode; $failedFolders += "$($f.Name)(Exit=$($pRes.ExitCode))" }
        }
    }

    $modeLabel = if ($Restore) { "Restore" } elseif ($DryRun) { "Preview" } else { "Sync" }
    if ($overallExit -eq 0) {
        Save-BackupHealth -Mode $modeLabel -Status "PASS" -ExitCode 0 -FoldersProcessed $processedCount -Summary "All $processedCount folder(s) succeeded cleanly. Log: $runLog" -TargetRemote $RemoteName
    } else {
        Save-BackupHealth -Mode $modeLabel -Status "FAIL" -ExitCode $overallExit -FoldersProcessed $processedCount -Summary "Failed: $($failedFolders -join ', '). Log: $runLog" -TargetRemote $RemoteName
    }
    return $overallExit
}

function Invoke-HeadlessCliDispatch {
    param([string]$CliAction)
    if ($CliAction -eq "Status") {
        $ident = Get-ConnectedGoogleIdentity -TargetRemote $RemoteName
        $mntL  = Get-MountedLetterForRemote -TargetRemote $RemoteName
        $uniI  = Get-UnifiedMountInfo
        if ($null -eq $mntL -and $null -ne $uniI -and ($uniI.Remotes.Count -eq 0 -or ($uniI.Remotes -contains $RemoteName))) { $mntL = "$($uniI.Letter) (Unified)" }
        $flds  = Get-SyncFolders -TargetRemote $RemoteName
        $sched = Get-ScheduleInfo -TargetRemote $RemoteName
        $rules = Build-SafeExcludeFile -TargetRemote $RemoteName
        $provs = (@(Get-RegisteredCloudProviders | ForEach-Object { $_.DisplayName }) -join ", ")
        [Console]::WriteLine("APP=$AppName v$AppVersion")
        [Console]::WriteLine("ENGINE=$(Get-RcloneVersionString)")
        [Console]::WriteLine("PROVIDERS=$provs")
        [Console]::WriteLine("ACTIVE_REMOTE=$RemoteName")
        [Console]::WriteLine("AUTHENTICATED=$($ident.Connected) | EMAIL=$($ident.Email) | CUSTOM_CLIENT_ID=$($ident.HasCustomClientId)")
        [Console]::WriteLine("DRIVE_MOUNTED=$($null -ne $mntL) (Letter=$mntL | Mode=$($Settings.MountMode))")
        [Console]::WriteLine("STARTUP_ENABLED=$(Get-StartupEnabled)")
        [Console]::WriteLine("DELETE_POLICY=$($Settings.DeletePolicy) | SPEED_PRESET=$($Settings.SpeedPreset)")
        [Console]::WriteLine("JSON_RULES=$($rules.Enabled) (Preset=$($rules.PresetName), Dirs=$($rules.DirCount), Files=$($rules.FileCount))")
        [Console]::WriteLine("AUTO_SCHEDULE=$($sched.Label)")
        [Console]::WriteLine("SYNC_FOLDERS_COUNT=$($flds.Count)")
        foreach ($f in $flds) {
            $eff = Resolve-EffectiveRemotePath -FolderItem $f
            [Console]::WriteLine("FOLDER: [$($f.Enabled)] $($f.Name) | Mode=$($f.TargetMode) | $($f.LocalPath) -> ${RemoteName}:$eff")
        }
        exit 0
    }
    if ($CliAction -eq "Sync")    { $ec = Invoke-HeadlessBatch -SingleFolder $FolderName; exit ([int](@($ec)[-1])) }
    if ($CliAction -eq "DryRun")  { $ec = Invoke-HeadlessBatch -DryRun -SingleFolder $FolderName; exit ([int](@($ec)[-1])) }
    if ($CliAction -eq "Restore") { $ec = Invoke-HeadlessBatch -Restore -SingleFolder $FolderName; exit ([int](@($ec)[-1])) }
    if ($CliAction -eq "Auth")    { $ok = Invoke-GDriveAuth -TargetRemote $RemoteName; exit $(if ($ok) { 0 } else { 1 }) }
    if ($CliAction -eq "Mount")   { $ok = Invoke-ToggleMount -TargetRemote $RemoteName -Letter $DriveLetter -ForceMount; exit $(if ($ok) { 0 } else { 1 }) }
    if ($CliAction -eq "Unmount") {
        $ok = Invoke-ToggleMount -TargetRemote $RemoteName -Letter $DriveLetter -ForceUnmount
        if ($null -ne (Get-UnifiedMountLetter)) { $null = Invoke-ToggleUnifiedMount -ForceUnmount }
        exit $(if ($ok) { 0 } else { 1 })
    }
    exit 1
}
