# ==============================================================================
# AlphaCloudSync Module: UI.Presenter (7-Language UI Binder, Folders/Drives/Activity Grids, Quota & Header Refresh)
# ==============================================================================

# 100% MULTILINGUAL UI APPLICATION (ALL 7 LANGUAGES + RTL/BIDI)
# ==============================================================================
function Apply-UiLanguage {
    param([string]$Lang, [switch]$SkipShellSync)
    $code = $Lang.ToLowerInvariant()
    $script:UiLang = $code
    $cfg = Get-Settings; $cfg.Language = $code; Save-Settings -Obj $cfg

    $loc = Get-LocaleDict -LangCode $code
    if ($null -eq $loc) { return }
    $script:CurrentLocale = $loc

    $uiFlow = if ($loc.rtl) { "RightToLeft" } else { "LeftToRight" }
    $WindowOuterBorder.FlowDirection  = $uiFlow
    $CtxMenuFolders.FlowDirection     = $uiFlow
    $trayMenu.RightToLeft             = if ($loc.rtl) { [System.Windows.Forms.RightToLeft]::Yes } else { [System.Windows.Forms.RightToLeft]::No }

    $window.Title              = "$($loc.windowTitle) " + [char]0x2014 + " $($loc.windowSubtitle)"
    $TxtWindowTitle.Text       = "AlphaCloudSync"
    $TxtWindowSubtitle.Text    = $loc.windowSubtitle
    $TxtBrandBadge.Text        = $loc.brandBadge
    $BtnTitleTray.ToolTip      = $loc.tipTray
    $BtnTitleMin.ToolTip       = $loc.tipMinimize
    $BtnTitleClose.ToolTip     = $loc.tipClose
    Update-WindowChromeMaximizeMargin

    # Sidebar Nav Labels & Organized Settings Center Headers
    $TxtNavFolders.Text           = $loc.navFolders
    $TxtNavActivity.Text          = $loc.navActivity
    $TxtNavStorage.Text           = $loc.navStorage
    $TxtNavSettings.Text          = $loc.navSettings
    $TxtSidebarAccountsTitle.Text = $loc.sidebarAccountsTitle
    $TxtSettingsPageTitle.Text    = $loc.navSettings
    $TxtSettingsSecAccounts.Text      = $loc.settingsSecAccounts
    $TxtSettingsSecGeneral.Text       = $loc.settingsSecGeneral
    $TxtSettingsSecNotifications.Text = $loc.settingsSecNotifications
    $ChkNotifMaster.Content           = $loc.chkNotifMaster
    $ChkNotifManual.Content           = $loc.chkNotifManual
    $ChkNotifAutoSync.Content         = $loc.chkNotifAutoSync
    $ChkNotifErrors.Content           = $loc.chkNotifErrors
    $ChkNotifDriveEvents.Content      = $loc.chkNotifDriveEvents
    $TxtSettingsSecBackup.Text        = $loc.settingsSecBackup
    $TxtSettingsSecSync.Text      = $loc.settingsSecSync
    $LblLanguage.Text             = $loc.lblLanguage
    $ChkCloudIsland.Content       = $loc.lblCloudIslandToggle
    $ChkCloudIsland.ToolTip       = $loc.tipIsland
    $ChkFolderBadges.Content      = $loc.lblFolderBadgesToggle
    $ChkFolderBadges.ToolTip      = $loc.tipFolderBadges
    $ChkExplorerMenu.Content      = $loc.lblExplorerMenuToggle
    $ChkAutoWatchSync.Content     = $loc.lblAutoWatchToggle
    $ChkAutoWatchSync.ToolTip     = $loc.tipAutoWatch
    Update-RealTimeWatchStatusText

    $CmbLanguage.ToolTip       = $loc.languageTooltip
    $BtnAddAccount.Content     = Wrap-RtlLead $loc.addAccount
    $BtnCustomClientId.ToolTip = $loc.apiKeyTooltip
    $CmbMountMode.ToolTip      = $loc.mountModeTooltip
    $CbiMountStream.Content    = $loc.mountModeStream
    $CbiMountMirror.Content    = $loc.mountModeMirror
    $CbiMountUnified.Content   = $loc.mountModeUnified
    $CmbMountScope.ToolTip     = $loc.mountScopeTooltip
    $CbiScopeMyDrive.Content   = $loc.mountScopeMyDrive
    $CbiScopeMyComputer.Content= $loc.mountScopeMyComputer
    $CbiScopeBoth.Content      = $loc.mountScopeBoth
    $ChkStartup.Content        = $loc.startupLabel
    $ChkStartup.ToolTip        = $loc.startupTooltip

    $TxtQuotaHeader.Text       = $loc.quotaHeader
    $BtnRefreshQuota.Content   = $loc.scanQuota
    $BtnEmptyDriveTrash.Content= $loc.emptyTrash
    $BtnEmptyDriveTrash.ToolTip= $loc.emptyTrashTooltip
    $BtnCleanArchive.Content   = $loc.cleanArchive
    $BtnCleanArchive.ToolTip   = $loc.cleanArchiveTooltip
    $BtnOpenDriveWeb.Content   = $loc.openDriveWeb

    $TxtMultiDriveTitle.Text   = $loc.multiDriveTitle
    $TxtMultiDriveDesc.Text    = $loc.multiDriveDesc
    $LblDriveLayout.Text       = $loc.lblDriveLayout
    $CbiLayoutSeparate.Content = $loc.driveLayoutSeparate
    $uniAutoFmt = Wrap-Ltr "$([string][char]0x2605) $(Get-AutoUnifiedDriveLetter)"
    $uniLblTag  = "$uniAutoFmt  $([char]0x2022)  $($loc.driveLayoutUnified)"
    $CbiLayoutUnified.Content  = $uniLblTag
    $LblDriveLayoutSet.Text    = $loc.lblDriveLayout
    $CbiLayoutSetSeparate.Content = $loc.driveLayoutSeparate
    $CbiLayoutSetUnified.Content  = $uniLblTag
    $isUnifiedMode = ((Get-Settings).DriveLayout -eq "Unified")
    $BtnMountAll.Content       = if ($isUnifiedMode) { $loc.btnMountUnified } else { $loc.btnMountAll }
    $BtnUnmountAll.Content     = $loc.btnUnmountAll
    $BtnToggleDriveRow.Content = $loc.btnToggleDriveRow
    $BtnRenameAccount.Content  = $loc.btnRenameAccount
    if ($GridMultiDrives.Columns.Count -ge 6) {
        $GridMultiDrives.Columns[0].Header = $loc.colAccountName
        $GridMultiDrives.Columns[1].Header = $loc.colDriveLetter
        $GridMultiDrives.Columns[2].Header = $loc.colBackupTarget
        $GridMultiDrives.Columns[3].Header = $loc.colMountScope
        $GridMultiDrives.Columns[4].Header = $loc.colDriveMode
        $GridMultiDrives.Columns[5].Header = $loc.colStatus
    }

    $TxtFoldersHeader.Text     = $loc.foldersHeader
    $LblFoldersSubHint.Text    = $loc.foldersSubHint
    $LblDeletePolicy.Text      = $loc.deletePolicyLabel
    $CbiPolicySafe.Content     = $loc.deletePolicySafeArchive
    $CbiPolicySafe.ToolTip     = $loc.deletePolicySafeArchiveTooltip
    $CbiPolicyCopy.Content     = $loc.deletePolicyCopyOnly
    $CbiPolicyCopy.ToolTip     = $loc.deletePolicyCopyOnlyTooltip
    $CbiPolicyMirror.Content   = $loc.deletePolicyStrictMirror
    $CbiPolicyMirror.ToolTip   = $loc.deletePolicyStrictMirrorTooltip
    $LblDefaultTarget.Text     = $loc.lblDefaultTarget
    $CbiDefTargetDrive.Content = $loc.targetMyDrive
    $CbiDefTargetComp.Content  = $loc.targetMyComputer
    $LblMyComputer.Text        = $loc.myComputerLabel
    $BtnAddFolder.Content      = Wrap-RtlLead $loc.addFolder
    $BtnRemoveFolder.Content   = Wrap-RtlLead $loc.removeFolder
    $BtnSyncSelected.Content   = $loc.syncSelected
    $BtnToggleTarget.Content   = $loc.switchTarget

    $ChkJsonRules.Content      = $loc.jsonExclusions
    $CbiPresetDev.Content      = $loc.presetDevDefault
    $CbiPresetCreative.Content = $loc.presetCreativeMedia
    $CbiPresetGeneral.Content  = $loc.presetGeneralBackup
    $CbiPresetCustom.Content   = $loc.presetCustomFile
    $BtnEditJsonRules.Content  = $loc.editJson
    $BtnLoadJsonRules.Content  = $loc.loadJson

    $LblSchedule.Text          = $loc.scheduleLabel
    $BtnOpenScheduler.Content  = $loc.configureSchedule
    $BtnDisableSchedule.Content= $loc.disableSchedule
    $TxtDryRun.Text            = $loc.dryRun
    $TxtRestore.Text           = $loc.restore
    $LblSpeedMode.Text         = $loc.speedMode
    $CbiSpeedTurbo.Content     = $loc.speedTurbo
    $CbiSpeedBalanced.Content  = $loc.speedBalanced
    $CbiSpeedEco.Content       = $loc.speedEco
    $LblFeedHeader.Text        = $loc.feedHeader
    $LblLogHeader.Text         = $loc.logHeader
    $BtnClearLog.Content       = $loc.clearLog

    $CtxSyncFolder.Header      = $loc.ctxSyncFolder
    $CtxDryRunFolder.Header    = $loc.ctxDryRunFolder
    $CtxRestoreFolder.Header   = $loc.ctxRestoreFolder
    $CtxSwitchTarget.Header    = $loc.ctxSwitchTarget
    $CtxOpenLocal.Header       = $loc.ctxOpenLocal
    $CtxRemoveFolder.Header    = $loc.ctxRemoveFolder
    $miOpen.Text               = $loc.trayOpen
    $miSync.Text               = $loc.traySync
    $miPauseAll.Text           = if ($script:IsGloballyPaused) { $loc.trayResumeAll } else { $loc.trayPauseAll }
    $miIsland.Text             = $loc.trayIsland
    $miExit.Text               = $loc.trayExit
    if (-not $SkipShellSync) {
        try { if ([bool](Get-Settings).ExplorerContextMenu) { $null = Set-ExplorerContextMenuEnabled -Enable $true } } catch {}
    }

    if ($GridFolders.Columns.Count -ge 7) {
        $GridFolders.Columns[0].Header = $loc.colBackup
        $GridFolders.Columns[1].Header = $loc.colFolder
        $GridFolders.Columns[2].Header = $loc.colLocal
        $GridFolders.Columns[3].Header = $loc.colDest
        $GridFolders.Columns[4].Header = $loc.colLocalSize
        $GridFolders.Columns[5].Header = $loc.colDriveSize
        $GridFolders.Columns[6].Header = $loc.colStatus
    }
    if ($GridActivity.Columns.Count -ge 4) {
        $GridActivity.Columns[0].Header = $loc.colState
        $GridActivity.Columns[1].Header = $loc.colFile
        $GridActivity.Columns[2].Header = $loc.colDetails
        $GridActivity.Columns[3].Header = $loc.colTime
    }

    $TxtSyncToggle.Text = if ($script:IsSyncRunning) { $loc.stopSync } else { $loc.syncAll }
    if (-not $script:IsSyncRunning) {
        $TxtUploadCounters.Text = $loc.countersInitial
        $TxtLiveTransfer.Text   = $loc.statusIdle
    }
    Update-DeletePolicyHint -Policy (Get-Settings).DeletePolicy
    Update-CloudIslandDisplay
}

