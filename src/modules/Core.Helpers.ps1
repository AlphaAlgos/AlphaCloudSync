# ==============================================================================
# AlphaCloudSync Module: Core.Helpers (BiDi, 12h Time, Math, i18n, Process, Dark MsgBox)
# ==============================================================================

# ==============================================================================
# PURE HELPERS: BIDI, 12-HOUR AM/PM TIME, PROGRESS MATH, WORKAREA CLAMPING, i18n
# ==============================================================================
$script:InvCulture = [System.Globalization.CultureInfo]::InvariantCulture
$script:LRM = [char]0x200E
$script:RLM = [char]0x200F
$script:LRE = [char]0x202A
$script:PDF = [char]0x202C
$script:CurrentLocale = $null
$script:AlphaSoundPlayer = $null

function Play-AlphaSound {
    param(
        [ValidateSet("UploadComplete", "PreviewComplete", "Activation", "Update")]
        [string]$Cue
    )
    $soundFile = switch ($Cue) {
        "UploadComplete"  { "chime.mp3" }
        "PreviewComplete" { "ping.mp3" }
        "Activation"      { "sparkle.mp3" }
        "Update"          { "notification.mp3" }
    }
    $soundPath = Join-Path $AssetsDir (Join-Path "sounds" $soundFile)
    if (-not (Test-Path -LiteralPath $soundPath -PathType Leaf)) { return }
    try {
        Add-Type -AssemblyName PresentationCore -ErrorAction Stop
        if ($null -ne $script:AlphaSoundPlayer) {
            try { $script:AlphaSoundPlayer.Stop(); $script:AlphaSoundPlayer.Close() } catch {}
        }
        $player = New-Object System.Windows.Media.MediaPlayer
        $player.Volume = 0.42
        $player.Add_MediaOpened({
            param($sender, $eventArgs)
            try { $sender.Play() } catch {}
        })
        $player.Open([System.Uri]::new($soundPath))
        $script:AlphaSoundPlayer = $player
    } catch {}
}

function Wrap-Ltr {
    param([string]$Text)
    if ([string]::IsNullOrEmpty($Text)) { return $Text }
    return "$($script:LRE)$Text$($script:PDF)"
}

function Wrap-RtlLead {
    param([string]$Text)
    if ([string]::IsNullOrEmpty($Text)) { return $Text }
    if ($null -ne $script:CurrentLocale -and $script:CurrentLocale.rtl) {
        return "$($script:RLM)$Text"
    }
    return $Text
}

function Set-SplashStage {
    param([string]$Stage)
    try {
        if (-not [string]::IsNullOrWhiteSpace($env:ALPHACLOUDSYNC_SPLASH_FILE)) {
            [System.IO.File]::WriteAllText($env:ALPHACLOUDSYNC_SPLASH_FILE, $Stage, (New-Object System.Text.UTF8Encoding($false)))
        }
    } catch {}
}

function Format-Time12h {
    param([datetime]$DateTime = (Get-Date), [switch]$WithSeconds)
    $fmt = if ($WithSeconds) { "hh:mm:ss tt" } else { "hh:mm tt" }
    return $DateTime.ToString($fmt, $script:InvCulture)
}

function Convert-Time12hTo24h {
    param([int]$Hour12, [int]$Minute, [string]$Period = "PM")
    if ($Hour12 -lt 1 -or $Hour12 -gt 12 -or $Minute -lt 0 -or $Minute -gt 59) { return $null }
    $p = $Period.Trim().ToUpperInvariant()
    if ($p -ne "AM" -and $p -ne "PM") { return $null }
    $h24 = if ($p -eq "AM") {
        if ($Hour12 -eq 12) { 0 } else { $Hour12 }
    } else {
        if ($Hour12 -eq 12) { 12 } else { $Hour12 + 12 }
    }
    return ("{0:D2}:{1:D2}" -f $h24, $Minute)
}

function Compute-OverallBatchProgress {
    param(
        [double]$CompletedWeight,
        [double]$CurrentWeight,
        [double]$TotalWeight,
        [double]$CurrentFolderPct
    )
    if ($TotalWeight -le 0) { return 0.0 }
    $clampedFolder = [math]::Max(0.0, [math]::Min(100.0, $CurrentFolderPct))
    $doneWeight = $CompletedWeight + ($CurrentWeight * ($clampedFolder / 100.0))
    $pct = [math]::Round(($doneWeight / $TotalWeight) * 100.0, 1)
    return [math]::Max(0.0, [math]::Min(100.0, $pct))
}

