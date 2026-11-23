# ==============================================================================
# AlphaCloudSync Provider Module: Google Drive (OAuth Branded Dark Flow, Identity, Account Discovery)
# ==============================================================================

$script:RcloneConfigDumpCacheObj = $null
$script:RcloneConfigDumpCacheUtc = [datetime]::MinValue

function Clear-RcloneConfigDumpCache {
    $script:RcloneConfigDumpCacheObj = $null
    $script:RcloneConfigDumpCacheUtc = [datetime]::MinValue
}

function Get-RcloneConfigDumpCached {
    param([switch]$ForceRefresh)
    $now = [datetime]::UtcNow
    if (-not $ForceRefresh -and $null -ne $script:RcloneConfigDumpCacheObj -and (($now - $script:RcloneConfigDumpCacheUtc).TotalSeconds -lt 3.0)) {
        return $script:RcloneConfigDumpCacheObj
    }
    $res = Invoke-RcloneCapture -Arguments "config dump --quiet" -TimeoutMs 10000
    if ($res.ExitCode -ne 0 -or [string]::IsNullOrWhiteSpace($res.StdOut)) { return $null }
    try {
        $script:RcloneConfigDumpCacheObj = ($res.StdOut | ConvertFrom-Json)
        $script:RcloneConfigDumpCacheUtc = $now
        return $script:RcloneConfigDumpCacheObj
    } catch { return $null }
}

function Load-UiAccountCache {
    try {
        if ([string]::IsNullOrWhiteSpace($UiAccountCacheFile) -or -not (Test-Path -LiteralPath $UiAccountCacheFile -PathType Leaf)) { return }
        $raw = [System.IO.File]::ReadAllText($UiAccountCacheFile, [System.Text.Encoding]::UTF8)
        if ([string]::IsNullOrWhiteSpace($raw)) { return }
        $obj = ConvertFrom-Json -InputObject $raw
        foreach ($prop in $obj.PSObject.Properties) {
            $rem = $prop.Name
            $val = $prop.Value
            if ($null -eq $val) { continue }
            if ($val.PSObject.Properties["AboutJson"] -and -not [string]::IsNullOrWhiteSpace($val.AboutJson)) {
                $script:LastAboutCache[$rem] = [string]$val.AboutJson
            }
            if ($val.PSObject.Properties["Email"] -and -not [string]::IsNullOrWhiteSpace($val.Email)) {
                $script:IdentityCache[$rem] = [PSCustomObject]@{
                    Connected         = $true
                    Email             = [string]$val.Email
                    DisplayName       = if ($val.PSObject.Properties["DisplayName"]) { [string]$val.DisplayName } else { "" }
                    Remote            = $rem
                    HasCustomClientId = if ($val.PSObject.Properties["HasCustomClientId"]) { [bool]$val.HasCustomClientId } else { $false }
                    CachedUtc         = if ($val.PSObject.Properties["UpdatedUtc"]) { [string]$val.UpdatedUtc } else { "" }
                }
            }
        }
    } catch {}
}

function Save-UiAccountCache {
    try {
        if ([string]::IsNullOrWhiteSpace($UiAccountCacheFile)) { return }
        $out = @{}
        $allKeys = @($script:IdentityCache.Keys) + @($script:LastAboutCache.Keys) | Sort-Object -Unique
        foreach ($rem in $allKeys) {
            if ([string]::IsNullOrWhiteSpace($rem)) { continue }
            $idObj = if ($script:IdentityCache.ContainsKey($rem)) { $script:IdentityCache[$rem] } else { $null }
            $abTxt = if ($script:LastAboutCache.ContainsKey($rem)) { [string]$script:LastAboutCache[$rem] } else { "" }
            $out[$rem] = [PSCustomObject]@{
                Email             = if ($null -ne $idObj -and $idObj.PSObject.Properties["Email"]) { [string]$idObj.Email } else { "" }
                DisplayName       = if ($null -ne $idObj -and $idObj.PSObject.Properties["DisplayName"]) { [string]$idObj.DisplayName } else { "" }
                HasCustomClientId = if ($null -ne $idObj -and $idObj.PSObject.Properties["HasCustomClientId"]) { [bool]$idObj.HasCustomClientId } else { $false }
                AboutJson         = $abTxt
                UpdatedUtc        = ([datetime]::UtcNow.ToString("o"))
            }
        }
        [System.IO.File]::WriteAllText($UiAccountCacheFile, (ConvertTo-Json -InputObject $out -Depth 4), (New-Object System.Text.UTF8Encoding($false)))
    } catch {}
}