function Set-SyncControlsRunningState {
    param([bool]$Running)
    $script:IsSyncRunning = $Running
    if (-not $Running) { $script:SyncingRemote = $null }
    Switch-AccountActivityView
    Update-CloudIslandDisplay
}

function Persist-GridCheckboxChanges {
    if (-not $script:FoldersGridHydrated) { return }
    $current = @()
    foreach ($row in $script:FolderItems) {
        $current += [PSCustomObject]@{
            Enabled    = [bool]$row.Enabled; Name = $row.Name; LocalPath = $row.LocalPath
            TargetMode = $row.TargetMode; RemotePath = $row.RemotePath
            LocalSize  = $row.LocalSize; LocalBytes = $row.LocalBytes
            RemoteSize = $row.RemoteSize; LastStatus = $row.LastStatus
        }
    }
    Save-SyncFolders -Folders $current -TargetRemote $script:ActiveRemote
}

function Format-GridDisplayValue {
    param([string]$RawVal, [string]$EmptyKey)
    if ([string]::IsNullOrWhiteSpace($RawVal)) { return (L $EmptyKey) }
    switch ($RawVal) {
        "Not scanned"        { return (L "gridNotScanned") }
        "Click 'Scan'"       { return (L "gridClickScan") }
        "Ready"              { return (L "gridReady") }
        "Missing locally"    { return (L "gridMissingLocally") }
        "0 MB (Not uploaded)"{ return (L "gridNotUploaded") }
        "Sign in to view"    { return (L "gridSignInToView") }
        default {
            if ($RawVal -match '^Synced\s+(.+)$') { return (LF "gridSyncedAt" @((Wrap-Ltr $Matches[1]))) }
            if ($RawVal -match '^Exit\s+(\d+)$')  { return (LF "gridExitError" @($Matches[1])) }
            if ($RawVal -match '^(.+?)\s*\((\d+)\s*files\)$') {
                $szTok = if ($null -ne $script:CurrentLocale -and $script:CurrentLocale.rtl) { "$(Wrap-Ltr $Matches[1].Trim())$($script:RLM)" } else { Wrap-Ltr $Matches[1].Trim() }
                return (LF "gridSizeWithFiles" @($szTok, $Matches[2]))
            }
            return (Wrap-Ltr $RawVal)
        }
    }
}