function Compute-ClampedWindowBounds {
    param(
        [double]$WorkLeft,
        [double]$WorkTop,
        [double]$WorkWidth,
        [double]$WorkHeight,
        [Nullable[double]]$SavedLeft = $null,
        [Nullable[double]]$SavedTop = $null,
        [Nullable[double]]$SavedWidth = $null,
        [Nullable[double]]$SavedHeight = $null,
        [bool]$UseSavedPosition = $false
    )
    $minW = [math]::Min(780.0, [math]::Max(480.0, $WorkWidth - 16.0))
    $minH = [math]::Min(540.0, [math]::Max(360.0, $WorkHeight - 16.0))
    $defW = [math]::Max($minW, [math]::Min(1180.0, [math]::Round($WorkWidth * 0.92)))
    $defH = [math]::Max($minH, [math]::Min(760.0,  [math]::Round($WorkHeight * 0.91)))

    $w = if ($null -ne $SavedWidth  -and $SavedWidth  -gt 100) { [double]$SavedWidth  } else { $defW }
    $h = if ($null -ne $SavedHeight -and $SavedHeight -gt 100) { [double]$SavedHeight } else { $defH }
    $w = [math]::Max($minW, [math]::Min($w, $WorkWidth))
    $h = [math]::Max($minH, [math]::Min($h, $WorkHeight))

    $maxLeft = $WorkLeft + [math]::Max(0.0, $WorkWidth - $w)
    $maxTop  = $WorkTop  + [math]::Max(0.0, $WorkHeight - $h)

    if ($UseSavedPosition -and $null -ne $SavedLeft -and $null -ne $SavedTop) {
        $l = [math]::Max($WorkLeft, [math]::Min([double]$SavedLeft, $maxLeft))
        $t = [math]::Max($WorkTop,  [math]::Min([double]$SavedTop,  $maxTop))
    } else {
        $l = $WorkLeft + (($WorkWidth  - $w) / 2.0)
        $t = $WorkTop  + (($WorkHeight - $h) / 2.0)
    }

    return [PSCustomObject]@{
        Left      = [math]::Round($l, 1)
        Top       = [math]::Round($t, 1)
        Width     = [math]::Round($w, 1)
        Height    = [math]::Round($h, 1)
        MinWidth  = [math]::Round($minW, 1)
        MinHeight = [math]::Round($minH, 1)
    }
}

function Select-AvailableDriveLetters {
    param(
        [string[]]$UsedLetters = @(),
        [string]$OwnedLetter = "",
        [string]$Preferred = "",
        [string[]]$ReservedLetters = @()
    )
    $usedSet = @($UsedLetters + $ReservedLetters | Where-Object { -not [string]::IsNullOrWhiteSpace($_) } | ForEach-Object { $_.ToUpperInvariant() } | Sort-Object -Unique)
    $ownedUp = if ([string]::IsNullOrWhiteSpace($OwnedLetter)) { "" } else { $OwnedLetter.ToUpperInvariant() }
    $prefUp  = if ([string]::IsNullOrWhiteSpace($Preferred))   { "" } else { $Preferred.ToUpperInvariant() }
    $letters = @()
    foreach ($code in (@(71..90) + @(68..70))) { # G..Z first, then D..F
        $l = "$([char]$code):"
        if (($usedSet -notcontains $l) -or ($l -eq $ownedUp)) { $letters += $l }
    }
    if (-not [string]::IsNullOrWhiteSpace($prefUp) -and ($letters -contains $prefUp)) {
        $letters = @($prefUp) + @($letters | Where-Object { $_ -ne $prefUp })
    }
    return $letters
}

function Get-LocaleDict {
    param([string]$LangCode = "en")
    $code = if ([string]::IsNullOrWhiteSpace($LangCode)) { "en" } else { $LangCode.ToLowerInvariant().Trim() }
    if ($code -notmatch '^[a-z]{2,5}$') { $code = "en" }
    $path = Join-Path $LocalesDir "$code.json"
    if (-not (Test-Path -LiteralPath $path)) { $path = Join-Path $LocalesDir "en.json" }
    if (Test-Path -LiteralPath $path) {
        try { return ([System.IO.File]::ReadAllText($path, [System.Text.Encoding]::UTF8) | ConvertFrom-Json) } catch {}
    }
    return $null
}

