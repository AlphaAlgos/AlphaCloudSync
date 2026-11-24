# ==============================================================================
# AlphaCloudSync Module: Core.Config (Settings, Account Prefs, Folders, Fail-Closed Rules, Health)
# ==============================================================================


function Save-Settings {
    param($Obj)
    $json = ConvertTo-Json -InputObject $Obj -Depth 6
    [System.IO.File]::WriteAllText($SettingsPath, $json, (New-Object System.Text.UTF8Encoding($false)))
}

function Get-DefaultPresetPath {
    $devPreset = Join-Path $PresetsDir "developer-default.json"
    if (Test-Path -LiteralPath $devPreset) { return $devPreset }
    return (Join-Path $AppDataDir "developer-default.json")
}

function Get-Settings {
    $script:SettingsLoadError = ""
    $defPreset = Get-DefaultPresetPath
    $defBounds = [PSCustomObject]@{ Left = $null; Top = $null; Width = $null; Height = $null; State = "Normal" }
    $defIsland = [PSCustomObject]@{ Left = $null; Top = $null }
    if (-not (Test-Path -LiteralPath $SettingsPath)) {
        $def = [PSCustomObject]@{
            ActiveRemote     = "gdrive"
            PreferredDrive   = "G:"
            MountMode        = "Stream"
            DriveLayout      = "Separate"
            ComputerLabel    = "My Computer"
            DeletePolicy     = "Safe Archive"
            MaxDeleteLimit   = 0
            SpeedPreset      = "Turbo"
            UseJsonRules     = $true
            JsonRulesPath    = $defPreset
            Language         = "en"
            MinimizeToTray   = $true
            ShowCloudIsland      = $false
            ShowFolderBadges     = $true
            ExplorerContextMenu  = $true
            AutoWatchSync        = $false
            NotificationsEnabled = $true
            NotifyManualSync     = $true
            NotifyAutoSync       = $true
            NotifyErrors         = $true
            NotifyDriveEvents    = $false
            WindowBounds         = $defBounds
            IslandPos            = $defIsland
        }
        Save-Settings -Obj $def
        return $def
    }
    try {
        $s = [System.IO.File]::ReadAllText($SettingsPath, [System.Text.Encoding]::UTF8) | ConvertFrom-Json
        if (-not $s.PSObject.Properties["MountMode"])       { $s | Add-Member -NotePropertyName "MountMode"       -NotePropertyValue "Stream"       -Force }
        if (-not $s.PSObject.Properties["DriveLayout"])     { $s | Add-Member -NotePropertyName "DriveLayout"     -NotePropertyValue "Separate"     -Force }
        if (-not $s.PSObject.Properties["ComputerLabel"])   { $s | Add-Member -NotePropertyName "ComputerLabel"   -NotePropertyValue "My Computer"  -Force }
        if (-not $s.PSObject.Properties["DeletePolicy"])    { $s | Add-Member -NotePropertyName "DeletePolicy"    -NotePropertyValue "Safe Archive" -Force }
        if (-not $s.PSObject.Properties["MaxDeleteLimit"])  { $s | Add-Member -NotePropertyName "MaxDeleteLimit"  -NotePropertyValue 0              -Force }
        else {
            $parsedLimit = 0
            if ([int]::TryParse("$($s.MaxDeleteLimit)", [ref]$parsedLimit) -and $parsedLimit -ge 0) { $s.MaxDeleteLimit = $parsedLimit }
            else { $s.MaxDeleteLimit = 0 }
        }
        if (-not $s.PSObject.Properties["SpeedPreset"])     { $s | Add-Member -NotePropertyName "SpeedPreset"     -NotePropertyValue "Turbo"        -Force }
        if (-not $s.PSObject.Properties["UseJsonRules"])    { $s | Add-Member -NotePropertyName "UseJsonRules"    -NotePropertyValue $true          -Force }
        if (-not $s.PSObject.Properties["Language"] -or [string]::IsNullOrWhiteSpace([string]$s.Language)) { $s | Add-Member -NotePropertyName "Language" -NotePropertyValue "en" -Force }
        if (-not $s.PSObject.Properties["MinimizeToTray"])   { $s | Add-Member -NotePropertyName "MinimizeToTray"   -NotePropertyValue $true      -Force }
        if (-not $s.PSObject.Properties["ShowCloudIsland"])  { $s | Add-Member -NotePropertyName "ShowCloudIsland"  -NotePropertyValue $false     -Force }
        if (-not $s.PSObject.Properties["ShowFolderBadges"]) { $s | Add-Member -NotePropertyName "ShowFolderBadges" -NotePropertyValue $true      -Force }
        if (-not $s.PSObject.Properties["ExplorerContextMenu"]) { $s | Add-Member -NotePropertyName "ExplorerContextMenu" -NotePropertyValue $true -Force }
        if (-not $s.PSObject.Properties["AutoWatchSync"])    { $s | Add-Member -NotePropertyName "AutoWatchSync"    -NotePropertyValue $false     -Force }
        if (-not $s.PSObject.Properties["NotificationsEnabled"]) { $s | Add-Member -NotePropertyName "NotificationsEnabled" -NotePropertyValue $true  -Force }
        if (-not $s.PSObject.Properties["NotifyManualSync"])     { $s | Add-Member -NotePropertyName "NotifyManualSync"     -NotePropertyValue $true  -Force }
        if (-not $s.PSObject.Properties["NotifyAutoSync"])       { $s | Add-Member -NotePropertyName "NotifyAutoSync"       -NotePropertyValue $true  -Force }
        if (-not $s.PSObject.Properties["NotifyErrors"])         { $s | Add-Member -NotePropertyName "NotifyErrors"         -NotePropertyValue $true  -Force }
        if (-not $s.PSObject.Properties["NotifyDriveEvents"])    { $s | Add-Member -NotePropertyName "NotifyDriveEvents"    -NotePropertyValue $false -Force }
        if (-not $s.PSObject.Properties["WindowBounds"])    { $s | Add-Member -NotePropertyName "WindowBounds"    -NotePropertyValue $defBounds     -Force }
        if (-not $s.PSObject.Properties["IslandPos"])       { $s | Add-Member -NotePropertyName "IslandPos"       -NotePropertyValue $defIsland     -Force }
        if (-not $s.PSObject.Properties["JsonRulesPath"]) {
            $s | Add-Member -NotePropertyName "JsonRulesPath" -NotePropertyValue $defPreset -Force
        } elseif ((-not [bool]$s.UseJsonRules) -and (-not [string]::IsNullOrWhiteSpace([string]$s.JsonRulesPath)) -and (-not (Test-Path -LiteralPath ([string]$s.JsonRulesPath) -PathType Leaf))) {
            $s.JsonRulesPath = $defPreset
        }
        return $s
    } catch {
        $script:SettingsLoadError = $_.Exception.Message
        return [PSCustomObject]@{
            ActiveRemote         = "gdrive"
            PreferredDrive       = "G:"
            MountMode            = "Stream"
            DriveLayout          = "Separate"
            ComputerLabel        = "My Computer"
            DeletePolicy         = "Safe Archive"
            MaxDeleteLimit       = 0
            SpeedPreset          = "Turbo"
            UseJsonRules         = $true
            JsonRulesPath        = ""
            Language             = "en"
            MinimizeToTray       = $true
            ShowCloudIsland      = $false
            ShowFolderBadges     = $true
            ExplorerContextMenu  = $true
            AutoWatchSync        = $false
            NotificationsEnabled = $true
            NotifyManualSync     = $true
            NotifyAutoSync       = $true
            NotifyErrors         = $true
            NotifyDriveEvents    = $false
            WindowBounds         = $defBounds
            IslandPos            = $defIsland
        }
    }
}