function Ensure-RemoteAutoNameCached {
    param([string]$TargetRemote)
    if ([string]::IsNullOrWhiteSpace($TargetRemote)) { return }
    if (-not $script:LastAboutCache.ContainsKey($TargetRemote)) {
        try {
            $abRes = Invoke-RcloneCapture -Arguments "about `"${TargetRemote}:`" --json --quiet" -TimeoutMs 10000
            if ($abRes.ExitCode -eq 0 -and -not [string]::IsNullOrWhiteSpace($abRes.StdOut)) {
                $script:LastAboutCache[$TargetRemote] = $abRes.StdOut
                Save-UiAccountCache
            }
        } catch {}
    }
    $map = Get-AccountPrefsMap
    if ($map.ContainsKey($TargetRemote) -and (-not [string]::IsNullOrWhiteSpace($map[$TargetRemote].AutoName) -or -not [string]::IsNullOrWhiteSpace($map[$TargetRemote].CustomName))) {
        return
    }
    for ($try = 0; $try -lt 2; $try++) {
        try {
            if ($try -eq 1) {
                $abRes2 = Invoke-RcloneCapture -Arguments "about `"${TargetRemote}:`" --json --quiet" -TimeoutMs 10000
                if ($abRes2.ExitCode -eq 0 -and -not [string]::IsNullOrWhiteSpace($abRes2.StdOut)) {
                    $script:LastAboutCache[$TargetRemote] = $abRes2.StdOut
                }
            }
            $dump = Get-RcloneConfigDumpCached -ForceRefresh
            if ($null -ne $dump) {
                $remObj = $dump.$TargetRemote
                if ($null -ne $remObj -and -not [string]::IsNullOrWhiteSpace($remObj.token)) {
                    $tok = $remObj.token | ConvertFrom-Json
                    if (-not [string]::IsNullOrWhiteSpace($tok.access_token)) {
                        $info = Invoke-RestMethod -Uri "https://www.googleapis.com/drive/v3/about?fields=user(displayName,emailAddress)" -Headers @{ Authorization = "Bearer $($tok.access_token)" } -Method Get -UseBasicParsing -TimeoutSec 6 -ErrorAction SilentlyContinue
                        if ($null -ne $info -and $null -ne $info.user -and -not [string]::IsNullOrWhiteSpace($info.user.emailAddress)) {
                            $hasCid = (-not [string]::IsNullOrWhiteSpace($remObj.client_id))
                            $script:IdentityCache[$TargetRemote] = [PSCustomObject]@{ Connected = $true; Email = $info.user.emailAddress; DisplayName = $info.user.displayName; Remote = $TargetRemote; HasCustomClientId = $hasCid; CachedUtc = ([datetime]::UtcNow.ToString("o")) }
                            Set-AccountPref -Remote $TargetRemote -AutoName (Format-EmailUsername -Email $info.user.emailAddress -FallbackRemote $TargetRemote)
                            Save-UiAccountCache
                            return
                        }
                    }
                }
            }
        } catch {}
    }
}

function Get-ConfiguredDriveRemotes {
    param([switch]$ForceRefresh)
    $dump = Get-RcloneConfigDumpCached -ForceRefresh:$ForceRefresh
    if ($null -eq $dump) { return @() }
    try {
        $list = @()
        foreach ($prop in $dump.PSObject.Properties) {
            if ($prop.Value.type -eq "drive") { $list += $prop.Name }
        }
        return $list
    } catch { return @() }
}

function Test-GDriveConfigured {
    param([string]$TargetRemote = $RemoteName)
    return (@(Get-ConfiguredDriveRemotes) -contains $TargetRemote)
}

