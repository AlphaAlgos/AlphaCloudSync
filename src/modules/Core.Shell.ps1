# ==============================================================================
# AlphaCloudSync Module: Core.Shell (Folder Badges, Git Exclude, Explorer Refresh, Startup, COM Scheduler)
# ==============================================================================

function Ensure-GitExcludeDesktopIni {
    param([string]$FolderPath)
    if ([string]::IsNullOrWhiteSpace($FolderPath) -or -not (Test-Path -LiteralPath $FolderPath -PathType Container)) { return }
    try {
        $dir = New-Object System.IO.DirectoryInfo($FolderPath)
        while ($null -ne $dir) {
            $gitEntry = Join-Path $dir.FullName ".git"
            $resolvedGitDir = $null
            if (Test-Path -LiteralPath $gitEntry -PathType Container) {
                $resolvedGitDir = $gitEntry
            } elseif (Test-Path -LiteralPath $gitEntry -PathType Leaf) {
                $gTxt = [System.IO.File]::ReadAllText($gitEntry, [System.Text.Encoding]::UTF8).Trim()
                if ($gTxt -match '(?i)^gitdir:\s*(.+)$') {
                    $rawGd = $Matches[1].Trim()
                    $candGd = if ([System.IO.Path]::IsPathRooted($rawGd)) { $rawGd } else { [System.IO.Path]::GetFullPath((Join-Path $dir.FullName $rawGd)) }
                    $commFile = Join-Path $candGd "commondir"
                    if (Test-Path -LiteralPath $commFile -PathType Leaf) {
                        $cRel = [System.IO.File]::ReadAllText($commFile, [System.Text.Encoding]::UTF8).Trim()
                        if (-not [string]::IsNullOrWhiteSpace($cRel)) {
                            $candGd = if ([System.IO.Path]::IsPathRooted($cRel)) { $cRel } else { [System.IO.Path]::GetFullPath((Join-Path $candGd $cRel)) }
                        }
                    }
                    if (Test-Path -LiteralPath $candGd -PathType Container) { $resolvedGitDir = $candGd }
                }
            }
            if ($null -ne $resolvedGitDir) {
                $infoDir = Join-Path $resolvedGitDir "info"
                if (-not (Test-Path -LiteralPath $infoDir)) { New-Item -ItemType Directory -Path $infoDir -Force | Out-Null }
                $exclFile = Join-Path $infoDir "exclude"
                $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
                $existingTxt = if (Test-Path -LiteralPath $exclFile) { [System.IO.File]::ReadAllText($exclFile, [System.Text.Encoding]::UTF8) } else { "" }
                $lines = @($existingTxt -split "`r?`n" | ForEach-Object { $_.Trim() })
                if ($lines -notcontains "desktop.ini") {
                    $prefix = if ($existingTxt.Length -gt 0 -and -not $existingTxt.EndsWith("`n")) { "`r`n" } else { "" }
                    [System.IO.File]::WriteAllText($exclFile, ($existingTxt + $prefix + "desktop.ini`r`n"), $utf8NoBom)
                }
                return
            }
            $dir = $dir.Parent
        }
    } catch {}
}