function Read-Utf8TailLines {
    param([string]$Path, [int]$MaxLines = 55)
    if ([string]::IsNullOrWhiteSpace($Path) -or -not (Test-Path -LiteralPath $Path)) { return @() }
    $fs = $null; $sr = $null
    try {
        $fs = New-Object System.IO.FileStream($Path, [System.IO.FileMode]::Open, [System.IO.FileAccess]::Read, [System.IO.FileShare]::ReadWrite)
        $sr = New-Object System.IO.StreamReader($fs, [System.Text.Encoding]::UTF8)
        $content = $sr.ReadToEnd()
        if ([string]::IsNullOrEmpty($content)) { return @() }
        $all = $content -split "`r?`n"
        if ($all.Count -gt $MaxLines) { return $all[($all.Count - $MaxLines)..($all.Count - 1)] }
        return $all
    } catch {
        return @()
    } finally {
        if ($null -ne $sr) { try { $sr.Dispose() } catch {} }
        if ($null -ne $fs) { try { $fs.Dispose() } catch {} }
    }
}

function Get-SanitizedName {
    param([string]$Name)
    $clean = (($Name -replace '[^a-zA-Z0-9_-]', '') -replace '^-+', '')
    if ([string]::IsNullOrWhiteSpace($clean) -or $clean -ieq "__UNIFIED__") { return "gdrive" }
    return $clean
}

