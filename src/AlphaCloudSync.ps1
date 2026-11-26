param(
    [ValidateSet("GUI", "Sync", "DryRun", "Restore", "Mount", "Unmount", "Auth", "Status", "ContextAdd", "ContextSync", "ContextPreview", "ContextRemove")]
    [string]$Action = "GUI",
    [string]$RemoteName = "",
    [string]$DriveLetter = "",
    [string]$FolderName = "",
    [string]$TargetPath = "",
    [switch]$Minimized,
    [switch]$AutoStartSync
)

$ErrorActionPreference = "Continue"
try { [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12 } catch {}
if (-not [string]::IsNullOrWhiteSpace($RemoteName)) {
    if ($RemoteName -notmatch '^[A-Za-z0-9][A-Za-z0-9_-]*$' -or $RemoteName -ieq "__UNIFIED__") {
        [Console]::Error.WriteLine("ERROR: Invalid -RemoteName parameter.")
        exit 1
    }
}
if (-not [string]::IsNullOrWhiteSpace($DriveLetter)) {
    if ($DriveLetter -notmatch '^[A-Za-z]:$') {
        [Console]::Error.WriteLine("ERROR: Invalid -DriveLetter parameter (expected format like G:).")
        exit 1
    }
    $DriveLetter = $DriveLetter.ToUpperInvariant()
}

$script:LastAboutCache = @{}
$script:IdentityCache  = @{}
$AppName      = "AlphaCloudSync"
$ScriptSelf   = $MyInvocation.MyCommand.Path
$ScriptDir    = Split-Path -Parent $ScriptSelf
$ProjectRoot  = if (-not [string]::IsNullOrWhiteSpace($env:ALPHACLOUDSYNC_RUNTIME_ROOT) -and (Test-Path -LiteralPath $env:ALPHACLOUDSYNC_RUNTIME_ROOT)) {
    $env:ALPHACLOUDSYNC_RUNTIME_ROOT
} else {
    Split-Path -Parent $ScriptDir
}
$AppVersion = if ($env:ALPHACLOUDSYNC_VERSION -match '^\d+\.\d+\.\d+$') {
    $env:ALPHACLOUDSYNC_VERSION
} else {
    $versionFile = Join-Path $ProjectRoot "VERSION"
    if (Test-Path -LiteralPath $versionFile) {
        (Get-Content -LiteralPath $versionFile -Raw).Trim()
    } else {
        "0.0.0"
    }
}
$PresetsDir     = Join-Path $ProjectRoot "presets"
$LocalesDir     = Join-Path $ProjectRoot "locales"
$AssetsDir      = Join-Path $ProjectRoot "assets"
$AppIconPath    = Join-Path $AssetsDir "AlphaCloudSync-icon.ico"
$FolderIconPath = Join-Path $AssetsDir "AlphaCloudSync-folder.ico"
$AppLogoPngPath = Join-Path $AssetsDir "AlphaCloudSync-icon.png"
$RunRegPath     = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run"

$AppDataDir   = Join-Path $env:APPDATA "AlphaCloudSync"
$IconsStoreDir = Join-Path $AppDataDir "icons"
$LocalDataDir = Join-Path $env:LOCALAPPDATA "AlphaCloudSync"
$LocalBinDir  = Join-Path $LocalDataDir "bin"
$LocalLogsDir = Join-Path $LocalDataDir "logs"
$RestoreBkDir = Join-Path $LocalDataDir "restore-backups"
$ProfilesDir  = Join-Path $AppDataDir "profiles"
$MountsFile   = Join-Path $AppDataDir "mounts-state.json"
$AccountPrefsFile = Join-Path $AppDataDir "account-prefs.json"
$SettingsPath = Join-Path $AppDataDir "settings.json"
$HealthPath   = Join-Path $AppDataDir "backup-health.json"
$IpcCmdFile   = Join-Path $LocalDataDir "ipc-command.json"
$IpcQueueDir  = Join-Path $LocalDataDir "ipc-queue"
$UiAccountCacheFile = Join-Path $LocalDataDir "ui-account-cache.json"

foreach ($d in @($AppDataDir, $IconsStoreDir, $LocalBinDir, $LocalLogsDir, $RestoreBkDir, $ProfilesDir, $IpcQueueDir)) {
    if (-not (Test-Path -LiteralPath $d)) {
        New-Item -ItemType Directory -Path $d -Force | Out-Null
    }
}

$StableFolderIconPath = Join-Path $IconsStoreDir "AlphaCloudSync-folder.ico"
$StableAppIconPath    = Join-Path $IconsStoreDir "AlphaCloudSync-icon.ico"
try {
    if (Test-Path -LiteralPath $FolderIconPath) {
        if (-not (Test-Path -LiteralPath $StableFolderIconPath) -or ((Get-Item -LiteralPath $FolderIconPath).Length -ne (Get-Item -LiteralPath $StableFolderIconPath).Length)) {
            Copy-Item -LiteralPath $FolderIconPath -Destination $StableFolderIconPath -Force -ErrorAction SilentlyContinue
        }
    }
    if (Test-Path -LiteralPath $AppIconPath) {
        if (-not (Test-Path -LiteralPath $StableAppIconPath) -or ((Get-Item -LiteralPath $AppIconPath).Length -ne (Get-Item -LiteralPath $StableAppIconPath).Length)) {
            Copy-Item -LiteralPath $AppIconPath -Destination $StableAppIconPath -Force -ErrorAction SilentlyContinue
        }
    }
} catch {}

$AppLaunchExe = if (-not [string]::IsNullOrWhiteSpace($env:ALPHACLOUDSYNC_EXE_PATH) -and (Test-Path -LiteralPath $env:ALPHACLOUDSYNC_EXE_PATH)) {
    $env:ALPHACLOUDSYNC_EXE_PATH
} else {
    $null
}

# ==============================================================================
# MODULAR RUNTIME LOADER (Core -> Cloud Providers -> Engines -> Headless / GUI)
# ==============================================================================
$ModulesDir = Join-Path $ScriptDir "modules"
foreach ($coreMod in @("Core.Helpers.ps1", "Core.Config.ps1", "Core.Rclone.ps1", "Core.Shell.ps1")) {
    . (Join-Path $ModulesDir $coreMod)
}
Set-SplashStage "2"

# Load Provider Registry + Auto-Discover All Cloud Provider Modules (Google Drive, future OneDrive/Dropbox/S3...)
$ProvidersDir = Join-Path $ModulesDir "Providers"
. (Join-Path $ProvidersDir "Provider.Registry.ps1")
foreach ($provScript in (Get-ChildItem -LiteralPath $ProvidersDir -Filter "Provider.*.ps1" -File | Where-Object { $_.Name -ne "Provider.Registry.ps1" } | Sort-Object Name)) {
    . $provScript.FullName
}

foreach ($engMod in @("Engine.Mount.ps1", "Engine.Headless.ps1")) {
    . (Join-Path $ModulesDir $engMod)
}

# Initialize User Settings, Active Locale & rclone Core
$Settings = Get-Settings
$script:CurrentLocale = Get-LocaleDict -LangCode $Settings.Language
if ([string]::IsNullOrWhiteSpace($RemoteName))  { $RemoteName  = $Settings.ActiveRemote }
if ([string]::IsNullOrWhiteSpace($DriveLetter)) { $DriveLetter = $Settings.PreferredDrive }

$script:PendingContextAction = ""
$script:PendingContextPath   = ""

# Windows Explorer Right-Click Context Menu actions: forward atomically to live GUI queue if running, else launch GUI with pending action!
if ($Action -in @("ContextAdd", "ContextSync", "ContextPreview", "ContextRemove")) {
    $cleanTarget = ""
    if (-not [string]::IsNullOrWhiteSpace($TargetPath)) {
        $rawTarget = $TargetPath.Trim().Trim('"')
        try { $cleanTarget = [System.IO.Path]::GetFullPath($rawTarget) } catch { $cleanTarget = $rawTarget }
        if ($cleanTarget.Length -gt 3) { $cleanTarget = $cleanTarget.TrimEnd('\') }
    }
    $forwarded = $false
    try {
        $evt = [System.Threading.EventWaitHandle]::OpenExisting("Local\AlphaCloudSync_RestoreSignal")
        if ($null -ne $evt) {
            $ipcPayload = ConvertTo-Json -InputObject ([PSCustomObject]@{ Action = $Action; Path = $cleanTarget }) -Compress
            $qStamp = "$([datetime]::UtcNow.Ticks)_$PID"
            $qTmp   = Join-Path $IpcQueueDir "$qStamp.tmp"
            $qFin   = Join-Path $IpcQueueDir "$qStamp.json"
            [System.IO.File]::WriteAllText($qTmp, $ipcPayload, (New-Object System.Text.UTF8Encoding($false)))
            [System.IO.File]::Move($qTmp, $qFin)
            $null = $evt.Set()
            $evt.Dispose()
            $forwarded = $true
        }
    } catch {}
    if ($forwarded) { exit 0 }
    $script:PendingContextAction = $Action
    $script:PendingContextPath   = $cleanTarget
    $Action = "GUI"
}

$RcloneExe = if ($Action -eq "GUI") { Ensure-RcloneInstalledInteractive } else { Find-RcloneExe }
if ([string]::IsNullOrWhiteSpace($RcloneExe)) {
    [Console]::Error.WriteLine("ERROR: rclone.exe not found.")
    exit 1
}

# Fast Headless CLI Path (Zero WPF overhead when running Status / Sync / DryRun / Restore / Mount / Unmount / Auth)
if ($Action -ne "GUI") {
    Invoke-HeadlessCliDispatch -CliAction $Action
    exit 0
}

# Load Native Dark Fluent Desktop Studio UI Modules
foreach ($uiMod in @("UI.Interop.ps1", "UI.ThemeAndLayout.ps1", "UI.ShellAndIsland.ps1", "UI.Presenter.ps1", "UI.SyncAndHandlers.ps1")) {
    . (Join-Path $ModulesDir $uiMod)
}

# ==============================================================================
# INITIALIZE UI CONTROLS FROM SETTINGS & LAUNCH
# ==============================================================================
$script:IsRefreshing = $true
$TxtComputerLabel.Text         = $Settings.ComputerLabel
$ChkCloudIsland.IsChecked      = [bool]$Settings.ShowCloudIsland
$ChkFolderBadges.IsChecked     = [bool]$Settings.ShowFolderBadges
$ChkExplorerMenu.IsChecked     = [bool]$Settings.ExplorerContextMenu
$ChkAutoWatchSync.IsChecked    = [bool]$Settings.AutoWatchSync
$ChkNotifMaster.IsChecked      = [bool]$Settings.NotificationsEnabled
$ChkNotifManual.IsChecked      = [bool]$Settings.NotifyManualSync
$ChkNotifAutoSync.IsChecked    = [bool]$Settings.NotifyAutoSync
$ChkNotifErrors.IsChecked      = [bool]$Settings.NotifyErrors
$ChkNotifDriveEvents.IsChecked = [bool]$Settings.NotifyDriveEvents
Update-NotificationSubState
$CmbDeletePolicy.SelectedIndex = switch ($Settings.DeletePolicy) { "Copy-Only" { 1 } "Strict Mirror" { 2 } default { 0 } }
$CmbSpeedPreset.SelectedIndex  = switch ($Settings.SpeedPreset)  { "Balanced"  { 1 } "Eco"           { 2 } default { 0 } }
$CmbMaxDelete.SelectedIndex    = switch ([int]$Settings.MaxDeleteLimit) { 200 { 1 } 500 { 2 } 1000 { 3 } 5000 { 4 } default { 0 } }
$CmbMountMode.SelectedIndex    = if ($Settings.DriveLayout -eq "Unified") { 2 } elseif ($Settings.MountMode -eq "Mirror") { 1 } else { 0 }
$langCodeInit = if ([string]::IsNullOrWhiteSpace($Settings.Language)) { "en" } else { $Settings.Language.ToLowerInvariant() }
$langIdxMap = @{ "en" = 0; "ar" = 1; "es" = 2; "fr" = 3; "de" = 4; "zh" = 5; "id" = 6 }
$CmbLanguage.SelectedIndex = if ($langIdxMap.ContainsKey($langCodeInit)) { $langIdxMap[$langCodeInit] } else { 0 }
$script:IsRefreshing = $false

Apply-UiLanguage -Lang $langCodeInit -SkipShellSync
Select-StudioTab "Folders"
Set-SplashStage "3"
Load-UiAccountCache
$script:SkipWmiMountProbe = $true
Refresh-StudioHeader -FastLocalOnly
Set-SplashStage "4"
$script:SkipWmiMountProbe = $false
$null = Get-MountsState
Set-SplashStage "5"
Write-StudioLog -Msg "AlphaCloudSync v$AppVersion Studio ready (Instant Launch, Sequential Account Hydration, Modular Core, 7 Languages)." -TargetRemote $script:ActiveRemote

if ($null -eq $window) {
    Set-SplashStage "DONE"
    [Console]::Error.WriteLine("FATAL: Failed to initialize MainWindow WPF XAML.")
    exit 1
}

$script:WpfApp = [System.Windows.Application]::Current
if ($null -eq $script:WpfApp) { $script:WpfApp = New-Object System.Windows.Application }
$script:WpfApp.ShutdownMode = [System.Windows.ShutdownMode]::OnExplicitShutdown
$script:WpfApp.MainWindow   = $window

if (-not $Minimized) {
    $window.Add_ContentRendered({
        try {
            Set-SplashStage "DONE"
            Bring-MainWindowToForeground -InitialLaunch
            $window.Dispatcher.BeginInvoke([Action]{ Invoke-PostStartupHousekeep }, [System.Windows.Threading.DispatcherPriority]::Background) | Out-Null
        } catch {
            Set-SplashStage "DONE"
        }
    })
    $window.Topmost = $true
    $window.Show()
} else {
    Set-SplashStage "DONE"
    $window.Dispatcher.BeginInvoke([Action]{ Invoke-PostStartupHousekeep }, [System.Windows.Threading.DispatcherPriority]::ApplicationIdle) | Out-Null
}
[void]$script:WpfApp.Run()