function Update-FoldersGrid {
    $script:FolderItems.Clear()
    $cfg = Get-Settings
    $compLbl = if ([string]::IsNullOrWhiteSpace($cfg.ComputerLabel)) { "My Computer" } else { $cfg.ComputerLabel.Trim() }
    foreach ($f in (Get-SyncFolders -TargetRemote $script:ActiveRemote)) {
        $eff = Resolve-EffectiveRemotePath -FolderItem $f
        $baseRel = $f.RemotePath.Trim('/')
        $optDrive = [PSCustomObject]@{ Value = "My Drive";    Label = "My Drive/$baseRel" }
        $optComp  = [PSCustomObject]@{ Value = "My Computer"; Label = "$compLbl/$baseRel" }
        $selOpt   = if ($f.TargetMode -eq "My Computer") { $optComp } else { $optDrive }
        $tDisp    = if ($f.TargetMode -eq "My Computer") { L "targetMyComputer" } else { L "targetMyDrive" }
        $script:FolderItems.Add([PSCustomObject]@{
            Enabled = [bool]$f.Enabled; Name = $f.Name; LocalPath = $f.LocalPath
            TargetMode = $f.TargetMode; TargetDisplay = $tDisp
            TargetOptions = @($optDrive, $optComp); SelectedTargetOption = $selOpt
            RemotePath = $f.RemotePath
            RemoteDisplay = "My Drive/$eff"; LocalSize = $f.LocalSize; LocalBytes = [double]$f.LocalBytes
            LocalSizeDisplay = Format-GridDisplayValue -RawVal $f.LocalSize -EmptyKey "gridNotScanned"
            RemoteSize = $f.RemoteSize; RemoteSizeDisplay = Format-GridDisplayValue -RawVal $f.RemoteSize -EmptyKey "gridNotScanned"
            LastStatus = $f.LastStatus; LastStatusDisplay = Format-GridDisplayValue -RawVal $f.LastStatus -EmptyKey "gridReady"
        })
    }
    $BtnRemoveFolder.IsEnabled = $false
    $BtnToggleTarget.IsEnabled = $false
    $BtnSyncSelected.IsEnabled = $false
    $script:FoldersGridHydrated = $true
}

$script:CachedDriveRemotes = @()

function Refresh-MultiDrivesGrid {
    param([switch]$ForceRefresh)
    try {
        $remotes = if (-not $ForceRefresh -and $script:CachedDriveRemotes.Count -gt 0) { @($script:CachedDriveRemotes) } else { @(Get-ConfiguredDriveRemotes) }
        if ($remotes.Count -gt 0) { $script:CachedDriveRemotes = $remotes }
        $mounts  = @(Get-MountsState)
        $cfg     = Get-Settings
        $uniInfo = Get-UnifiedMountInfo
        $uniLtr  = if ($null -ne $uniInfo) { $uniInfo.Letter } else { $null }
        $uniAutoLtr = Get-AutoUnifiedDriveLetter
        $showUniChoice = ($cfg.DriveLayout -eq "Unified" -or $null -ne $uniLtr -or (@(Get-UnifiedPoolRemotes)).Count -gt 0)
        $starCh  = [string][char]0x2605
        $uniChoiceLbl = "$starCh $uniAutoLtr"
        $defModeLoc = if ($cfg.MountMode -eq "Mirror") { L "mountModeMirror" } else { L "mountModeStream" }
        $lblDrive  = L "targetMyDrive"
        $lblComp   = L "targetMyComputer"
        $lblMixed  = L "targetMixed" "Mixed"
        $lblScDrv  = L "mountScopeMyDrive"
        $lblScCmp  = L "mountScopeMyComputer"
        $lblScBoth = L "mountScopeBoth"
        $lblAct    = L "driveStatusActive" "Active"
        $lblHid    = L "driveStatusHidden" "Hidden"
        $newRows = @()
        $reservedInGrid = if ($showUniChoice) { @($uniAutoLtr) } else { @() }
        foreach ($rem in $remotes) {
            $m = $mounts | Where-Object { $_.Remote -eq $rem } | Select-Object -First 1
            $ltr = if ($null -ne $m) { $m.Letter } else { Get-MountedLetterForRemote -TargetRemote $rem }
            $remAssign = Get-AccountDriveAssignment -TargetRemote $rem
            $inActiveUni = ($null -eq $ltr -and $null -ne $uniLtr -and ($uniInfo.Remotes.Count -eq 0 -or ($uniInfo.Remotes -contains $rem)))
            $effLtr = if ($null -ne $ltr) { $ltr } elseif ($inActiveUni) { $uniLtr } else { $null }
            $prefLtr = if ($ltr) { $ltr } else { Get-AccountPreferredDrive -TargetRemote $rem -DefaultLetter "" }
            $availRaw = @(Get-AvailableDriveLetters -TargetRemote $rem -Preferred $prefLtr -ReservedLetters $reservedInGrid)
            if ($showUniChoice) {
                $availLtrs = @($uniChoiceLbl) + @($availRaw | Where-Object { $_ -ne $uniAutoLtr })
            } else {
                $availLtrs = $availRaw
            }
            $selLtr = if ($null -ne $ltr) { $ltr } elseif ($showUniChoice -and ($remAssign -eq "Unified" -or $inActiveUni)) { $uniChoiceLbl } elseif ($prefLtr -and ($availLtrs -contains $prefLtr)) { $prefLtr } elseif ($availLtrs.Count -gt 0) { $availLtrs[0] } else { $uniChoiceLbl }
            if ($selLtr -match '^[A-Z]:$' -and ($reservedInGrid -notcontains $selLtr)) { $reservedInGrid += $selLtr }

            $tSummary = Get-AccountTargetModeSummary -TargetRemote $rem
            $optDrive = [PSCustomObject]@{ Value = "My Drive";    Label = $lblDrive }
            $optComp  = [PSCustomObject]@{ Value = "My Computer"; Label = $lblComp  }
            if ($tSummary -eq "Mixed") {
                $optMix = [PSCustomObject]@{ Value = "Mixed"; Label = $lblMixed }
                $tOpts = @($optMix, $optDrive, $optComp)
                $selTOpt = $optMix
            } else {
                $tOpts = @($optDrive, $optComp)
                $selTOpt = if ($tSummary -eq "My Computer") { $optComp } else { $optDrive }
            }

            $scVal = Get-AccountMountScope -TargetRemote $rem
            $scDrive = [PSCustomObject]@{ Value = "MyDrive";    Label = $lblScDrv  }
            $scComp  = [PSCustomObject]@{ Value = "MyComputer"; Label = $lblScCmp  }
            $scBoth  = [PSCustomObject]@{ Value = "Both";       Label = $lblScBoth }
            $scOpts  = @($scDrive, $scComp, $scBoth)
            $selSc   = switch ($scVal) { "MyComputer" { $scComp } "Both" { $scBoth } default { $scDrive } }

            $modeTxt = if ($inActiveUni) { L "mountModeUnified" "Unified Drive" } elseif ($null -ne $m) { if ($m.Mode -eq "Mirror") { L "mountModeMirror" } else { L "mountModeStream" } } elseif ($remAssign -eq "Unified") { L "mountModeUnified" "Unified Drive" } else { $defModeLoc }
            $uniPoolCnt = if ($null -ne $uniInfo -and $uniInfo.Remotes.Count -gt 0) { $uniInfo.Remotes.Count } else { $remotes.Count }
            $stTxt   = if ($null -ne $ltr) { LF "mountMounted" @((Wrap-Ltr $ltr), $modeTxt) } elseif ($inActiveUni) { LF "unifiedDriveActive" @((Wrap-Ltr $uniLtr), $uniPoolCnt) } else { L "mountHidden" }
            $newRows += [PSCustomObject]@{
                Remote               = $rem
                DisplayName          = (Get-AccountDisplayLabel -TargetRemote $rem)
                Letter               = $effLtr
                IsUnifiedRow         = $inActiveUni
                SelectedLetter       = $selLtr
                AvailableLetters     = $availLtrs
                SelectedTargetValue  = $tSummary
                TargetOptions        = $tOpts
                SelectedTargetOption = $selTOpt
                SelectedScopeValue   = $scVal
                ScopeOptions         = $scOpts
                SelectedScopeOption  = $selSc
                ModeDisplay          = $modeTxt
                StatusDisplay        = $stTxt
                StatusShort          = if ($null -ne $effLtr) { $lblAct } else { $lblHid }
                StatusBrush          = if ($inActiveUni) { "#FBBF24" } elseif ($null -ne $effLtr) { "#4ADE80" } else { "#64748B" }
            }
        }
        $script:MultiDriveItems.Clear()
        foreach ($nr in $newRows) { $script:MultiDriveItems.Add($nr) }
    } catch {}
}