function Get-ProfileFilePath {
    param([string]$TargetRemote = $RemoteName)
    return (Join-Path $ProfilesDir "folders-$(Get-SanitizedName $TargetRemote).json")
}

function Save-SyncFolders {
    param([array]$Folders, [string]$TargetRemote = $RemoteName)
    $pFile = Get-ProfileFilePath -TargetRemote $TargetRemote
    [System.IO.File]::WriteAllText($pFile, (ConvertTo-Json -InputObject @($Folders) -Depth 5), (New-Object System.Text.UTF8Encoding($false)))
}

function Get-SyncFolders {
    param([string]$TargetRemote = $RemoteName)
    $pFile = Get-ProfileFilePath -TargetRemote $TargetRemote
    if (-not (Test-Path -LiteralPath $pFile)) {
        $legacyFile = Join-Path $env:APPDATA "AlphaCloudDriveStudio\sync-profiles.json"
        if ($TargetRemote -eq "gdrive" -and (Test-Path -LiteralPath $legacyFile)) {
            try { Copy-Item -LiteralPath $legacyFile -Destination $pFile -Force } catch {}
        }
    }
    if (-not (Test-Path -LiteralPath $pFile)) {
        Save-SyncFolders -Folders @() -TargetRemote $TargetRemote
        return @()
    }
    try {
        $raw = [System.IO.File]::ReadAllText($pFile, [System.Text.Encoding]::UTF8)
        if ([string]::IsNullOrWhiteSpace($raw)) { return @() }
        $parsed = ConvertFrom-Json -InputObject $raw
        $arr = if ($parsed -is [System.Array]) { $parsed } else { @($parsed) }
        foreach ($item in $arr) {
            if (-not $item.PSObject.Properties["Enabled"])    { $item | Add-Member -NotePropertyName "Enabled"    -NotePropertyValue $true      -Force }
            if (-not $item.PSObject.Properties["TargetMode"]) { $item | Add-Member -NotePropertyName "TargetMode" -NotePropertyValue "My Drive" -Force }
            if (-not $item.PSObject.Properties["LocalSize"])  { $item | Add-Member -NotePropertyName "LocalSize"  -NotePropertyValue ""         -Force }
            if (-not $item.PSObject.Properties["LocalBytes"]) { $item | Add-Member -NotePropertyName "LocalBytes" -NotePropertyValue 0.0        -Force }
            if (-not $item.PSObject.Properties["RemoteSize"]) { $item | Add-Member -NotePropertyName "RemoteSize" -NotePropertyValue ""         -Force }
            if (-not $item.PSObject.Properties["LastStatus"]) { $item | Add-Member -NotePropertyName "LastStatus" -NotePropertyValue ""         -Force }
        }
        return $arr
    } catch { return @() }
}

function Resolve-EffectiveRemotePath {
    param($FolderItem)
    $cfg = Get-Settings
    $rawComp = if ([string]::IsNullOrWhiteSpace($cfg.ComputerLabel)) { "My Computer" } else { $cfg.ComputerLabel.Trim() }
    $compLabel = (($rawComp -replace '["=\\/:*?<>|]', '').Trim())
    if ([string]::IsNullOrWhiteSpace($compLabel) -or $compLabel -eq "." -or $compLabel -eq "..") { $compLabel = "My Computer" }
    $rawRel = if ($null -ne $FolderItem -and -not [string]::IsNullOrWhiteSpace($FolderItem.RemotePath)) { [string]$FolderItem.RemotePath } elseif ($null -ne $FolderItem -and -not [string]::IsNullOrWhiteSpace($FolderItem.Name)) { [string]$FolderItem.Name } else { "Backup" }
    $baseRel = (($rawRel -replace '["\\:*?<>|]', '').Trim('/'))
    $baseRel = (($baseRel -split '/' | Where-Object { -not [string]::IsNullOrWhiteSpace($_) -and $_ -ne '.' -and $_ -ne '..' }) -join '/')
    if ([string]::IsNullOrWhiteSpace($baseRel)) { $baseRel = "Backup" }
    if ($FolderItem.TargetMode -eq "My Computer") { return "$compLabel/$baseRel" }
    return $baseRel
}