function Format-WinArg {
    param([string]$Value)
    if ($null -eq $Value -or $Value.Length -eq 0) { return '""' }
    $sb = New-Object System.Text.StringBuilder
    [void]$sb.Append('"')
    $bs = 0
    for ($i = 0; $i -lt $Value.Length; $i++) {
        $ch = $Value[$i]
        if ($ch -eq '\') {
            $bs++
        } elseif ($ch -eq '"') {
            [void]$sb.Append('\', ($bs * 2 + 1))
            [void]$sb.Append('"')
            $bs = 0
        } else {
            if ($bs -gt 0) { [void]$sb.Append('\', $bs); $bs = 0 }
            [void]$sb.Append($ch)
        }
    }
    if ($bs -gt 0) { [void]$sb.Append('\', ($bs * 2)) }
    [void]$sb.Append('"')
    return $sb.ToString()
}

function L {
    param([string]$Key, [string]$Fallback = "")
    if ($null -ne $script:CurrentLocale -and $script:CurrentLocale.PSObject.Properties[$Key]) {
        $val = [string]$script:CurrentLocale.$Key
        if (-not [string]::IsNullOrEmpty($val)) { return $val }
    }
    if (-not [string]::IsNullOrEmpty($Fallback)) { return $Fallback }
    return $Key
}

function LF {
    param([string]$Key, [object[]]$ArgsList = @(), [string]$Fallback = "")
    $tpl = L -Key $Key -Fallback $Fallback
    if ($null -eq $ArgsList -or $ArgsList.Count -eq 0) { return $tpl }
    try { return ($tpl -f $ArgsList) } catch { return $tpl }
}

function Invoke-SilentProcess {
    param([string]$FilePath, [string]$Arguments = "", [int]$TimeoutMs = 30000)
    $proc = $null
    try {
        $psi = New-Object System.Diagnostics.ProcessStartInfo
        $psi.FileName = $FilePath
        $psi.Arguments = $Arguments
        $psi.UseShellExecute = $false
        $psi.CreateNoWindow = $true
        $psi.RedirectStandardOutput = $true
        $psi.RedirectStandardError = $true
        $psi.StandardOutputEncoding = [System.Text.Encoding]::UTF8
        $psi.StandardErrorEncoding = [System.Text.Encoding]::UTF8
        $proc = [System.Diagnostics.Process]::Start($psi)
        $outTask = $proc.StandardOutput.ReadToEndAsync()
        $errTask = $proc.StandardError.ReadToEndAsync()
        if ($TimeoutMs -le 0) {
            $proc.WaitForExit()
            return [PSCustomObject]@{ ExitCode = $proc.ExitCode; StdOut = $outTask.Result; StdErr = $errTask.Result }
        }
        $done = $proc.WaitForExit($TimeoutMs)
        if (-not $done) {
            try { $proc.Kill() } catch {}
            return [PSCustomObject]@{ ExitCode = -1; StdOut = ""; StdErr = "Timeout" }
        }
        return [PSCustomObject]@{ ExitCode = $proc.ExitCode; StdOut = $outTask.Result; StdErr = $errTask.Result }
    } catch {
        return [PSCustomObject]@{ ExitCode = -1; StdOut = ""; StdErr = $_.Exception.Message }
    } finally {
        if ($null -ne $proc) { try { $proc.Dispose() } catch {} }
    }
}

function Show-AlphaMessageBox {
    param(
        [string]$Message,
        [string]$Title = "AlphaCloudSync",
        [string]$Buttons = "OK",
        [string]$Icon = "Information"
    )
    try {
        Add-Type -AssemblyName PresentationFramework -ErrorAction SilentlyContinue
        Add-Type -AssemblyName PresentationCore -ErrorAction SilentlyContinue
        Add-Type -AssemblyName WindowsBase -ErrorAction SilentlyContinue

        $flowDir = if ($null -ne $script:CurrentLocale -and $script:CurrentLocale.rtl) { "RightToLeft" } else { "LeftToRight" }
        $safeTitle = [System.Security.SecurityElement]::Escape($(if ([string]::IsNullOrWhiteSpace($Title)) { "AlphaCloudSync" } else { $Title }))
        $safeMsg   = [System.Security.SecurityElement]::Escape($Message)
        $closeTip  = [System.Security.SecurityElement]::Escape((L "tipClose" "Close"))

        $icoBg = "#0D291E"; $icoBorder = "#10B981"; $icoFg = "#34D399"; $icoGlyph = "M 10,5 V 6 M 10,9 V 15"
        switch ($Icon) {
            "Question" { $icoBg = "#0F243D"; $icoBorder = "#38BDF8"; $icoFg = "#38BDF8"; $icoGlyph = "M 7.5,7.2 C 7.5,5.5 8.6,4.5 10.2,4.5 C 11.8,4.5 12.8,5.5 12.8,6.8 C 12.8,8.2 11.4,8.8 10.2,9.6 C 9.9,9.8 9.8,10.3 9.8,11.2 M 9.8,14.5 V 15.2" }
            "Warning"  { $icoBg = "#2E200C"; $icoBorder = "#F59E0B"; $icoFg = "#FBBF24"; $icoGlyph = "M 10,4.5 V 11 M 10,14.2 V 15" }
            "Error"    { $icoBg = "#2D1116"; $icoBorder = "#EF4444"; $icoFg = "#F87171"; $icoGlyph = "M 6,6 L 14,14 M 14,6 L 6,14" }
            default    { $icoBg = "#0D291E"; $icoBorder = "#10B981"; $icoFg = "#34D399"; $icoGlyph = "M 5.5,10.5 L 8.7,13.7 L 15,6.5" }
        }

        $lblYes    = [System.Security.SecurityElement]::Escape((L "btnYes" "Yes"))
        $lblNo     = [System.Security.SecurityElement]::Escape((L "btnNo" "No"))
        $lblOk     = [System.Security.SecurityElement]::Escape((L "btnOk" "OK"))
        $lblCancel = [System.Security.SecurityElement]::Escape((L "btnCancel" "Cancel"))

        $primaryBg = if ($Icon -eq "Warning") { "#D97706" } elseif ($Icon -eq "Error") { "#DC2626" } else { "#0284C7" }
        $primaryBd = if ($Icon -eq "Warning") { "#F59E0B" } elseif ($Icon -eq "Error") { "#F87171" } else { "#38BDF8" }

        $btnXaml = ""
        if ($Buttons -eq "YesNo") {
            $btnXaml = @"
                <Button x:Name="BtnDlgYes" Content="$lblYes" MinWidth="92" Background="$primaryBg" BorderBrush="$primaryBd" Foreground="#FFFFFF" Margin="0,0,8,0"/>
                <Button x:Name="BtnDlgNo"  Content="$lblNo"  MinWidth="92"/>
"@
        } elseif ($Buttons -eq "YesNoCancel") {
            $btnXaml = @"
                <Button x:Name="BtnDlgYes"    Content="$lblYes"    MinWidth="86" Background="$primaryBg" BorderBrush="$primaryBd" Foreground="#FFFFFF" Margin="0,0,8,0"/>
                <Button x:Name="BtnDlgNo"     Content="$lblNo"     MinWidth="86" Margin="0,0,8,0"/>
                <Button x:Name="BtnDlgCancel" Content="$lblCancel" MinWidth="86"/>
"@
        } elseif ($Buttons -eq "OKCancel") {
            $btnXaml = @"
                <Button x:Name="BtnDlgOk"     Content="$lblOk"     MinWidth="92" Background="$primaryBg" BorderBrush="$primaryBd" Foreground="#FFFFFF" Margin="0,0,8,0"/>
                <Button x:Name="BtnDlgCancel" Content="$lblCancel" MinWidth="92"/>
"@
        } else {
            $btnXaml = @"
                <Button x:Name="BtnDlgOk" Content="$lblOk" MinWidth="100" Background="$primaryBg" BorderBrush="$primaryBd" Foreground="#FFFFFF"/>
"@
        }

        [xml]$mbXml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="$safeTitle" Width="470" SizeToContent="Height" MaxHeight="520"
        WindowStyle="SingleBorderWindow" ResizeMode="NoResize"
        WindowStartupLocation="CenterScreen" FlowDirection="LeftToRight"
        Background="#080D17" Foreground="#F8FAFC" FontFamily="Segoe UI">
    <WindowChrome.WindowChrome>
        <WindowChrome CaptionHeight="0" CornerRadius="0" GlassFrameThickness="0" ResizeBorderThickness="0" UseAeroCaptionButtons="False"/>
    </WindowChrome.WindowChrome>
    <Window.Resources>
        <Style TargetType="Button">
            <Setter Property="Foreground" Value="#E2E8F0"/>
            <Setter Property="Background" Value="#162238"/>
            <Setter Property="BorderBrush" Value="#273A57"/>
            <Setter Property="BorderThickness" Value="1"/>
            <Setter Property="FontWeight" Value="SemiBold"/>
            <Setter Property="FontSize" Value="12"/>
            <Setter Property="Padding" Value="14,7"/>
            <Setter Property="Cursor" Value="Hand"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="Button">
                        <Border x:Name="btnBd" Background="{TemplateBinding Background}" BorderBrush="{TemplateBinding BorderBrush}" BorderThickness="{TemplateBinding BorderThickness}" CornerRadius="7" Padding="{TemplateBinding Padding}">
                            <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
                        </Border>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsMouseOver" Value="True">
                                <Setter TargetName="btnBd" Property="Opacity" Value="0.88"/>
                                <Setter TargetName="btnBd" Property="BorderBrush" Value="#38BDF8"/>
                            </Trigger>
                            <Trigger Property="IsPressed" Value="True">
                                <Setter TargetName="btnBd" Property="Opacity" Value="0.74"/>
                            </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>
    </Window.Resources>
    <Border FlowDirection="$flowDir" Background="#080D17" BorderBrush="#243550" BorderThickness="1">
        <Grid>
            <Grid.RowDefinitions>
                <RowDefinition Height="36"/>
                <RowDefinition Height="*"/>
                <RowDefinition Height="Auto"/>
            </Grid.RowDefinitions>
            <Border x:Name="MbTitleBar" Grid.Row="0" Background="#070C15" BorderBrush="#192438" BorderThickness="0,0,0,1">
                <Grid>
                    <Grid.ColumnDefinitions>
                        <ColumnDefinition Width="*"/>
                        <ColumnDefinition Width="Auto"/>
                    </Grid.ColumnDefinitions>
                    <DockPanel Grid.Column="0" LastChildFill="True" VerticalAlignment="Center" Margin="11,0,8,0">
                        <Image x:Name="ImgMbIcon" DockPanel.Dock="Left" FlowDirection="LeftToRight" Width="16" Height="16" Margin="0,0,8,0" RenderOptions.BitmapScalingMode="HighQuality"/>
                        <TextBlock Text="$safeTitle" FontSize="12" FontWeight="SemiBold" Foreground="#E2E8F0" VerticalAlignment="Center" TextTrimming="CharacterEllipsis"/>
                    </DockPanel>
                    <Button x:Name="BtnMbCloseX" WindowChrome.IsHitTestVisibleInChrome="True" Grid.Column="1" Width="40" Height="36" Background="Transparent" Foreground="#94A3B8" BorderThickness="0" Padding="0" Cursor="Hand" Focusable="False" ToolTip="$closeTip">
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
            <Grid Grid.Row="1" Margin="20,18,20,16">
                <Grid.ColumnDefinitions>
                    <ColumnDefinition Width="Auto"/>
                    <ColumnDefinition Width="*"/>
                </Grid.ColumnDefinitions>
                <Border Grid.Column="0" Width="40" Height="40" CornerRadius="20" Background="$icoBg" BorderBrush="$icoBorder" BorderThickness="1.3" VerticalAlignment="Top" Margin="0,2,14,0">
                    <Path FlowDirection="LeftToRight" Width="20" Height="20" Stretch="None" HorizontalAlignment="Center" VerticalAlignment="Center"
                          Stroke="$icoFg" StrokeThickness="2.1" StrokeStartLineCap="Round" StrokeEndLineCap="Round" StrokeLineJoin="Round" Data="$icoGlyph"/>
                </Border>
                <ScrollViewer Grid.Column="1" VerticalScrollBarVisibility="Auto" MaxHeight="340">
                    <TextBlock Text="$safeMsg" FontSize="12.8" Foreground="#E2E8F0" TextWrapping="Wrap" LineHeight="21" VerticalAlignment="Center"/>
                </ScrollViewer>
            </Grid>
            <Border Grid.Row="2" Background="#0B1220" BorderBrush="#192438" BorderThickness="0,1,0,0" Padding="18,12">
                <StackPanel Orientation="Horizontal" HorizontalAlignment="Right">
                    $btnXaml
                </StackPanel>
            </Border>
        </Grid>
    </Border>
</Window>
"@
        $dlg = [Windows.Markup.XamlReader]::Load((New-Object System.Xml.XmlNodeReader $mbXml))
        if ($null -ne $script:AppIconSource) { $dlg.Icon = $script:AppIconSource }
        if ($null -ne $script:AppLogoPngSource) { $dlg.FindName("ImgMbIcon").Source = $script:AppLogoPngSource }
        elseif (Test-Path -LiteralPath $AppLogoPngPath) {
            try {
                $biPre = New-Object System.Windows.Media.Imaging.BitmapImage
                $biPre.BeginInit(); $biPre.CacheOption = [System.Windows.Media.Imaging.BitmapCacheOption]::OnLoad; $biPre.UriSource = [Uri]::new($AppLogoPngPath); $biPre.EndInit(); $biPre.Freeze()
                $dlg.FindName("ImgMbIcon").Source = $biPre
                if ($null -eq $dlg.Icon) { $dlg.Icon = $biPre }
            } catch {}
        }
        if ($null -ne $window -and $window.IsVisible -and $window.WindowState -ne [System.Windows.WindowState]::Minimized) {
            $dlg.Owner = $window
            $dlg.WindowStartupLocation = [System.Windows.WindowStartupLocation]::CenterOwner
        }

        $resBox = [PSCustomObject]@{ Val = if ($Buttons -eq "YesNo") { [System.Windows.MessageBoxResult]::No } elseif ($Buttons -eq "OK") { [System.Windows.MessageBoxResult]::OK } else { [System.Windows.MessageBoxResult]::Cancel } }
        $bClose = $dlg.FindName("BtnMbCloseX")
        if ($null -ne $bClose) {
            $bClose.Add_Click({
                param($s, $e)
                try { $wObj = [System.Windows.Window]::GetWindow($s); if ($null -ne $wObj) { $wObj.Close() } } catch {}
            })
            $bClose.Add_PreviewMouseLeftButtonDown({
                param($s, $e)
                $e.Handled = $true
                try { $wObj = [System.Windows.Window]::GetWindow($s); if ($null -ne $wObj) { $wObj.Close() } } catch {}
            })
        }
        $mbTitleBar = $dlg.FindName("MbTitleBar")
        if ($null -ne $mbTitleBar) {
            $mbTitleBar.Add_MouseLeftButtonDown({
                param($s, $e)
                try {
                    if ($e.ButtonState -eq [System.Windows.Input.MouseButtonState]::Pressed) {
                        $cur = $e.OriginalSource
                        $isClose = $false
                        while ($null -ne $cur) {
                            if ($cur -is [System.Windows.Controls.Button] -and $cur.Name -eq "BtnMbCloseX") { $isClose = $true; break }
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
        $bYes = $dlg.FindName("BtnDlgYes"); if ($null -ne $bYes) { $bYes.Add_Click({ param($s,$e) $resBox.Val = [System.Windows.MessageBoxResult]::Yes; $wObj = [System.Windows.Window]::GetWindow($s); if ($null -ne $wObj) { $wObj.Close() } }) }
        $bNo  = $dlg.FindName("BtnDlgNo");  if ($null -ne $bNo)  { $bNo.Add_Click({  param($s,$e) $resBox.Val = [System.Windows.MessageBoxResult]::No;  $wObj = [System.Windows.Window]::GetWindow($s); if ($null -ne $wObj) { $wObj.Close() } }) }
        $bOk  = $dlg.FindName("BtnDlgOk");  if ($null -ne $bOk)  { $bOk.Add_Click({  param($s,$e) $resBox.Val = [System.Windows.MessageBoxResult]::OK;  $wObj = [System.Windows.Window]::GetWindow($s); if ($null -ne $wObj) { $wObj.Close() } }) }
        $bCan = $dlg.FindName("BtnDlgCancel"); if ($null -ne $bCan) { $bCan.Add_Click({ param($s,$e) $resBox.Val = [System.Windows.MessageBoxResult]::Cancel; $wObj = [System.Windows.Window]::GetWindow($s); if ($null -ne $wObj) { $wObj.Close() } }) }
        $dlg.Add_KeyDown({
            param($s, $e)
            if ($e.Key -eq [System.Windows.Input.Key]::Escape) { try { $s.Close() } catch {} }
            elseif ($e.Key -eq [System.Windows.Input.Key]::Enter) {
                if ($null -ne $bOk) { $resBox.Val = [System.Windows.MessageBoxResult]::OK; try { $s.Close() } catch {} }
                elseif ($null -ne $bYes) { $resBox.Val = [System.Windows.MessageBoxResult]::Yes; try { $s.Close() } catch {} }
            }
        })
        [void]$dlg.ShowDialog()
        return $resBox.Val
    } catch {
        return [System.Windows.MessageBox]::Show($Message, $Title, $Buttons, $Icon)
    }
}