function Test-ActivityRowPathMatch {
    param([string]$ExistingPath, [string]$IncomingPath)
    if ([string]::IsNullOrWhiteSpace($ExistingPath) -or [string]::IsNullOrWhiteSpace($IncomingPath)) { return $false }
    if ($ExistingPath -ieq $IncomingPath) { return $true }
    if ($ExistingPath.Contains("...") -and -not $IncomingPath.Contains("...")) {
        $parts = $ExistingPath -split '\.\.\.', 2
        if ($parts.Count -eq 2 -and $IncomingPath.StartsWith($parts[0], [System.StringComparison]::OrdinalIgnoreCase) -and $IncomingPath.EndsWith($parts[1], [System.StringComparison]::OrdinalIgnoreCase)) {
            return $true
        }
    }
    if ($IncomingPath.Contains("...") -and -not $ExistingPath.Contains("...")) {
        $parts = $IncomingPath -split '\.\.\.', 2
        if ($parts.Count -eq 2 -and $ExistingPath.StartsWith($parts[0], [System.StringComparison]::OrdinalIgnoreCase) -and $ExistingPath.EndsWith($parts[1], [System.StringComparison]::OrdinalIgnoreCase)) {
            return $true
        }
    }
    return $false
}

function Add-FileActivityRow {
    param(
        [string]$State,
        [string]$FileName,
        [string]$Details,
        [string]$TargetRemote = $script:ActiveRemote,
        [int]$Priority = 1,
        [switch]$FromStats,
        [string]$BrushHex = ""
    )
    if ([string]::IsNullOrWhiteSpace($TargetRemote)) { $TargetRemote = $script:ActiveRemote }
    $rt = Get-AccountRuntime -TargetRemote $TargetRemote
    $nowUtc = [datetime]::UtcNow

    # Prune old completion memory (> 60s)
    if ($rt.PSObject.Properties["RecentlyCompleted"] -and $null -ne $rt.RecentlyCompleted) {
        for ($rc = $rt.RecentlyCompleted.Count - 1; $rc -ge 0; $rc--) {
            if (($nowUtc - [datetime]$rt.RecentlyCompleted[$rc].Utc).TotalSeconds -ge 60) {
                $rt.RecentlyCompleted.RemoveAt($rc)
            }
        }
        if ($Priority -eq 2) {
            # Fresh queued edit/delete/preview on a previously completed file allows it to re-enter the queue
            for ($rc = $rt.RecentlyCompleted.Count - 1; $rc -ge 0; $rc--) {
                if (Test-ActivityRowPathMatch -ExistingPath $rt.RecentlyCompleted[$rc].Path -IncomingPath $FileName) {
                    $rt.RecentlyCompleted.RemoveAt($rc)
                }
            }
        } elseif ($FromStats -or $Priority -eq 0) {
            # Never resurrect a completed / auto-dismissed file from stale rclone log-tail stats lines
            foreach ($rcItem in $rt.RecentlyCompleted) {
                if (Test-ActivityRowPathMatch -ExistingPath $rcItem.Path -IncomingPath $FileName) { return }
            }
        }
        if ($Priority -eq 1) {
            for ($rc = $rt.RecentlyCompleted.Count - 1; $rc -ge 0; $rc--) {
                if (Test-ActivityRowPathMatch -ExistingPath $rt.RecentlyCompleted[$rc].Path -IncomingPath $FileName) {
                    if ($FileName.Contains("...") -and -not $rt.RecentlyCompleted[$rc].Path.Contains("...")) { return }
                    $rt.RecentlyCompleted.RemoveAt($rc)
                }
            }
            $rt.RecentlyCompleted.Add([PSCustomObject]@{ Path = $FileName; Utc = $nowUtc })
        }
    }

    $ts = Format-Time12h -DateTime (Get-Date) -WithSeconds
    $doneAt = if ($Priority -eq 1) { $nowUtc } else { $null }
    $clrHex = if (-not [string]::IsNullOrWhiteSpace($BrushHex)) { $BrushHex } elseif ($Priority -eq 0) { "#38BDF8" } elseif ($Priority -eq 1) { "#4ADE80" } else { "#94A3B8" }
    $newItem = [PSCustomObject]@{ State = $State; StateBrush = $clrHex; FileName = $FileName; Details = $Details; Time = $ts; Priority = $Priority; CompletedUtc = $doneAt }

    # Remove any matching existing row (including middle-ellipsis truncated rows from rclone stats!)
    for ($i = $rt.ActivityItems.Count - 1; $i -ge 0; $i--) {
        if (Test-ActivityRowPathMatch -ExistingPath $rt.ActivityItems[$i].FileName -IncomingPath $FileName) {
            # Never downgrade or truncate an already-completed full-path row back to an ellipsis stat line
            if ($rt.ActivityItems[$i].Priority -eq 1 -and ($Priority -eq 0 -or $Priority -eq 1) -and $FileName.Contains("...") -and -not $rt.ActivityItems[$i].FileName.Contains("...")) { return }
            $rt.ActivityItems.RemoveAt($i)
        }
    }

    # Keep Activity Queue strictly organized:
    # Priority 0 = Active Uploading (ALWAYS TOP) -> Priority 1 = Completed / Archived (right below, auto-dismisses after 3.5s) -> Priority 2 = Queued / Preview (appended at BOTTOM, FIFO!)
    $insertIdx = $rt.ActivityItems.Count
    if ($Priority -lt 2) {
        for ($i = 0; $i -lt $rt.ActivityItems.Count; $i++) {
            $itemPri = if ($rt.ActivityItems[$i].PSObject.Properties["Priority"]) { [int]$rt.ActivityItems[$i].Priority } else { 1 }
            if ($itemPri -ge $Priority) {
                $insertIdx = $i
                break
            }
        }
    }
    $rt.ActivityItems.Insert($insertIdx, $newItem)
    while ($rt.ActivityItems.Count -gt 300) { $rt.ActivityItems.RemoveAt($rt.ActivityItems.Count - 1) }

    # Automatically keep the top event ceiling (active uploads & latest completions) visible in the live feed!
    if ($TargetRemote -eq $script:ActiveRemote -and $Priority -le 1 -and $rt.ActivityItems.Count -gt 0) {
        try { if ($null -ne $GridActivity) { $GridActivity.ScrollIntoView($rt.ActivityItems[0]) } } catch {}
    }
}

