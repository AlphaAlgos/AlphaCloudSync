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
    if ($null -ne $CtxMenuDrives) { $CtxMenuDrives.FlowDirection = $uiFlow }
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
    $TxtSettingsSecAccounts.Text      = if ($loc.lblConnectedAccounts) { $loc.lblConnectedAccounts } else { $loc.settingsSecAccounts }
    if ($null -ne $TxtAccountsListHint -and $loc.accountsListDesc) { $TxtAccountsListHint.Text = $loc.accountsListDesc }
    $TxtSettingsSecGeneral.Text       = $loc.settingsSecGeneral
    $TxtSettingsSecNotifications.Text = $loc.settingsSecNotifications
    $BtnSetTabAccounts.Content        = $loc.settingsSecAccounts
    $BtnSetTabSync.Content            = $loc.settingsSecSync
    $BtnSetTabBackup.Content          = $loc.settingsSecBackup
    $BtnSetTabGeneral.Content         = $loc.settingsSecGeneral
    $BtnSetTabNotif.Content           = $loc.settingsSecNotifications
    $BtnCheckUpdates.Content          = $loc.btnCheckUpdates
    $BtnCloudTransfer.Content         = $loc.btnCloudTransfer
    $BtnCloudTransferSet.Content      = $loc.btnCloudTransfer
    Update-AppVersionBannerUi
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
    if ($null -ne $CbiMountHidden -and $loc.mountModeExcluded) { $CbiMountHidden.Content = $loc.mountModeExcluded }
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
    if ($null -ne $BtnMount -and $loc.showDrive) { $BtnMount.Content = $loc.showDrive }
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
    if ($null -ne $BtnPickExclusions -and $loc.btnPickExclusions) { $BtnPickExclusions.Content = $loc.btnPickExclusions }

    $LblSchedule.Text          = $loc.scheduleLabel
    $BtnOpenScheduler.Content  = $loc.configureSchedule
    $BtnDisableSchedule.Content= $loc.disableSchedule
    $TxtDryRun.Text            = $loc.dryRun
    $TxtRestore.Text           = $loc.restore
    $LblSpeedMode.Text         = $loc.speedMode
    $CbiSpeedTurbo.Content     = $loc.speedTurbo
    $CbiSpeedBalanced.Content  = $loc.speedBalanced
    $CbiSpeedEco.Content       = $loc.speedEco
    $LblMaxDelete.Text         = $loc.lblMaxDelete
    $CmbMaxDelete.ToolTip      = $loc.tipMaxDelete
    $CbiMaxDelUnlimited.Content= $loc.maxDelUnlimited
    $CbiMaxDel200.Content      = (LF "maxDelFilesFmt" @(200))
    $CbiMaxDel500.Content      = (LF "maxDelFilesFmt" @(500))
    $CbiMaxDel1000.Content     = (LF "maxDelFilesFmt" @(1000))
    $CbiMaxDel5000.Content     = (LF "maxDelFilesFmt" @(5000))
    $LblFeedHeader.Text        = $loc.feedHeader
    $BtnOpenLog.Content        = $loc.openLogFile

    $CtxSyncFolder.Header      = $loc.ctxSyncFolder
    $CtxDryRunFolder.Header    = $loc.ctxDryRunFolder
    $CtxRestoreFolder.Header   = $loc.ctxRestoreFolder
    $CtxSwitchTarget.Header    = $loc.ctxSwitchTarget
    $CtxOpenLocal.Header       = $loc.ctxOpenLocal
    $CtxRemoveFolder.Header    = $loc.ctxRemoveFolder
    if ($null -ne $CtxDriveToggle   -and $loc.ctxDriveToggle)   { $CtxDriveToggle.Header   = $loc.ctxDriveToggle }
    if ($null -ne $CtxDriveUnified  -and $loc.ctxDriveUnified)  { $CtxDriveUnified.Header  = $loc.ctxDriveUnified }
    if ($null -ne $CtxDriveSeparate -and $loc.ctxDriveSeparate) { $CtxDriveSeparate.Header = $loc.ctxDriveSeparate }
    if ($null -ne $CtxDriveHide     -and $loc.ctxDriveHide)     { $CtxDriveHide.Header     = $loc.ctxDriveHide }
    if ($null -ne $CtxDriveRename   -and $loc.ctxDriveRename)   { $CtxDriveRename.Header   = $loc.ctxDriveRename }
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
        $GridActivity.Columns[2].Header = $(if ($loc.PSObject.Properties["colProgress"]) { $loc.colProgress } else { "Progress" })
        $GridActivity.Columns[3].Header = $loc.colTime
    }

    $TxtSyncToggle.Text = if ($script:IsSyncRunning) { $loc.stopSync } else { $loc.syncAll }
    if (-not $script:IsSyncRunning) {
        foreach ($rtRef in $script:AccountRuntimeMap.Values) {
            if ($null -ne $rtRef -and $null -ne $rtRef.LastSummary) {
                Format-AccountLastSummaryIntoRuntime -Runtime $rtRef
            }
        }
        if (Get-Command Switch-AccountActivityView -ErrorAction SilentlyContinue) {
            Switch-AccountActivityView
        } else {
            $TxtUploadCounters.Text = $loc.countersInitial
            $TxtLiveTransfer.Text   = $loc.statusIdle
        }
    }
    Update-DeletePolicyHint -Policy (Get-Settings).DeletePolicy
    Update-CloudIslandDisplay
    if (Get-Command Refresh-SettingsAccountsList -ErrorAction SilentlyContinue) { Refresh-SettingsAccountsList }
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
        "Err:MaxDelete"      { return (L "gridErrMaxDelete" "Delete limit paused") }
        "Err:QuotaFull"      { return (L "gridErrQuotaFull" "Drive storage full") }
        "Err:AuthExpired"    { return (L "gridErrAuthExpired" "Sign-in required") }
        "Err:PathOrAccess"   { return (L "gridErrPathOrAccess" "File in use or missing") }
        "Err:Network"        { return (L "gridErrNetwork" "Network interrupted") }
        "Err:General"        { return (L "gridErrGeneral" "Needs attention") }
        default {
            if ($RawVal -match '^Synced\s+(.+)$') { return (LF "gridSyncedAt" @((Wrap-Ltr $Matches[1]))) }
            if ($RawVal -match '^Exit\s+(\d+)$')  {
                if ($Matches[1] -eq "7") { return (L "gridErrMaxDelete" "Delete limit paused") }
                return (L "gridErrGeneral" "Needs attention")
            }
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
        $starCh  = [string][char]0x2605
        $uniChoiceLbl = "$starCh $uniAutoLtr"
        $hidChoiceLbl = L "driveChoiceHiddenShort" "$([char]0x2298) Off"
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
        $reservedInGrid = @($uniAutoLtr)
        foreach ($rem in $remotes) {
            $m = $mounts | Where-Object { $_.Remote -eq $rem } | Select-Object -First 1
            $ltr = if ($null -ne $m) { $m.Letter } else { Get-MountedLetterForRemote -TargetRemote $rem }
            $remAssign = Get-AccountDriveAssignment -TargetRemote $rem
            $inActiveUni = ($null -eq $ltr -and $null -ne $uniLtr -and (($uniInfo.Remotes.Count -gt 0 -and ($uniInfo.Remotes -contains $rem)) -or ($uniInfo.Remotes.Count -eq 0 -and $remAssign -ne "Hidden")))
            $effLtr = if ($null -ne $ltr) { $ltr } elseif ($inActiveUni) { $uniLtr } else { $null }
            $prefLtr = if ($ltr) { $ltr } else { Get-AccountPreferredDrive -TargetRemote $rem -DefaultLetter "" }
            $availRaw = @(Get-AvailableDriveLetters -TargetRemote $rem -Preferred $prefLtr -ReservedLetters $reservedInGrid)
            $availSep = @($availRaw | Where-Object { $_ -ne $uniAutoLtr -or $ltr -eq $uniAutoLtr })
            $availLtrs = @($uniChoiceLbl, $hidChoiceLbl) + $availSep
            $selLtr = if ($null -ne $ltr) { $ltr } elseif ($inActiveUni) { $uniChoiceLbl } elseif ($remAssign -eq "Hidden") { $hidChoiceLbl } elseif ($remAssign -eq "Unified") { $uniChoiceLbl } elseif ($prefLtr -and ($availLtrs -contains $prefLtr)) { $prefLtr } elseif ($availSep.Count -gt 0) { $availSep[0] } else { $uniChoiceLbl }
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

            $modeTxt = if ($inActiveUni) { L "mountModeUnified" "Unified Drive" } elseif ($null -ne $m) { if ($m.Mode -eq "Mirror") { L "mountModeMirror" } else { L "mountModeStream" } } elseif ($remAssign -eq "Hidden") { L "mountModeExcluded" "Hidden (Do not show)" } elseif ($remAssign -eq "Unified") { L "mountModeUnified" "Unified Drive" } else { $defModeLoc }
            $uniPoolCnt = if ($null -ne $uniInfo -and $uniInfo.Remotes.Count -gt 0) { $uniInfo.Remotes.Count } else { $remotes.Count }
            $stTxt   = if ($null -ne $ltr) { LF "mountMounted" @((Wrap-Ltr $ltr), $modeTxt) } elseif ($inActiveUni) { LF "unifiedDriveActive" @((Wrap-Ltr $uniLtr), $uniPoolCnt) } elseif ($remAssign -eq "Hidden") { L "accountDriveExcluded" "This account: Hidden (Excluded)" } else { L "mountHidden" }
            $ltrBrush = if ($selLtr -eq $hidChoiceLbl) { "#F87171" } elseif ($selLtr -eq $uniChoiceLbl) { "#FBBF24" } else { "#38BDF8" }
            $newRows += [PSCustomObject]@{
                Remote               = $rem
                DisplayName          = (Get-AccountDisplayLabel -TargetRemote $rem)
                Letter               = $effLtr
                IsUnifiedRow         = $inActiveUni
                SelectedLetter       = $selLtr
                LetterBrush          = $ltrBrush
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

# ==============================================================================
# LIVE ACTIVITY GRID SCROLL ANCHOR (Zero-Jump viewport stability)
# Keeps the row the user is currently reading pinned under the cursor while new
# uploads are inserted, promoted to 100% or auto-dismissed. The wheel is never
# yanked away and the top ceiling stays exactly where the user pinned it.
# ==============================================================================
function Find-VisualChildByType {
    param($Parent, [Type]$Type, [int]$Depth = 0)
    if ($null -eq $Parent -or $Depth -gt 24) { return $null }
    try {
        $count = [System.Windows.Media.VisualTreeHelper]::GetChildrenCount($Parent)
        for ($i = 0; $i -lt $count; $i++) {
            $child = [System.Windows.Media.VisualTreeHelper]::GetChild($Parent, $i)
            if ($null -eq $child) { continue }
            if ($Type.IsInstanceOfType($child)) { return $child }
            $found = Find-VisualChildByType -Parent $child -Type $Type -Depth ($Depth + 1)
            if ($null -ne $found) { return $found }
        }
    } catch {}
    return $null
}

function Get-ActivityScrollViewer {
    try {
        if ($null -eq $GridActivity) { return $null }
        if ($null -ne $script:ActivityScrollViewer -and [object]::ReferenceEquals($script:ActivityScrollViewerTarget, $GridActivity)) {
            return $script:ActivityScrollViewer
        }
        $script:ActivityScrollViewer = Find-VisualChildByType -Parent $GridActivity -Type ([System.Windows.Controls.ScrollViewer])
        $script:ActivityScrollViewerTarget = $GridActivity
        return $script:ActivityScrollViewer
    } catch { return $null }
}

function Get-ActivityScrollAnchor {
    try {
        if ($null -eq $GridActivity -or $null -eq $GridActivity.Items) { return $null }
        $sv = Get-ActivityScrollViewer
        if ($null -eq $sv) { return $null }
        $offset = [double]$sv.VerticalOffset
        $isContentScroll = [bool]$sv.CanContentScroll
        # User is pinned to the top ceiling: always keep the top pinned, never drift
        if ($offset -le 0.51) {
            return [PSCustomObject]@{ PinnedTop = $true; Offset = $offset; Index = -1; Item = $null; Content = $isContentScroll }
        }
        $idx = -1
        $startIdx = if ($isContentScroll) { [int][math]::Floor([math]::Max(0.0, $offset)) } else { 0 }
        for ($i = $startIdx; $i -lt $GridActivity.Items.Count; $i++) {
            $c = $GridActivity.ItemContainerGenerator.ContainerFromIndex($i)
            if ($null -eq $c) { continue }
            $p = $c.TranslatePoint((New-Object System.Windows.Point(0, 0)), $sv)
            if ($p.Y -ge -0.5) { $idx = $i; break }
        }
        $it = if ($idx -ge 0) { $GridActivity.Items[$idx] } else { $null }
        return [PSCustomObject]@{ PinnedTop = $false; Offset = $offset; Index = $idx; Item = $it; Content = $isContentScroll }
    } catch { return $null }
}

function Restore-ActivityScrollAnchor {
    param($Anchor, [double]$RowHeight = 32.0)
    if ($null -eq $Anchor) { return }
    try {
        $sv = Get-ActivityScrollViewer
        if ($null -eq $sv) { return }
        if ($Anchor.PinnedTop) { $sv.ScrollToTop(); return }
        $newIdx = if ($null -ne $Anchor.Item) { $GridActivity.Items.IndexOf($Anchor.Item) } else { -1 }
        if ($newIdx -ge 0 -and $Anchor.Index -ge 0) {
            $delta = [double]($newIdx - $Anchor.Index)
            $target = if ($Anchor.Content) { [double]$Anchor.Offset + $delta } else { [double]$Anchor.Offset + ($delta * $RowHeight) }
            $sv.ScrollToVerticalOffset([math]::Max(0.0, $target))
        } else {
            $sv.ScrollToVerticalOffset([double]$Anchor.Offset)
        }
    } catch {}
}

function Get-ActivityDisplayRank {
    param([int]$Priority, [switch]$IsPreview)
    if ($IsPreview) { return 3 } # Saved preview rows are history, never part of the live queue.
    switch ($Priority) {
        0 { return 0 } # The one active transfer stays first.
        2 { return 1 } # Waiting files retain FIFO order after the active file.
        1 { return 2 } # Completed activity follows the live queue.
        default { return 3 }
    }
}

function Add-FileActivityRow {
    param(
        [string]$State,
        [string]$FileName,
        [string]$Details,
        [string]$TargetRemote = $script:ActiveRemote,
        [int]$Priority = 1,
        [switch]$FromStats,
        [string]$BrushHex = "",
        [double]$ProgressPct = -1
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

    # Per-file upload percentage (drives the slim in-row progress bar)
    $pctVal = 0.0; $pctTxt = ""
    if ($ProgressPct -ge 0) {
        $pctVal = [math]::Round([double]$ProgressPct, 1)
        if ($pctVal -gt 100.0) { $pctVal = 100.0 }
        $pctTxt = "{0:0.#}%" -f $pctVal
    }
    $pctBrush = if ($pctVal -ge 100.0) { "#34D399" } elseif ($Priority -eq 0) { "#5EEAD4" } else { "#64748B" }

    $newItem = [PSCustomObject]@{
        State        = $State
        StateBrush   = $clrHex
        FileName     = $FileName
        Details      = $Details
        Time         = $ts
        Priority     = $Priority
        IsPreview    = [bool]$IsPreview
        CompletedUtc = $doneAt
        ProgressPct  = $pctVal
        ProgressText = $pctTxt
        ProgressBrush = $pctBrush
        ShowProgress = ($ProgressPct -ge 0)
    }

    # Capture the viewport anchor BEFORE mutating the queue so nothing ever jumps
    $scrollAnchor = if ($TargetRemote -eq $script:ActiveRemote) { Get-ActivityScrollAnchor } else { $null }

    # Locate any matching existing row (including middle-ellipsis truncated rows from rclone stats!)
    $existingIdx = -1
    $existingIsPreview = $false
    for ($i = $rt.ActivityItems.Count - 1; $i -ge 0; $i--) {
        if (Test-ActivityRowPathMatch -ExistingPath $rt.ActivityItems[$i].FileName -IncomingPath $FileName) {
            # Never downgrade or truncate an already-completed full-path row back to an ellipsis stat line
            if ($rt.ActivityItems[$i].Priority -eq 1 -and ($Priority -eq 0 -or $Priority -eq 1) -and $FileName.Contains("...") -and -not $rt.ActivityItems[$i].FileName.Contains("...")) { return }
            if ($existingIdx -lt 0) {
                $existingIdx = $i
                $existingIsPreview = $rt.ActivityItems[$i].PSObject.Properties["IsPreview"] -and [bool]$rt.ActivityItems[$i].IsPreview
            } else {
                $rt.ActivityItems.RemoveAt($i)
                # Removing a row below the kept one shifts its index down by exactly one
                if ($existingIdx -gt $i) { $existingIdx-- }
            }
        }
    }

    $shouldReorder = $true
    if ($existingIdx -ge 0) {
        $oldPriority = if ($rt.ActivityItems[$existingIdx].PSObject.Properties["Priority"]) { [int]$rt.ActivityItems[$existingIdx].Priority } else { 1 }
        if ($oldPriority -eq $Priority -and $existingIsPreview -eq [bool]$IsPreview) {
            # Keep the row in place while its progress changes to avoid scroll jumps.
            $rt.ActivityItems[$existingIdx] = $newItem
            $shouldReorder = $false
        } else {
            # A file changes position only when its queue state changes (queued -> active -> completed).
            $rt.ActivityItems.RemoveAt($existingIdx)
        }
    }

    if ($shouldReorder) {
        # One active transfer at the top, queued files next in FIFO order, then completed history.
        $newRank = Get-ActivityDisplayRank -Priority $Priority -IsPreview:$IsPreview
        $insertIdx = $rt.ActivityItems.Count
        for ($i = 0; $i -lt $rt.ActivityItems.Count; $i++) {
            $itemPri = if ($rt.ActivityItems[$i].PSObject.Properties["Priority"]) { [int]$rt.ActivityItems[$i].Priority } else { 1 }
            $itemIsPreview = $rt.ActivityItems[$i].PSObject.Properties["IsPreview"] -and [bool]$rt.ActivityItems[$i].IsPreview
            if ((Get-ActivityDisplayRank -Priority $itemPri -IsPreview:$itemIsPreview) -gt $newRank) {
                $insertIdx = $i
                break
            }
        }
        $rt.ActivityItems.Insert($insertIdx, $newItem)
        while ($rt.ActivityItems.Count -gt 300) { $rt.ActivityItems.RemoveAt($rt.ActivityItems.Count - 1) }
    }

    # Restore the exact viewport the user was reading (pinned top stays pinned)
    if ($TargetRemote -eq $script:ActiveRemote) {
        if ($null -ne $scrollAnchor) {
            Restore-ActivityScrollAnchor -Anchor $scrollAnchor
        } elseif ($Priority -le 1 -and $rt.ActivityItems.Count -gt 0) {
            try { if ($null -ne $GridActivity) { $GridActivity.ScrollIntoView($rt.ActivityItems[0]) } } catch {}
        }
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
        $promoteAnchor = if ($TargetRemote -eq $script:ActiveRemote) { Get-ActivityScrollAnchor } else { $null }
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
                Add-FileActivityRow -State $doneLbl -FileName $oldR.FileName -Details "100%" -TargetRemote $TargetRemote -Priority 1 -ProgressPct 100
            }
        }
        if ($TargetRemote -eq $script:ActiveRemote) { Restore-ActivityScrollAnchor -Anchor $promoteAnchor }
    } catch {}
}

function Refresh-DriveLettersDropdown {
    $cfg = Get-Settings
    $bc = New-Object System.Windows.Media.BrushConverter
    $mounted = Get-MountedLetterForRemote -TargetRemote $script:ActiveRemote
    $assign  = Get-AccountDriveAssignment -TargetRemote $script:ActiveRemote
    $uniAuto = Get-AutoUnifiedDriveLetter
    $starCh  = [string][char]0x2605
    $accPref = Get-AccountPreferredDrive -TargetRemote $script:ActiveRemote -DefaultLetter $(if ($cfg.PreferredDrive) { $cfg.PreferredDrive } else { "G:" })
    $pref = if ($mounted) { $mounted } else { $accPref }
    $avail = @(Get-AvailableDriveLetters -TargetRemote $script:ActiveRemote -Preferred $pref)

    $CmbDriveLetter.Items.Clear()
    $cbiUni = New-Object System.Windows.Controls.ComboBoxItem
    $cbiUni.Content = "$starCh $uniAuto"
    $cbiUni.Tag = "__UNIFIED__"
    $cbiUni.Foreground = $bc.ConvertFromString("#FBBF24")
    $cbiUni.FontWeight = [System.Windows.FontWeights]::Bold
    $cbiUni.FlowDirection = [System.Windows.FlowDirection]::LeftToRight
    $cbiUni.ToolTip = "$(L 'mountModeUnified' 'Show in Unified Drive') ($uniAuto)"
    [void]$CmbDriveLetter.Items.Add($cbiUni)

    $cbiHid = New-Object System.Windows.Controls.ComboBoxItem
    $cbiHid.Content = L "driveChoiceHiddenShort" "$([char]0x2298) Off"
    $cbiHid.Tag = "__HIDDEN__"
    $cbiHid.Foreground = $bc.ConvertFromString("#F87171")
    $cbiHid.FontWeight = [System.Windows.FontWeights]::Bold
    $cbiHid.FlowDirection = [System.Windows.FlowDirection]::LeftToRight
    $cbiHid.ToolTip = L "mountModeExcluded" "Hidden (Do not show)"
    [void]$CmbDriveLetter.Items.Add($cbiHid)

    # Never duplicate the Unified Drive letter as a separate letter unless this account itself holds it separately
    if ($mounted -ne $uniAuto) {
        $avail = @($avail | Where-Object { $_ -ne $uniAuto })
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

    if ($null -eq $mounted -and $assign -eq "Hidden") {
        $CmbDriveLetter.SelectedItem = $cbiHid
        $CmbDriveLetter.Foreground = $bc.ConvertFromString("#F87171")
        $CmbDriveLetter.FontWeight = [System.Windows.FontWeights]::Bold
    } elseif ($null -eq $mounted -and $assign -eq "Unified") {
        $CmbDriveLetter.SelectedItem = $cbiUni
        $CmbDriveLetter.Foreground = $bc.ConvertFromString("#FBBF24")
        $CmbDriveLetter.FontWeight = [System.Windows.FontWeights]::Bold
    } elseif ($null -ne $selItem) {
        $CmbDriveLetter.SelectedItem = $selItem
        $CmbDriveLetter.Foreground = $bc.ConvertFromString("#E2E8F0")
        $CmbDriveLetter.FontWeight = [System.Windows.FontWeights]::SemiBold
    } elseif ($CmbDriveLetter.Items.Count -gt 2) {
        $CmbDriveLetter.SelectedIndex = 2
        $CmbDriveLetter.Foreground = $bc.ConvertFromString("#E2E8F0")
        $CmbDriveLetter.FontWeight = [System.Windows.FontWeights]::SemiBold
    } elseif ($CmbDriveLetter.Items.Count -gt 0) {
        $CmbDriveLetter.SelectedIndex = 0
        $CmbDriveLetter.Foreground = $bc.ConvertFromString("#FBBF24")
        $CmbDriveLetter.FontWeight = [System.Windows.FontWeights]::Bold
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
    param([switch]$ForceRefresh)
    $remotes = @(Get-ConfiguredDriveRemotes -ForceRefresh:$ForceRefresh)
    $script:CachedDriveRemotes = $remotes
    if ($remotes.Count -eq 0) { $remotes = @("gdrive") }
    if ($remotes -notcontains $script:ActiveRemote) { $script:ActiveRemote = $remotes[0] }
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
    param([switch]$FastLocalOnly, [switch]$ForceRefresh)
    if ($script:IsRefreshing) { return }
    $script:IsRefreshing = $true
    try {
        Refresh-ProfilesDropdown -ForceRefresh:$ForceRefresh
        Refresh-DriveLettersDropdown
        Sync-JsonRulesUiForActiveAccount
        $ident = Get-ConnectedGoogleIdentity -TargetRemote $script:ActiveRemote -CacheOnly
        $dispLabel = Get-AccountDisplayLabel -TargetRemote $script:ActiveRemote
        $activeLetter = Get-MountedLetterForRemote -TargetRemote $script:ActiveRemote
        $schedInfo = if ($FastLocalOnly) { [PSCustomObject]@{ Active = $false; Label = (L "scheduleOff" "OFF (Manual Only)") } } else { Get-ScheduleInfo -TargetRemote $script:ActiveRemote }
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
            if ($null -ne $TxtSettingsAccount) { $TxtSettingsAccount.Text = if ($idDisplay -ieq $dispLabel) { Wrap-Ltr $dispLabel } else { Wrap-Ltr "$dispLabel  --  $idDisplay" } }
            if ($null -ne $DotSettingsAccount) { $DotSettingsAccount.Fill = $bc.ConvertFromString("#10B981") }
            if ($null -ne $BtnAuthToggle) {
                $BtnAuthToggle.Content = L "signOut"
                $BtnAuthToggle.Background  = $bc.ConvertFromString("#162238")
                $BtnAuthToggle.BorderBrush = $bc.ConvertFromString("#273A57")
            }
            $BtnCustomClientId.Content = if ($ident.HasCustomClientId) { L "apiKeyActive" } else { L "apiKey" }
            Update-DriveQuotaDisplay -UseCache
        } else {
            $TxtAccountStatus.Text = L "accountNotSignedIn"
            $TxtAccountStatus.ToolTip = $null
            $DotAccount.Fill = $bc.ConvertFromString("#F59E0B")
            if ($null -ne $TxtSettingsAccount) { $TxtSettingsAccount.Text = L "accountNotSignedIn" }
            if ($null -ne $DotSettingsAccount) { $DotSettingsAccount.Fill = $bc.ConvertFromString("#F59E0B") }
            if ($null -ne $BtnAuthToggle) {
                $BtnAuthToggle.Content = L "signIn"
                $BtnAuthToggle.Background  = $bc.ConvertFromString("#0284C7")
                $BtnAuthToggle.BorderBrush = $bc.ConvertFromString("#38BDF8")
            }
            $BtnCustomClientId.Content = L "apiKey"
            Update-DriveQuotaDisplay -UseCache
        }

        $assignActive = Get-AccountDriveAssignment -TargetRemote $script:ActiveRemote
        $uniInfoActive = Get-UnifiedMountInfo
        $uniLtrActive  = if ($null -ne $uniInfoActive) { $uniInfoActive.Letter } else { $null }
        $uniAutoLtr    = Get-AutoUnifiedDriveLetter
        $inActiveUni   = ($null -eq $activeLetter -and $null -ne $uniLtrActive -and (($uniInfoActive.Remotes.Count -gt 0 -and ($uniInfoActive.Remotes -contains $script:ActiveRemote)) -or ($uniInfoActive.Remotes.Count -eq 0 -and $assignActive -ne "Hidden")))

        $mModeRaw = (Get-Settings).MountMode
        $mModeLoc = if ($mModeRaw -eq "Mirror") { L "mountModeMirror" } else { L "mountModeStream" }
        $CmbMountMode.IsEnabled = $true
        $starCh = [string][char]0x2605
        if ($null -ne $activeLetter) {
            $CmbMountMode.SelectedIndex = if ($mModeRaw -eq "Mirror") { 1 } else { 0 }
            $TxtMountStatus.Text = LF "mountMounted" @((Wrap-Ltr $activeLetter), $mModeLoc)
            $DotMount.Fill = $bc.ConvertFromString("#10B981")
            $BtnMount.Content = "$(L 'hideDrive') ($(Wrap-Ltr $activeLetter))"
            $BtnMount.Background  = $bc.ConvertFromString("#162238")
            $BtnMount.BorderBrush = $bc.ConvertFromString("#38BDF8")
        } elseif ($inActiveUni) {
            $CmbMountMode.SelectedIndex = 2
            $poolCnt = if ($null -ne $uniInfoActive -and $uniInfoActive.Remotes.Count -gt 0) { $uniInfoActive.Remotes.Count } else { (@(Get-UnifiedPoolRemotes)).Count }
            $uniLtrTok = if ($script:CurrentLocale -and $script:CurrentLocale.rtl) { "$(Wrap-Ltr $uniLtrActive)$($script:RLM)" } else { Wrap-Ltr $uniLtrActive }
            $TxtMountStatus.Text = LF "unifiedDriveActive" @($uniLtrTok, $poolCnt)
            $DotMount.Fill = $bc.ConvertFromString("#FBBF24")
            $BtnMount.Content = "$(L 'hideAccountFromUnified' 'Hide this account from') $(Wrap-Ltr "$starCh $uniLtrActive")"
            $BtnMount.Background  = $bc.ConvertFromString("#261D0B")
            $BtnMount.BorderBrush = $bc.ConvertFromString("#D97706")
        } elseif ($assignActive -eq "Hidden") {
            $CmbMountMode.SelectedIndex = 3
            $TxtMountStatus.Text = L "accountDriveExcluded" "This account: Hidden (Excluded)"
            $DotMount.Fill = $bc.ConvertFromString("#64748B")
            if ($dlCur -eq "Unified" -or $null -ne $uniLtrActive) {
                $showUniLtr = if ($null -ne $uniLtrActive) { $uniLtrActive } else { $uniAutoLtr }
                $BtnMount.Content = "$(L 'showAccountInUnified' 'Show this account in') $(Wrap-Ltr "$starCh $showUniLtr")"
            } else {
                $prefShow = Get-AccountPreferredDrive -TargetRemote $script:ActiveRemote -DefaultLetter ""
                $avShow = @(Get-AvailableDriveLetters -TargetRemote $script:ActiveRemote -Preferred $prefShow)
                $showSepLtr = if ($avShow.Count -gt 0) { $avShow[0] } else { $uniAutoLtr }
                $BtnMount.Content = "$(L 'showDrive') ($(Wrap-Ltr $showSepLtr))"
            }
            $BtnMount.Background  = $bc.ConvertFromString("#0E7490")
            $BtnMount.BorderBrush = $bc.ConvertFromString("#06B6D4")
        } elseif ($assignActive -eq "Unified") {
            $CmbMountMode.SelectedIndex = 2
            $TxtMountStatus.Text = L "mountHidden"
            $DotMount.Fill = $bc.ConvertFromString("#475569")
            $BtnMount.Content = "$(L 'showAccountInUnified' 'Show this account in') $(Wrap-Ltr "$starCh $uniAutoLtr")"
            $BtnMount.Background  = $bc.ConvertFromString("#B45309")
            $BtnMount.BorderBrush = $bc.ConvertFromString("#FBBF24")
        } else {
            $CmbMountMode.SelectedIndex = if ($mModeRaw -eq "Mirror") { 1 } else { 0 }
            $selL = Get-SelectedDriveLetter
            if ($selL -eq "__UNIFIED__" -or $selL -eq "__HIDDEN__") { $selL = $uniAutoLtr }
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

        try { Update-FoldersGrid } catch {}
        try { Refresh-MultiDrivesGrid -ForceRefresh:$ForceRefresh } catch {}
        try { Switch-AccountActivityView } catch {}
        try { Refresh-SidebarAccountsOverview -ForceRefresh:$ForceRefresh } catch {}
        try { Refresh-SettingsAccountsList -ForceRefresh:$ForceRefresh } catch {}
    } catch {
        Write-StudioLog "[WARN] Header refresh notice: $($_.Exception.Message)"
    } finally { $script:IsRefreshing = $false }
}

# ==============================================================================
