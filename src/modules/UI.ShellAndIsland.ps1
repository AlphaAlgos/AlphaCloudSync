# ==============================================================================
# AlphaCloudSync Module: UI.ShellAndIsland (Navigation, Runtime State, WindowChrome, Modals Factory, Cloud Island, Tray & Notifications)
# ==============================================================================

# ==============================================================================
# NAVIGATION CONTROLLER (4 CLEAN STUDIO VIEWS)
# ==============================================================================
$script:ActiveTab = "Folders"
function Select-StudioTab {
    param([string]$TabName)
    $script:ActiveTab = $TabName
    $bc = New-Object System.Windows.Media.BrushConverter
    $PanelFolders.Visibility  = if ($TabName -eq "Folders")  { "Visible" } else { "Collapsed" }
    $PanelActivity.Visibility = if ($TabName -eq "Activity") { "Visible" } else { "Collapsed" }
    $PanelStorage.Visibility  = if ($TabName -eq "Storage")  { "Visible" } else { "Collapsed" }
    $PanelSettings.Visibility = if ($TabName -eq "Settings") { "Visible" } else { "Collapsed" }

    $map = @(
        @{ Key="Folders";  Btn=$BtnNavFolders;  Ind=$IndNavFolders  },
        @{ Key="Activity"; Btn=$BtnNavActivity; Ind=$IndNavActivity },
        @{ Key="Storage";  Btn=$BtnNavStorage;  Ind=$IndNavStorage  },
        @{ Key="Settings"; Btn=$BtnNavSettings; Ind=$IndNavSettings }
    )
    foreach ($item in $map) {
        if ($item.Key -eq $TabName) {
            $item.Btn.Background = $bc.ConvertFromString("#13233D")
            $item.Btn.Foreground = $bc.ConvertFromString("#F8FAFC")
            $item.Ind.Background = $bc.ConvertFromString("#38BDF8")
        } else {
            $item.Btn.Background = [System.Windows.Media.Brushes]::Transparent
            $item.Btn.Foreground = $bc.ConvertFromString("#94A3B8")
            $item.Ind.Background = [System.Windows.Media.Brushes]::Transparent
        }
    }
    if ($TabName -eq "Storage") { Refresh-MultiDrivesGrid }
    if ($TabName -eq "Settings") { Refresh-SettingsAccountsList }
}

$BtnNavFolders.Add_Click({  Select-StudioTab "Folders"  })
$BtnNavActivity.Add_Click({ Select-StudioTab "Activity" })
$BtnNavStorage.Add_Click({  Select-StudioTab "Storage"  })
$BtnNavSettings.Add_Click({ Select-StudioTab "Settings" })

$script:ActiveSettingsSubTab = "Accounts"
function Select-SettingsSubTab {
    param([string]$SubTab = "Accounts")
    $script:ActiveSettingsSubTab = $SubTab
    $bc = New-Object System.Windows.Media.BrushConverter
    $CardSetAccounts.Visibility = if ($SubTab -eq "Accounts") { "Visible" } else { "Collapsed" }
    $CardSetSync.Visibility     = if ($SubTab -eq "Sync")     { "Visible" } else { "Collapsed" }
    $CardSetBackup.Visibility   = if ($SubTab -eq "Backup")   { "Visible" } else { "Collapsed" }
    $CardSetGeneral.Visibility  = if ($SubTab -eq "General")  { "Visible" } else { "Collapsed" }
    $CardSetNotif.Visibility    = if ($SubTab -eq "Notif")    { "Visible" } else { "Collapsed" }

    $subMap = @(
        @{ Key = "Accounts"; Btn = $BtnSetTabAccounts },
        @{ Key = "Sync";     Btn = $BtnSetTabSync     },
        @{ Key = "Backup";   Btn = $BtnSetTabBackup   },
        @{ Key = "General";  Btn = $BtnSetTabGeneral  },
        @{ Key = "Notif";    Btn = $BtnSetTabNotif    }
    )
    foreach ($st in $subMap) {
        if ($null -eq $st.Btn) { continue }
        if ($st.Key -eq $SubTab) {
            $st.Btn.Background  = $bc.ConvertFromString("#13233A")
            $st.Btn.BorderBrush = $bc.ConvertFromString("#38BDF8")
            $st.Btn.Foreground  = $bc.ConvertFromString("#F8FAFC")
        } else {
            $st.Btn.Background  = $bc.ConvertFromString("#0B1322")
            $st.Btn.BorderBrush = $bc.ConvertFromString("#1E2C42")
            $st.Btn.Foreground  = $bc.ConvertFromString("#94A3B8")
        }
    }
}

$BtnSetTabAccounts.Add_Click({ Select-SettingsSubTab "Accounts" })
$BtnSetTabSync.Add_Click({     Select-SettingsSubTab "Sync"     })
$BtnSetTabBackup.Add_Click({   Select-SettingsSubTab "Backup"   })
$BtnSetTabGeneral.Add_Click({  Select-SettingsSubTab "General"  })
$BtnSetTabNotif.Add_Click({    Select-SettingsSubTab "Notif"    })

# ==============================================================================
# STATE, BATCH TRACKING & PER-JOB UNIQUE LOGS
# ==============================================================================
$script:ActiveProcess        = $null
$script:ActiveJobLogFile     = $null
$script:ActiveFilesFromFile  = $null
$script:ActiveTargetFiles    = $null
$script:CurrentFolderPath    = $null
$script:FoldersGridHydrated  = $false
$script:IsActivityDotPulsing = $false
$script:IsHandlingIpc        = $false
$script:WatchExcludeCacheKey = ""
$script:WatchExcludeCacheLines = @()
$script:JobSeq               = 0
$script:IsSyncRunning        = $false
$script:SyncingRemote        = $null
$script:WasPausedByUser      = $false
$script:WatchResumeAfterUtc  = [datetime]::MinValue
$script:LastBatchMode        = "Sync"
$script:LastBatchOnlyFolder  = ""
$script:IsSignedIn           = $false
$script:LastTrashBytes       = 0.0
$script:JobQueue             = New-Object System.Collections.Queue
$script:CurrentFolder        = $null
$script:BatchTotalFolders    = 0
$script:BatchCurrentIndex    = 0
$script:BatchTotalWeight     = 1.0
$script:BatchCompletedWeight = 0.0
$script:BatchCurrentWeight   = 1.0
$script:LastOverallPct       = 0.0
$script:LastSpeedTxt         = ""
$script:LastEtaTxt           = ""
$script:LastFilesSummary     = ""
$script:ActiveRemote         = $RemoteName
$script:AccountRuntimeMap    = @{}
$script:FolderItems          = New-Object System.Collections.ObjectModel.ObservableCollection[object]
$script:MultiDriveItems      = New-Object System.Collections.ObjectModel.ObservableCollection[object]
$script:SidebarAccountCards  = New-Object System.Collections.ObjectModel.ObservableCollection[object]
$script:SettingsAccountCards = New-Object System.Collections.ObjectModel.ObservableCollection[object]
$script:SeenLogLines         = @{}
$script:UploadedCount        = 0
$script:IsRefreshing         = $false
$script:UiLang               = if ([string]::IsNullOrWhiteSpace($Settings.Language)) { "en" } else { $Settings.Language.ToLowerInvariant() }
$script:RestoreStateTray     = [System.Windows.WindowState]::Normal
$script:IslandWindow         = $null
$script:IslandEnabled        = [bool]$Settings.ShowCloudIsland
$script:IslandCollapseTimer  = $null
$script:AutoWatchEnabled     = [bool]$Settings.AutoWatchSync
$script:LastBatchIsAuto      = $false
$script:BatchHadError        = $false
$script:WatchHub             = $null
$script:PendingAutoSyncFolders = @()
try { if ("AlphaFolderWatchHub" -as [type]) { $script:WatchHub = New-Object AlphaFolderWatchHub } } catch {}

function Get-AccountRuntime {
    param([string]$TargetRemote = $script:ActiveRemote)
    if ([string]::IsNullOrWhiteSpace($TargetRemote)) { $TargetRemote = "gdrive" }
    if (-not $script:AccountRuntimeMap.ContainsKey($TargetRemote)) {
        $script:AccountRuntimeMap[$TargetRemote] = [PSCustomObject]@{
            Remote            = $TargetRemote
            LogBuilder        = (New-Object System.Text.StringBuilder)
            ActivityItems     = (New-Object System.Collections.ObjectModel.ObservableCollection[object])
            RecentlyCompleted = (New-Object System.Collections.Generic.List[object])
            UploadedCount     = 0
            ArchivedCount     = 0
            PreviewCount      = 0
            LastOverallPct    = 0.0
            LastSpeedTxt      = ""
            LastEtaTxt        = ""
            LastFilesSummary  = ""
            WasPausedByUser   = $false
            CountersText      = ""
            LiveTransferText  = ""
            ProgressPctText   = "0.0%"
            BatchTotalFolders = 0
            BatchCurrentIndex = 0
            CurrentFolder     = ""
        }
    }
    return $script:AccountRuntimeMap[$TargetRemote]
}

$GridActivity.ItemsSource        = (Get-AccountRuntime -TargetRemote $script:ActiveRemote).ActivityItems
$GridFolders.ItemsSource         = $script:FolderItems
$GridMultiDrives.ItemsSource     = $script:MultiDriveItems
$ListSidebarAccounts.ItemsSource = $script:SidebarAccountCards
if ($null -ne $ListSettingsAccounts) { $ListSettingsAccounts.ItemsSource = $script:SettingsAccountCards }

# ==============================================================================
# WINDOWCHROME SYMMETRIC MAXIMIZE PADDING & MULTI-DPI CLAMPING
# ==============================================================================
function Update-WindowChromeMaximizeMargin {
    try {
        if ($window.WindowState -eq [System.Windows.WindowState]::Maximized) {
            $WindowOuterBorder.BorderThickness = [System.Windows.Thickness]::new(0)
            $WindowOuterBorder.Padding = [System.Windows.Thickness]::new(7)
            $PathMaxIcon.Data = [System.Windows.Media.Geometry]::Parse("M 2,2 V 0 H 10 V 8 H 8 M 0,2 H 8 V 10 H 0 Z")
            $BtnTitleMax.ToolTip = L "tipRestore" "Restore Down"
        } else {
            $WindowOuterBorder.BorderThickness = [System.Windows.Thickness]::new(1)
            $WindowOuterBorder.Padding = [System.Windows.Thickness]::new(0)
            $PathMaxIcon.Data = [System.Windows.Media.Geometry]::Parse("M 0,0 H 10 V 10 H 0 Z")
            $BtnTitleMax.ToolTip = L "tipMaximize" "Maximize"
        }
    } catch {}
}

function Update-ResponsiveLayout {
    try {
        $aw = $window.ActualWidth
        if ($aw -le 0) { return }
        $TxtWindowSubtitle.Visibility = if ($aw -lt 960) { "Collapsed" } else { "Visible" }
        $GridQuotaMetrics.Columns = if ($aw -lt 960) { 2 } else { 4 }
    } catch {}
}

function Save-CurrentWindowBounds {
    try {
        $cfg = Get-Settings
        $rb = if ($window.WindowState -eq [System.Windows.WindowState]::Normal) {
            [System.Windows.Rect]::new($window.Left, $window.Top, $window.Width, $window.Height)
        } else { $window.RestoreBounds }
        if ($rb.Width -gt 100 -and $rb.Height -gt 100 -and -not [double]::IsNaN($rb.Left) -and -not [double]::IsInfinity($rb.Left)) {
            $cfg.WindowBounds = [PSCustomObject]@{
                Left   = [math]::Round($rb.Left, 1)
                Top    = [math]::Round($rb.Top, 1)
                Width  = [math]::Round($rb.Width, 1)
                Height = [math]::Round($rb.Height, 1)
                State  = if ($window.WindowState -eq [System.Windows.WindowState]::Maximized) { "Maximized" } else { "Normal" }
            }
            Save-Settings -Obj $cfg
        }
    } catch {}
}