function Complete-StuckUploadingRowsForFolder {
    param([string]$FolderPrefix, [string]$TargetRemote, [switch]$ClearPendingPreview, [string[]]$TargetFiles = $null)
    if ([string]::IsNullOrWhiteSpace($FolderPrefix)) { return }
    try {
        $rt = Get-AccountRuntime -TargetRemote $TargetRemote
        $doneLbl = L "feedStateUploaded"
        $targetSet = @{}
        if ($null -ne $TargetFiles -and $TargetFiles.Count -gt 0) {
            foreach ($tf in $TargetFiles) {
                if (-not [string]::IsNullOrWhiteSpace($tf)) {
                    $tNorm = "$FolderPrefix/$(($tf -replace '\\', '/').TrimStart('/'))".ToLowerInvariant()
                    $targetSet[$tNorm] = $true
                }
            }
        }
        $toPromote = @()
        for ($i = $rt.ActivityItems.Count - 1; $i -ge 0; $i--) {
            $row = $rt.ActivityItems[$i]
            $pri = if ($row.PSObject.Properties["Priority"]) { [int]$row.Priority } else { 1 }
            if ($row.FileName.StartsWith("$FolderPrefix/", [System.StringComparison]::OrdinalIgnoreCase)) {
                if ($pri -eq 0) {
                    $toPromote += $row
                    $rt.ActivityItems.RemoveAt($i)
                } elseif ($pri -eq 2 -and ($ClearPendingPreview -or ($targetSet.Count -gt 0 -and $targetSet.ContainsKey($row.FileName.ToLowerInvariant())))) {
                    $rt.ActivityItems.RemoveAt($i)
                }
            }
        }
        foreach ($oldR in $toPromote) {
            # Only add back if no full-path completed row already represents it
            $already = $false
            foreach ($ex in $rt.ActivityItems) {
                if (Test-ActivityRowPathMatch -ExistingPath $ex.FileName -IncomingPath $oldR.FileName) { $already = $true; break }
            }
            if (-not $already) {
                Add-FileActivityRow -State $doneLbl -FileName $oldR.FileName -Details "100%" -TargetRemote $TargetRemote -Priority 1
            }
        }
    } catch {}
}

function Refresh-DriveLettersDropdown {
    $cfg = Get-Settings
    $bc = New-Object System.Windows.Media.BrushConverter
    $mounted = Get-MountedLetterForRemote -TargetRemote $script:ActiveRemote
    $assign  = Get-AccountDriveAssignment -TargetRemote $script:ActiveRemote
    $uniInfo = Get-UnifiedMountInfo
    $uniAuto = Get-AutoUnifiedDriveLetter
    $showUniChoice = ($cfg.DriveLayout -eq "Unified" -or $null -ne $uniInfo -or $assign -eq "Unified")
    $starCh  = [string][char]0x2605
    $accPref = Get-AccountPreferredDrive -TargetRemote $script:ActiveRemote -DefaultLetter $(if ($cfg.PreferredDrive) { $cfg.PreferredDrive } else { "G:" })
    $pref = if ($mounted) { $mounted } else { $accPref }
    $avail = @(Get-AvailableDriveLetters -TargetRemote $script:ActiveRemote -Preferred $pref)

    $CmbDriveLetter.Items.Clear()
    $cbiUni = $null
    if ($showUniChoice) {
        $cbiUni = New-Object System.Windows.Controls.ComboBoxItem
        $cbiUni.Content = "$starCh $uniAuto"
        $cbiUni.Tag = "__UNIFIED__"
        $cbiUni.Foreground = $bc.ConvertFromString("#FBBF24")
        $cbiUni.FontWeight = [System.Windows.FontWeights]::Bold
        $cbiUni.FlowDirection = [System.Windows.FlowDirection]::LeftToRight
        $cbiUni.ToolTip = "$(L 'mountModeUnified' 'Show in Unified Drive') ($uniAuto)"
        [void]$CmbDriveLetter.Items.Add($cbiUni)
        # Never duplicate the Unified Drive letter as a separate letter unless this account itself holds it separately
        if ($mounted -ne $uniAuto) {
            $avail = @($avail | Where-Object { $_ -ne $uniAuto })
        }
    }

    $selItem = $null
    foreach ($l in $avail) {
        $cbi = New-Object System.Windows.Controls.ComboBoxItem
        $cbi.Content = $l
        $cbi.Tag = $l
        $cbi.FlowDirection = [System.Windows.FlowDirection]::LeftToRight
        [void]$CmbDriveLetter.Items.Add($cbi)
        if ($l -eq $pref -and $null -eq $selItem) { $selItem = $cbi }
    }

    if ($null -ne $cbiUni -and $null -eq $mounted -and $assign -eq "Unified") {
        $CmbDriveLetter.SelectedItem = $cbiUni
        $CmbDriveLetter.Foreground = $bc.ConvertFromString("#FBBF24")
        $CmbDriveLetter.FontWeight = [System.Windows.FontWeights]::Bold
    } elseif ($null -ne $selItem) {
        $CmbDriveLetter.SelectedItem = $selItem
        $CmbDriveLetter.Foreground = $bc.ConvertFromString("#E2E8F0")
        $CmbDriveLetter.FontWeight = [System.Windows.FontWeights]::SemiBold
    } elseif ($CmbDriveLetter.Items.Count -gt 0) {
        $pickIdx = if ($null -ne $cbiUni -and $CmbDriveLetter.Items.Count -gt 1 -and $assign -ne "Unified") { 1 } else { 0 }
        $CmbDriveLetter.SelectedIndex = $pickIdx
        $isPickUni = ($null -ne $cbiUni -and $pickIdx -eq 0)
        $CmbDriveLetter.Foreground = $bc.ConvertFromString($(if ($isPickUni) { "#FBBF24" } else { "#E2E8F0" }))
        $CmbDriveLetter.FontWeight = if ($isPickUni) { [System.Windows.FontWeights]::Bold } else { [System.Windows.FontWeights]::SemiBold }
    }
    $CmbDriveLetter.IsEnabled = $true
}