function Format-ByteSize {
    param([double]$Bytes)
    if ($Bytes -le 0)   { return "0 MB" }
    if ($Bytes -ge 1TB) { return ("{0:N2} TB" -f ($Bytes / 1TB)) }
    if ($Bytes -ge 1GB) { return ("{0:N2} GB" -f ($Bytes / 1GB)) }
    if ($Bytes -ge 1MB) { return ("{0:N1} MB" -f ($Bytes / 1MB)) }
    if ($Bytes -ge 1KB) { return ("{0:N0} KB" -f ($Bytes / 1KB)) }
    return ("{0:N0} B" -f $Bytes)
}

function Build-SafeExcludeFile {
    param([string]$TargetRemote = $RemoteName)
    if ([string]::IsNullOrWhiteSpace($TargetRemote)) { $TargetRemote = "gdrive" }
    $rCfg = Get-AccountRulesConfig -TargetRemote $TargetRemote
    $rulesFile = $rCfg.JsonRulesPath
    $outFilterFile = Join-Path $AppDataDir "active-excludes-$(Get-SanitizedName $TargetRemote).txt"
    if (-not $rCfg.UseJsonRules) {
        return [PSCustomObject]@{ Enabled = $false; Valid = $true; Error = ""; Path = $rulesFile; FilterFile = $null; Lines = @(); HasComplexPatterns = $false; DirCount = 0; FileCount = 0; PresetName = (L "rulesDisabled" "Disabled") }
    }
    if ([string]::IsNullOrWhiteSpace($rulesFile) -or -not (Test-Path -LiteralPath $rulesFile -PathType Leaf)) {
        return [PSCustomObject]@{ Enabled = $false; Valid = $false; Error = "Configured exclusion rules file is missing: $rulesFile"; Path = $rulesFile; FilterFile = $null; Lines = @(); HasComplexPatterns = $false; DirCount = 0; FileCount = 0; PresetName = (L "rulesInvalid" "Invalid Rules File") }
    }
    try {
        $rObj = [System.IO.File]::ReadAllText($rulesFile, [System.Text.Encoding]::UTF8) | ConvertFrom-Json
        if ($rObj.PSObject.Properties["enabled"] -and -not $rObj.enabled) {
            return [PSCustomObject]@{ Enabled = $false; Valid = $true; Error = ""; Path = $rulesFile; FilterFile = $null; Lines = @(); HasComplexPatterns = $false; DirCount = 0; FileCount = 0; PresetName = (L "rulesDisabled" "Disabled") }
        }
        $lines = New-Object System.Collections.Generic.List[string]
        $dCount = 0; $fCount = 0; $hasComplex = $false
        if ($rObj.excludeDirectories) {
            foreach ($d in $rObj.excludeDirectories) {
                $cleanD = ($d.ToString().Trim().Trim('/') -replace '[\r\n"]', '')
                if (-not [string]::IsNullOrWhiteSpace($cleanD) -and -not $cleanD.StartsWith("-")) {
                    if ($cleanD.Contains("**") -or $cleanD.Contains("{") -or $cleanD.Contains("}")) { $hasComplex = $true }
                    $lines.Add("$cleanD/**"); $dCount++
                }
            }
        }
        if ($rObj.excludeFiles) {
            foreach ($f in $rObj.excludeFiles) {
                $cleanF = ($f.ToString().Trim() -replace '[\r\n"]', '')
                if (-not [string]::IsNullOrWhiteSpace($cleanF) -and -not $cleanF.StartsWith("-")) {
                    if ($cleanF.Contains("**") -or $cleanF.Contains("{") -or $cleanF.Contains("}") -or $cleanF.StartsWith("!") -or $cleanF.StartsWith("+")) { $hasComplex = $true }
                    $lines.Add($cleanF); $fCount++
                }
            }
        }
        if ($rObj.customRclonePatterns) {
            foreach ($c in $rObj.customRclonePatterns) {
                $cleanC = ($c.ToString().Trim() -replace '[\r\n"]', '')
                if (-not [string]::IsNullOrWhiteSpace($cleanC) -and -not $cleanC.StartsWith("-")) {
                    $trimTail = if ($cleanC.EndsWith("/**")) { $cleanC.Substring(0, $cleanC.Length - 3) } else { $cleanC }
                    if ($trimTail.Contains("**") -or $cleanC.Contains("{") -or $cleanC.Contains("}") -or $cleanC.StartsWith("!") -or $cleanC.StartsWith("+")) { $hasComplex = $true }
                    $lines.Add($cleanC); $fCount++
                }
            }
        }
        [System.IO.File]::WriteAllLines($outFilterFile, $lines, (New-Object System.Text.UTF8Encoding($false)))
        $pName = if ($rObj.PSObject.Properties["presetName"]) { $rObj.presetName } else { Split-Path -Path $rulesFile -Leaf }
        return [PSCustomObject]@{ Enabled = $true; Valid = $true; Error = ""; Path = $rulesFile; FilterFile = $outFilterFile; Lines = $lines.ToArray(); HasComplexPatterns = $hasComplex; DirCount = $dCount; FileCount = $fCount; PresetName = $pName }
    } catch {
        return [PSCustomObject]@{ Enabled = $false; Valid = $false; Error = $_.Exception.Message; Path = $rulesFile; FilterFile = $null; Lines = @(); HasComplexPatterns = $false; DirCount = 0; FileCount = 0; PresetName = (L "rulesInvalid" "Invalid Rules File") }
    }
}