$sb = $Settings.WindowBounds
$hintL = if ($sb -and $null -ne $sb.Left)   { [Nullable[double]][double]$sb.Left   } else { $null }
$hintT = if ($sb -and $null -ne $sb.Top)    { [Nullable[double]][double]$sb.Top    } else { $null }
$hintW = if ($sb -and $null -ne $sb.Width)  { [Nullable[double]][double]$sb.Width  } else { $null }
$hintH = if ($sb -and $null -ne $sb.Height) { [Nullable[double]][double]$sb.Height } else { $null }
$waInfo = Get-ScreenWorkAreaDip -HintLeftDip $hintL -HintTopDip $hintT -HintWDip $(if ($hintW) { $hintW } else { 1160 }) -HintHDip $(if ($hintH) { $hintH } else { 750 })
$clamped = Compute-ClampedWindowBounds -WorkLeft $waInfo.Rect.Left -WorkTop $waInfo.Rect.Top -WorkWidth $waInfo.Rect.Width -WorkHeight $waInfo.Rect.Height `
    -SavedLeft $hintL -SavedTop $hintT -SavedWidth $hintW -SavedHeight $hintH -UseSavedPosition $waInfo.MatchedSaved
$window.MinWidth  = $clamped.MinWidth
$window.MinHeight = $clamped.MinHeight
$window.Width     = $clamped.Width
$window.Height    = $clamped.Height
$window.Left      = $clamped.Left
$window.Top       = $clamped.Top

$window.Add_SourceInitialized({
    if (-not $Minimized -and $sb -and $sb.State -eq "Maximized") {
        $window.WindowState = [System.Windows.WindowState]::Maximized
    }
    Update-WindowChromeMaximizeMargin
    Update-ResponsiveLayout
})
$window.Add_StateChanged({
    $window.Dispatcher.BeginInvoke([Action]{ Update-WindowChromeMaximizeMargin }, [System.Windows.Threading.DispatcherPriority]::Loaded) | Out-Null
})
$window.Add_SizeChanged({
    Update-WindowChromeMaximizeMargin
    Update-ResponsiveLayout
})

function Bring-MainWindowToForeground {
    param([switch]$InitialLaunch)
    try {
        if (-not $window.IsVisible) { $window.Show() }
        if ($window.WindowState -eq [System.Windows.WindowState]::Minimized) {
            $window.WindowState = if ($script:RestoreStateTray -eq [System.Windows.WindowState]::Maximized) { [System.Windows.WindowState]::Maximized } else { [System.Windows.WindowState]::Normal }
        }
        $window.Topmost = $true
        $null = $window.Activate()
        $null = $window.Focus()
        if ("AlphaWinShellHelper" -as [type]) {
            $hwnd = (New-Object System.Windows.Interop.WindowInteropHelper $window).Handle
            if ($hwnd -ne [IntPtr]::Zero) { [AlphaWinShellHelper]::ForceForeground($hwnd) }
        }
        if ($InitialLaunch) {
            $window.Dispatcher.BeginInvoke([Action]{
                try {
                    if ("AlphaWinShellHelper" -as [type]) {
                        $h2 = (New-Object System.Windows.Interop.WindowInteropHelper $window).Handle
                        if ($h2 -ne [IntPtr]::Zero) { [AlphaWinShellHelper]::ForceForeground($h2) }
                    }
                    $null = $window.Activate()
                    $window.Topmost = $false
                } catch {}
            }, [System.Windows.Threading.DispatcherPriority]::ApplicationIdle) | Out-Null
        } else {
            $window.Topmost = $false
        }
        Update-WindowChromeMaximizeMargin
    } catch {}
}

function Restore-MainWindowFromTray {
    try {
        $window.Show()
        $window.WindowState = $script:RestoreStateTray
        Bring-MainWindowToForeground
    } catch {}
}

function Hide-MainWindowToTray {
    try {
        Save-CurrentWindowBounds
        $script:RestoreStateTray = if ($window.WindowState -eq [System.Windows.WindowState]::Maximized) { [System.Windows.WindowState]::Maximized } else { [System.Windows.WindowState]::Normal }
        $window.Hide()
        Show-TrayToast -Title (L "toastMinimizedTitle") -Body (L "toastMinimizedBody") -Category "System"
    } catch {}
}

$BtnTitleMin.Add_Click({ $window.WindowState = [System.Windows.WindowState]::Minimized })
$BtnTitleMax.Add_Click({ $window.WindowState = if ($window.WindowState -eq [System.Windows.WindowState]::Maximized) { [System.Windows.WindowState]::Normal } else { [System.Windows.WindowState]::Maximized } })
$BtnTitleTray.Add_Click({ Hide-MainWindowToTray })
$BtnTitleClose.Add_Click({ $window.Close() })

# ==============================================================================
# UNIFIED NATIVE DARK MODAL FACTORY (Inherits Full Dark Controls Theme!)
# ==============================================================================
function New-AlphaModalWindow {
    param([string]$Title, [double]$ReqWidth = 520, [double]$ReqHeight = 340, [bool]$Resizable = $false, [string]$BodyXaml = "")
    $wa = (Get-ScreenWorkAreaDip -Win $(if ($window.IsVisible) { $window } else { $null })).Rect
    $w = [math]::Min([double]$ReqWidth,  [math]::Max(340.0, [double]$wa.Width  - 28.0))
    $h = [math]::Min([double]$ReqHeight, [math]::Max(220.0, [double]$wa.Height - 28.0))
    $resizeMode = if ($Resizable) { "CanResize" } else { "NoResize" }
    $resizeBorder = if ($Resizable) { "6" } else { "0" }
    $flowDir = if ($null -ne $script:CurrentLocale -and $script:CurrentLocale.rtl) { "RightToLeft" } else { "LeftToRight" }
    $safeTitle = [System.Security.SecurityElement]::Escape($Title)
    $closeTip  = [System.Security.SecurityElement]::Escape((L "tipClose" "Close"))

    [xml]$mXml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="$safeTitle" Width="$w" Height="$h"
        MinWidth="$([math]::Min(420.0, [double]$w))" MinHeight="$([math]::Min(220.0, [double]$h))"
        WindowStyle="SingleBorderWindow" ResizeMode="$resizeMode"
        WindowStartupLocation="Manual" FlowDirection="LeftToRight"
        Background="#080D17" Foreground="#F8FAFC" FontFamily="Segoe UI">
    <WindowChrome.WindowChrome>
        <WindowChrome CaptionHeight="0" CornerRadius="0" GlassFrameThickness="0"
                      ResizeBorderThickness="$resizeBorder" UseAeroCaptionButtons="False"/>
    </WindowChrome.WindowChrome>
    <Window.Resources>
        $($script:DarkControlStylesXaml)
    </Window.Resources>
    <Border x:Name="ModalShellBorder" FlowDirection="$flowDir" Background="#080D17" BorderBrush="#243550" BorderThickness="1">
        <Grid>
            <Grid.RowDefinitions>
                <RowDefinition Height="36"/>
                <RowDefinition Height="*"/>
            </Grid.RowDefinitions>
            <Border x:Name="ModalTitleBar" Grid.Row="0" Background="#070C15" BorderBrush="#192438" BorderThickness="0,0,0,1">
                <Grid>
                    <Grid.ColumnDefinitions>
                        <ColumnDefinition Width="*"/>
                        <ColumnDefinition Width="Auto"/>
                    </Grid.ColumnDefinitions>
                    <DockPanel Grid.Column="0" LastChildFill="True" VerticalAlignment="Center" Margin="11,0,8,0">
                        <Image x:Name="ImgModalIcon" DockPanel.Dock="Left" FlowDirection="LeftToRight" Width="16" Height="16" Margin="0,0,8,0" RenderOptions.BitmapScalingMode="HighQuality"/>
                        <TextBlock Text="$safeTitle" FontSize="12" FontWeight="SemiBold" Foreground="#E2E8F0" VerticalAlignment="Center" TextTrimming="CharacterEllipsis"/>
                    </DockPanel>
                    <Button x:Name="BtnModalCloseX" WindowChrome.IsHitTestVisibleInChrome="True" Grid.Column="1" Width="42" Height="36" Background="Transparent" Foreground="#94A3B8" BorderThickness="0" Cursor="Hand" Focusable="False" ToolTip="$closeTip">
                        <Button.Template>
                            <ControlTemplate TargetType="Button">
                                <Border x:Name="Bd" Background="{TemplateBinding Background}">
                                    <Path FlowDirection="LeftToRight" Width="9" Height="9" HorizontalAlignment="Center" VerticalAlignment="Center" Stroke="{TemplateBinding Foreground}" StrokeThickness="1.3" Data="M 0,0 L 9,9 M 9,0 L 0,9"/>
                                </Border>
                                <ControlTemplate.Triggers>
                                    <Trigger Property="IsMouseOver" Value="True">
                                        <Setter TargetName="Bd" Property="Background" Value="#DC2626"/>
                                        <Setter Property="Foreground" Value="#FFFFFF"/>
                                    </Trigger>
                                </ControlTemplate.Triggers>
                            </ControlTemplate>
                        </Button.Template>
                    </Button>
                </Grid>
            </Border>
            <ScrollViewer Grid.Row="1" VerticalScrollBarVisibility="Auto" HorizontalScrollBarVisibility="Disabled">
                <Grid Margin="18">
                    $BodyXaml
                </Grid>
            </ScrollViewer>
        </Grid>
    </Border>
</Window>
"@
    $mw = [Windows.Markup.XamlReader]::Load((New-Object System.Xml.XmlNodeReader $mXml))
    if ($null -ne $script:AppIconSource)    { $mw.Icon = $script:AppIconSource }
    if ($null -ne $script:AppLogoPngSource) { $mw.FindName("ImgModalIcon").Source = $script:AppLogoPngSource }
    if ($window.IsVisible -and $window.WindowState -ne [System.Windows.WindowState]::Minimized) {
        $mw.Owner = $window
        $cx = $window.Left + (($window.ActualWidth  - $w) / 2.0)
        $cy = $window.Top  + (($window.ActualHeight - $h) / 2.0)
    } else {
        $cx = $wa.Left + (($wa.Width  - $w) / 2.0)
        $cy = $wa.Top  + (($wa.Height - $h) / 2.0)
    }
    $mw.Left = [math]::Max($wa.Left, [math]::Min($cx, $wa.Right  - $w))
    $mw.Top  = [math]::Max($wa.Top,  [math]::Min($cy, $wa.Bottom - $h))

    $closeBtn = $mw.FindName("BtnModalCloseX")
    if ($null -ne $closeBtn) {
        $closeBtn.Add_Click({
            param($s, $e)
            try { $wObj = [System.Windows.Window]::GetWindow($s); if ($null -ne $wObj) { $wObj.Close() } } catch {}
        })
        $closeBtn.Add_PreviewMouseLeftButtonDown({
            param($s, $e)
            $e.Handled = $true
            try { $wObj = [System.Windows.Window]::GetWindow($s); if ($null -ne $wObj) { $wObj.Close() } } catch {}
        })
    }
    $titleBar = $mw.FindName("ModalTitleBar")
    if ($null -ne $titleBar) {
        $titleBar.Add_MouseLeftButtonDown({
            param($s, $e)
            try {
                if ($e.ButtonState -eq [System.Windows.Input.MouseButtonState]::Pressed) {
                    $cur = $e.OriginalSource
                    $isClose = $false
                    while ($null -ne $cur) {
                        if ($cur -is [System.Windows.Controls.Button] -and $cur.Name -eq "BtnModalCloseX") { $isClose = $true; break }
                        if ($cur -is [System.Windows.Media.Visual] -or $cur -is [System.Windows.Media.Media3D.Visual3D]) {
                            $cur = [System.Windows.Media.VisualTreeHelper]::GetParent($cur)
                        } else {
                            $cur = [System.Windows.LogicalTreeHelper]::GetParent($cur)
                        }
                    }
                    if (-not $isClose) {
                        $wObj = [System.Windows.Window]::GetWindow($s)
                        if ($null -ne $wObj) { $wObj.DragMove() }
                    }
                }
            } catch {}
        })
    }
    $mw.Add_KeyDown({
        param($s, $e)
        if ($e.Key -eq [System.Windows.Input.Key]::Escape) {
            try { $s.Close() } catch {}
        }
    })
    return $mw
}

# ==============================================================================
# DYNAMIC CLOUD ISLAND (Draggable Anywhere on Windows + Smart Hover + Quick-Snap)
# ==============================================================================
$script:IsDraggingIsland     = $false
$script:IslandDragStartMouse = $null
$script:IslandDragStartLeft  = 0.0
$script:IslandDragStartTop   = 0.0
$script:IslandHoverTimer     = $null

function Save-CloudIslandPosition {
    param([System.Windows.Window]$IslWin)
    if ($null -eq $IslWin) { return }
    try {
        $cfgI = Get-Settings
        $cfgI.IslandPos = [PSCustomObject]@{ Left = [math]::Round([double]$IslWin.Left, 1); Top = [math]::Round([double]$IslWin.Top, 1) }
        Save-Settings -Obj $cfgI
    } catch {}
}

function Move-CloudIslandToSnap {
    param([string]$Anchor)
    if ($null -eq $script:IslandWindow) { return }
    $iw = $script:IslandWindow
    $wa = (Get-ScreenWorkAreaDip -Win $iw).Rect
    $iw.UpdateLayout()
    $w = [math]::Max(220.0, [double]$iw.ActualWidth)
    $h = [math]::Max(36.0,  [double]$iw.ActualHeight)
    $pad = 10.0
    switch ($Anchor) {
        "TopLeft"     { $iw.Left = $wa.Left + $pad;                        $iw.Top = $wa.Top + 6.0 }
        "TopRight"    { $iw.Left = $wa.Right - $w - $pad;                  $iw.Top = $wa.Top + 6.0 }
        "BottomLeft"  { $iw.Left = $wa.Left + $pad;                        $iw.Top = $wa.Bottom - $h - $pad }
        "BottomRight" { $iw.Left = $wa.Right - $w - $pad;                  $iw.Top = $wa.Bottom - $h - $pad }
        default       { $iw.Left = $wa.Left + (($wa.Width - $w) / 2.0);    $iw.Top = $wa.Top + 6.0 }
    }
    Save-CloudIslandPosition -IslWin $iw
}

function Initialize-CloudIsland {
    if ($null -ne $script:IslandWindow) { return }
    [xml]$islXml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        WindowStyle="None" AllowsTransparency="True" Background="Transparent"
        Topmost="True" ShowInTaskbar="False" ShowActivated="False"
        ResizeMode="NoResize" SizeToContent="WidthAndHeight"
        WindowStartupLocation="Manual" FlowDirection="LeftToRight" FontFamily="Segoe UI">
    <Window.Resources>
        $($script:DarkControlStylesXaml)
    </Window.Resources>
    <Border x:Name="IslandOuter" Background="#F00B1220" BorderBrush="#2563EB" BorderThickness="1.2" CornerRadius="16" Padding="9,5,10,5" Margin="6" Cursor="SizeAll">
        <Border.ContextMenu>
            <ContextMenu x:Name="IslCtxMenu">
                <MenuItem x:Name="IslCtxTopCenter"   Header="Snap: Top Center"/>
                <MenuItem x:Name="IslCtxTopLeft"     Header="Snap: Top Left"/>
                <MenuItem x:Name="IslCtxTopRight"    Header="Snap: Top Right"/>
                <MenuItem x:Name="IslCtxBottomLeft"  Header="Snap: Bottom Left"/>
                <MenuItem x:Name="IslCtxBottomRight" Header="Snap: Bottom Right"/>
                <Separator/>
                <MenuItem x:Name="IslCtxOpen"        Header="Open AlphaCloudSync"/>
                <MenuItem x:Name="IslCtxHide"        Header="Hide Island"/>
            </ContextMenu>
        </Border.ContextMenu>
        <Border.Effect>
            <DropShadowEffect Color="#000000" BlurRadius="14" ShadowDepth="2" Opacity="0.55"/>
        </Border.Effect>
        <StackPanel x:Name="IslandRoot" Orientation="Vertical">
            <StackPanel Orientation="Horizontal" VerticalAlignment="Center">
                <!-- Subtle 6-Dot Drag Grip Handle -->
                <Canvas x:Name="IslDragGrip" FlowDirection="LeftToRight" Width="8" Height="14" Margin="0,0,7,0" VerticalAlignment="Center" Opacity="0.65">
                    <Ellipse Canvas.Left="1" Canvas.Top="1"  Width="2.2" Height="2.2" Fill="#94A3B8"/>
                    <Ellipse Canvas.Left="5" Canvas.Top="1"  Width="2.2" Height="2.2" Fill="#94A3B8"/>
                    <Ellipse Canvas.Left="1" Canvas.Top="6"  Width="2.2" Height="2.2" Fill="#94A3B8"/>
                    <Ellipse Canvas.Left="5" Canvas.Top="6"  Width="2.2" Height="2.2" Fill="#94A3B8"/>
                    <Ellipse Canvas.Left="1" Canvas.Top="11" Width="2.2" Height="2.2" Fill="#94A3B8"/>
                    <Ellipse Canvas.Left="5" Canvas.Top="11" Width="2.2" Height="2.2" Fill="#94A3B8"/>
                </Canvas>
                <Image x:Name="IslIcon" FlowDirection="LeftToRight" Width="16" Height="16" Margin="0,0,7,0" RenderOptions.BitmapScalingMode="HighQuality" VerticalAlignment="Center"/>
                <Ellipse x:Name="IslDot" Width="7" Height="7" Fill="#10B981" Margin="0,0,7,0" VerticalAlignment="Center"/>
                <Grid Width="78" Height="8" Margin="0,0,8,0" VerticalAlignment="Center" FlowDirection="LeftToRight">
                    <Border Background="#162238" CornerRadius="4"/>
                    <ProgressBar x:Name="IslBarSlim" Minimum="0" Maximum="100" Value="0" Background="Transparent" BorderThickness="0">
                        <ProgressBar.Template>
                            <ControlTemplate TargetType="ProgressBar">
                                <Grid>
                                    <Border x:Name="PART_Track" Background="Transparent" CornerRadius="4"/>
                                    <Border x:Name="PART_Indicator" HorizontalAlignment="Left" Background="{TemplateBinding Foreground}" CornerRadius="4"/>
                                </Grid>
                            </ControlTemplate>
                        </ProgressBar.Template>
                        <ProgressBar.Foreground>
                            <LinearGradientBrush StartPoint="0,0" EndPoint="1,0">
                                <GradientStop Color="#38BDF8" Offset="0.0"/>
                                <GradientStop Color="#A855F7" Offset="0.55"/>
                                <GradientStop Color="#10B981" Offset="1.0"/>
                            </LinearGradientBrush>
                        </ProgressBar.Foreground>
                    </ProgressBar>
                </Grid>
                <TextBlock x:Name="IslPct" FlowDirection="LeftToRight" Text="0%" FontSize="11.5" FontWeight="Bold" Foreground="#F8FAFC" VerticalAlignment="Center" Margin="0,0,8,0"/>
                <TextBlock x:Name="IslSpeed" FlowDirection="LeftToRight" Text="" FontSize="10.5" Foreground="#7DD3FC" VerticalAlignment="Center" Margin="0,0,8,0"/>
                <Button x:Name="IslBtnToggleSlim" Width="22" Height="22" Background="#1E293B" Foreground="#F8FAFC" BorderThickness="0" Cursor="Hand" Focusable="False">
                    <Button.Template>
                        <ControlTemplate TargetType="Button">
                            <Border x:Name="B" Background="{TemplateBinding Background}" CornerRadius="11">
                                <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
                            </Border>
                            <ControlTemplate.Triggers>
                                <Trigger Property="IsMouseOver" Value="True"><Setter TargetName="B" Property="Opacity" Value="0.82"/></Trigger>
                            </ControlTemplate.Triggers>
                        </ControlTemplate>
                    </Button.Template>
                    <TextBlock x:Name="IslGlyphSlim" FlowDirection="LeftToRight" Text="&#x25B6;" FontSize="10" Foreground="#FFFFFF"/>
                </Button>
            </StackPanel>

            <StackPanel x:Name="IslExpandedPanel" Visibility="Collapsed" Margin="0,8,0,2" Width="320">
                <Border BorderBrush="#1E2D44" BorderThickness="0,1,0,0" Padding="0,7,0,0">
                    <StackPanel Orientation="Vertical">
                        <TextBlock x:Name="IslFolderTitle" Text="" FontSize="11.5" FontWeight="Bold" Foreground="#38BDF8" TextTrimming="CharacterEllipsis" Margin="0,0,0,5"/>
                        <Grid Height="14" Margin="0,0,0,6" FlowDirection="LeftToRight">
                            <ProgressBar x:Name="IslBarFull" Minimum="0" Maximum="100" Value="0" Background="#070C15" BorderBrush="#243550">
                                <ProgressBar.Template>
                                    <ControlTemplate TargetType="ProgressBar">
                                        <Grid>
                                            <Border x:Name="PART_Track" Background="{TemplateBinding Background}" BorderBrush="{TemplateBinding BorderBrush}" BorderThickness="1" CornerRadius="6"/>
                                            <Border x:Name="PART_Indicator" HorizontalAlignment="Left" Background="{TemplateBinding Foreground}" CornerRadius="6"/>
                                        </Grid>
                                    </ControlTemplate>
                                </ProgressBar.Template>
                                <ProgressBar.Foreground>
                                    <LinearGradientBrush StartPoint="0,0" EndPoint="1,0">
                                        <GradientStop Color="#38BDF8" Offset="0.0"/>
                                        <GradientStop Color="#6366F1" Offset="0.28"/>
                                        <GradientStop Color="#A855F7" Offset="0.54"/>
                                        <GradientStop Color="#EC4899" Offset="0.78"/>
                                        <GradientStop Color="#10B981" Offset="1.0"/>
                                    </LinearGradientBrush>
                                </ProgressBar.Foreground>
                            </ProgressBar>
                            <TextBlock x:Name="IslPctFull" Text="0.0%" FontSize="10" FontWeight="Bold" Foreground="#FFFFFF" HorizontalAlignment="Center" VerticalAlignment="Center"/>
                        </Grid>
                        <TextBlock x:Name="IslMetaLine" Text="" FontSize="10.5" Foreground="#94A3B8" TextTrimming="CharacterEllipsis" Margin="0,0,0,7"/>
                        <DockPanel LastChildFill="False">
                            <Button x:Name="IslBtnAction" DockPanel.Dock="Left" Content="Sync" Background="#10B981" Foreground="#FFFFFF" FontSize="11" FontWeight="Bold" Padding="11,4" BorderThickness="0" Cursor="Hand">
                                <Button.Template>
                                    <ControlTemplate TargetType="Button">
                                        <Border Background="{TemplateBinding Background}" CornerRadius="5" Padding="{TemplateBinding Padding}">
                                            <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
                                        </Border>
                                    </ControlTemplate>
                                </Button.Template>
                            </Button>
                            <StackPanel DockPanel.Dock="Right" Orientation="Horizontal">
                                <Button x:Name="IslBtnOpen" Content="Open" Background="#1E293B" Foreground="#7DD3FC" FontSize="11" Padding="10,4" Margin="0,0,6,0" BorderThickness="0" Cursor="Hand">
                                    <Button.Template>
                                        <ControlTemplate TargetType="Button">
                                            <Border Background="{TemplateBinding Background}" CornerRadius="5" Padding="{TemplateBinding Padding}">
                                                <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
                                            </Border>
                                        </ControlTemplate>
                                    </Button.Template>
                                </Button>
                                <Button x:Name="IslBtnHide" Content="&#x2715;" Background="#334155" Foreground="#E2E8F0" FontSize="11" Padding="8,4" BorderThickness="0" Cursor="Hand">
                                    <Button.Template>
                                        <ControlTemplate TargetType="Button">
                                            <Border Background="{TemplateBinding Background}" CornerRadius="5" Padding="{TemplateBinding Padding}">
                                                <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
                                            </Border>
                                        </ControlTemplate>
                                    </Button.Template>
                                </Button>
                            </StackPanel>
                        </DockPanel>
                    </StackPanel>
                </Border>
            </StackPanel>
        </StackPanel>
    </Border>
</Window>
"@
    $iw = [Windows.Markup.XamlReader]::Load((New-Object System.Xml.XmlNodeReader $islXml))
    if ($null -ne $script:AppLogoPngSource) { $iw.FindName("IslIcon").Source = $script:AppLogoPngSource }

    $vLeft   = [double][System.Windows.SystemParameters]::VirtualScreenLeft
    $vTop    = [double][System.Windows.SystemParameters]::VirtualScreenTop
    $vRight  = $vLeft + [double][System.Windows.SystemParameters]::VirtualScreenWidth
    $vBottom = $vTop  + [double][System.Windows.SystemParameters]::VirtualScreenHeight
    $wa = (Get-ScreenWorkAreaDip).Rect
    $cfg = Get-Settings
    if ($cfg.IslandPos -and $null -ne $cfg.IslandPos.Left -and $null -ne $cfg.IslandPos.Top) {
        $iw.Left = [math]::Max($vLeft, [math]::Min([double]$cfg.IslandPos.Left, $vRight - 140.0))
        $iw.Top  = [math]::Max($vTop,  [math]::Min([double]$cfg.IslandPos.Top,  $vBottom - 40.0))
    } else {
        $iw.Left = $wa.Left + (($wa.Width - 260.0) / 2.0)
        $iw.Top  = $wa.Top + 6.0
    }

    $script:IslandWindow   = $iw
    $script:IslandOuter    = $iw.FindName("IslandOuter")
    $script:IslandExpPanel = $iw.FindName("IslExpandedPanel")

    # Silky 60fps Anywhere-on-Windows Drag (Mouse, Trackpad, Touch & Pen; Multi-Monitor)
    $script:IslandOuter.Add_PreviewMouseLeftButtonDown({
        param($s, $e)
        $cur = $e.OriginalSource
        while ($null -ne $cur) {
            if ($cur -is [System.Windows.Controls.Primitives.ButtonBase]) { return }
            if ($cur -is [System.Windows.Media.Visual] -or $cur -is [System.Windows.Media.Media3D.Visual3D]) {
                $cur = [System.Windows.Media.VisualTreeHelper]::GetParent($cur)
            } elseif ($cur -is [System.Windows.DependencyObject]) {
                $cur = [System.Windows.LogicalTreeHelper]::GetParent($cur)
            } else { break }
        }
        if ($script:IslandHoverTimer) { $script:IslandHoverTimer.Stop() }
        if ($null -ne $script:IslandExpPanel) { $script:IslandExpPanel.Visibility = "Collapsed" }
        $script:IsDraggingIsland     = $true
        $script:IslandDragStartMouse = [System.Windows.Forms.Control]::MousePosition
        $script:IslandDragStartLeft  = [double]$script:IslandWindow.Left
        $script:IslandDragStartTop   = [double]$script:IslandWindow.Top
        [void]$script:IslandOuter.CaptureMouse()
        $e.Handled = $true
    })

    $script:IslandOuter.Add_PreviewMouseMove({
        param($s, $e)
        if (-not $script:IsDraggingIsland -or $null -eq $script:IslandWindow) { return }
        if ($e.LeftButton -ne [System.Windows.Input.MouseButtonState]::Pressed) {
            $script:IsDraggingIsland = $false
            if ($script:IslandOuter.IsMouseCaptured) { $script:IslandOuter.ReleaseMouseCapture() }
            Save-CloudIslandPosition -IslWin $script:IslandWindow
            return
        }
        $now = [System.Windows.Forms.Control]::MousePosition
        $dpiX = 1.0; $dpiY = 1.0
        try {
            $ps = [System.Windows.PresentationSource]::FromVisual($script:IslandWindow)
            if ($null -ne $ps -and $null -ne $ps.CompositionTarget) {
                $dpiX = $ps.CompositionTarget.TransformToDevice.M11
                $dpiY = $ps.CompositionTarget.TransformToDevice.M22
            }
        } catch {}
        $dx = ([double]($now.X - $script:IslandDragStartMouse.X)) / $dpiX
        $dy = ([double]($now.Y - $script:IslandDragStartMouse.Y)) / $dpiY
        $vl = [double][System.Windows.SystemParameters]::VirtualScreenLeft
        $vt = [double][System.Windows.SystemParameters]::VirtualScreenTop
        $vr = $vl + [double][System.Windows.SystemParameters]::VirtualScreenWidth
        $vb = $vt + [double][System.Windows.SystemParameters]::VirtualScreenHeight
        $wCur = [math]::Max(180.0, [double]$script:IslandWindow.ActualWidth)
        $hCur = [math]::Max(34.0,  [double]$script:IslandWindow.ActualHeight)
        $script:IslandWindow.Left = [math]::Max($vl - 20.0, [math]::Min($script:IslandDragStartLeft + $dx, $vr - $wCur + 20.0))
        $script:IslandWindow.Top  = [math]::Max($vt,        [math]::Min($script:IslandDragStartTop  + $dy, $vb - $hCur))
    })

    $finishIslandDrag = {
        if ($script:IsDraggingIsland) {
            $script:IsDraggingIsland = $false
            if ($null -ne $script:IslandOuter -and $script:IslandOuter.IsMouseCaptured) { $script:IslandOuter.ReleaseMouseCapture() }
            Save-CloudIslandPosition -IslWin $script:IslandWindow
        }
    }
    $script:IslandOuter.Add_PreviewMouseLeftButtonUp($finishIslandDrag)
    $script:IslandOuter.Add_LostMouseCapture($finishIslandDrag)

    # Smart 220ms hover-to-expand (never interferes with instant grab-and-drag!)
    $script:IslandHoverTimer = New-Object System.Windows.Threading.DispatcherTimer
    $script:IslandHoverTimer.Interval = [TimeSpan]::FromMilliseconds(220)
    $script:IslandHoverTimer.Add_Tick({
        $script:IslandHoverTimer.Stop()
        if ($null -ne $script:IslandWindow -and -not $script:IsDraggingIsland -and $script:IslandWindow.IsMouseOver) {
            $script:IslandWindow.FindName("IslExpandedPanel").Visibility = "Visible"
        }
    })
    $script:IslandCollapseTimer = New-Object System.Windows.Threading.DispatcherTimer
    $script:IslandCollapseTimer.Interval = [TimeSpan]::FromMilliseconds(350)
    $script:IslandCollapseTimer.Add_Tick({
        $script:IslandCollapseTimer.Stop()
        if ($null -ne $script:IslandWindow -and -not $script:IslandWindow.IsMouseOver) {
            $script:IslandWindow.FindName("IslExpandedPanel").Visibility = "Collapsed"
        }
    })
    $iw.Add_MouseEnter({
        if ($script:IslandCollapseTimer) { $script:IslandCollapseTimer.Stop() }
        if (-not $script:IsDraggingIsland -and $script:IslandHoverTimer) { $script:IslandHoverTimer.Start() }
    })
    $iw.Add_MouseLeave({
        if ($script:IslandHoverTimer) { $script:IslandHoverTimer.Stop() }
        if (-not $script:IsDraggingIsland -and $script:IslandCollapseTimer) { $script:IslandCollapseTimer.Start() }
    })

    # Right-Click Quick-Snap Context Menu Handlers
    $iw.FindName("IslCtxTopCenter").Add_Click({   Move-CloudIslandToSnap "TopCenter"   })
    $iw.FindName("IslCtxTopLeft").Add_Click({     Move-CloudIslandToSnap "TopLeft"     })
    $iw.FindName("IslCtxTopRight").Add_Click({    Move-CloudIslandToSnap "TopRight"    })
    $iw.FindName("IslCtxBottomLeft").Add_Click({  Move-CloudIslandToSnap "BottomLeft"  })
    $iw.FindName("IslCtxBottomRight").Add_Click({ Move-CloudIslandToSnap "BottomRight" })
    $iw.FindName("IslCtxOpen").Add_Click({        Restore-MainWindowFromTray           })
    $iw.FindName("IslCtxHide").Add_Click({        Set-CloudIslandEnabled -Enable $false })

    $toggleAction = {
        try {
            if ($script:IsSyncRunning) { Invoke-PauseOrStopSync }
            else {
                if ($script:IsGloballyPaused) { Set-GlobalSyncPaused -Paused $false -Silent }
                if ($script:WasPausedByUser) { Start-StudioBatch -Mode $script:LastBatchMode -OnlyFolderPath $script:LastBatchOnlyFolder }
                else { Start-StudioBatch -Mode "Sync" }
            }
        } catch {}
    }
    $iw.FindName("IslBtnToggleSlim").Add_Click($toggleAction)
    $iw.FindName("IslBtnAction").Add_Click($toggleAction)
    $iw.FindName("IslBtnOpen").Add_Click({ Restore-MainWindowFromTray })
    $iw.FindName("IslBtnHide").Add_Click({ Set-CloudIslandEnabled -Enable $false })

    $script:IslandWindow = $iw
    Update-CloudIslandDisplay
}

function Update-ActivityLiveDotState {
    try {
        if ($null -eq $DotNavActivityLive) { return }
        $isActiveUpload = ($script:IsSyncRunning -and $script:SyncingRemote -eq $script:ActiveRemote -and $script:LastBatchMode -notin @("DryRun", "RestorePreview"))
        if ($isActiveUpload) {
            $DotNavActivityLive.Visibility = "Visible"
            if (-not $script:IsActivityDotPulsing) {
                $anim = New-Object System.Windows.Media.Animation.DoubleAnimation
                $anim.From = 1.0
                $anim.To = 0.12
                $anim.Duration = New-Object System.Windows.Duration ([TimeSpan]::FromMilliseconds(850))
                $anim.AutoReverse = $true
                $anim.RepeatBehavior = [System.Windows.Media.Animation.RepeatBehavior]::Forever
                $DotNavActivityLive.BeginAnimation([System.Windows.UIElement]::OpacityProperty, $anim)
                $script:IsActivityDotPulsing = $true
            }
        } else {
            if ($script:IsActivityDotPulsing) {
                $DotNavActivityLive.BeginAnimation([System.Windows.UIElement]::OpacityProperty, $null)
                $DotNavActivityLive.Opacity = 1.0
                $script:IsActivityDotPulsing = $false
            }
            $DotNavActivityLive.Visibility = "Collapsed"
        }
    } catch {}
}

function Set-CloudIslandEnabled {
    param([bool]$Enable)
    $script:IslandEnabled = $Enable
    $cfg = Get-Settings
    $cfg.ShowCloudIsland = $Enable
    Save-Settings -Obj $cfg

    if ($Enable) {
        Initialize-CloudIsland
        $script:IslandWindow.Show()
        Update-CloudIslandDisplay
    } else {
        if ($null -ne $script:IslandWindow) { $script:IslandWindow.Hide() }
    }
    if ($null -ne $ChkCloudIsland) {
        $prevR = $script:IsRefreshing
        $script:IsRefreshing = $true
        $ChkCloudIsland.IsChecked = $Enable
        $script:IsRefreshing = $prevR
    }
}

function Update-CloudIslandDisplay {
    try {
        Update-ActivityLiveDotState
        if ($script:IsSyncRunning) {
            $TaskbarInfo.ProgressState = [System.Windows.Shell.TaskbarItemProgressState]::Normal
            $TaskbarInfo.ProgressValue = [math]::Max(0.02, [math]::Min(1.0, ($script:LastOverallPct / 100.0)))
        } elseif ($script:IsGloballyPaused -or $script:WasPausedByUser) {
            $TaskbarInfo.ProgressState = [System.Windows.Shell.TaskbarItemProgressState]::Paused
        } else {
            $TaskbarInfo.ProgressState = [System.Windows.Shell.TaskbarItemProgressState]::None
            $TaskbarInfo.ProgressValue = 0
        }

        if ($null -eq $script:IslandWindow -or -not $script:IslandEnabled) { return }
        $iw = $script:IslandWindow
        $bc = New-Object System.Windows.Media.BrushConverter
        $iw.FindName("IslandRoot").FlowDirection = if ($script:CurrentLocale -and $script:CurrentLocale.rtl) { "RightToLeft" } else { "LeftToRight" }
        $iw.FindName("IslCtxMenu").FlowDirection = if ($script:CurrentLocale -and $script:CurrentLocale.rtl) { "RightToLeft" } else { "LeftToRight" }
        $iw.FindName("IslandOuter").ToolTip      = L "islandDragTip" "Drag anywhere on Windows"
        $iw.FindName("IslCtxTopCenter").Header   = L "islandSnapTopCenter" "Snap: Top Center"
        $iw.FindName("IslCtxTopLeft").Header     = L "islandSnapTopLeft" "Snap: Top Left"
        $iw.FindName("IslCtxTopRight").Header    = L "islandSnapTopRight" "Snap: Top Right"
        $iw.FindName("IslCtxBottomLeft").Header  = L "islandSnapBottomLeft" "Snap: Bottom Left"
        $iw.FindName("IslCtxBottomRight").Header = L "islandSnapBottomRight" "Snap: Bottom Right"
        $iw.FindName("IslCtxOpen").Header        = L "islandOpenMain" "Open"
        $iw.FindName("IslCtxHide").Header        = L "islandHide" "Hide Island"

        $pctTxt = ("{0:N1}%" -f $script:LastOverallPct)
        $iw.FindName("IslBarSlim").Value = $script:LastOverallPct
        $iw.FindName("IslBarFull").Value = $script:LastOverallPct
        $iw.FindName("IslPct").Text      = $pctTxt
        $iw.FindName("IslPctFull").Text  = $pctTxt
        $iw.FindName("IslBtnOpen").Content = L "islandOpenMain" "Open"
        $iw.FindName("IslBtnHide").ToolTip = L "islandHide" "Hide Island"

        if ($script:IsSyncRunning) {
            $iw.FindName("IslDot").Fill = $bc.ConvertFromString("#38BDF8")
            $iw.FindName("IslSpeed").Text = if ($script:LastSpeedTxt) { $script:LastSpeedTxt } else { "..." }
            $iw.FindName("IslGlyphSlim").Text = ([string][char]0x23F8)
            $iw.FindName("IslBtnToggleSlim").Background = $bc.ConvertFromString("#DC2626")
            $iw.FindName("IslBtnAction").Content = L "islandPause" "Pause"
            $iw.FindName("IslBtnAction").Background = $bc.ConvertFromString("#DC2626")
            $iw.FindName("IslFolderTitle").Text = LF "islandFolderProgress" @($script:BatchCurrentIndex, [math]::Max(1, $script:BatchTotalFolders), $script:CurrentFolder)
            $metaParts = @()
            if ($script:LastFilesSummary) { $metaParts += $script:LastFilesSummary }
            if ($script:LastEtaTxt)       { $metaParts += "$(L 'etaShort' 'ETA') $($script:LastEtaTxt)" }
            $iw.FindName("IslMetaLine").Text = if ($metaParts.Count -gt 0) { Wrap-Ltr ($metaParts -join ("  " + [char]0x2022 + "  ")) } else { $TxtLiveTransfer.Text }
        } else {
            $isPausedNow = ($script:IsGloballyPaused -or $script:WasPausedByUser)
            $dotColor = if ($isPausedNow) { "#F59E0B" } else { "#10B981" }
            $iw.FindName("IslDot").Fill = $bc.ConvertFromString($dotColor)
            $iw.FindName("IslSpeed").Text = ""
            $iw.FindName("IslGlyphSlim").Text = ([string][char]0x25B6)
            $iw.FindName("IslBtnToggleSlim").Background = $bc.ConvertFromString("#10B981")
            $iw.FindName("IslBtnAction").Content = if ($isPausedNow) { L "islandResume" "Resume" } else { L "islandStart" "Sync" }
            $iw.FindName("IslBtnAction").Background = $bc.ConvertFromString("#10B981")
            $iw.FindName("IslFolderTitle").Text = if ($script:IsGloballyPaused) { L "trayPausedShort" "Paused" } elseif ($script:WasPausedByUser) { L "statusStopped" } else { L "islandIdle" }
            $iw.FindName("IslMetaLine").Text = $TxtUploadCounters.Text
        }
    } catch {}
}

$ChkCloudIsland.Add_Click({
    if ($script:IsRefreshing) { return }
    try { Set-CloudIslandEnabled -Enable ([bool]$ChkCloudIsland.IsChecked) } catch {}
})

function Update-RealTimeWatchStatusText {
    try {
        $bc = New-Object System.Windows.Media.BrushConverter
        if ($script:IsGloballyPaused) {
            $TxtAutoWatchStatus.Text = L "trayPausedShort" "Paused"
            $TxtAutoWatchStatus.Foreground = $bc.ConvertFromString("#F59E0B")
        } elseif ($script:AutoWatchEnabled) {
            $cnt = if ($null -ne $script:WatchHub) { [int]$script:WatchHub.WatchCount } else { 0 }
            $TxtAutoWatchStatus.Text = LF "autoWatchStatusActive" @($cnt)
            $TxtAutoWatchStatus.Foreground = $bc.ConvertFromString("#4ADE80")
        } else {
            $TxtAutoWatchStatus.Text = L "autoWatchStatusOff"
            $TxtAutoWatchStatus.Foreground = $bc.ConvertFromString("#94A3B8")
        }
    } catch {}
}

function Sync-RealTimeWatchers {
    try {
        $script:PendingAutoSyncFolders = @()
        if ($null -eq $script:WatchHub) { Update-RealTimeWatchStatusText; return }
        if (-not $script:AutoWatchEnabled) {
            $script:WatchHub.StopAll()
            Update-RealTimeWatchStatusText
            return
        }
        $watchList = @()
        foreach ($f in @(Get-SyncFolders -TargetRemote $script:ActiveRemote)) {
            if ($f -and $f.Enabled -ne $false -and -not [string]::IsNullOrWhiteSpace($f.LocalPath) -and (Test-Path -LiteralPath $f.LocalPath -PathType Container)) {
                $watchList += $f.LocalPath
            }
        }
        $script:WatchHub.SetFolders([string[]]$watchList)
        Update-RealTimeWatchStatusText
    } catch {}
}

$ChkFolderBadges.Add_Click({
    if ($script:IsRefreshing) { return }
    try {
        $en = [bool]$ChkFolderBadges.IsChecked
        $cfg = Get-Settings; $cfg.ShowFolderBadges = $en; Save-Settings -Obj $cfg
        Sync-AllFolderAndDriveBadges -Enable $en
        Write-StudioLog -Msg "[OK] Windows folder & drive icon badges: $(if ($en) { 'ENABLED' } else { 'DISABLED' })." -TargetRemote $script:ActiveRemote
    } catch {}
})

$ChkExplorerMenu.Add_Click({
    if ($script:IsRefreshing) { return }
    try {
        $en = [bool]$ChkExplorerMenu.IsChecked
        $cfg = Get-Settings; $cfg.ExplorerContextMenu = $en; Save-Settings -Obj $cfg
        $null = Set-ExplorerContextMenuEnabled -Enable $en
        Write-StudioLog -Msg "[OK] Windows Explorer folder right-click menu: $(if ($en) { 'ENABLED' } else { 'DISABLED' })." -TargetRemote $script:ActiveRemote
    } catch {}
})

$ChkAutoWatchSync.Add_Click({
    if ($script:IsRefreshing) { return }
    try {
        $en = [bool]$ChkAutoWatchSync.IsChecked
        $script:AutoWatchEnabled = $en
        $cfg = Get-Settings; $cfg.AutoWatchSync = $en; Save-Settings -Obj $cfg
        Sync-RealTimeWatchers
        Write-StudioLog -Msg "[OK] Real-Time Auto-Sync: $(if ($en) { 'ENABLED' } else { 'DISABLED' })." -TargetRemote $script:ActiveRemote
    } catch {}
})

# ==============================================================================
# SYSTEM TRAY ICON + GLOBAL PAUSE + TOAST NOTIFICATIONS + IPC RESTORE LISTENER
# ==============================================================================
$script:IsGloballyPaused = $false
$script:TrayIcon = New-Object System.Windows.Forms.NotifyIcon
if (-not [string]::IsNullOrEmpty($AppIconPath) -and (Test-Path -LiteralPath $AppIconPath)) {
    try { $script:TrayIcon.Icon = New-Object System.Drawing.Icon($AppIconPath, 32, 32) }
    catch { $script:TrayIcon.Icon = New-Object System.Drawing.Icon($AppIconPath) }
} else { $script:TrayIcon.Icon = [System.Drawing.SystemIcons]::Application }
$script:TrayIcon.Text = "AlphaCloudSync v$AppVersion"
$script:TrayIcon.Visible = $true

$trayMenu = New-Object System.Windows.Forms.ContextMenuStrip
try {
    if ("AlphaDarkTrayRenderer" -as [type]) {
        $trayMenu.Renderer = New-Object AlphaDarkTrayRenderer
        $trayMenu.ShowImageMargin = $false
        $trayMenu.BackColor = [System.Drawing.Color]::FromArgb(13, 21, 36)
        $trayMenu.ForeColor = [System.Drawing.Color]::FromArgb(226, 232, 240)
        $trayMenu.Font = New-Object System.Drawing.Font("Segoe UI", 9.5)
    }
} catch {}
$miOpen     = $trayMenu.Items.Add((L "trayOpen" "Open AlphaCloudSync"))
$miSync     = $trayMenu.Items.Add((L "traySync" "Start Backup Now"))
$miPauseAll = $trayMenu.Items.Add((L "trayPauseAll" "Pause All Syncing (Save Bandwidth)"))
$miIsland   = $trayMenu.Items.Add((L "trayIsland" "Show / Hide Cloud Island"))
$trayMenu.Items.Add("-") | Out-Null
$miExit     = $trayMenu.Items.Add((L "trayExit" "Exit Completely"))
$script:TrayIcon.ContextMenuStrip = $trayMenu

function Set-GlobalSyncPaused {
    param([bool]$Paused, [switch]$Silent)
    try {
        $script:IsGloballyPaused = $Paused
        if ($Paused) {
            if ($script:IsSyncRunning) { Invoke-PauseOrStopSync }
            if ($null -ne $script:WatchHub) { $script:WatchHub.Paused = $true; $script:WatchHub.ClearPending() }
            $script:PendingAutoSyncFolders = @()
            $miPauseAll.Text = L "trayResumeAll" "Resume Syncing"
            $pShort = L "trayPausedShort" "Paused"
            $tTxt = "AlphaCloudSync ($pShort)"
            if ($tTxt.Length -le 63) { $script:TrayIcon.Text = $tTxt }
            Write-StudioLog -Msg "[PAUSED] Global Pause enabled -- all syncing and auto-watch paused to free internet bandwidth." -TargetRemote $script:ActiveRemote
            if (-not $Silent) {
                Show-TrayToast -Title (L "toastGlobalPauseTitle" "AlphaCloudSync Paused") -Body (L "toastGlobalPauseBody" "All syncing paused to free your internet bandwidth.") -Category "Manual"
            }
        } else {
            $script:WasPausedByUser = $false
            foreach ($rtAcc in $script:AccountRuntimeMap.Values) { $rtAcc.WasPausedByUser = $false }
            if ($null -ne $script:WatchHub) { $script:WatchHub.Paused = $false }
            $miPauseAll.Text = L "trayPauseAll" "Pause All Syncing (Save Bandwidth)"
            $script:TrayIcon.Text = "AlphaCloudSync v$AppVersion"
            Write-StudioLog -Msg "[OK] Global Pause disabled -- syncing and live watch resumed." -TargetRemote $script:ActiveRemote
            if (-not $Silent) {
                Show-TrayToast -Title (L "toastGlobalResumeTitle" "AlphaCloudSync Resumed") -Body (L "toastGlobalResumeBody" "Syncing and live folder monitoring have resumed.") -Category "Manual"
            }
        }
        Refresh-SidebarAccountsOverview
        Update-RealTimeWatchStatusText
        Update-CloudIslandDisplay
    } catch {}
}

function Show-TrayToast {
    param(
        [string]$Title,
        [string]$Body,
        [ValidateSet("Manual", "AutoSync", "Error", "Drive", "System")]
        [string]$Category = "Manual",
        [System.Windows.Forms.ToolTipIcon]$Icon = [System.Windows.Forms.ToolTipIcon]::Info
    )
    try {
        $cfgN = Get-Settings
        if (-not [bool]$cfgN.NotificationsEnabled) { return }
        switch ($Category) {
            "Manual"   { if (-not [bool]$cfgN.NotifyManualSync)  { return } }
            "AutoSync" { if (-not [bool]$cfgN.NotifyAutoSync)    { return } }
            "Error"    { if (-not [bool]$cfgN.NotifyErrors)      { return } }
            "Drive"    { if (-not [bool]$cfgN.NotifyDriveEvents) { return } }
        }
        $script:TrayIcon.ShowBalloonTip(4000, $Title, $Body, $Icon)
    } catch {}
}

function Update-NotificationSubState {
    try {
        $masterOn = [bool]$ChkNotifMaster.IsChecked
        $PnlNotifSub.IsEnabled = $masterOn
        $PnlNotifSub.Opacity   = if ($masterOn) { 1.0 } else { 0.45 }
    } catch {}
}

$saveNotifPrefs = {
    if ($script:IsRefreshing) { return }
    try {
        $cfgN = Get-Settings
        $cfgN.NotificationsEnabled = [bool]$ChkNotifMaster.IsChecked
        $cfgN.NotifyManualSync     = [bool]$ChkNotifManual.IsChecked
        $cfgN.NotifyAutoSync       = [bool]$ChkNotifAutoSync.IsChecked
        $cfgN.NotifyErrors         = [bool]$ChkNotifErrors.IsChecked
        $cfgN.NotifyDriveEvents    = [bool]$ChkNotifDriveEvents.IsChecked
        Save-Settings -Obj $cfgN
        Update-NotificationSubState
    } catch {}
}
$ChkNotifMaster.Add_Click($saveNotifPrefs)
$ChkNotifManual.Add_Click($saveNotifPrefs)
$ChkNotifAutoSync.Add_Click($saveNotifPrefs)
$ChkNotifErrors.Add_Click($saveNotifPrefs)
$ChkNotifDriveEvents.Add_Click($saveNotifPrefs)

$miOpen.Add_Click({ Restore-MainWindowFromTray })
$script:TrayIcon.Add_MouseClick({
    param($s, $e)
    if ($e.Button -eq [System.Windows.Forms.MouseButtons]::Left) { Restore-MainWindowFromTray }
})
$script:TrayIcon.Add_DoubleClick({ Restore-MainWindowFromTray })
$miSync.Add_Click({ Restore-MainWindowFromTray; if ($script:IsGloballyPaused) { Set-GlobalSyncPaused -Paused $false -Silent }; if (-not $script:IsSyncRunning) { Start-StudioBatch -Mode "Sync" } })
$miPauseAll.Add_Click({ Set-GlobalSyncPaused -Paused (-not $script:IsGloballyPaused) })
$miIsland.Add_Click({ Set-CloudIslandEnabled -Enable (-not $script:IslandEnabled) })
$script:AppShuttingDown = $false
function Stop-AlphaCloudSyncApp {
    if ($script:AppShuttingDown) { return }
    $script:AppShuttingDown = $true
    try { if (Get-Command Stop-SequentialAccountHydration -ErrorAction SilentlyContinue) { Stop-SequentialAccountHydration } } catch {}
    try { if ($null -ne $timer) { $timer.Stop() } } catch {}
    try { if ($null -ne $script:RestoreSignalTimer) { $script:RestoreSignalTimer.Stop() } } catch {}
    try { Persist-GridCheckboxChanges } catch {}
    try { if ($window.IsLoaded) { Save-CurrentWindowBounds } } catch {}
    try {
        if ($null -ne $script:ActiveProcess -and -not $script:ActiveProcess.HasExited) {
            Stop-Process -Id $script:ActiveProcess.Id -Force -ErrorAction SilentlyContinue
            $script:ActiveProcess = $null
        }
        if ($script:ActiveJobLogFile -and (Test-Path -LiteralPath $script:ActiveJobLogFile)) {
            Remove-Item -LiteralPath $script:ActiveJobLogFile -Force -ErrorAction SilentlyContinue
        }
        if ($script:ActiveFilesFromFile -and (Test-Path -LiteralPath $script:ActiveFilesFromFile)) {
            Remove-Item -LiteralPath $script:ActiveFilesFromFile -Force -ErrorAction SilentlyContinue
        }
    } catch {}
    try { if ($null -ne $script:IslandWindow) { $script:IslandWindow.Close() } } catch {}
    try { if ($null -ne $script:WatchHub) { $script:WatchHub.Dispose(); $script:WatchHub = $null } } catch {}
    try { if ($null -ne $script:RestoreSignalEvent) { $script:RestoreSignalEvent.Dispose() } } catch {}
    try { $script:TrayIcon.Visible = $false; $script:TrayIcon.Dispose() } catch {}
    try { if ($null -ne $script:WpfApp) { $script:WpfApp.Shutdown(0) } } catch {}
}

$miExit.Add_Click({
    try { if ($window.IsLoaded) { $window.Close() } } catch {}
    Stop-AlphaCloudSyncApp
})

function Invoke-DrainIpcQueue {
    if ($script:IsHandlingIpc) { return }
    $script:IsHandlingIpc = $true
    try {
        $queueFiles = @()
        if (Test-Path -LiteralPath $IpcCmdFile) {
            $queueFiles += $IpcCmdFile
        }
        if ($IpcQueueDir -and (Test-Path -LiteralPath $IpcQueueDir)) {
            $queueFiles += @(Get-ChildItem -LiteralPath $IpcQueueDir -Filter "*.json" -File -ErrorAction SilentlyContinue | Sort-Object Name | ForEach-Object { $_.FullName })
        }
        foreach ($qFile in $queueFiles) {
            try {
                if (-not (Test-Path -LiteralPath $qFile)) { continue }
                $rawIpc = [System.IO.File]::ReadAllText($qFile, [System.Text.Encoding]::UTF8)
                Remove-Item -LiteralPath $qFile -Force -ErrorAction SilentlyContinue
                if (-not [string]::IsNullOrWhiteSpace($rawIpc)) {
                    $ipcObj = $rawIpc | ConvertFrom-Json
                    if ($ipcObj -and -not [string]::IsNullOrWhiteSpace($ipcObj.Action) -and (Get-Command Invoke-HandleContextCommand -ErrorAction SilentlyContinue)) {
                        Restore-MainWindowFromTray
                        Invoke-HandleContextCommand -ContextAction ([string]$ipcObj.Action) -FolderPath ([string]$ipcObj.Path)
                    }
                }
            } catch {}
        }
    } finally {
        $script:IsHandlingIpc = $false
    }
}

# Single-instance restore signal: if user re-launches AlphaCloudSync.exe while hidden in Tray, pop window back to front!
$script:RestoreSignalEvent = $null
$script:RestoreSignalTimer = $null
try {
    $createdEvt = $false
    $script:RestoreSignalEvent = New-Object System.Threading.EventWaitHandle($false, [System.Threading.EventResetMode]::AutoReset, "Local\AlphaCloudSync_RestoreSignal", [ref]$createdEvt)
    $script:RestoreSignalTimer = New-Object System.Windows.Threading.DispatcherTimer
    $script:RestoreSignalTimer.Interval = [TimeSpan]::FromMilliseconds(350)
    $script:RestoreSignalTimer.Add_Tick({
        try {
            $sig = ($null -ne $script:RestoreSignalEvent -and $script:RestoreSignalEvent.WaitOne(0))
            if ($sig) {
                Restore-MainWindowFromTray
                Invoke-DrainIpcQueue
            } elseif (-not $script:IsHandlingIpc) {
                $hasPending = (Test-Path -LiteralPath $IpcCmdFile) -or ($IpcQueueDir -and (Test-Path -LiteralPath $IpcQueueDir) -and (@(Get-ChildItem -LiteralPath $IpcQueueDir -Filter "*.json" -File -ErrorAction SilentlyContinue).Count -gt 0))
                if ($hasPending) { Invoke-DrainIpcQueue }
            }
        } catch {}
    })
    $script:RestoreSignalTimer.Start()
} catch {}

$window.Add_Closing({
    try { Persist-GridCheckboxChanges } catch {}
    Save-CurrentWindowBounds
})

$window.Add_Closed({
    Stop-AlphaCloudSyncApp
})

function Write-StudioLog {
    param([string]$Msg, [string]$TargetRemote = $script:ActiveRemote)
    try {
        if ([string]::IsNullOrWhiteSpace($TargetRemote)) { $TargetRemote = $script:ActiveRemote }
        $ts = Format-Time12h -DateTime (Get-Date) -WithSeconds
        $line = "[$ts] $Msg`r`n"
        $rt = Get-AccountRuntime -TargetRemote $TargetRemote
        [void]$rt.LogBuilder.Append($line)
        if ($rt.LogBuilder.Length -gt 240000) {
            $null = $rt.LogBuilder.Remove(0, $rt.LogBuilder.Length - 180000)
        }
        if ($TargetRemote -eq $script:ActiveRemote) {
            $TxtLog.AppendText($line)
            if ($TxtLog.Text.Length -gt 240000) { $TxtLog.Text = $rt.LogBuilder.ToString() }
            $TxtLog.ScrollToEnd()
        }
    } catch {}
}

function Switch-AccountActivityView {
    try {
        $bc = New-Object System.Windows.Media.BrushConverter
        $rt = Get-AccountRuntime -TargetRemote $script:ActiveRemote
        $GridActivity.ItemsSource = $rt.ActivityItems
        $TxtLog.Text = $rt.LogBuilder.ToString()
        $TxtLog.ScrollToEnd()

        $isThisSyncing = ($script:IsSyncRunning -and $script:SyncingRemote -eq $script:ActiveRemote)
        $BarSyncProgress.Value = if ($isThisSyncing) { [math]::Max(1.0, [double]$rt.LastOverallPct) } else { [double]$rt.LastOverallPct }
        $TxtProgressPct.Text = $rt.ProgressPctText
        $TxtUploadCounters.Text = if (-not [string]::IsNullOrWhiteSpace($rt.CountersText)) { $rt.CountersText } else { L "countersInitial" }
        $TxtLiveTransfer.Text = if (-not [string]::IsNullOrWhiteSpace($rt.LiveTransferText)) { $rt.LiveTransferText } else { L "statusIdle" }
        Update-ActivityLiveDotState

        if ($isThisSyncing) {
            $TxtSyncToggle.Text        = L "stopSync"
            $BtnSyncToggle.Background  = $bc.ConvertFromString("#DC2626")
            $BtnSyncToggle.BorderBrush = $bc.ConvertFromString("#F87171")
            $BtnDryRun.IsEnabled       = $false
            $BtnRestore.IsEnabled      = $false
            $BtnSyncSelected.IsEnabled = $false
        } else {
            $TxtSyncToggle.Text        = L "syncAll"
            $BtnSyncToggle.Background  = $bc.ConvertFromString("#10B981")
            $BtnSyncToggle.BorderBrush = $bc.ConvertFromString("#34D399")
            $BtnDryRun.IsEnabled       = (-not $script:IsSyncRunning)
            $BtnRestore.IsEnabled      = (-not $script:IsSyncRunning)
            $BtnSyncSelected.IsEnabled = ($null -ne $GridFolders.SelectedItem -and -not $script:IsSyncRunning)
        }
    } catch {}
}

function Build-SidebarAccountCardObject {
    param([string]$TargetRemote, [array]$Mounts, $UniInfo = $null, [switch]$UniInfoProvided)
    $disp = Get-AccountDisplayLabel -TargetRemote $TargetRemote
    $m = $Mounts | Where-Object { $_.Remote -eq $TargetRemote } | Select-Object -First 1
    $ltr = if ($null -ne $m) { $m.Letter } else { Get-MountedLetterForRemote -TargetRemote $TargetRemote }
    $isUniMember = $false
    $isMounted   = ($null -ne $ltr)
    $uniInfo = if ($UniInfoProvided) { $UniInfo } else { Get-UnifiedMountInfo }
    if (-not $isMounted -and $null -ne $uniInfo -and -not [string]::IsNullOrWhiteSpace($uniInfo.Letter)) {
        if ($uniInfo.Remotes.Count -eq 0 -or ($uniInfo.Remotes -contains $TargetRemote)) {
            $ltr = $uniInfo.Letter
            $isUniMember = $true
            $isMounted   = $true
        }
    }
    $assign = Get-AccountDriveAssignment -TargetRemote $TargetRemote
    if (-not $isMounted) {
        if ($assign -eq "Unified") {
            $ltr = Get-AutoUnifiedDriveLetter
            $isUniMember = $true
        } else {
            $ltr = Get-AccountPreferredDrive -TargetRemote $TargetRemote -DefaultLetter ""
        }
    }
    $rt = Get-AccountRuntime -TargetRemote $TargetRemote
    $isSyncingThis = ($script:IsSyncRunning -and $script:SyncingRemote -eq $TargetRemote)
    $isActiveCard  = ($TargetRemote -eq $script:ActiveRemote)

    $qSummary = "-- / --"
    $qPct = 0.0
    if ($script:LastAboutCache.ContainsKey($TargetRemote) -and -not [string]::IsNullOrWhiteSpace($script:LastAboutCache[$TargetRemote])) {
        try {
            $ab = $script:LastAboutCache[$TargetRemote] | ConvertFrom-Json
            $tot = [double]$ab.total; $usd = [double]$ab.used
            if ($tot -gt 0) {
                $rawPct = [math]::Round(($usd / $tot) * 100, 2)
                $qSummary = "$(Format-ByteSize $usd) / $(Format-ByteSize $tot) ($rawPct%)"
                $qPct = [math]::Max(2.0, [double]$rawPct)
            }
        } catch {}
    }

    $syncVis = if ($isSyncingThis -or $rt.WasPausedByUser) { "Visible" } else { "Collapsed" }
    $syncPct = [double]$rt.LastOverallPct
    $syncSum = ""
    if ($isSyncingThis) {
        $spdPart = if (-not [string]::IsNullOrWhiteSpace($rt.LastSpeedTxt)) { "  $([char]0x2022)  $($rt.LastSpeedTxt)" } else { "" }
        $syncSum = ("{0:N1}%{1}" -f $syncPct, $spdPart)
    } elseif ($rt.WasPausedByUser) {
        $syncSum = ("{0:N1}%  $([char]0x2022)  {1}" -f $syncPct, (L "trayPausedShort" "Paused"))
    }

    $dotHex = if ($isSyncingThis) { "#38BDF8" } elseif ($isMounted) { if ($isUniMember) { "#FBBF24" } else { "#10B981" } } elseif ($rt.WasPausedByUser) { "#F59E0B" } else { "#64748B" }
    $starCh = [string][char]0x2605
    $badgeTxt = if (-not [string]::IsNullOrWhiteSpace($ltr)) { if ($isUniMember) { "$starCh $ltr" } else { $ltr } } else { "" }
    $badgeBg     = if ($isMounted) { if ($isUniMember) { "#261D0B" } else { "#10243C" } } else { "#111A2B" }
    $badgeBorder = if ($isMounted) { if ($isUniMember) { "#D97706" } else { "#1E3B5C" } } else { if ($isUniMember) { "#5C4514" } else { "#25344D" } }
    $badgeFg     = if ($isMounted) { if ($isUniMember) { "#FBBF24" } else { "#38BDF8" } } else { if ($isUniMember) { "#B8933A" } else { "#64748B" } }
    return [PSCustomObject]@{
        Remote           = $TargetRemote
        DisplayName      = $disp
        DriveLetter      = $badgeTxt
        DriveBadgeVis    = if (-not [string]::IsNullOrWhiteSpace($badgeTxt)) { "Visible" } else { "Collapsed" }
        DriveBadgeBg     = $badgeBg
        DriveBadgeBorder = $badgeBorder
        DriveBadgeFg     = $badgeFg
        QuotaSummary  = $qSummary
        QuotaPct      = $qPct
        SyncVis       = $syncVis
        SyncPct       = $syncPct
        SyncSummary   = $syncSum
        DotBrush      = $dotHex
        CardBg        = if ($isActiveCard) { "#12233E" } else { "#0F1829" }
        CardBorder    = if ($isActiveCard) { "#38BDF8" } else { "#1C2A40" }
    }
}

function Refresh-SidebarAccountsOverview {
    param([switch]$ForceRefresh)
    try {
        $remotes = if ($ForceRefresh -or $script:CachedDriveRemotes.Count -eq 0) { @(Get-ConfiguredDriveRemotes -ForceRefresh) } else { @($script:CachedDriveRemotes) }
        if ($remotes.Count -eq 0) {
            if (Test-GDriveConfigured -TargetRemote $script:ActiveRemote) { $remotes = @($script:ActiveRemote) }
        }
        $script:CachedDriveRemotes = $remotes
        $mounts  = @(Get-MountsState)
        $uniSnap = Get-UnifiedMountInfo
        if ($null -ne $TxtSidebarAccountsCount) {
            $TxtSidebarAccountsCount.Text = "$($remotes.Count)"
        }
        $script:SidebarAccountCards.Clear()
        foreach ($r in $remotes) {
            try {
                $script:SidebarAccountCards.Add((Build-SidebarAccountCardObject -TargetRemote $r -Mounts $mounts -UniInfo $uniSnap -UniInfoProvided))
            } catch {}
        }
        Refresh-SettingsAccountsList -ForceRefresh:$ForceRefresh
    } catch {}
}

function Update-SidebarSingleAccountCard {
    param([string]$TargetRemote)
    if ([string]::IsNullOrWhiteSpace($TargetRemote)) { return }
    try {
        $mounts  = @(Get-MountsState)
        $uniSnap = Get-UnifiedMountInfo
        for ($i = 0; $i -lt $script:SidebarAccountCards.Count; $i++) {
            if ($script:SidebarAccountCards[$i].Remote -eq $TargetRemote) {
                $script:SidebarAccountCards[$i] = Build-SidebarAccountCardObject -TargetRemote $TargetRemote -Mounts $mounts -UniInfo $uniSnap -UniInfoProvided
                break
            }
        }
        Refresh-SettingsAccountsList
    } catch {}
}

function Build-SettingsAccountCardObject {
    param([string]$TargetRemote, [array]$Mounts, $UniInfo = $null, [switch]$UniInfoProvided)
    $disp = Get-AccountDisplayLabel -TargetRemote $TargetRemote
    $m = $Mounts | Where-Object { $_.Remote -eq $TargetRemote } | Select-Object -First 1
    $ltr = if ($null -ne $m) { $m.Letter } else { Get-MountedLetterForRemote -TargetRemote $TargetRemote }
    $isUniMember = $false
    $isMounted   = ($null -ne $ltr)
    $uniInfo = if ($UniInfoProvided) { $UniInfo } else { Get-UnifiedMountInfo }
    if (-not $isMounted -and $null -ne $uniInfo -and -not [string]::IsNullOrWhiteSpace($uniInfo.Letter)) {
        if ($uniInfo.Remotes.Count -eq 0 -or ($uniInfo.Remotes -contains $TargetRemote)) {
            $ltr = $uniInfo.Letter
            $isUniMember = $true
            $isMounted   = $true
        }
    }
    $assign = Get-AccountDriveAssignment -TargetRemote $TargetRemote
    if (-not $isMounted) {
        if ($assign -eq "Unified") {
            $ltr = Get-AutoUnifiedDriveLetter
            $isUniMember = $true
        } else {
            $ltr = Get-AccountPreferredDrive -TargetRemote $TargetRemote -DefaultLetter ""
        }
    }

    $isActive = ($TargetRemote -eq $script:ActiveRemote)

    $qSummary = "-- / --"
    if ($script:LastAboutCache.ContainsKey($TargetRemote) -and -not [string]::IsNullOrWhiteSpace($script:LastAboutCache[$TargetRemote])) {
        try {
            $ab = $script:LastAboutCache[$TargetRemote] | ConvertFrom-Json
            $tot = [double]$ab.total; $usd = [double]$ab.used
            if ($tot -gt 0) {
                $rawPct = [math]::Round(($usd / $tot) * 100, 2)
                $qSummary = "$(Format-ByteSize $usd) / $(Format-ByteSize $tot) ($rawPct%)"
            }
        } catch {}
    }

    $starCh = [string][char]0x2605
    $badgeTxt = if (-not [string]::IsNullOrWhiteSpace($ltr)) { if ($isUniMember) { "$starCh $ltr" } else { $ltr } } else { "" }
    $badgeBg     = if ($isMounted) { if ($isUniMember) { "#261D0B" } else { "#10243C" } } else { "#111A2B" }
    $badgeBorder = if ($isMounted) { if ($isUniMember) { "#D97706" } else { "#1E3B5C" } } else { if ($isUniMember) { "#5C4514" } else { "#25344D" } }
    $badgeFg     = if ($isMounted) { if ($isUniMember) { "#FBBF24" } else { "#38BDF8" } } else { if ($isUniMember) { "#B8933A" } else { "#64748B" } }
    $dotHex      = if ($isMounted) { if ($isUniMember) { "#FBBF24" } else { "#10B981" } } else { "#38BDF8" }

    $cardBg     = if ($isActive) { "#112240" } else { "#0A1322" }
    $cardBorder = if ($isActive) { "#38BDF8" } else { "#1C2A40" }
    $cardThick  = if ($isActive) { "2" } else { "1" }

    return [PSCustomObject]@{
        Remote              = $TargetRemote
        DisplayName         = $disp
        RemoteLabel         = "($TargetRemote)"
        DotBrush            = $dotHex
        DriveLetter         = $badgeTxt
        DriveBadgeVis       = if (-not [string]::IsNullOrWhiteSpace($badgeTxt)) { "Visible" } else { "Collapsed" }
        DriveBadgeBg        = $badgeBg
        DriveBadgeBorder    = $badgeBorder
        DriveBadgeFg        = $badgeFg
        QuotaSummary        = $qSummary
        CardBg              = $cardBg
        CardBorder          = $cardBorder
        CardBorderThickness = $cardThick
        DefaultBadgeVis     = if ($isActive) { "Visible" } else { "Collapsed" }
        DefaultBadgeText    = (L "badgeDefaultAccount" "✓ الحساب الافتراضي")
        SetDefaultBtnVis    = if ($isActive) { "Collapsed" } else { "Visible" }
        SetDefaultBtnText   = (L "btnSetDefaultAccount" "تعيين كافتراضي")
        SetDefaultToolTip   = (L "tipSetDefault" "تعيين هذا الحساب كحساب افتراضي للمزامنة")
        ActiveBtnVis        = if ($isActive) { "Visible" } else { "Collapsed" }
        ActiveStatusText    = (L "btnCurrentDefault" "الافتراضي الحالي")
        OpenWebBtnText      = (L "openDriveWeb" "فتح Drive بالمتصفح")
        SignOutBtnText      = (L "signOut" "تسجيل الخروج")
    }
}

function Refresh-SettingsAccountsList {
    param([switch]$ForceRefresh)
    try {
        if ($null -eq $ListSettingsAccounts) { return }
        $remotes = if ($ForceRefresh -or $script:CachedDriveRemotes.Count -eq 0) { @(Get-ConfiguredDriveRemotes -ForceRefresh) } else { @($script:CachedDriveRemotes) }
        if ($remotes.Count -eq 0) {
            if (Test-GDriveConfigured -TargetRemote $script:ActiveRemote) { $remotes = @($script:ActiveRemote) }
        }
        $script:CachedDriveRemotes = $remotes
        $mounts  = @(Get-MountsState)
        $uniSnap = Get-UnifiedMountInfo
        if ($null -ne $TxtSettingsAccountsCount) {
            $TxtSettingsAccountsCount.Text = "$($remotes.Count)"
        }
        $script:SettingsAccountCards.Clear()
        foreach ($r in $remotes) {
            try {
                $script:SettingsAccountCards.Add((Build-SettingsAccountCardObject -TargetRemote $r -Mounts $mounts -UniInfo $uniSnap -UniInfoProvided))
            } catch {}
        }
    } catch {}
}

# ==============================================================================
# SEQUENTIAL NON-BLOCKING ACCOUNT HYDRATION QUEUE (Account #1 -> #2 -> ... #N)
# Never blocks window launch or UI clicks even with 10-50+ Google Drive accounts!
# ==============================================================================
$script:HydrateQueue       = New-Object System.Collections.Generic.List[string]
$script:HydrateTimer       = $null
$script:HydrateCurrentRem  = $null
$script:HydratePhase       = "Idle"
$script:HydrateProc        = $null
$script:HydrateOutTask     = $null
$script:HydrateWebClient   = $null
$script:HydrateWebTask     = $null
$script:HydrateStartUtc    = [datetime]::MinValue
$script:HydrateDoneCount   = 0
$script:HydrateTotalCount  = 0
$script:HydrateRefreshedUtc = @{}

function Stop-SequentialAccountHydration {
    try { if ($null -ne $script:HydrateTimer) { $script:HydrateTimer.Stop() } } catch {}
    try {
        if ($null -ne $script:HydrateProc) {
            if (-not $script:HydrateProc.HasExited) { $script:HydrateProc.Kill() }
            $script:HydrateProc.Dispose()
            $script:HydrateProc = $null
        }
    } catch {}
    try {
        if ($null -ne $script:HydrateWebClient) {
            $script:HydrateWebClient.CancelAsync()
            $script:HydrateWebClient.Dispose()
            $script:HydrateWebClient = $null
        }
    } catch {}
    $script:HydrateOutTask    = $null
    $script:HydrateWebTask    = $null
    $script:HydrateCurrentRem = $null
    $script:HydratePhase      = "Idle"
    $script:HydrateQueue.Clear()
}

function Apply-HydratedAccountToUi {
    param([string]$TargetRemote)
    try {
        Update-SidebarSingleAccountCard -TargetRemote $TargetRemote
        if ($TargetRemote -eq $script:ActiveRemote) {
            Update-DriveQuotaDisplay -UseCache
            $bc = New-Object System.Windows.Media.BrushConverter
            $ident = Get-ConnectedGoogleIdentity -TargetRemote $TargetRemote -CacheOnly
            $dispLabel = Get-AccountDisplayLabel -TargetRemote $TargetRemote
            if ($ident.Connected) {
                $idDisplay = if (-not [string]::IsNullOrWhiteSpace($ident.DisplayName)) { "$($ident.Email) ($($ident.DisplayName))" } else { $ident.Email }
                $TxtAccountStatus.Text    = Wrap-Ltr $idDisplay
                $TxtAccountStatus.ToolTip = $idDisplay
                $DotAccount.Fill          = $bc.ConvertFromString("#10B981")
                if ($null -ne $TxtSettingsAccount) { $TxtSettingsAccount.Text = if ($idDisplay -ieq $dispLabel) { Wrap-Ltr $dispLabel } else { Wrap-Ltr "$dispLabel  --  $idDisplay" } }
                if ($null -ne $DotSettingsAccount) { $DotSettingsAccount.Fill = $bc.ConvertFromString("#10B981") }
                $BtnCustomClientId.Content = if ($ident.HasCustomClientId) { L "apiKeyActive" } else { L "apiKey" }
            }
        }
        # Refresh dropdown label if AutoName was just discovered
        $prevR = $script:IsRefreshing
        $script:IsRefreshing = $true
        try {
            $newLbl = Get-AccountDisplayLabel -TargetRemote $TargetRemote
            foreach ($ci in $CmbAccountProfile.Items) {
                if ($ci -is [System.Windows.Controls.ComboBoxItem] -and [string]$ci.Tag -eq $TargetRemote -and [string]$ci.Content -ne $newLbl) {
                    $ci.Content = $newLbl
                }
            }
        } finally { $script:IsRefreshing = $prevR }
    } catch {}
}

function Step-SequentialAccountHydration {
    try {
        if ($script:AppShuttingDown) { Stop-SequentialAccountHydration; return }
        $now = [datetime]::UtcNow

        if ($script:HydratePhase -eq "About") {
            $timedOut = (($now - $script:HydrateStartUtc).TotalSeconds -ge 12.0)
            if ($null -eq $script:HydrateProc -or $script:HydrateProc.HasExited -or $timedOut) {
                $rem = $script:HydrateCurrentRem
                $aboutOk = $false
                try {
                    if ($null -ne $script:HydrateProc) {
                        if (-not $script:HydrateProc.HasExited) { $script:HydrateProc.Kill() }
                        elseif ($script:HydrateProc.ExitCode -eq 0 -and $null -ne $script:HydrateOutTask) {
                            $txt = $script:HydrateOutTask.GetAwaiter().GetResult()
                            if (-not [string]::IsNullOrWhiteSpace($txt)) {
                                $script:LastAboutCache[$rem] = $txt
                                $aboutOk = $true
                            }
                        }
                        $script:HydrateProc.Dispose()
                    }
                } catch {}
                $script:HydrateProc    = $null
                $script:HydrateOutTask = $null

                if ($aboutOk) {
                    Save-UiAccountCache
                    Apply-HydratedAccountToUi -TargetRemote $rem
                }

                # Check if identity email needs fresh fetch (missing email or older than 10 min)
                $needIdentity = $true
                if ($script:IdentityCache.ContainsKey($rem) -and -not [string]::IsNullOrWhiteSpace($script:IdentityCache[$rem].Email) -and $script:IdentityCache[$rem].Email.Contains("@")) {
                    $cu = if ($script:IdentityCache[$rem].PSObject.Properties["CachedUtc"]) { [string]$script:IdentityCache[$rem].CachedUtc } else { "" }
                    $parsedDt = [datetime]::MinValue
                    if (-not [string]::IsNullOrWhiteSpace($cu) -and [datetime]::TryParse($cu, [ref]$parsedDt)) {
                        if (([datetime]::UtcNow - $parsedDt.ToUniversalTime()).TotalMinutes -lt 10.0) { $needIdentity = $false }
                    }
                }

                $startedIdentity = $false
                if ($needIdentity) {
                    try {
                        $dump = Get-RcloneConfigDumpCached -ForceRefresh
                        if ($null -ne $dump -and $dump.PSObject.Properties[$rem]) {
                            $remObj = $dump.$rem
                            if ($null -ne $remObj -and -not [string]::IsNullOrWhiteSpace($remObj.token)) {
                                $tok = $remObj.token | ConvertFrom-Json
                                if (-not [string]::IsNullOrWhiteSpace($tok.access_token)) {
                                    $wc = New-Object System.Net.WebClient
                                    $wc.Encoding = [System.Text.Encoding]::UTF8
                                    $wc.Headers.Add("Authorization", "Bearer $($tok.access_token)")
                                    $script:HydrateWebClient = $wc
                                    $script:HydrateWebTask   = $wc.DownloadStringTaskAsync("https://www.googleapis.com/drive/v3/about?fields=user(displayName,emailAddress)")
                                    $script:HydrateStartUtc  = [datetime]::UtcNow
                                    $script:HydratePhase     = "Identity"
                                    $startedIdentity = $true
                                }
                            }
                        }
                    } catch {}
                }

                if (-not $startedIdentity) {
                    $script:HydrateDoneCount++
                    $script:HydrateRefreshedUtc[$rem] = [datetime]::UtcNow
                    $script:HydrateCurrentRem = $null
                    $script:HydratePhase      = "Idle"
                }
            }
            return
        }

        if ($script:HydratePhase -eq "Identity") {
            $timedOut = (($now - $script:HydrateStartUtc).TotalSeconds -ge 8.0)
            if ($null -eq $script:HydrateWebTask -or $script:HydrateWebTask.IsCompleted -or $timedOut) {
                $rem = $script:HydrateCurrentRem
                try {
                    if ($null -ne $script:HydrateWebTask -and $script:HydrateWebTask.Status -eq [System.Threading.Tasks.TaskStatus]::RanToCompletion) {
                        $rawId = $script:HydrateWebTask.Result
                        if (-not [string]::IsNullOrWhiteSpace($rawId)) {
                            $info = $rawId | ConvertFrom-Json
                            if ($null -ne $info -and $null -ne $info.user -and -not [string]::IsNullOrWhiteSpace($info.user.emailAddress)) {
                                $hasCid = $false
                                $dmpC = Get-RcloneConfigDumpCached
                                if ($null -ne $dmpC -and $dmpC.PSObject.Properties[$rem] -and $null -ne $dmpC.$rem) {
                                    $hasCid = (-not [string]::IsNullOrWhiteSpace($dmpC.$rem.client_id))
                                }
                                $script:IdentityCache[$rem] = [PSCustomObject]@{
                                    Connected         = $true
                                    Email             = [string]$info.user.emailAddress
                                    DisplayName       = [string]$info.user.displayName
                                    Remote            = $rem
                                    HasCustomClientId = $hasCid
                                    CachedUtc         = ([datetime]::UtcNow.ToString("o"))
                                }
                                Set-AccountPref -Remote $rem -AutoName (Format-EmailUsername -Email $info.user.emailAddress -FallbackRemote $rem)
                                Save-UiAccountCache
                                Apply-HydratedAccountToUi -TargetRemote $rem
                            }
                        }
                    }
                } catch {}
                try {
                    if ($null -ne $script:HydrateWebClient) {
                        if ($timedOut) { $script:HydrateWebClient.CancelAsync() }
                        $script:HydrateWebClient.Dispose()
                    }
                } catch {}
                $script:HydrateWebClient  = $null
                $script:HydrateWebTask    = $null
                $script:HydrateDoneCount++
                $script:HydrateRefreshedUtc[$rem] = [datetime]::UtcNow
                $script:HydrateCurrentRem = $null
                $script:HydratePhase      = "Idle"
            }
            return
        }

        # Idle: pop the NEXT account strictly ONE AT A TIME
        if ($script:HydrateQueue.Count -eq 0) {
            if ($null -ne $script:HydrateTimer) { $script:HydrateTimer.Stop() }
            if ($script:HydrateTotalCount -gt 0) {
                Write-StudioLog -Msg "[OK] All $($script:HydrateTotalCount) connected account(s) refreshed sequentially." -TargetRemote $script:ActiveRemote
                $script:HydrateTotalCount = 0
            }
            return
        }

        $nextRem = $script:HydrateQueue[0]
        $script:HydrateQueue.RemoveAt(0)
        if ([string]::IsNullOrWhiteSpace($nextRem)) { return }

        $script:HydrateCurrentRem = $nextRem
        $script:HydratePhase      = "About"
        $script:HydrateStartUtc   = [datetime]::UtcNow

        $psi = New-Object System.Diagnostics.ProcessStartInfo
        $psi.FileName = $RcloneExe
        $psi.Arguments = "about $(Format-WinArg "${nextRem}:") --json --quiet"
        $psi.UseShellExecute = $false
        $psi.CreateNoWindow = $true
        $psi.RedirectStandardOutput = $true
        $psi.RedirectStandardError = $true
        $psi.StandardOutputEncoding = [System.Text.Encoding]::UTF8
        $script:HydrateProc    = [System.Diagnostics.Process]::Start($psi)
        $script:HydrateOutTask = $script:HydrateProc.StandardOutput.ReadToEndAsync()
    } catch {
        $script:HydrateCurrentRem = $null
        $script:HydratePhase      = "Idle"
    }
}

function Start-SequentialAccountHydration {
    param([string[]]$Remotes = $null)
    try {
        $allRems = if ($null -ne $Remotes -and $Remotes.Count -gt 0) { @($Remotes) } else { @(Get-ConfiguredDriveRemotes) }
        if ($allRems.Count -eq 0) { return }

        # Order strictly: Active account FIRST, then every other account one by one!
        $ordered = New-Object System.Collections.Generic.List[string]
        if ($allRems -contains $script:ActiveRemote) { $ordered.Add($script:ActiveRemote) }
        foreach ($r in $allRems) {
            if ($r -ne $script:ActiveRemote -and -not $ordered.Contains($r)) { $ordered.Add($r) }
        }

        $script:HydrateQueue.Clear()
        foreach ($r in $ordered) { $script:HydrateQueue.Add($r) }
        $script:HydrateDoneCount  = 0
        $script:HydrateTotalCount = $ordered.Count

        if ($null -eq $script:HydrateTimer) {
            $script:HydrateTimer = New-Object System.Windows.Threading.DispatcherTimer
            $script:HydrateTimer.Interval = [TimeSpan]::FromMilliseconds(110)
            $script:HydrateTimer.Add_Tick({ Step-SequentialAccountHydration })
        }
        $script:HydrateTimer.Start()
    } catch {}
}

function Promote-AccountInHydrationQueue {
    param([string]$TargetRemote)
    if ([string]::IsNullOrWhiteSpace($TargetRemote)) { return }
    try {
        if ($script:HydrateCurrentRem -eq $TargetRemote) { return }
        if ($script:HydrateRefreshedUtc.ContainsKey($TargetRemote) -and (([datetime]::UtcNow - $script:HydrateRefreshedUtc[$TargetRemote]).TotalSeconds -lt 45.0)) {
            return
        }
        [void]$script:HydrateQueue.Remove($TargetRemote)
        $script:HydrateQueue.Insert(0, $TargetRemote)
        if ($null -eq $script:HydrateTimer) {
            $script:HydrateTimer = New-Object System.Windows.Threading.DispatcherTimer
            $script:HydrateTimer.Interval = [TimeSpan]::FromMilliseconds(110)
            $script:HydrateTimer.Add_Tick({ Step-SequentialAccountHydration })
        }
        if (-not $script:HydrateTimer.IsEnabled) { $script:HydrateTimer.Start() }
    } catch {}
}

function Set-SplashStage {
    param([string]$Stage)
    try {
        if (-not [string]::IsNullOrWhiteSpace($env:ALPHACLOUDSYNC_SPLASH_FILE)) {
            [System.IO.File]::WriteAllText($env:ALPHACLOUDSYNC_SPLASH_FILE, $Stage, (New-Object System.Text.UTF8Encoding($false)))
        }
    } catch {}
}

$script:LatestAvailableVersion = ""
$script:UpdateCheckWebClient   = $null
$script:UpdateCheckTask        = $null
$script:UpdateCheckTimer       = $null
$script:UpdateToastShown       = $false

function Test-IsNewerReleaseVersion {
    param([string]$CurrentVer = $AppVersion, [string]$RemoteTag = "")
    if ([string]::IsNullOrWhiteSpace($RemoteTag)) { return $false }
    try {
        $cClean = ($CurrentVer.Trim() -replace '^[vV]', '' -replace '-.*$', '')
        $rClean = ($RemoteTag.Trim()  -replace '^[vV]', '' -replace '-.*$', '')
        $vCur = [version]$cClean
        $vRem = [version]$rClean
        return ($vRem -gt $vCur)
    } catch { return $false }
}

function Update-AppVersionBannerUi {
    try {
        if (-not [string]::IsNullOrWhiteSpace($script:LatestAvailableVersion)) {
            $verDisp = Wrap-Ltr "v$($script:LatestAvailableVersion)"
            if ($null -ne $TxtUpdateBanner) { $TxtUpdateBanner.Text = (LF "updateBannerBtn" @($verDisp)) }
            if ($null -ne $BtnUpdateBanner) { $BtnUpdateBanner.Visibility = "Visible" }
            if ($null -ne $TxtUpdateStatus) {
                $TxtUpdateStatus.Text = (LF "updateStatusAvail" @($verDisp))
                $TxtUpdateStatus.Foreground = (New-Object System.Windows.Media.BrushConverter).ConvertFromString("#4ADE80")
            }
        } else {
            if ($null -ne $BtnUpdateBanner) { $BtnUpdateBanner.Visibility = "Collapsed" }
            if ($null -ne $TxtUpdateStatus) {
                $curDisp = Wrap-Ltr "v$AppVersion"
                $TxtUpdateStatus.Text = (LF "updateStatusCurrent" @($curDisp))
                $TxtUpdateStatus.Foreground = (New-Object System.Windows.Media.BrushConverter).ConvertFromString("#94A3B8")
            }
        }
    } catch {}
}

function Start-BackgroundUpdateCheck {
    try {
        if ($null -ne $script:UpdateCheckTask -and -not $script:UpdateCheckTask.IsCompleted) { return }
        $wc = New-Object System.Net.WebClient
        $wc.Encoding = [System.Text.Encoding]::UTF8
        $wc.Headers.Add("User-Agent", "AlphaCloudSync/$AppVersion")
        $wc.Headers.Add("Accept", "application/vnd.github.v3+json")
        $script:UpdateCheckWebClient = $wc
        $script:UpdateCheckTask = $wc.DownloadStringTaskAsync("https://api.github.com/repos/AlphaAlgos/AlphaCloudSync/releases/latest")
        $script:UpdateCheckStartUtc = [datetime]::UtcNow
        if ($null -eq $script:UpdateCheckTimer) {
            $script:UpdateCheckTimer = New-Object System.Windows.Threading.DispatcherTimer
            $script:UpdateCheckTimer.Interval = [TimeSpan]::FromMilliseconds(400)
            $script:UpdateCheckTimer.Add_Tick({
                try {
                    if ($null -eq $script:UpdateCheckTask) { $script:UpdateCheckTimer.Stop(); return }
                    $elapsed = ([datetime]::UtcNow - $script:UpdateCheckStartUtc).TotalSeconds
                    if ($script:UpdateCheckTask.IsCompleted -or $elapsed -ge 12.0) {
                        $script:UpdateCheckTimer.Stop()
                        if ($script:UpdateCheckTask.IsCompleted -and -not $script:UpdateCheckTask.IsFaulted -and -not $script:UpdateCheckTask.IsCanceled) {
                            $rawJson = $script:UpdateCheckTask.Result
                            if (-not [string]::IsNullOrWhiteSpace($rawJson)) {
                                $relObj = $rawJson | ConvertFrom-Json
                                $tag = [string]$relObj.tag_name
                                if (Test-IsNewerReleaseVersion -CurrentVer $AppVersion -RemoteTag $tag) {
                                    $cleanV = ($tag.Trim() -replace '^[vV]', '')
                                    $script:LatestAvailableVersion = $cleanV
                                    Update-AppVersionBannerUi
                                    if (-not $script:UpdateToastShown) {
                                        $script:UpdateToastShown = $true
                                        Show-TrayToast -Title (L "toastUpdateAvailTitle" "AlphaCloudSync Update Available") -Body (LF "toastUpdateAvailBody" @("v$cleanV"))
                                    }
                                }
                            }
                        }
                        try { if ($null -ne $script:UpdateCheckWebClient) { $script:UpdateCheckWebClient.Dispose() } } catch {}
                        $script:UpdateCheckWebClient = $null
                        $script:UpdateCheckTask = $null
                    }
                } catch {
                    $script:UpdateCheckTimer.Stop()
                    $script:UpdateCheckWebClient = $null
                    $script:UpdateCheckTask = $null
                }
            })
        }
        $script:UpdateCheckTimer.Start()
    } catch {}
}

function Invoke-AppSelfUpdate {
    param([switch]$ManualCheck)
    try {
        if ($ManualCheck -and [string]::IsNullOrWhiteSpace($script:LatestAvailableVersion)) {
            Invoke-UiPump
            try {
                [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12
                $rel = Invoke-RestMethod -Uri "https://api.github.com/repos/AlphaAlgos/AlphaCloudSync/releases/latest" -Headers @{ "User-Agent" = "AlphaCloudSync/$AppVersion" } -TimeoutSec 12
                if ($null -ne $rel -and -not [string]::IsNullOrWhiteSpace([string]$rel.tag_name)) {
                    $tag = [string]$rel.tag_name
                    if (Test-IsNewerReleaseVersion -CurrentVer $AppVersion -RemoteTag $tag) {
                        $script:LatestAvailableVersion = ($tag.Trim() -replace '^[vV]', '')
                    }
                }
            } catch {}
            Update-AppVersionBannerUi
        }

        if ([string]::IsNullOrWhiteSpace($script:LatestAvailableVersion)) {
            Show-AlphaMessageBox -Message (LF "msgUpToDateBody" @("v$AppVersion")) -Title (L "msgUpToDateTitle" "Up to Date") -Buttons "OK" -Icon "Information" | Out-Null
            return
        }

        $newV = "v$($script:LatestAvailableVersion)"
        $curV = "v$AppVersion"
        $descT    = [System.Security.SecurityElement]::Escape((LF "msgConfirmUpdateBody" @($newV, $curV)))
        $updNowT  = [System.Security.SecurityElement]::Escape((L "btnUpdateNow" "Update Now"))
        $canT     = [System.Security.SecurityElement]::Escape((L "btnCancel" "Cancel"))
        $closeT   = [System.Security.SecurityElement]::Escape((L "btnClose" "Close"))
        $fetchT   = [System.Security.SecurityElement]::Escape((L "updStageFetch" "Connecting to GitHub and fetching release package..."))

        $body = @"
            <Grid>
                <Grid.RowDefinitions>
                    <RowDefinition Height="Auto"/>
                    <RowDefinition Height="Auto"/>
                    <RowDefinition Height="Auto"/>
                    <RowDefinition Height="Auto"/>
                </Grid.RowDefinitions>
                <StackPanel Grid.Row="0" Orientation="Horizontal" FlowDirection="LeftToRight" HorizontalAlignment="Center" Margin="0,0,0,12">
                    <Border Background="#111C30" BorderBrush="#263A59" BorderThickness="1" CornerRadius="6" Padding="10,4">
                        <TextBlock Text="$curV" Foreground="#94A3B8" FontWeight="SemiBold" FontSize="12.5"/>
                    </Border>
                    <TextBlock Text="  &#x2192;  " Foreground="#38BDF8" FontWeight="Bold" FontSize="14" VerticalAlignment="Center"/>
                    <Border Background="#0B2E22" BorderBrush="#10B981" BorderThickness="1" CornerRadius="6" Padding="10,4">
                        <TextBlock Text="$newV" Foreground="#34D399" FontWeight="Bold" FontSize="12.5"/>
                    </Border>
                </StackPanel>
                <TextBlock x:Name="TxtUpdDesc" Grid.Row="1" Text="$descT" TextWrapping="Wrap" Foreground="#CBD5E1" FontSize="12.5" LineHeight="20" Margin="0,0,0,14"/>
                <Border x:Name="PnlUpdProgress" Grid.Row="2" Visibility="Collapsed" Background="#0B1526" BorderBrush="#1E3A5F" BorderThickness="1" CornerRadius="8" Padding="12,10" Margin="0,0,0,14">
                    <StackPanel Orientation="Vertical">
                        <DockPanel LastChildFill="True" Margin="0,0,0,8">
                            <TextBlock x:Name="TxtUpdPct" DockPanel.Dock="Right" FlowDirection="LeftToRight" Text="0%" Foreground="#38BDF8" FontWeight="Bold" FontSize="12" Margin="8,0,0,0"/>
                            <TextBlock x:Name="TxtUpdStage" Text="$fetchT" TextWrapping="Wrap" Foreground="#E2E8F0" FontSize="12" FontWeight="SemiBold"/>
                        </DockPanel>
                        <ProgressBar x:Name="BarUpdProgress" FlowDirection="LeftToRight" Height="9" Minimum="0" Maximum="100" Value="0" Background="#070C15" Foreground="#38BDF8" BorderBrush="#1E3454"/>
                    </StackPanel>
                </Border>
                <StackPanel x:Name="PnlUpdActions" Grid.Row="3" Orientation="Horizontal" HorizontalAlignment="Right">
                    <Button x:Name="BtnStartUpdate" Content="$updNowT" Background="#10B981" BorderBrush="#34D399" Foreground="#FFFFFF" FontWeight="Bold" MinWidth="112" Margin="0,0,8,0"/>
                    <Button x:Name="BtnCancelUpdate" Content="$canT" MinWidth="86"/>
                    <Button x:Name="BtnCloseUpdErr" Content="$closeT" Visibility="Collapsed" MinWidth="86"/>
                </StackPanel>
            </Grid>
"@
        $updWin = New-AlphaModalWindow -Title (L "msgConfirmUpdateTitle" "Update AlphaCloudSync") -ReqWidth 500 -ReqHeight 290 -Resizable $false -BodyXaml $body
        $pnlProg  = $updWin.FindName("PnlUpdProgress")
        $txtStage = $updWin.FindName("TxtUpdStage")
        $txtPct   = $updWin.FindName("TxtUpdPct")
        $barProg  = $updWin.FindName("BarUpdProgress")
        $btnStart = $updWin.FindName("BtnStartUpdate")
        $btnCan   = $updWin.FindName("BtnCancelUpdate")
        $btnErrCl = $updWin.FindName("BtnCloseUpdErr")
        $bcUpd    = New-Object System.Windows.Media.BrushConverter

        $updState = [PSCustomObject]@{
            Phase         = "Idle"
            WebClient     = $null
            Task          = $null
            ExeTmp        = (Join-Path $LocalDataDir "pending-update.exe")
            SumsTmp       = (Join-Path $LocalDataDir "pending-update-sums.txt")
            ExeUrl        = ""
            SumsUrl       = ""
            ExpectedBytes = [int64]0
            FinishAtUtc   = [datetime]::MinValue
            ShouldQuitApp = $false
        }

        $updTimer = New-Object System.Windows.Threading.DispatcherTimer
        $updTimer.Interval = [TimeSpan]::FromMilliseconds(120)

        $showUpdFail = {
            param([string]$ErrMsg)
            try { $updTimer.Stop() } catch {}
            try { if ($null -ne $updState.WebClient) { $updState.WebClient.Dispose(); $updState.WebClient = $null } } catch {}
            Remove-Item -LiteralPath $updState.ExeTmp, $updState.SumsTmp -Force -ErrorAction SilentlyContinue
            $txtStage.Text = LF "updStageFailed" @($ErrMsg)
            $txtStage.Foreground = $bcUpd.ConvertFromString("#F87171")
            $barProg.Foreground  = $bcUpd.ConvertFromString("#EF4444")
            $btnErrCl.Visibility = "Visible"
            $updState.Phase = "Failed"
        }

        $updTimer.Add_Tick({
            try {
                switch ($updState.Phase) {
                    "WaitMeta" {
                        if ($updState.Task.IsCompleted) {
                            if ($updState.Task.IsFaulted -or $updState.Task.IsCanceled) {
                                $em = if ($updState.Task.Exception) { $updState.Task.Exception.InnerException.Message } else { "Network error" }
                                & $showUpdFail $em; return
                            }
                            $relObj = $updState.Task.Result | ConvertFrom-Json
                            $exeAsset  = $relObj.assets | Where-Object { $_.name -eq "AlphaCloudSync.exe" } | Select-Object -First 1
                            $sumsAsset = $relObj.assets | Where-Object { $_.name -eq "SHA256SUMS.txt" }     | Select-Object -First 1
                            if ($null -eq $exeAsset -or $null -eq $sumsAsset) {
                                & $showUpdFail "Release assets missing on GitHub."; return
                            }
                            if (($exeAsset.browser_download_url -notmatch '^https://') -or ($sumsAsset.browser_download_url -notmatch '^https://')) {
                                & $showUpdFail "Asset URL must use HTTPS."; return
                            }
                            $updState.ExeUrl        = [string]$exeAsset.browser_download_url
                            $updState.SumsUrl       = [string]$sumsAsset.browser_download_url
                            $updState.ExpectedBytes = [int64]$exeAsset.size
                            try { $updState.WebClient.Dispose() } catch {}

                            $barProg.Value = 12; $txtPct.Text = "12%"
                            $wcSums = New-Object System.Net.WebClient
                            $wcSums.Headers.Add("User-Agent", "AlphaCloudSync/$AppVersion")
                            $updState.WebClient = $wcSums
                            $updState.Task      = $wcSums.DownloadFileTaskAsync([Uri]$updState.SumsUrl, $updState.SumsTmp)
                            $updState.Phase     = "WaitSums"
                        }
                    }
                    "WaitSums" {
                        if ($updState.Task.IsCompleted) {
                            if ($updState.Task.IsFaulted -or $updState.Task.IsCanceled) {
                                $em = if ($updState.Task.Exception) { $updState.Task.Exception.InnerException.Message } else { "Checksum download failed" }
                                & $showUpdFail $em; return
                            }
                            try { $updState.WebClient.Dispose() } catch {}

                            $barProg.Value = 16; $txtPct.Text = "16%"
                            $txtStage.Text = LF "updStageDownload" @($newV, 0, "0 KB / $(Format-ByteSize $updState.ExpectedBytes)")
                            $wcExe = New-Object System.Net.WebClient
                            $wcExe.Headers.Add("User-Agent", "AlphaCloudSync/$AppVersion")
                            $updState.WebClient = $wcExe
                            $updState.Task      = $wcExe.DownloadFileTaskAsync([Uri]$updState.ExeUrl, $updState.ExeTmp)
                            $updState.Phase     = "WaitExe"
                        }
                    }
                    "WaitExe" {
                        $curBytes = [int64]0
                        if (Test-Path -LiteralPath $updState.ExeTmp) {
                            try { $curBytes = (Get-Item -LiteralPath $updState.ExeTmp).Length } catch {}
                        }
                        if ($updState.ExpectedBytes -gt 0 -and $curBytes -gt 0) {
                            $dlPct = [int][math]::Min(99, [math]::Floor(([double]$curBytes / [double]$updState.ExpectedBytes) * 100.0))
                            $barVal = [int][math]::Min(86, 16 + [math]::Round($dlPct * 0.70))
                            $barProg.Value = $barVal
                            $txtPct.Text   = "$barVal%"
                            $txtStage.Text = LF "updStageDownload" @($newV, $dlPct, "$(Format-ByteSize $curBytes) / $(Format-ByteSize $updState.ExpectedBytes)")
                        }
                        if ($updState.Task.IsCompleted) {
                            if ($updState.Task.IsFaulted -or $updState.Task.IsCanceled) {
                                $em = if ($updState.Task.Exception) { $updState.Task.Exception.InnerException.Message } else { "Binary download failed" }
                                & $showUpdFail $em; return
                            }
                            try { $updState.WebClient.Dispose(); $updState.WebClient = $null } catch {}
                            $barProg.Value = 90; $txtPct.Text = "90%"
                            $txtStage.Text = L "updStageVerify" "Verifying SHA-256 security checksum..."
                            $updState.Phase = "VerifyAndSwap"
                        }
                    }
                    "VerifyAndSwap" {
                        $updState.Phase = "Verifying"
                        # Fail-Closed SHA-256 Verification
                        $expectedHash = $null
                        foreach ($ln in @(Get-Content -LiteralPath $updState.SumsTmp -ErrorAction Stop)) {
                            if ($ln.Trim() -match '^([a-fA-F0-9]{64})\s+\*?(.+)$') {
                                if ($Matches[2].Trim() -ieq "AlphaCloudSync.exe") {
                                    $expectedHash = $Matches[1].ToLowerInvariant(); break
                                }
                            }
                        }
                        if ([string]::IsNullOrWhiteSpace($expectedHash)) {
                            & $showUpdFail "SHA-256 entry missing in SHA256SUMS.txt (Fail-Closed)."; return
                        }
                        $actualHash = (Get-FileHash -LiteralPath $updState.ExeTmp -Algorithm SHA256).Hash.ToLowerInvariant()
                        if ($actualHash -ne $expectedHash) {
                            & $showUpdFail "SHA-256 checksum mismatch (Fail-Closed)."; return
                        }

                        # Verified! Prepare atomic swap + clean relaunch with visible Splash Screen
                        $barProg.Value      = 100
                        $txtPct.Text        = "100%"
                        $barProg.Foreground = $bcUpd.ConvertFromString("#10B981")
                        $txtPct.Foreground  = $bcUpd.ConvertFromString("#34D399")
                        $txtStage.Text      = L "updStageRestart" "Verified! Installing update and restarting..."
                        $txtStage.Foreground= $bcUpd.ConvertFromString("#4ADE80")
                        Write-StudioLog -Msg "[UPDATE] AlphaCloudSync $newV verified (SHA-256: $actualHash). Restarting cleanly..." -TargetRemote $script:ActiveRemote

                        $destExe = if (-not [string]::IsNullOrWhiteSpace($AppLaunchExe) -and (Test-Path -LiteralPath $AppLaunchExe)) {
                            $AppLaunchExe
                        } else {
                            Join-Path $env:LOCALAPPDATA "AlphaCloudSync\app\AlphaCloudSync.exe"
                        }
                        Remove-Item -LiteralPath $updState.SumsTmp -Force -ErrorAction SilentlyContinue
                        # Pure native C# atomic self-update (zero hidden PowerShell, zero temp scripts!)
                        $psiSwap = New-Object System.Diagnostics.ProcessStartInfo
                        $psiSwap.FileName = $updState.ExeTmp
                        $psiSwap.Arguments = "--apply-update `"$destExe`" $PID"
                        $psiSwap.WorkingDirectory = $LocalDataDir
                        $psiSwap.UseShellExecute = $true
                        [void][System.Diagnostics.Process]::Start($psiSwap)

                        $updState.ShouldQuitApp = $true
                        $updState.FinishAtUtc   = [datetime]::UtcNow.AddMilliseconds(550)
                        $updState.Phase         = "ClosingToRestart"
                    }
                    "ClosingToRestart" {
                        if ([datetime]::UtcNow -ge $updState.FinishAtUtc) {
                            $updTimer.Stop()
                            try { $updWin.Close() } catch {}
                        }
                    }
                }
            } catch {
                & $showUpdFail $_.Exception.Message
            }
        })

        $btnStart.Add_Click({
            try {
                [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12
                $btnStart.Visibility = "Collapsed"
                $btnCan.Visibility   = "Collapsed"
                $pnlProg.Visibility  = "Visible"
                $barProg.Value       = 6
                $txtPct.Text         = "6%"
                $txtStage.Text       = L "updStageFetch" "Connecting to GitHub and fetching release package..."
                $wcMeta = New-Object System.Net.WebClient
                $wcMeta.Encoding = [System.Text.Encoding]::UTF8
                $wcMeta.Headers.Add("User-Agent", "AlphaCloudSync/$AppVersion")
                $wcMeta.Headers.Add("Accept", "application/vnd.github.v3+json")
                $updState.WebClient = $wcMeta
                $updState.Task      = $wcMeta.DownloadStringTaskAsync("https://api.github.com/repos/AlphaAlgos/AlphaCloudSync/releases/latest")
                $updState.Phase     = "WaitMeta"
                $updTimer.Start()
            } catch {
                & $showUpdFail $_.Exception.Message
            }
        })

        $btnCan.Add_Click({ param($s,$e) try { $wObj = [System.Windows.Window]::GetWindow($s); if ($null -ne $wObj) { $wObj.Close() } } catch {} })
        $btnErrCl.Add_Click({ param($s,$e) try { $wObj = [System.Windows.Window]::GetWindow($s); if ($null -ne $wObj) { $wObj.Close() } } catch {} })
        $updWin.Add_Closed({
            try { $updTimer.Stop() } catch {}
            if (-not $updState.ShouldQuitApp) {
                try { if ($null -ne $updState.WebClient) { $updState.WebClient.CancelAsync(); $updState.WebClient.Dispose() } } catch {}
                Remove-Item -LiteralPath $updState.ExeTmp, $updState.SumsTmp -Force -ErrorAction SilentlyContinue
            }
        })

        [void]$updWin.ShowDialog()

        if ($updState.ShouldQuitApp) {
            Stop-AlphaCloudSyncApp
        }
    } catch {
        Write-StudioLog "[ERR] Update check failed: $($_.Exception.Message)"
    }
}