function Get-ConnectedGoogleIdentity {
    param([string]$TargetRemote = $RemoteName, [switch]$CacheOnly)
    if (-not (Test-GDriveConfigured -TargetRemote $TargetRemote)) {
        return [PSCustomObject]@{ Connected = $false; Email = ""; DisplayName = ""; Remote = $TargetRemote; HasCustomClientId = $false }
    }
    $hasCustom = $false
    $dump = Get-RcloneConfigDumpCached
    if ($null -ne $dump -and $dump.PSObject.Properties[$TargetRemote]) {
        $remObj0 = $dump.$TargetRemote
        if ($null -ne $remObj0) { $hasCustom = (-not [string]::IsNullOrWhiteSpace($remObj0.client_id)) }
    }
    if ($CacheOnly) {
        if ($script:IdentityCache.ContainsKey($TargetRemote)) {
            $cachedId = $script:IdentityCache[$TargetRemote]
            return [PSCustomObject]@{ Connected = $true; Email = $cachedId.Email; DisplayName = $cachedId.DisplayName; Remote = $TargetRemote; HasCustomClientId = $hasCustom }
        }
        $dispFb = Get-AccountDisplayLabel -TargetRemote $TargetRemote
        return [PSCustomObject]@{ Connected = $true; Email = $dispFb; DisplayName = ""; Remote = $TargetRemote; HasCustomClientId = $hasCustom }
    }
    try {
        $abRes = Invoke-RcloneCapture -Arguments "about `"${TargetRemote}:`" --json --quiet" -TimeoutMs 12000
        if ($abRes.ExitCode -eq 0 -and -not [string]::IsNullOrWhiteSpace($abRes.StdOut)) {
            $script:LastAboutCache[$TargetRemote] = $abRes.StdOut
        }
        $dumpFresh = Get-RcloneConfigDumpCached -ForceRefresh
        if ($null -ne $dumpFresh) {
            $remObj = $dumpFresh.$TargetRemote
            if ($null -ne $remObj) {
                $hasCustom = (-not [string]::IsNullOrWhiteSpace($remObj.client_id))
                if (-not [string]::IsNullOrWhiteSpace($remObj.token)) {
                    $tok = $remObj.token | ConvertFrom-Json
                    if (-not [string]::IsNullOrWhiteSpace($tok.access_token)) {
                        $headers = @{ Authorization = "Bearer $($tok.access_token)" }
                        $info = Invoke-RestMethod -Uri "https://www.googleapis.com/drive/v3/about?fields=user(displayName,emailAddress)" -Headers $headers -Method Get -UseBasicParsing -TimeoutSec 12 -ErrorAction SilentlyContinue
                        if ($null -ne $info -and $null -ne $info.user -and -not [string]::IsNullOrWhiteSpace($info.user.emailAddress)) {
                            $resolvedId = [PSCustomObject]@{ Connected = $true; Email = $info.user.emailAddress; DisplayName = $info.user.displayName; Remote = $TargetRemote; HasCustomClientId = $hasCustom; CachedUtc = ([datetime]::UtcNow.ToString("o")) }
                            $script:IdentityCache[$TargetRemote] = $resolvedId
                            Set-AccountPref -Remote $TargetRemote -AutoName (Format-EmailUsername -Email $info.user.emailAddress -FallbackRemote $TargetRemote)
                            Save-UiAccountCache
                            return $resolvedId
                        }
                    }
                }
            }
        }
        Save-UiAccountCache
    } catch {}
    if ($script:IdentityCache.ContainsKey($TargetRemote)) {
        $cachedId = $script:IdentityCache[$TargetRemote]
        return [PSCustomObject]@{ Connected = $true; Email = $cachedId.Email; DisplayName = $cachedId.DisplayName; Remote = $TargetRemote; HasCustomClientId = $hasCustom }
    }
    return [PSCustomObject]@{ Connected = $true; Email = $TargetRemote; DisplayName = ""; Remote = $TargetRemote; HasCustomClientId = $hasCustom }
}

function Get-NextUniqueRemoteId {
    param([string]$UserInput = "", [string[]]$ExistingRemotes = $null)
    $existing = if ($null -ne $ExistingRemotes) { @($ExistingRemotes) } else { @(Get-ConfiguredDriveRemotes) }
    $existingLow = @($existing | ForEach-Object { $_.ToLowerInvariant() })
    if (-not [string]::IsNullOrWhiteSpace($UserInput)) {
        $base = Get-SanitizedName -Name $UserInput.Trim()
        if ($existingLow -notcontains $base.ToLowerInvariant()) { return $base }
        for ($i = 2; $i -le 999; $i++) {
            $cand = "$base-$i"
            if ($existingLow -notcontains $cand.ToLowerInvariant()) { return $cand }
        }
        return "$base-$(Get-Random -Minimum 1000 -Maximum 9999)"
    }
    if ($existingLow -notcontains "gdrive") { return "gdrive" }
    for ($i = 2; $i -le 999; $i++) {
        $cand = "gdrive-$i"
        if ($existingLow -notcontains $cand.ToLowerInvariant()) { return $cand }
    }
    return "gdrive-$(Get-Random -Minimum 1000 -Maximum 9999)"
}

function New-BrandedOAuthTemplateFile {
    $isRtl = ($null -ne $script:CurrentLocale -and [bool]$script:CurrentLocale.rtl)
    $dirAttr = if ($isRtl) { "rtl" } else { "ltr" }
    $titleOk = [System.Net.WebUtility]::HtmlEncode((L "authSuccessTitle" "Connected Successfully"))
    $hintTxt = [System.Net.WebUtility]::HtmlEncode((L "oauthPageCloseHint" "You can close this tab now -- AlphaCloudSync is bringing itself to the front."))
    $html = @"
<!DOCTYPE html>
<html dir="$dirAttr">
<head>
<meta charset="utf-8"/>
<meta name="viewport" content="width=device-width, initial-scale=1"/>
<title>AlphaCloudSync</title>
<style>
  *{box-sizing:border-box;margin:0;padding:0}
  body{min-height:100vh;display:flex;align-items:center;justify-content:center;background:radial-gradient(circle at top,#112240 0%,#080D17 65%);font-family:'Segoe UI',system-ui,-apple-system,sans-serif;color:#E2E8F0;padding:24px}
  .card{width:100%;max-width:460px;background:#0F1829;border:1px solid #243550;border-radius:16px;padding:34px 30px;text-align:center;box-shadow:0 24px 64px rgba(0,0,0,.55)}
  .brand{display:inline-flex;align-items:center;gap:8px;padding:5px 14px;border-radius:999px;background:#12243D;border:1px solid #1F3B61;color:#38BDF8;font-size:12px;font-weight:700;letter-spacing:.3px;margin-bottom:22px}
  .badge{width:64px;height:64px;border-radius:50%;background:#0F291E;border:2px solid #10B981;display:flex;align-items:center;justify-content:center;margin:0 auto 18px}
  .badge.err{background:#2A1215;border-color:#EF4444}
  h1{font-size:21px;font-weight:700;color:#F8FAFC;margin-bottom:10px}
  p{font-size:14px;line-height:1.65;color:#94A3B8}
  .raw{display:none}
</style>
</head>
<body>
  <div class="card">
    <div class="brand">AlphaCloudSync</div>
    <div id="bIcon" class="badge">
      <svg width="30" height="30" viewBox="0 0 24 24" fill="none" stroke="#4ADE80" stroke-width="2.6" stroke-linecap="round" stroke-linejoin="round"><polyline points="20 6 9 17 4 12"/></svg>
    </div>
    <h1 id="hTitle">$titleOk</h1>
    <p id="pHint">$hintTxt</p>
    <div id="rawTitle" class="raw">{{ .Title }}</div>
    <div id="rawBody" class="raw">{{ .Body }}</div>
  </div>
  <script>
    (function(){
      var rt=(document.getElementById('rawTitle').textContent||'').toLowerCase();
      if(rt.indexOf('fail')>=0||rt.indexOf('err')>=0){
        document.getElementById('bIcon').className='badge err';
        document.getElementById('hTitle').textContent=document.getElementById('rawTitle').textContent;
        document.getElementById('pHint').textContent=document.getElementById('rawBody').textContent;
      } else {
        setTimeout(function(){ try{ window.open('','_self'); window.close(); }catch(e){} }, 1200);
      }
    })();
  </script>
</body>
</html>
"@
    $tplPath = Join-Path $env:TEMP "alphacloudsync_oauth_${PID}_$([guid]::NewGuid().ToString('N').Substring(0,6)).html"
    [System.IO.File]::WriteAllText($tplPath, $html, (New-Object System.Text.UTF8Encoding($false)))
    return $tplPath
}

function Invoke-GDriveAuth {
    param([string]$TargetRemote = $RemoteName)
    $wasConfigured = Test-GDriveConfigured -TargetRemote $TargetRemote
    $customCid = ""; $customCsec = ""
    if ($wasConfigured) {
        try {
            $dmpObj = Get-RcloneConfigDumpCached -ForceRefresh
            if ($null -ne $dmpObj) {
                $remCfg = $dmpObj.$TargetRemote
                if ($null -ne $remCfg -and -not [string]::IsNullOrWhiteSpace($remCfg.client_id) -and -not [string]::IsNullOrWhiteSpace($remCfg.client_secret)) {
                    $customCid = [string]$remCfg.client_id
                    $customCsec = [string]$remCfg.client_secret
                }
            }
        } catch {}
    }

    $tplFile = New-BrandedOAuthTemplateFile
    $proc = $null
    $cancelled = $false
    $stdOutTxt = ""; $stdErrTxt = ""
    try {
        $authArgs = if (-not [string]::IsNullOrWhiteSpace($customCid) -and -not [string]::IsNullOrWhiteSpace($customCsec)) {
            "authorize `"drive`" $(Format-WinArg $customCid) $(Format-WinArg $customCsec) --template $(Format-WinArg $tplFile)"
        } else {
            "authorize `"drive`" --template $(Format-WinArg $tplFile)"
        }

        $psi = New-Object System.Diagnostics.ProcessStartInfo
        $psi.FileName = $RcloneExe
        $psi.Arguments = $authArgs
        $psi.UseShellExecute = $false
        $psi.CreateNoWindow = $true
        $psi.RedirectStandardInput = $true
        $psi.RedirectStandardOutput = $true
        $psi.RedirectStandardError = $true
        $psi.StandardOutputEncoding = [System.Text.Encoding]::UTF8
        $psi.StandardErrorEncoding = [System.Text.Encoding]::UTF8
        $proc = [System.Diagnostics.Process]::Start($psi)
        if ($null -eq $proc) { return $false }
        try { $proc.StandardInput.Close() } catch {}
        $outTask = $proc.StandardOutput.ReadToEndAsync()
        $errTask = $proc.StandardError.ReadToEndAsync()

        if ($Action -eq "GUI" -and (Get-Command New-AlphaModalWindow -ErrorAction SilentlyContinue)) {
            try {
                $waitBodyTxt = [System.Security.SecurityElement]::Escape((L "authWaitBody" "Your browser has opened for Google Sign-In. Please complete authorization in your browser -- AlphaCloudSync will return automatically."))
                $canTxt      = [System.Security.SecurityElement]::Escape((L "btnCancel" "Cancel"))
                $bodyXaml = @"
                <Grid>
                    <Grid.RowDefinitions>
                        <RowDefinition Height="Auto"/>
                        <RowDefinition Height="Auto"/>
                        <RowDefinition Height="Auto"/>
                    </Grid.RowDefinitions>
                    <TextBlock Grid.Row="0" Text="$waitBodyTxt" TextWrapping="Wrap" FontSize="12.5" LineHeight="20" Foreground="#CBD5E1" Margin="0,0,0,14"/>
                    <ProgressBar Grid.Row="1" Height="6" IsIndeterminate="True" Background="#0F1829" BorderBrush="#1E314D" Foreground="#38BDF8" Margin="0,0,0,18"/>
                    <StackPanel Grid.Row="2" Orientation="Horizontal" HorizontalAlignment="Right">
                        <Button x:Name="BtnCancelAuthWait" Content="$canTxt" MinWidth="96"/>
                    </StackPanel>
                </Grid>
"@
                $waitWin = New-AlphaModalWindow -Title (L "authWaitTitle" "Waiting for Google Sign-In...") -ReqWidth 460 -ReqHeight 215 -Resizable $false -BodyXaml $bodyXaml
                $authState = [PSCustomObject]@{ Cancelled = $false }
                $pollTimer = New-Object System.Windows.Threading.DispatcherTimer
                $pollTimer.Interval = [TimeSpan]::FromMilliseconds(150)
                $pollTimer.Add_Tick({
                    try {
                        if ($proc.HasExited) {
                            $pollTimer.Stop()
                            $waitWin.Close()
                        }
                    } catch {}
                })
                $waitWin.FindName("BtnCancelAuthWait").Add_Click({
                    $authState.Cancelled = $true
                    try { $pollTimer.Stop() } catch {}
                    try { if (-not $proc.HasExited) { $proc.Kill() } } catch {}
                    $waitWin.Close()
                })
                $waitWin.Add_Closed({
                    try { $pollTimer.Stop() } catch {}
                    if (-not $proc.HasExited) {
                        $authState.Cancelled = $true
                        try { $proc.Kill() } catch {}
                    }
                })
                $pollTimer.Start()
                [void]$waitWin.ShowDialog()
                $cancelled = [bool]$authState.Cancelled
            } catch {
                $null = $proc.WaitForExit(180000)
            }
        } else {
            if (-not $proc.WaitForExit(180000)) {
                try { $proc.Kill() } catch {}
                return $false
            }
        }
        $exitCode = if ($proc.HasExited) { $proc.ExitCode } else { -1 }
        try { $stdOutTxt = $outTask.GetAwaiter().GetResult() } catch {}
        try { $stdErrTxt = $errTask.GetAwaiter().GetResult() } catch {}
    } finally {
        if ($null -ne $proc) { try { $proc.Dispose() } catch {} }
        if ($tplFile -and (Test-Path -LiteralPath $tplFile)) { Remove-Item -LiteralPath $tplFile -Force -ErrorAction SilentlyContinue }
    }

    if ($cancelled) { return $false }

    # Extract OAuth JSON token emitted by `rclone authorize`
    $tokenJson = ""
    if ($exitCode -eq 0 -and -not [string]::IsNullOrWhiteSpace($stdOutTxt)) {
        if ($stdOutTxt -match '(?s)--->\s*(\{.+?\})\s*<---') {
            $tokenJson = $Matches[1].Trim()
        } elseif ($stdOutTxt -match '(\{"access_token":[^\r\n]+\})') {
            $tokenJson = $Matches[1].Trim()
        }
    }

    $ok = $false
    if (-not [string]::IsNullOrWhiteSpace($tokenJson)) {
        $tokArg = Format-WinArg "token=$tokenJson"
        $cfgRes = if ($wasConfigured) {
            Invoke-RcloneCapture -Arguments "config update $(Format-WinArg $TargetRemote) $tokArg config_refresh_token=false --non-interactive" -TimeoutMs 15000
        } else {
            Invoke-RcloneCapture -Arguments "config create $(Format-WinArg $TargetRemote) drive scope=drive $tokArg --non-interactive" -TimeoutMs 15000
        }
        Clear-RcloneConfigDumpCache
        $ok = ($cfgRes.ExitCode -eq 0 -and (Test-GDriveConfigured -TargetRemote $TargetRemote))
        if (-not $ok -and -not $wasConfigured) {
            try { $null = Invoke-RcloneCapture -Arguments "config delete $(Format-WinArg $TargetRemote) --quiet" -TimeoutMs 8000; Clear-RcloneConfigDumpCache } catch {}
        }
        if (-not $ok -and -not [string]::IsNullOrWhiteSpace($cfgRes.StdErr)) { $stdErrTxt = $cfgRes.StdErr }
    }

    if ($ok -and $Action -eq "GUI") {
        try {
            if (Get-Command Restore-MainWindowFromTray -ErrorAction SilentlyContinue) { Restore-MainWindowFromTray }
            $ident = Get-ConnectedGoogleIdentity -TargetRemote $TargetRemote
            $accLbl = Get-AccountDisplayLabel -TargetRemote $TargetRemote
            $accSub = if ($ident -and -not [string]::IsNullOrWhiteSpace($ident.Email)) { $ident.Email } else { $TargetRemote }
            $null = Show-AlphaMessageBox -Message (LF "authSuccessBody" @((Wrap-Ltr $accLbl), (Wrap-Ltr $accSub)) "Account '{0}' ({1}) is now connected and ready.") -Title (L "authSuccessTitle" "Connected Successfully") -Buttons "OK" -Icon "Information"
        } catch {}
    } elseif (-not $ok -and -not $cancelled -and $Action -eq "GUI") {
        if (Get-Command Write-StudioLog -ErrorAction SilentlyContinue) {
            Write-StudioLog -Msg "[ERR] Google sign-in failed: $($stdErrTxt.Trim())" -TargetRemote $TargetRemote
        }
        $errSnippet = if (-not [string]::IsNullOrWhiteSpace($stdErrTxt)) { ($stdErrTxt -split "`r?`n" | Where-Object { $_.Trim() } | Select-Object -Last 2) -join "`r`n" } else { (L "authIncompleteMsg" "Authorization was not completed.") }
        $null = Show-AlphaMessageBox -Message $errSnippet -Title (L "authWaitTitle" "Google Sign-In") -Buttons "OK" -Icon "Warning"
    }
    return $ok
}


if (Get-Command Register-CloudProvider -ErrorAction SilentlyContinue) {
    Register-CloudProvider `
        -Id "drive" `
        -DisplayName "Google Drive" `
        -RcloneType "drive" `
        -DefaultRemotePrefix "gdrive" `
        -SupportsQuota $true `
        -SupportsTrash $true `
        -SupportsMyComputerScope $true `
        -SupportsUnifiedCombine $true `
        -AuthFunction "Invoke-GDriveAuth" `
        -IdentityFunction "Get-ConnectedGoogleIdentity" `
        -ListRemotesFunction "Get-ConfiguredDriveRemotes"
}