function Test-RelPathExcludedByRules {
    param([string]$RelPath, [string[]]$ExcludeLines, [bool]$ExcludeDesktopIni = $true)
    if ([string]::IsNullOrWhiteSpace($RelPath)) { return $true }
    $norm = ($RelPath -replace '\\', '/').TrimStart('/')
    $parts = $norm -split '/'
    $leaf  = $parts[$parts.Count - 1]
    if ($ExcludeDesktopIni -and $leaf -ieq "desktop.ini") { return $true }
    if ($null -eq $ExcludeLines -or $ExcludeLines.Count -eq 0) { return $false }
    foreach ($patRaw in $ExcludeLines) {
        if ([string]::IsNullOrWhiteSpace($patRaw)) { continue }
        $pat = $patRaw.Trim()
        if ($pat.EndsWith("/**")) {
            # Directory rule 'dir/**' applies ONLY to files inside a matching directory segment, NEVER to a regular file named 'dir'!
            if ($parts.Count -lt 2) { continue }
            $dirP = $pat.Substring(0, $pat.Length - 3).Trim('/')
            if ([string]::IsNullOrWhiteSpace($dirP)) { continue }
            if ($dirP.Contains("/")) {
                $esc = [regex]::Escape($dirP) -replace '\\\*', '[^/]*'
                if ($norm -imatch "(^|/)$esc/") { return $true }
            } else {
                for ($si = 0; $si -lt ($parts.Count - 1); $si++) {
                    if ($parts[$si] -ilike $dirP) { return $true }
                }
            }
        } else {
            if ($leaf -ilike $pat -or $norm -ilike $pat) { return $true }
        }
    }
    return $false
}

function Get-SpeedFlagsString {
    param([string]$Preset = "Turbo")
    switch ($Preset) {
        "Turbo"    { return "--transfers 12 --checkers 24 --drive-chunk-size 128M --drive-upload-cutoff 64M --tpslimit 10 --tpslimit-burst 20 --fast-list" }
        "Balanced" { return "--transfers 6 --checkers 12 --drive-chunk-size 64M --drive-upload-cutoff 32M --tpslimit 8 --fast-list" }
        "Eco"      { return "--transfers 2 --checkers 4 --bwlimit 2M --drive-chunk-size 32M --fast-list" }
        default    { return "--transfers 8 --checkers 16 --drive-chunk-size 64M --fast-list" }
    }
}

function Format-EmailUsername {
    param([string]$Email, [string]$FallbackRemote = "gdrive")
    if (-not [string]::IsNullOrWhiteSpace($Email)) {
        $e = $Email.Trim()
        if ($e -match '^([^@]+)@') { return $Matches[1] }
        return $e
    }
    return $FallbackRemote
}