function Set-SyncedFolderBadge {
    param([string]$FolderPath)
    if ([string]::IsNullOrWhiteSpace($FolderPath)) { return $false }
    $trimmed = $FolderPath.TrimEnd('\', '/')
    if ($trimmed.Length -le 2 -or -not (Test-Path -LiteralPath $trimmed -PathType Container)) { return $false }
    $icoUse = if (Test-Path -LiteralPath $StableFolderIconPath) { $StableFolderIconPath } elseif (Test-Path -LiteralPath $FolderIconPath) { $FolderIconPath } else { "" }
    if ([string]::IsNullOrWhiteSpace($icoUse)) { return $false }
    try {
        $iniPath = Join-Path $trimmed "desktop.ini"
        if (Test-Path -LiteralPath $iniPath) {
            $curContent = [System.IO.File]::ReadAllText($iniPath)
            if ($curContent -notmatch '(?i)Managed by AlphaCloudSync') {
                return $false
            }
            try { [System.IO.File]::SetAttributes($iniPath, [System.IO.FileAttributes]::Normal) } catch {}
        }
        Ensure-GitExcludeDesktopIni -FolderPath $trimmed
        $icoResStr = if ($icoUse.StartsWith($env:APPDATA, [System.StringComparison]::OrdinalIgnoreCase)) {
            "%APPDATA%" + $icoUse.Substring($env:APPDATA.Length)
        } else { $icoUse }
        $iniBody = "; Managed by AlphaCloudSync`r`n[.ShellClassInfo]`r`nIconResource=$icoResStr,0`r`nInfoTip=Synced by AlphaCloudSync`r`n"
        # Windows Explorer GetPrivateProfileStringW requires Unicode (UTF-16LE) or ANSI for non-ASCII usernames in desktop.ini
        [System.IO.File]::WriteAllText($iniPath, $iniBody, [System.Text.Encoding]::Unicode)
        [System.IO.File]::SetAttributes($iniPath, ([System.IO.FileAttributes]::Hidden -bor [System.IO.FileAttributes]::System))
        $curDirAttr = [System.IO.File]::GetAttributes($trimmed)
        if (-not ($curDirAttr.HasFlag([System.IO.FileAttributes]::ReadOnly))) {
            [System.IO.File]::SetAttributes($trimmed, ($curDirAttr -bor [System.IO.FileAttributes]::ReadOnly))
        }
        if ("AlphaWinShellHelper" -as [type]) { [AlphaWinShellHelper]::NotifyPathChanged($trimmed) }
        return $true
    } catch { return $false }
}

function Clear-SyncedFolderBadge {
    param([string]$FolderPath)
    if ([string]::IsNullOrWhiteSpace($FolderPath)) { return $false }
    $trimmed = $FolderPath.TrimEnd('\', '/')
    if ($trimmed.Length -le 2 -or -not (Test-Path -LiteralPath $trimmed -PathType Container)) { return $false }
    try {
        $iniPath = Join-Path $trimmed "desktop.ini"
        if (-not (Test-Path -LiteralPath $iniPath)) { return $false }
        $curContent = [System.IO.File]::ReadAllText($iniPath)
        if ($curContent -notmatch '(?i)Managed by AlphaCloudSync') { return $false }
        try { [System.IO.File]::SetAttributes($iniPath, [System.IO.FileAttributes]::Normal) } catch {}
        Remove-Item -LiteralPath $iniPath -Force -ErrorAction SilentlyContinue
        $curDirAttr = [System.IO.File]::GetAttributes($trimmed)
        if ($curDirAttr.HasFlag([System.IO.FileAttributes]::ReadOnly)) {
            [System.IO.File]::SetAttributes($trimmed, ($curDirAttr -band (-bnot [System.IO.FileAttributes]::ReadOnly)))
        }
        if ("AlphaWinShellHelper" -as [type]) { [AlphaWinShellHelper]::NotifyPathChanged($trimmed) }
        return $true
    } catch { return $false }
}

function Set-CloudDriveExplorerIcon {
    param([string]$Letter)
    if ([string]::IsNullOrWhiteSpace($Letter)) { return }
    $cleanL = ($Letter.Trim().TrimEnd(':', '\', '/')).ToUpperInvariant()
    if ($cleanL.Length -ne 1 -or $cleanL -notmatch '^[A-Z]$') { return }
    $icoUse = if (Test-Path -LiteralPath $StableAppIconPath) { $StableAppIconPath } elseif (Test-Path -LiteralPath $AppIconPath) { $AppIconPath } else { "" }
    if ([string]::IsNullOrWhiteSpace($icoUse)) { return }
    try {
        $keyPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\DriveIcons\$cleanL\DefaultIcon"
        if (-not (Test-Path -LiteralPath $keyPath)) { New-Item -Path $keyPath -Force | Out-Null }
        Set-ItemProperty -Path $keyPath -Name "(Default)" -Value "$icoUse,0" -Force
        if ("AlphaWinShellHelper" -as [type]) { [AlphaWinShellHelper]::NotifyDriveIconChanged() }
    } catch {}
}

function Clear-CloudDriveExplorerIcon {
    param([string]$Letter)
    if ([string]::IsNullOrWhiteSpace($Letter)) { return }
    $cleanL = ($Letter.Trim().TrimEnd(':', '\', '/')).ToUpperInvariant()
    if ($cleanL.Length -ne 1 -or $cleanL -notmatch '^[A-Z]$') { return }
    try {
        $keyPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\DriveIcons\$cleanL"
        if (Test-Path -LiteralPath $keyPath) { Remove-Item -LiteralPath $keyPath -Recurse -Force -ErrorAction SilentlyContinue }
        if ("AlphaWinShellHelper" -as [type]) { [AlphaWinShellHelper]::NotifyDriveIconChanged() }
    } catch {}
}

function Sync-AllFolderAndDriveBadges {
    param([bool]$Enable)
    try {
        $allPaths = New-Object System.Collections.Generic.HashSet[string]([System.StringComparer]::OrdinalIgnoreCase)
        $remotes = @(Get-ConfiguredDriveRemotes)
        if ($remotes.Count -eq 0) { $remotes = @($RemoteName) }
        foreach ($rem in $remotes) {
            foreach ($f in @(Get-SyncFolders -TargetRemote $rem)) {
                if ($f -and -not [string]::IsNullOrWhiteSpace($f.LocalPath)) { [void]$allPaths.Add($f.LocalPath) }
            }
        }
        foreach ($p in $allPaths) {
            if ($Enable) { $null = Set-SyncedFolderBadge -FolderPath $p }
            else         { $null = Clear-SyncedFolderBadge -FolderPath $p }
        }
        foreach ($m in @(Get-MountsState)) {
            if ($m -and -not [string]::IsNullOrWhiteSpace($m.Letter)) {
                if ($Enable) { Set-CloudDriveExplorerIcon -Letter $m.Letter }
                else         { Clear-CloudDriveExplorerIcon -Letter $m.Letter }
            }
        }
    } catch {}
}

function Test-WinFspInstalled {
    $p86 = Join-Path ${env:ProgramFiles(x86)} "WinFsp"
    $p64 = Join-Path $env:ProgramFiles "WinFsp"
    if ((Test-Path -LiteralPath $p86) -or (Test-Path -LiteralPath $p64)) { return $true }
    if ((Test-Path -LiteralPath "HKLM:\SOFTWARE\WOW6432Node\WinFsp") -or (Test-Path -LiteralPath "HKLM:\SOFTWARE\WinFsp")) { return $true }
    return $false
}

function Refresh-WindowsExplorerSilently {
    param([string]$DriveLetter = "", [string]$ChangeKind = "Update")
    try {
        $drvRoot = if (-not [string]::IsNullOrWhiteSpace($DriveLetter)) {
            ($DriveLetter.Trim().TrimEnd('\', '/')).ToUpperInvariant() + "\"
        } else { "" }
        if ("AlphaWinShellHelper" -as [type]) {
            if ($ChangeKind -eq "Add" -and $drvRoot) { [AlphaWinShellHelper]::NotifyDriveAdded($drvRoot) }
            elseif ($ChangeKind -eq "Remove" -and $drvRoot) { [AlphaWinShellHelper]::NotifyDriveRemoved($drvRoot) }
            else { [AlphaWinShellHelper]::NotifyDriveIconChanged() }
        }
    } catch {}
    try {
        $shell = New-Object -ComObject Shell.Application
        foreach ($win in @($shell.Windows())) {
            try {
                if ($null -ne $win) { $win.Refresh() }
            } catch {}
        }
    } catch {}
}

function Wait-DriveLetterReleased {
    param([string]$Letter, [int]$MaxWaitMs = 4000)
    if ([string]::IsNullOrWhiteSpace($Letter)) { return }
    $cleanL = $Letter.Trim().TrimEnd('\', '/').ToUpperInvariant()
    $steps = [math]::Max(1, [int]($MaxWaitMs / 250))
    for ($i = 0; $i -lt $steps; $i++) {
        if (-not (Test-Path -LiteralPath "${cleanL}\")) { return }
        Start-Sleep -Milliseconds 250
        if (Get-Command Invoke-UiPump -ErrorAction SilentlyContinue) { Invoke-UiPump }
    }
}

function Get-StartupEnabled {
    try {
        $val = (Get-ItemProperty -Path $RunRegPath -Name $AppName -ErrorAction SilentlyContinue).$AppName
        return (-not [string]::IsNullOrWhiteSpace($val))
    } catch { return $false }
}

function Set-StartupEnabled {
    param([bool]$Enable)
    if ($Enable) {
        $psExe = Join-Path $env:SystemRoot "System32\WindowsPowerShell\v1.0\powershell.exe"
        $cmdStr = if ($null -ne $AppLaunchExe) { "`"$AppLaunchExe`" --minimized" } else { "`"$psExe`" -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$ScriptSelf`" -Minimized" }
        Set-ItemProperty -Path $RunRegPath -Name $AppName -Value $cmdStr -Force
    } else {
        Remove-ItemProperty -Path $RunRegPath -Name $AppName -ErrorAction SilentlyContinue
    }
}

function Get-ExplorerContextMenuEnabled {
    return (Test-Path -LiteralPath "HKCU:\Software\Classes\Directory\shell\AlphaCloudSync")
}

function Set-ExplorerContextMenuEnabled {
    param([bool]$Enable)
    $rootKey = "HKCU:\Software\Classes\Directory\shell\AlphaCloudSync"
    try {
        if (-not $Enable) {
            if (Test-Path -LiteralPath $rootKey) {
                Remove-Item -LiteralPath $rootKey -Recurse -Force -ErrorAction SilentlyContinue
            }
            return $true
        }
        $iconUse = if (Test-Path -LiteralPath $StableAppIconPath) { $StableAppIconPath } elseif (Test-Path -LiteralPath $AppIconPath) { $AppIconPath } else { "" }
        $psExe = Join-Path $env:SystemRoot "System32\WindowsPowerShell\v1.0\powershell.exe"
        $baseCmd = if ($null -ne $AppLaunchExe) { "`"$AppLaunchExe`"" } else { "`"$psExe`" -NoProfile -ExecutionPolicy Bypass -STA -WindowStyle Hidden -File `"$ScriptSelf`"" }

        New-Item -Path $rootKey -Force | Out-Null
        Set-ItemProperty -Path $rootKey -Name "MUIVerb" -Value "AlphaCloudSync" -Force
        Set-ItemProperty -Path $rootKey -Name "SubCommands" -Value "" -Force
        if (-not [string]::IsNullOrWhiteSpace($iconUse)) {
            Set-ItemProperty -Path $rootKey -Name "Icon" -Value "`"$iconUse`"" -Force
        }

        $items = @(
            @{ Key = "01_Add";     Label = (L "ctxWinAddFolder" "Add Folder to Cloud Sync...");            Act = "ContextAdd" },
            @{ Key = "02_Sync";    Label = (L "ctxWinSyncFolder" "Sync This Folder Now");                  Act = "ContextSync" },
            @{ Key = "03_Preview"; Label = (L "ctxWinPreviewFolder" "Preview Changes Only");               Act = "ContextPreview" },
            @{ Key = "04_Remove";  Label = (L "ctxWinRemoveFolder" "Remove Folder from Sync");             Act = "ContextRemove" }
        )
        $subShell = "$rootKey\shell"
        New-Item -Path $subShell -Force | Out-Null
        foreach ($it in $items) {
            $kPath = "$subShell\$($it.Key)"
            $cPath = "$kPath\command"
            New-Item -Path $cPath -Force | Out-Null
            Set-ItemProperty -Path $kPath -Name "MUIVerb" -Value $it.Label -Force
            if (-not [string]::IsNullOrWhiteSpace($iconUse)) {
                Set-ItemProperty -Path $kPath -Name "Icon" -Value "`"$iconUse`"" -Force
            }
            Set-ItemProperty -Path $cPath -Name "(Default)" -Value "$baseCmd -Action $($it.Act) -TargetPath `"%V`"" -Force
        }
        return $true
    } catch { return $false }
}

function Get-TaskNameForRemote {
    param([string]$TargetRemote = $RemoteName)
    return "AlphaCloudSync_AutoBackup_$(Get-SanitizedName $TargetRemote)"
}

function Get-ScheduleInfo {
    param([string]$TargetRemote = $RemoteName)
    $tName = Get-TaskNameForRemote -TargetRemote $TargetRemote
    # Locale-independent Windows Task Scheduler COM query (works identically on Arabic, Chinese, German, English Windows!)
    try {
        $svc = New-Object -ComObject Schedule.Service
        $svc.Connect()
        $rootF = $svc.GetFolder("\")
        $task = $rootF.GetTask($tName)
        if ($null -ne $task) {
            $nextDt = $task.NextRunTime
            if ($nextDt -is [datetime] -and $nextDt.Year -gt 2000) {
                $displayNext = Wrap-Ltr ($nextDt.ToString("yyyy-MM-dd hh:mm tt", $script:InvCulture))
                return [PSCustomObject]@{ Active = $true; Label = (LF "scheduleActiveNext" @($displayNext)) }
            }
            return [PSCustomObject]@{ Active = $true; Label = (L "scheduleActive" "ACTIVE") }
        }
    } catch {}
    return [PSCustomObject]@{ Active = $false; Label = (L "scheduleOff" "OFF (Manual Only)") }
}

function Set-AutoBackupScheduledTask {
    param(
        [string]$TargetRemote,
        [int]$ModeIndex,
        [datetime]$StartDateTime,
        [int]$DaysBitmask = 0,
        [int]$HourlyInterval = 2
    )
    try {
        $tName = Get-TaskNameForRemote -TargetRemote $TargetRemote
        $safeRem = Get-SanitizedName $TargetRemote
        $svc = New-Object -ComObject Schedule.Service
        $svc.Connect()
        $rootF = $svc.GetFolder("\")
        $td = $svc.NewTask(0)
        $td.RegistrationInfo.Description = "AlphaCloudSync Automatic Scheduled Cloud Backup ($safeRem)"
        $td.Settings.Enabled = $true
        $td.Settings.StartWhenAvailable = $true
        $td.Settings.DisallowStartIfOnBatteries = $false
        $td.Settings.StopIfGoingOnBatteries = $false

        $isoStart = $StartDateTime.ToString("yyyy-MM-ddTHH:mm:00", $script:InvCulture)
        if ($ModeIndex -eq 0) {
            # Daily
            $tr = $td.Triggers.Create(2)
            $tr.StartBoundary = $isoStart
            $tr.DaysInterval = 1
        } elseif ($ModeIndex -eq 1) {
            # One-Time
            $tr = $td.Triggers.Create(1)
            $tr.StartBoundary = $isoStart
        } elseif ($ModeIndex -eq 2) {
            # Weekly
            $tr = $td.Triggers.Create(3)
            $tr.StartBoundary = $isoStart
            $tr.WeeksInterval = 1
            $tr.DaysOfWeek = if ($DaysBitmask -gt 0) { $DaysBitmask } else { 2 }
        } else {
            # Hourly (Daily trigger with repetition interval)
            $tr = $td.Triggers.Create(2)
            $tr.StartBoundary = $isoStart
            $tr.DaysInterval = 1
            $tr.Repetition.Interval = "PT$($HourlyInterval)H"
            $tr.Repetition.Duration = "P1D"
        }

        $act = $td.Actions.Create(0)
        if ($null -ne $AppLaunchExe) {
            $act.Path = $AppLaunchExe
            $act.Arguments = "-Action Sync -RemoteName $(Format-WinArg $safeRem)"
        } else {
            $act.Path = Join-Path $env:SystemRoot "System32\WindowsPowerShell\v1.0\powershell.exe"
            $act.Arguments = "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File $(Format-WinArg $ScriptSelf) -Action Sync -RemoteName $(Format-WinArg $safeRem)"
        }
        $null = $rootF.RegisterTaskDefinition($tName, $td, 6, $null, $null, 3, $null)
        return [PSCustomObject]@{ Ok = $true; Error = "" }
    } catch {
        return [PSCustomObject]@{ Ok = $false; Error = $_.Exception.Message }
    }
}

function Remove-AutoBackupScheduledTask {
    param([string]$TargetRemote)
    try {
        $tName = Get-TaskNameForRemote -TargetRemote $TargetRemote
        $svc = New-Object -ComObject Schedule.Service
        $svc.Connect()
        $svc.GetFolder("\").DeleteTask($tName, 0)
        return $true
    } catch { return $false }
}