function Get-SelectedDriveLetter {
    if ($null -ne $CmbDriveLetter.SelectedItem) {
        if ($CmbDriveLetter.SelectedItem -is [System.Windows.Controls.ComboBoxItem] -and $CmbDriveLetter.SelectedItem.Tag) {
            return $CmbDriveLetter.SelectedItem.Tag.ToString()
        }
        return $CmbDriveLetter.SelectedItem.ToString()
    }
    return "G:"
}

function Refresh-ProfilesDropdown {
    $remotes = @(Get-ConfiguredDriveRemotes)
    $script:CachedDriveRemotes = $remotes
    if ($remotes.Count -eq 0) { $remotes = @("gdrive") }
    if ($remotes -notcontains $script:ActiveRemote) { $script:ActiveRemote = $remotes[0] }
    $checkedCount = 0
    foreach ($r in $remotes) {
        if ($checkedCount -lt 10) {
            Ensure-RemoteAutoNameCached -TargetRemote $r
            $checkedCount++
        }
    }
    $CmbAccountProfile.Items.Clear()
    $selectedObj = $null
    foreach ($r in $remotes) {
        $cbi = New-Object System.Windows.Controls.ComboBoxItem
        $cbi.Content = Get-AccountDisplayLabel -TargetRemote $r
        $cbi.Tag = $r
        $cbi.FlowDirection = [System.Windows.FlowDirection]::LeftToRight
        [void]$CmbAccountProfile.Items.Add($cbi)
        if ($r -eq $script:ActiveRemote) { $selectedObj = $cbi }
    }
    if ($null -ne $selectedObj) { $CmbAccountProfile.SelectedItem = $selectedObj }
    elseif ($CmbAccountProfile.Items.Count -gt 0) { $CmbAccountProfile.SelectedIndex = 0 }
}

function Sync-JsonRulesUiForActiveAccount {
    $rCfg = Get-AccountRulesConfig -TargetRemote $script:ActiveRemote
    $ChkJsonRules.IsChecked = [bool]$rCfg.UseJsonRules
    $rPath = $rCfg.JsonRulesPath
    $CmbJsonPreset.SelectedIndex = if ($rPath -match 'creative-media\.json$') { 1 } elseif ($rPath -match 'general-backup\.json$') { 2 } elseif ($rPath -match 'developer-default\.json$') { 0 } else { 3 }
    Refresh-JsonRulesBanner
}

function Refresh-JsonRulesBanner {
    $rInfo = Build-SafeExcludeFile -TargetRemote $script:ActiveRemote
    if ($rInfo.Enabled) {
        $TxtRulesSummary.Text = LF "rulesSummaryActive" @((Wrap-Ltr $rInfo.PresetName), $rInfo.DirCount, $rInfo.FileCount)
    } else {
        $TxtRulesSummary.Text = L "rulesSummaryOff"
    }
}

function Update-DeletePolicyHint {
    param([string]$Policy)
    switch ($Policy) {
        "Copy-Only"     { $TxtDeletePolicyHint.Text = L "deletePolicyCopyOnlyHint";     $TxtQuickPolicyChip.Text = L "deletePolicyCopyOnly" }
        "Strict Mirror" { $TxtDeletePolicyHint.Text = L "deletePolicyStrictMirrorHint"; $TxtQuickPolicyChip.Text = L "deletePolicyStrictMirror" }
        default         { $TxtDeletePolicyHint.Text = L "deletePolicySafeArchiveHint";  $TxtQuickPolicyChip.Text = L "deletePolicySafeArchive" }
    }
}