function Get-AccountPrefsMap {
    $map = @{}
    $script:AccountPrefsLoadError = ""
    if (-not (Test-Path -LiteralPath $AccountPrefsFile)) { return $map }
    try {
        $raw = [System.IO.File]::ReadAllText($AccountPrefsFile, [System.Text.Encoding]::UTF8)
        if ([string]::IsNullOrWhiteSpace($raw)) {
            $script:AccountPrefsLoadError = "Account preferences file is empty."
            return $map
        }
        $obj = ConvertFrom-Json -InputObject $raw
        foreach ($prop in $obj.PSObject.Properties) {
            $v = $prop.Value
            $map[$prop.Name] = [PSCustomObject]@{
                CustomName        = if ($v.PSObject.Properties["CustomName"])        { [string]$v.CustomName }        else { "" }
                AutoName          = if ($v.PSObject.Properties["AutoName"])          { [string]$v.AutoName }          else { "" }
                PreferredDrive    = if ($v.PSObject.Properties["PreferredDrive"])    { [string]$v.PreferredDrive }    else { "" }
                DefaultTargetMode = if ($v.PSObject.Properties["DefaultTargetMode"]) { [string]$v.DefaultTargetMode } else { "" }
                MountScope        = if ($v.PSObject.Properties["MountScope"])        { [string]$v.MountScope }        else { "MyDrive" }
                DriveAssignment   = if ($v.PSObject.Properties["DriveAssignment"])   { [string]$v.DriveAssignment }   else { "" }
                HasRulesPref      = if ($v.PSObject.Properties["HasRulesPref"])      { [bool]$v.HasRulesPref }        else { $false }
                UseJsonRules      = if ($v.PSObject.Properties["UseJsonRules"])      { [bool]$v.UseJsonRules }        else { $false }
                JsonRulesPath     = if ($v.PSObject.Properties["JsonRulesPath"])     { [string]$v.JsonRulesPath }     else { "" }
            }
        }
    } catch { $script:AccountPrefsLoadError = $_.Exception.Message }
    return $map
}

function Save-AccountPrefsMap {
    param([hashtable]$Map)
    try {
        $outObj = [ordered]@{}
        foreach ($k in ($Map.Keys | Sort-Object)) { $outObj[$k] = $Map[$k] }
        [System.IO.File]::WriteAllText($AccountPrefsFile, (ConvertTo-Json -InputObject $outObj -Depth 4), (New-Object System.Text.UTF8Encoding($false)))
    } catch {}
}

function Set-AccountPref {
    param(
        [string]$Remote,
        [string]$CustomName = $null,
        [string]$AutoName = $null,
        [string]$PreferredDrive = $null,
        [string]$DefaultTargetMode = $null,
        [string]$MountScope = $null,
        [string]$DriveAssignment = $null,
        [object]$UseJsonRules = $null,
        [string]$JsonRulesPath = $null
    )
    if ([string]::IsNullOrWhiteSpace($Remote)) { return }
    $map = Get-AccountPrefsMap
    if (-not $map.ContainsKey($Remote)) {
        $map[$Remote] = [PSCustomObject]@{
            CustomName = ""; AutoName = ""; PreferredDrive = ""; DefaultTargetMode = ""; MountScope = "MyDrive"; DriveAssignment = ""
            HasRulesPref = $false; UseJsonRules = $false; JsonRulesPath = ""
        }
    }
    if ($PSBoundParameters.ContainsKey("CustomName"))        { $map[$Remote].CustomName        = $CustomName.Trim() }
    if ($PSBoundParameters.ContainsKey("AutoName"))          { $map[$Remote].AutoName          = $AutoName.Trim() }
    if ($PSBoundParameters.ContainsKey("PreferredDrive"))    { $map[$Remote].PreferredDrive    = $PreferredDrive.Trim().ToUpperInvariant() }
    if ($PSBoundParameters.ContainsKey("DefaultTargetMode")) { $map[$Remote].DefaultTargetMode = $DefaultTargetMode.Trim() }
    if ($PSBoundParameters.ContainsKey("MountScope"))        { $map[$Remote].MountScope        = $MountScope.Trim() }
    if ($PSBoundParameters.ContainsKey("DriveAssignment"))   { $map[$Remote].DriveAssignment   = $DriveAssignment.Trim() }
    if ($PSBoundParameters.ContainsKey("UseJsonRules"))      { $map[$Remote].UseJsonRules      = [bool]$UseJsonRules; $map[$Remote].HasRulesPref = $true }
    if ($PSBoundParameters.ContainsKey("JsonRulesPath"))     { $map[$Remote].JsonRulesPath     = $JsonRulesPath;      $map[$Remote].HasRulesPref = $true }
    Save-AccountPrefsMap -Map $map
}

function Get-AccountMountScope {
    param([string]$TargetRemote)
    if ([string]::IsNullOrWhiteSpace($TargetRemote)) { return "MyDrive" }
    $map = Get-AccountPrefsMap
    if ($map.ContainsKey($TargetRemote) -and $map[$TargetRemote].MountScope -in @("MyDrive", "MyComputer", "Both")) {
        return $map[$TargetRemote].MountScope
    }
    return "MyDrive"
}