$BtnUpdateBanner.Add_Click({ Invoke-AppSelfUpdate })
$BtnCheckUpdates.Add_Click({ Invoke-AppSelfUpdate -ManualCheck })

function Invoke-PostStartupHousekeep {
    try {
        $script:SkipWmiMountProbe = $false
        $cfgInit = Get-Settings
        if ([bool]$cfgInit.ShowFolderBadges) { Sync-AllFolderAndDriveBadges -Enable $true }
        $null = Set-ExplorerContextMenuEnabled -Enable ([bool]$cfgInit.ExplorerContextMenu)
        Sync-RealTimeWatchers
        if ($script:IslandEnabled) { Set-CloudIslandEnabled -Enable $true }
        Refresh-StudioHeader
        Start-SequentialAccountHydration
        Start-BackgroundUpdateCheck
        if (-not [string]::IsNullOrWhiteSpace($script:PendingContextAction)) {
            $actC = $script:PendingContextAction; $pthC = $script:PendingContextPath
            $script:PendingContextAction = ""; $script:PendingContextPath = ""
            Invoke-HandleContextCommand -ContextAction $actC -FolderPath $pthC
        } elseif ($AutoStartSync) {
            Start-StudioBatch -Mode "Sync"
        }
        Invoke-DrainIpcQueue
    } catch {}
}

[System.Windows.Threading.Dispatcher]::CurrentDispatcher.add_UnhandledException({
    param($sender, $e)
    $e.Handled = $true
    Write-StudioLog "[UI-GUARD] Safely handled error: $($e.Exception.Message)"
})

function Invoke-UiPump {
    try { [System.Windows.Threading.Dispatcher]::CurrentDispatcher.Invoke([Action]{}, [System.Windows.Threading.DispatcherPriority]::Background) } catch {}
}