function Update-DriveQuotaDisplay {
    param([switch]$UseCache)
    if (-not (Test-GDriveConfigured -TargetRemote $script:ActiveRemote)) {
        $script:LastTrashBytes = 0
        $BarDriveQuota.Value = 0; $BarSideQuota.Value = 0
        $TxtQuotaTotal.Text  = LF "quotaTotal" @((Wrap-Ltr "-- GB"))
        $TxtQuotaUsed.Text   = L "quotaUsedEmpty"
        $TxtQuotaFree.Text   = LF "quotaFree"  @((Wrap-Ltr "-- GB"))
        $TxtQuotaTrash.Text  = LF "quotaTrash" @((Wrap-Ltr "-- GB"))
        $TxtSideQuotaLabel.Text = "-- / --"
        return
    }
    try {
        $rawJson = $null
        if ($UseCache -and $script:LastAboutCache.ContainsKey($script:ActiveRemote) -and -not [string]::IsNullOrWhiteSpace($script:LastAboutCache[$script:ActiveRemote])) {
            $rawJson = $script:LastAboutCache[$script:ActiveRemote]
        } else {
            $res = Invoke-RcloneCapture -Arguments "about `"$($script:ActiveRemote):`" --json --quiet" -TimeoutMs 15000
            if ($res.ExitCode -eq 0 -and -not [string]::IsNullOrWhiteSpace($res.StdOut)) {
                $rawJson = $res.StdOut
                $script:LastAboutCache[$script:ActiveRemote] = $rawJson
            }
        }
        if (-not [string]::IsNullOrWhiteSpace($rawJson)) {
            $ab = $rawJson | ConvertFrom-Json
            $total = [double]$ab.total; $used = [double]$ab.used; $free = [double]$ab.free; $trash = [double]$ab.trashed
            $script:LastTrashBytes = $trash
            $pct = if ($total -gt 0) { [math]::Round(($used / $total) * 100, 2) } else { 0 }

            $BarDriveQuota.Value = [double]$pct; $BarSideQuota.Value = [math]::Max(2.0, [double]$pct)
            $TxtQuotaTotal.Text  = LF "quotaTotal" @((Wrap-Ltr (Format-ByteSize $total)))
            $TxtQuotaUsed.Text   = LF "quotaUsed"  @((Wrap-Ltr (Format-ByteSize $used)), (Wrap-Ltr "$pct"))
            $TxtQuotaFree.Text   = LF "quotaFree"  @((Wrap-Ltr (Format-ByteSize $free)))
            $TxtQuotaTrash.Text  = LF "quotaTrash" @((Wrap-Ltr (Format-ByteSize $trash)))
            $TxtSideQuotaLabel.Text = "$(Format-ByteSize $used) / $(Format-ByteSize $total) ($pct%)"
            Update-SidebarSingleAccountCard -TargetRemote $script:ActiveRemote
        }
    } catch {}
}

function Invoke-ScanFolderSizes {
    Persist-GridCheckboxChanges
    Write-StudioLog "Scanning local sizes, filter savings, and Google Drive quota..."
    Invoke-UiPump
    $folders = @(Get-SyncFolders -TargetRemote $script:ActiveRemote)
    $exInfo  = Build-SafeExcludeFile -TargetRemote $script:ActiveRemote
    $exFlag  = if ($exInfo.Enabled -and $exInfo.FilterFile) { "--exclude-from $(Format-WinArg $exInfo.FilterFile)" } else { "" }
    $isAuth  = Test-GDriveConfigured -TargetRemote $script:ActiveRemote
    $totalSavedBytes = 0.0; $totalSavedFiles = 0

    foreach ($f in $folders) {
        $eff = Resolve-EffectiveRemotePath -FolderItem $f
        if (Test-Path -LiteralPath $f.LocalPath) {
            $locArgS = Format-WinArg $f.LocalPath
            $locRes = Invoke-RcloneCapture -Arguments "size $locArgS --json --quiet $exFlag" -TimeoutMs 45000
            $cleanBytes = 0.0; $cleanCount = 0
            if ($locRes.ExitCode -eq 0 -and -not [string]::IsNullOrWhiteSpace($locRes.StdOut)) {
                try {
                    $lj = $locRes.StdOut | ConvertFrom-Json
                    $cleanBytes = [double]$lj.bytes; $cleanCount = [int]$lj.count
                    $f.LocalBytes = $cleanBytes; $f.LocalSize = "$(Format-ByteSize $cleanBytes) ($cleanCount files)"
                } catch {}
            }
            if ($exInfo.Enabled) {
                $rawRes = Invoke-RcloneCapture -Arguments "size $locArgS --json --quiet" -TimeoutMs 45000
                if ($rawRes.ExitCode -eq 0 -and -not [string]::IsNullOrWhiteSpace($rawRes.StdOut)) {
                    try {
                        $rjRaw = $rawRes.StdOut | ConvertFrom-Json
                        $diff = [double]$rjRaw.bytes - $cleanBytes; $diffF = [int]$rjRaw.count - $cleanCount
                        if ($diff -gt 0)  { $totalSavedBytes += $diff }
                        if ($diffF -gt 0) { $totalSavedFiles += $diffF }
                    } catch {}
                }
            }
        } else { $f.LocalSize = "Missing locally" }

        if ($isAuth) {
            $remArgS = Format-WinArg "$($script:ActiveRemote):$eff"
            $remRes = Invoke-RcloneCapture -Arguments "size $remArgS --fast-list --json --quiet" -TimeoutMs 45000
            if ($remRes.ExitCode -eq 0 -and -not [string]::IsNullOrWhiteSpace($remRes.StdOut)) {
                try { $rj = $remRes.StdOut | ConvertFrom-Json; $f.RemoteSize = "$(Format-ByteSize ([double]$rj.bytes)) ($($rj.count) files)" } catch { $f.RemoteSize = "0 MB (Not uploaded)" }
            } else { $f.RemoteSize = "0 MB (Not uploaded)" }
        } else { $f.RemoteSize = "Sign in to view" }
        Save-SyncFolders -Folders $folders -TargetRemote $script:ActiveRemote
        Update-FoldersGrid; Invoke-UiPump
    }

    if ($totalSavedBytes -gt 1MB) {
        $TxtSavedSpace.Text = LF "savedSpaceLabel" @((Wrap-Ltr (Format-ByteSize $totalSavedBytes)), $totalSavedFiles)
        $PillSavedSpace.Visibility = "Visible"
    } else { $PillSavedSpace.Visibility = "Collapsed" }
    Update-DriveQuotaDisplay
    Write-StudioLog "[OK] Folder sizes, filter savings ($(Format-ByteSize $totalSavedBytes)), and Drive quota updated."
}

function Refresh-StudioHeader {
    if ($script:IsRefreshing) { return }
    $script:IsRefreshing = $true
    try {
        Refresh-ProfilesDropdown
        Refresh-DriveLettersDropdown
        Sync-JsonRulesUiForActiveAccount
        $ident = Get-ConnectedGoogleIdentity -TargetRemote $script:ActiveRemote
        $dispLabel = Get-AccountDisplayLabel -TargetRemote $script:ActiveRemote
        $activeLetter = Get-MountedLetterForRemote -TargetRemote $script:ActiveRemote
        $schedInfo = Get-ScheduleInfo -TargetRemote $script:ActiveRemote
        $bc = New-Object System.Windows.Media.BrushConverter

        $scActive = Get-AccountMountScope -TargetRemote $script:ActiveRemote
        $CmbMountScope.SelectedIndex = switch ($scActive) { "MyComputer" { 1 } "Both" { 2 } default { 0 } }
        $tSumActive = Get-AccountTargetModeSummary -TargetRemote $script:ActiveRemote
        $CmbDefaultTarget.SelectedIndex = if ($tSumActive -eq "My Computer") { 1 } else { 0 }
        $dlCur = (Get-Settings).DriveLayout
        $dlIdx = if ($dlCur -eq "Unified") { 1 } else { 0 }
        $uniTagHdr = "$(Wrap-Ltr "$([string][char]0x2605) $(Get-AutoUnifiedDriveLetter)")  $([char]0x2022)  $(L 'driveLayoutUnified')"
        $CbiLayoutUnified.Content    = $uniTagHdr
        $CbiLayoutSetUnified.Content = $uniTagHdr
        $CmbDriveLayout.SelectedIndex = $dlIdx
        $CmbDriveLayoutSettings.SelectedIndex = $dlIdx
        $BtnMountAll.Content = if ($dlCur -eq "Unified") { L "btnMountUnified" } else { L "btnMountAll" }

        $script:IsSignedIn = [bool]$ident.Connected
        if ($ident.Connected) {
            $idDisplay = if (-not [string]::IsNullOrWhiteSpace($ident.DisplayName)) { "$($ident.Email) ($($ident.DisplayName))" } else { $ident.Email }
            $TxtAccountStatus.Text = Wrap-Ltr $idDisplay
            $TxtAccountStatus.ToolTip = $idDisplay
            $DotAccount.Fill = $bc.ConvertFromString("#10B981")
            $TxtSettingsAccount.Text = if ($idDisplay -ieq $dispLabel) { Wrap-Ltr $dispLabel } else { Wrap-Ltr "$dispLabel  --  $idDisplay" }
            $DotSettingsAccount.Fill = $bc.ConvertFromString("#10B981")
            $BtnAuthToggle.Content = L "signOut"
            $BtnAuthToggle.Background  = $bc.ConvertFromString("#162238")
            $BtnAuthToggle.BorderBrush = $bc.ConvertFromString("#273A57")
            $BtnCustomClientId.Content = if ($ident.HasCustomClientId) { L "apiKeyActive" } else { L "apiKey" }
            Update-DriveQuotaDisplay -UseCache
        } else {
            $TxtAccountStatus.Text = L "accountNotSignedIn"
            $TxtAccountStatus.ToolTip = $null
            $DotAccount.Fill = $bc.ConvertFromString("#F59E0B")
            $TxtSettingsAccount.Text = L "accountNotSignedIn"
            $DotSettingsAccount.Fill = $bc.ConvertFromString("#F59E0B")
            $BtnAuthToggle.Content = L "signIn"
            $BtnAuthToggle.Background  = $bc.ConvertFromString("#0284C7")
            $BtnAuthToggle.BorderBrush = $bc.ConvertFromString("#38BDF8")
            $BtnCustomClientId.Content = L "apiKey"
            Update-DriveQuotaDisplay -UseCache
        }

        $assignActive = Get-AccountDriveAssignment -TargetRemote $script:ActiveRemote
        $uniInfoActive = Get-UnifiedMountInfo
        $uniLtrActive  = if ($null -ne $uniInfoActive) { $uniInfoActive.Letter } else { $null }
        $uniAutoLtr    = Get-AutoUnifiedDriveLetter
        $inActiveUni   = ($null -eq $activeLetter -and $null -ne $uniLtrActive -and ($uniInfoActive.Remotes.Count -eq 0 -or ($uniInfoActive.Remotes -contains $script:ActiveRemote)))

        $mModeRaw = (Get-Settings).MountMode
        $mModeLoc = if ($mModeRaw -eq "Mirror") { L "mountModeMirror" } else { L "mountModeStream" }
        $CmbMountMode.IsEnabled = $true
        if ($null -ne $activeLetter) {
            $CmbMountMode.SelectedIndex = if ($mModeRaw -eq "Mirror") { 1 } else { 0 }
            $TxtMountStatus.Text = LF "mountMounted" @((Wrap-Ltr $activeLetter), $mModeLoc)
            $DotMount.Fill = $bc.ConvertFromString("#10B981")
            $BtnMount.Content = "$(L 'hideDrive') ($(Wrap-Ltr $activeLetter))"
            $BtnMount.Background  = $bc.ConvertFromString("#162238")
            $BtnMount.BorderBrush = $bc.ConvertFromString("#38BDF8")
        } elseif ($assignActive -eq "Unified" -or $inActiveUni) {
            $CmbMountMode.SelectedIndex = 2
            $poolCnt = if ($null -ne $uniInfoActive -and $uniInfoActive.Remotes.Count -gt 0) { $uniInfoActive.Remotes.Count } else { (@(Get-UnifiedPoolRemotes)).Count }
            $starCh = [string][char]0x2605
            if ($inActiveUni) {
                $uniLtrTok = if ($script:CurrentLocale -and $script:CurrentLocale.rtl) { "$(Wrap-Ltr $uniLtrActive)$($script:RLM)" } else { Wrap-Ltr $uniLtrActive }
                $TxtMountStatus.Text = LF "unifiedDriveActive" @($uniLtrTok, $poolCnt)
                $DotMount.Fill = $bc.ConvertFromString("#FBBF24")
                $BtnMount.Content = "$(L 'hideUnifiedDrive' 'Hide Unified Drive') ($(Wrap-Ltr "$starCh $uniLtrActive"))"
                $BtnMount.Background  = $bc.ConvertFromString("#261D0B")
                $BtnMount.BorderBrush = $bc.ConvertFromString("#D97706")
            } else {
                $TxtMountStatus.Text = L "mountHidden"
                $DotMount.Fill = $bc.ConvertFromString("#475569")
                $BtnMount.Content = "$(L 'btnMountUnified' 'Mount Unified Drive') ($(Wrap-Ltr "$starCh $uniAutoLtr"))"
                $BtnMount.Background  = $bc.ConvertFromString("#B45309")
                $BtnMount.BorderBrush = $bc.ConvertFromString("#FBBF24")
            }
        } else {
            $CmbMountMode.SelectedIndex = if ($mModeRaw -eq "Mirror") { 1 } else { 0 }
            $selL = Get-SelectedDriveLetter
            if ($selL -eq "__UNIFIED__") { $selL = $uniAutoLtr }
            $TxtMountStatus.Text = L "mountHidden"
            $DotMount.Fill = $bc.ConvertFromString("#475569")
            $BtnMount.Content = "$(L 'showDrive') ($(Wrap-Ltr $selL))"
            $BtnMount.Background  = $bc.ConvertFromString("#0E7490")
            $BtnMount.BorderBrush = $bc.ConvertFromString("#06B6D4")
        }

        $ChkStartup.IsChecked = Get-StartupEnabled

        $TxtScheduleStatus.Text = $schedInfo.Label
        if ($schedInfo.Active) {
            $TxtScheduleStatus.Foreground = $bc.ConvertFromString("#4ADE80")
            $BtnDisableSchedule.Visibility = "Visible"
        } else {
            $TxtScheduleStatus.Foreground = $bc.ConvertFromString("#94A3B8")
            $BtnDisableSchedule.Visibility = "Collapsed"
        }

        Update-FoldersGrid
        Refresh-MultiDrivesGrid
        Switch-AccountActivityView
        Refresh-SidebarAccountsOverview
    } catch {
        Write-StudioLog "[WARN] Header refresh notice: $($_.Exception.Message)"
    } finally { $script:IsRefreshing = $false }
}

# ==============================================================================