function Get-AccountDriveAssignment {
    param([string]$TargetRemote)
    if (-not [string]::IsNullOrWhiteSpace($TargetRemote)) {
        $map = Get-AccountPrefsMap
        if ($map.ContainsKey($TargetRemote) -and $map[$TargetRemote].DriveAssignment -in @("Unified", "Separate")) {
            return $map[$TargetRemote].DriveAssignment
        }
    }
    $dl = (Get-Settings).DriveLayout
    if ($dl -eq "Unified") { return "Unified" }
    return "Separate"
}

function Get-UnifiedPoolRemotes {
    $all = @(Get-ConfiguredDriveRemotes)
    $pool = @($all | Where-Object { (Get-AccountDriveAssignment -TargetRemote $_) -eq "Unified" })
    return $pool
}


function Get-AccountDisplayLabel {
    param([string]$TargetRemote)
    if ([string]::IsNullOrWhiteSpace($TargetRemote)) { return "gdrive" }
    $map = Get-AccountPrefsMap
    if ($map.ContainsKey($TargetRemote)) {
        $p = $map[$TargetRemote]
        if (-not [string]::IsNullOrWhiteSpace($p.CustomName)) { return $p.CustomName }
        if (-not [string]::IsNullOrWhiteSpace($p.AutoName))   { return $p.AutoName }
    }
    return $TargetRemote
}

function Get-AccountPreferredDrive {
    param([string]$TargetRemote, [string]$DefaultLetter = "")
    $map = Get-AccountPrefsMap
    if ($map.ContainsKey($TargetRemote) -and -not [string]::IsNullOrWhiteSpace($map[$TargetRemote].PreferredDrive)) {
        return $map[$TargetRemote].PreferredDrive.ToUpperInvariant()
    }
    return $DefaultLetter
}

function Get-AccountRulesConfig {
    param([string]$TargetRemote = $RemoteName)
    if ([string]::IsNullOrWhiteSpace($TargetRemote)) { $TargetRemote = "gdrive" }
    $map = Get-AccountPrefsMap
    if (-not [string]::IsNullOrWhiteSpace($script:AccountPrefsLoadError)) {
        # Corrupt account preferences may contain the only record of custom skip rules.
        # Block sync rather than silently treating the account as having no exclusions.
        return [PSCustomObject]@{ UseJsonRules = $true; JsonRulesPath = "" }
    }
    if ($map.ContainsKey($TargetRemote) -and [bool]$map[$TargetRemote].HasRulesPref) {
        $rPath = $map[$TargetRemote].JsonRulesPath
        # Never silently replace a missing custom rules file with a bundled preset
        # that happens to share its filename; changed filters can upload private files.
        if ([string]::IsNullOrWhiteSpace($rPath) -and -not [bool]$map[$TargetRemote].UseJsonRules) { $rPath = Get-DefaultPresetPath }
        return [PSCustomObject]@{ UseJsonRules = [bool]$map[$TargetRemote].UseJsonRules; JsonRulesPath = $rPath }
    }
    if ($TargetRemote -eq "gdrive") {
        $cfg = Get-Settings
        if (-not [string]::IsNullOrWhiteSpace($script:SettingsLoadError)) {
            # The global settings file may contain the only saved custom skip-rules path.
            # Do not replace it with a default preset after a parse/read failure.
            return [PSCustomObject]@{ UseJsonRules = $true; JsonRulesPath = "" }
        }
        $uRules = [bool]$cfg.UseJsonRules
        $rPath  = if (-not [string]::IsNullOrWhiteSpace($cfg.JsonRulesPath)) { $cfg.JsonRulesPath } else { Get-DefaultPresetPath }
        Set-AccountPref -Remote $TargetRemote -UseJsonRules $uRules -JsonRulesPath $rPath
        return [PSCustomObject]@{ UseJsonRules = $uRules; JsonRulesPath = $rPath }
    }
    $defPath = Get-DefaultPresetPath
    Set-AccountPref -Remote $TargetRemote -UseJsonRules $false -JsonRulesPath $defPath
    return [PSCustomObject]@{ UseJsonRules = $false; JsonRulesPath = $defPath }
}

function Get-AccountTargetModeSummary {
    param([string]$TargetRemote)
    $fList = @(Get-SyncFolders -TargetRemote $TargetRemote)
    if ($fList.Count -gt 0) {
        $modes = @($fList | ForEach-Object { if ($_.TargetMode -eq "My Computer") { "My Computer" } else { "My Drive" } } | Select-Object -Unique)
        if ($modes.Count -eq 1) { return $modes[0] }
        return "Mixed"
    }
    $map = Get-AccountPrefsMap
    if ($map.ContainsKey($TargetRemote) -and $map[$TargetRemote].DefaultTargetMode -eq "My Computer") {
        return "My Computer"
    }
    return "My Drive"
}

function Save-BackupHealth {
    param([string]$Mode, [string]$Status, [int]$ExitCode, [int]$FoldersProcessed, [string]$Summary, [string]$TargetRemote = "")
    try {
        $remUse = if (-not [string]::IsNullOrWhiteSpace($TargetRemote)) { $TargetRemote } elseif (-not [string]::IsNullOrWhiteSpace($script:ActiveRemote)) { $script:ActiveRemote } else { $RemoteName }
        $obj = [PSCustomObject]@{
            Timestamp        = (Get-Date -Format "o")
            Remote           = $remUse
            Mode             = $Mode
            Status           = $Status
            ExitCode         = $ExitCode
            FoldersProcessed = $FoldersProcessed
            Summary          = $Summary
        }
        [System.IO.File]::WriteAllText($HealthPath, (ConvertTo-Json -InputObject $obj -Depth 4), (New-Object System.Text.UTF8Encoding($false)))
    } catch {}
}

function Get-MaxDeleteFlagString {
    param(
        [string]$Policy = "Safe Archive",
        [int]$Limit = 0
    )
    # Safe Archive moves deleted/moved files safely to _CloudSync_Trash_Archive without deleting anything.
    # Copy-Only never deletes or moves remote files. Neither mode should ever be blocked by --max-delete.
    if ($Policy -ne "Strict Mirror") { return "" }
    if ($Limit -gt 0) { return "--max-delete $Limit" }
    return ""
}

function Resolve-FriendlySyncError {
    param(
        [string]$FolderName = "",
        [int]$ExitCode = 1,
        [string]$RawError = ""
    )
    $errText = if ($null -ne $RawError) { $RawError.Trim() } else { "" }
    if ($errText -match '(?i)max[- ]delete|Deleting more than') {
        return [PSCustomObject]@{
            StatusToken = "Err:MaxDelete"
            ShortStatus = (L "gridErrMaxDelete" "Delete limit paused")
            UserMessage = (LF "errMaxDeleteBody" @($FolderName))
        }
    }
    if ($errText -match '(?i)storageQuotaExceeded|quota.*exceeded|insufficient.*storage|storage.*full|not enough space') {
        return [PSCustomObject]@{
            StatusToken = "Err:QuotaFull"
            ShortStatus = (L "gridErrQuotaFull" "Drive storage full")
            UserMessage = (LF "errQuotaFullBody" @($FolderName))
        }
    }
    if ($errText -match '(?i)invalid_grant|token.*expired|oauth2|unauthorized|401\b|didn''t find section in config') {
        return [PSCustomObject]@{
            StatusToken = "Err:AuthExpired"
            ShortStatus = (L "gridErrAuthExpired" "Sign-in required")
            UserMessage = (LF "errAuthExpiredBody" @($FolderName))
        }
    }
    if ($ExitCode -in @(3, 4) -or $errText -match '(?i)directory not found|path not found|does not exist|being used by another process|access is denied|The process cannot access the file') {
        return [PSCustomObject]@{
            StatusToken = "Err:PathOrAccess"
            ShortStatus = (L "gridErrPathOrAccess" "File in use or missing")
            UserMessage = (LF "errPathOrAccessBody" @($FolderName))
        }
    }
    if ($errText -match '(?i)dial tcp|no such host|connection reset|context deadline exceeded|i/o timeout|TLS handshake|EOF\b|network is unreachable|temporary failure') {
        return [PSCustomObject]@{
            StatusToken = "Err:Network"
            ShortStatus = (L "gridErrNetwork" "Network interrupted")
            UserMessage = (LF "errNetworkBody" @($FolderName))
        }
    }
    return [PSCustomObject]@{
        StatusToken = "Err:General"
        ShortStatus = (L "gridErrGeneral" "Needs attention")
        UserMessage = (LF "errGeneralBody" @($FolderName))
    }
}
