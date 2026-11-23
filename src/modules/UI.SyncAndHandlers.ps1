# ==============================================================================
# AlphaCloudSync Module: UI.SyncAndHandlers (Sequential Sync Engine, Live Auto-Sync Timer, Event Handlers & Dark Modals)
# ==============================================================================

# SEQUENTIAL FOLDER-BY-FOLDER SYNC ENGINE + WEIGHTED OVERALL PROGRESS
# ==============================================================================
function Translate-RcloneAction {
    param([string]$RawAct)
    switch ($RawAct) {
        "Copied (new)"               { return (L "feedActCopiedNew") }
        "Copied (replaced existing)" { return (L "feedActCopiedReplaced") }
        "Updated"                    { return (L "feedActUpdated") }
        "Moved (server-side)"        { return (L "feedActMoved") }
        "Deleted"                    { return (L "feedActDeleted") }
        default                      { return $RawAct }
    }
}

function Invoke-PauseOrStopSync {
    $syncRem = if (-not [string]::IsNullOrWhiteSpace($script:SyncingRemote)) { $script:SyncingRemote } else { $script:ActiveRemote }
    $rt = Get-AccountRuntime -TargetRemote $syncRem
    $script:JobQueue.Clear()
    $script:PendingAutoSyncFolders = @()
    $script:WasPausedByUser = $true
    $rt.WasPausedByUser = $true
    if ($null -ne $script:ActiveProcess -and -not $script:ActiveProcess.HasExited) {
        Stop-Process -Id $script:ActiveProcess.Id -Force -ErrorAction SilentlyContinue
        $script:ActiveProcess = $null
    }
    if ($script:ActiveJobLogFile -and (Test-Path -LiteralPath $script:ActiveJobLogFile)) {
        Remove-Item -LiteralPath $script:ActiveJobLogFile -Force -ErrorAction SilentlyContinue
    }
    if ($script:ActiveFilesFromFile -and (Test-Path -LiteralPath $script:ActiveFilesFromFile)) {
        Remove-Item -LiteralPath $script:ActiveFilesFromFile -Force -ErrorAction SilentlyContinue
        $script:ActiveFilesFromFile = $null
    }
    $rt.CountersText     = LF "countersCompleted" @($rt.UploadedCount)
    $rt.LiveTransferText = L "statusStopped"
    if (-not $script:IsGloballyPaused) { $script:TrayIcon.Text = "AlphaCloudSync v$AppVersion" }
    if ($null -ne $script:WatchHub) { $script:WatchHub.Paused = $script:IsGloballyPaused }
    Set-SyncControlsRunningState -Running $false
    Write-StudioLog -Msg "[PAUSED] Sync paused/stopped cleanly by user." -TargetRemote $syncRem
    Update-SidebarSingleAccountCard -TargetRemote $syncRem
    Update-CloudIslandDisplay
}

function Start-NextStudioJob {
    if ($script:JobQueue.Count -eq 0) {
        $syncRem = if (-not [string]::IsNullOrWhiteSpace($script:SyncingRemote)) { $script:SyncingRemote } else { $script:ActiveRemote }
        $rt = Get-AccountRuntime -TargetRemote $syncRem
        $script:WasPausedByUser = $false; $script:LastOverallPct = 100.0; $script:LastSpeedTxt = ""; $script:LastEtaTxt = ""
        $rt.WasPausedByUser = $false; $rt.LastOverallPct = 100.0; $rt.LastSpeedTxt = ""; $rt.LastEtaTxt = ""
        $rt.ProgressPctText  = "100.0%"
        $rt.LiveTransferText = L "statusCompleted"

        $isPreviewMode = ($script:LastBatchMode -in @("DryRun", "RestorePreview"))
        $isRestoreMode = ($script:LastBatchMode -eq "Restore")
        $totalSynced   = $rt.UploadedCount + $rt.ArchivedCount

        if ($isPreviewMode) {
            $rt.CountersText = LF "countersPreviewDone" @($rt.PreviewCount)
        } else {
            $rt.CountersText = LF "countersCompleted" @($totalSynced)
        }
        if (-not $script:IsGloballyPaused) { $script:TrayIcon.Text = "AlphaCloudSync v$AppVersion" }
        if ($null -ne $script:WatchHub) {
            if ($isRestoreMode) {
                $script:WatchHub.ClearPending()
                $script:WatchResumeAfterUtc = [datetime]::UtcNow.AddSeconds(2.5)
            }
            $script:WatchHub.Paused = $script:IsGloballyPaused
        }
        Set-SyncControlsRunningState -Running $false
        Write-StudioLog -Msg "=== ALL QUEUED FOLDERS COMPLETED (100%) ===" -TargetRemote $syncRem
        Save-BackupHealth -Mode "GUI-$($script:LastBatchMode)" -Status "PASS" -ExitCode 0 -FoldersProcessed $script:BatchTotalFolders -Summary "Completed $($script:BatchTotalFolders) folder(s), uploaded=$($rt.UploadedCount), archived=$($rt.ArchivedCount), preview=$($rt.PreviewCount)." -TargetRemote $syncRem
        if ($syncRem -eq $script:ActiveRemote -and -not $isPreviewMode) { Update-DriveQuotaDisplay }
        $dispDone = Get-AccountDisplayLabel -TargetRemote $syncRem
        if ($isPreviewMode) {
            Show-TrayToast -Title (L "toastPreviewDoneTitle" "Preview Completed") -Body (LF "toastPreviewDoneBody" @($rt.PreviewCount, $dispDone)) -Category "Manual"
        } elseif ($isRestoreMode) {
            Show-TrayToast -Title (L "toastRestoreDoneTitle" "Safe Restore Completed") -Body (LF "toastRestoreDoneBody" @($rt.UploadedCount, $dispDone)) -Category "Manual"
        } elseif ($script:LastBatchIsAuto) {
            # Silent Auto-Sync: ONLY show a notification when real files were uploaded/archived (NEVER spam "0 file(s)"!)
            if ($totalSynced -gt 0 -and -not $script:BatchHadError) {
                Show-TrayToast -Title (L "toastSyncDoneTitle") -Body (LF "toastSyncDoneBody" @($totalSynced, $dispDone)) -Category "AutoSync"
            }
        } else {
            if (-not $script:BatchHadError) {
                Show-TrayToast -Title (L "toastSyncDoneTitle") -Body (LF "toastSyncDoneBody" @($totalSynced, $dispDone)) -Category "Manual"
            }
        }
        Update-SidebarSingleAccountCard -TargetRemote $syncRem
        Update-CloudIslandDisplay
        return
    }

    $job = $script:JobQueue.Dequeue()
    $syncRem = if (-not [string]::IsNullOrWhiteSpace($job.Remote)) { $job.Remote } else { $script:ActiveRemote }
    $script:SyncingRemote = $syncRem
    $rt = Get-AccountRuntime -TargetRemote $syncRem
    $script:BatchCurrentIndex++
    $script:BatchCurrentWeight  = [double]$job.Weight
    $script:CurrentFolder       = $job.FolderName
    $script:CurrentFolderPath   = $job.LocalPath
    $script:ActiveJobLogFile    = $job.LogFile
    $script:ActiveFilesFromFile = if ($job.PSObject.Properties["FilesFromFile"]) { $job.FilesFromFile } else { $null }
    $script:ActiveTargetFiles   = if ($job.PSObject.Properties["TargetFiles"])   { $job.TargetFiles }   else { $null }
    $script:SeenLogLines.Clear()

    $basePct = Compute-OverallBatchProgress -CompletedWeight $script:BatchCompletedWeight -CurrentWeight $script:BatchCurrentWeight -TotalWeight $script:BatchTotalWeight -CurrentFolderPct 0.0
    $script:LastOverallPct = $basePct
    $rt.LastOverallPct    = $basePct
    $rt.BatchCurrentIndex = $script:BatchCurrentIndex
    $rt.BatchTotalFolders = $script:BatchTotalFolders
    $rt.CurrentFolder     = $job.FolderName
    $rt.ProgressPctText   = LF "progressScanning" @((Wrap-Ltr ("{0:N1}" -f $basePct)))
    $rt.LiveTransferText  = LF "liveFolderBanner" @($script:BatchCurrentIndex, $script:BatchTotalFolders, (Wrap-Ltr $job.FolderName), $job.Title)
    $remPrefix = if ($job.PSObject.Properties["TargetMode"] -and $job.TargetMode -eq "My Computer") { "" } else { "My Drive/" }
    Write-StudioLog -Msg ">>> [$($script:BatchCurrentIndex)/$($script:BatchTotalFolders)] Starting $($job.Title): $($job.LocalPath) <==> ${remPrefix}$($job.RemotePath)" -TargetRemote $syncRem

    if (Test-Path -LiteralPath $job.LogFile) { Remove-Item -LiteralPath $job.LogFile -Force -ErrorAction SilentlyContinue }

    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = $RcloneExe; $psi.Arguments = $job.Arguments; $psi.UseShellExecute = $false; $psi.CreateNoWindow = $true
    $script:ActiveProcess = [System.Diagnostics.Process]::Start($psi)
    Set-SyncControlsRunningState -Running $true
    Update-SidebarSingleAccountCard -TargetRemote $syncRem
}

$timer = New-Object System.Windows.Threading.DispatcherTimer
$timer.Interval = [TimeSpan]::FromMilliseconds(850)
$timer.Add_Tick({
    try {
        # Auto-dismiss completed/archived rows from the live queue after 3.5s (like Google Drive; full history remains in the log below!)
        $nowTick = [datetime]::UtcNow
        foreach ($rtAcc in $script:AccountRuntimeMap.Values) {
            for ($ai = $rtAcc.ActivityItems.Count - 1; $ai -ge 0; $ai--) {
                $aRow = $rtAcc.ActivityItems[$ai]
                if ($null -ne $aRow -and $aRow.PSObject.Properties["CompletedUtc"] -and $null -ne $aRow.CompletedUtc) {
                    if (($nowTick - [datetime]$aRow.CompletedUtc).TotalSeconds -ge 3.5) {
                        $rtAcc.ActivityItems.RemoveAt($ai)
                    }
                }
            }
        }

        # Instantly surface newly detected file changes/deletions into the Activity Queue with exact status!
        if ($script:AutoWatchEnabled -and -not $script:IsGloballyPaused -and $null -ne $script:WatchHub -and [datetime]::UtcNow -ge $script:WatchResumeAfterUtc) {
            $recentEvs = @($script:WatchHub.PopRecentFileEvents())
            if ($recentEvs.Count -gt 0) {
                $curFoldersMap = @{}
                foreach ($cf in @(Get-SyncFolders -TargetRemote $script:ActiveRemote)) {
                    if ($cf -and $cf.Enabled -ne $false -and -not [string]::IsNullOrWhiteSpace($cf.LocalPath)) {
                        $normK = if ($cf.LocalPath.Length -gt 3) { $cf.LocalPath.TrimEnd('\') } else { $cf.LocalPath }
                        $curFoldersMap[$normK.ToLowerInvariant()] = $cf.Name
                    }
                }
                $cfgW = Get-Settings
                $rCfgW = Get-AccountRulesConfig -TargetRemote $script:ActiveRemote
                $mtimeW = if ($rCfgW.UseJsonRules -and -not [string]::IsNullOrWhiteSpace($rCfgW.JsonRulesPath) -and (Test-Path -LiteralPath $rCfgW.JsonRulesPath -PathType Leaf)) {
                    (Get-Item -LiteralPath $rCfgW.JsonRulesPath).LastWriteTimeUtc.Ticks
                } else { 0 }
                $cacheKeyW = "$($script:ActiveRemote)|$($rCfgW.UseJsonRules)|$($rCfgW.JsonRulesPath)|$mtimeW"
                if ($script:WatchExcludeCacheKey -ne $cacheKeyW) {
                    $exW = Build-SafeExcludeFile -TargetRemote $script:ActiveRemote
                    $script:WatchExcludeCacheLines = if ($exW.Enabled -and $exW.PSObject.Properties["Lines"]) { @($exW.Lines) } else { @() }
                    $script:WatchExcludeCacheKey = $cacheKeyW
                }
                $exLinesW = $script:WatchExcludeCacheLines
                $qState = L "feedStateQueued" "Queued"
                $qDet   = L "feedActQueuedChange" "Pending auto-sync"
                $delSt  = L "feedStateDeleteSync" "Delete Sync"
                $renSt  = L "feedStateRenameSync" "Rename Sync"
                foreach ($ev in $recentEvs) {
                    $kRoot = if ($ev.FolderRoot.Length -gt 3) { $ev.FolderRoot.TrimEnd('\').ToLowerInvariant() } else { $ev.FolderRoot.ToLowerInvariant() }
                    if ($curFoldersMap.ContainsKey($kRoot) -and -not [string]::IsNullOrWhiteSpace($ev.RelPath)) {
                        if (Test-RelPathExcludedByRules -RelPath $ev.RelPath -ExcludeLines $exLinesW -ExcludeDesktopIni ([bool]$cfgW.ShowFolderBadges)) { continue }
                        $fDisplay = "$($curFoldersMap[$kRoot])/$($ev.RelPath)"
                        if ($ev.Kind -eq "Deleted") {
                            if ($cfgW.DeletePolicy -eq "Copy-Only") {
                                Add-FileActivityRow -State $delSt -FileName $fDisplay -Details (L "feedActKeptCopyOnly" "Deleted locally (kept on Drive)") -TargetRemote $script:ActiveRemote -Priority 1 -BrushHex "#FB7185"
                            } elseif ($cfgW.DeletePolicy -eq "Strict Mirror") {
                                Add-FileActivityRow -State $delSt -FileName $fDisplay -Details (L "feedActPendingDelete" "Pending cloud deletion") -TargetRemote $script:ActiveRemote -Priority 2 -BrushHex "#FB7185"
                            } else {
                                Add-FileActivityRow -State $delSt -FileName $fDisplay -Details (L "feedActPendingArchive" "Pending cloud archive") -TargetRemote $script:ActiveRemote -Priority 2 -BrushHex "#FB7185"
                            }
                        } elseif ($ev.Kind -eq "Renamed") {
                            Add-FileActivityRow -State $renSt -FileName $fDisplay -Details $qDet -TargetRemote $script:ActiveRemote -Priority 2 -BrushHex "#C084FC"
                        } else {
                            Add-FileActivityRow -State $qState -FileName $fDisplay -Details $qDet -TargetRemote $script:ActiveRemote -Priority 2 -BrushHex "#94A3B8"
                        }
                    }
                }
            }
        }

        if ($null -ne $script:ActiveProcess) {
            $syncRem = if (-not [string]::IsNullOrWhiteSpace($script:SyncingRemote)) { $script:SyncingRemote } else { $script:ActiveRemote }
            $rt = Get-AccountRuntime -TargetRemote $syncRem
            $lines = Read-Utf8TailLines -Path $script:ActiveJobLogFile -MaxLines 85
            $activeUploading = 0; $bytesRatioTxt = ""; $speedTxt = ""; $etaTxt = ""; $bytePct = -1.0; $filesDone = -1; $filesTotal = -1

            foreach ($ln in $lines) {
                $clean = $ln.Trim()
                if ([string]::IsNullOrWhiteSpace($clean)) { continue }
                if ($clean -match 'INFO\s*:\s*(.+?):\s*(Copied \(new\)|Copied \(replaced existing\)|Updated|Moved \(server-side\)|Deleted)') {
                    $fName = $Matches[1].Trim(); $act = $Matches[2].Trim(); $key = "$fName|$act"
                    if (-not $script:SeenLogLines.ContainsKey($key)) {
                        $script:SeenLogLines[$key] = $true
                        $isArch = ($act -match 'Deleted|Moved')
                        $stateLabel = if ($isArch) { L "feedStateArchived" } else { L "feedStateUploaded" }
                        $stateClr   = if ($isArch) { "#FBBF24" } else { "#4ADE80" }
                        if ($isArch) { $rt.ArchivedCount++ } else { $script:UploadedCount++; $rt.UploadedCount++ }
                        Add-FileActivityRow -State $stateLabel -FileName "$($script:CurrentFolder)/$fName" -Details (Translate-RcloneAction $act) -TargetRemote $syncRem -Priority 1 -BrushHex $stateClr
                        Write-StudioLog -Msg "[$(if ($isArch) { 'ARCHIVED' } else { 'UPLOADED' })] $($script:CurrentFolder)/$fName ($act)" -TargetRemote $syncRem
                    }
                } elseif ($clean -match 'NOTICE:\s*(.+?):\s*Skipped (copy|update|delete|move) as --dry-run is set') {
                    $fName = $Matches[1].Trim(); $op = $Matches[2].Trim(); $key = "$fName|preview|$op"
                    if (-not $script:SeenLogLines.ContainsKey($key)) {
                        $script:SeenLogLines[$key] = $true
                        $rt.PreviewCount++
                        $det = switch ($op) { "update" { L "feedActWillUpdate" } "delete" { L "feedActWillDelete" } "move" { L "feedActMoved" } default { L "feedActWillCopy" } }
                        Add-FileActivityRow -State (L "feedStatePreview") -FileName "$($script:CurrentFolder)/$fName" -Details $det -TargetRemote $syncRem -Priority 2
                    }
                } elseif ($clean -match '^\*\s+(.+?):\s*(\d+)%\s*/([^,]+),\s*([^,]+)') {
                    $fName = ($Matches[1].Trim() -replace ([char]0x2026), '...'); $fPct = $Matches[2]; $fSpd = $Matches[4].Trim()
                    if ([int]$fPct -lt 100) {
                        $activeUploading++
                        Add-FileActivityRow -State (L "feedStateUploading") -FileName "$($script:CurrentFolder)/$fName" -Details (Wrap-Ltr "$fPct% ($fSpd)") -TargetRemote $syncRem -Priority 0 -FromStats
                    } else {
                        Add-FileActivityRow -State (L "feedStateUploaded") -FileName "$($script:CurrentFolder)/$fName" -Details (Wrap-Ltr "100% ($fSpd)") -TargetRemote $syncRem -Priority 1 -FromStats
                    }
                } elseif ($clean -match 'Transferred:\s+([^/]+/\s*[^,]+),\s*(\d+)%,\s*([^,]+/s),\s*ETA\s*(.+)$') {
                    $bytesRatioTxt = $Matches[1].Trim(); $bytePct = [double]$Matches[2]; $speedTxt = $Matches[3].Trim(); $etaTxt = $Matches[4].Trim()
                } elseif ($clean -match 'Transferred:\s+(\d+)\s*/\s*(\d+),\s*(\d+)%') {
                    $filesDone = [int]$Matches[1]; $filesTotal = [int]$Matches[2]
                }
            }

            $folderPct = -1.0
            if ($filesTotal -gt 0 -and $filesDone -ge 0) {
                $filePctExact = [math]::Round(($filesDone / [double]$filesTotal) * 100.0, 1)
                $folderPct = if ($bytePct -ge 0) { [math]::Round([math]::Max([double]$filePctExact, [double]$bytePct), 1) } else { $filePctExact }
                if ($folderPct -gt 99.9 -and $filesDone -lt $filesTotal) { $folderPct = 99.9 }
                $script:LastFilesSummary = "$filesDone / $filesTotal"
                $rt.LastFilesSummary = $script:LastFilesSummary
                $rt.CountersText = LF "countersProgress" @((Wrap-Ltr "$filesDone / $filesTotal"), $activeUploading)
            } elseif ($bytePct -ge 0) {
                $folderPct = $bytePct; $script:LastFilesSummary = "$($rt.UploadedCount)"
                $rt.LastFilesSummary = $script:LastFilesSummary
                $rt.CountersText = LF "countersProgress" @($rt.UploadedCount, $activeUploading)
            } else {
                $shownCnt = if ($script:LastBatchMode -in @("DryRun","RestorePreview")) { $rt.PreviewCount } else { $rt.UploadedCount }
                $rt.CountersText = LF "countersProgress" @($shownCnt, $activeUploading)
            }

            if ($folderPct -ge 0) {
                $overallPct = Compute-OverallBatchProgress -CompletedWeight $script:BatchCompletedWeight -CurrentWeight $script:BatchCurrentWeight -TotalWeight $script:BatchTotalWeight -CurrentFolderPct $folderPct
                $script:LastOverallPct = $overallPct
                $rt.LastOverallPct = $overallPct
                $rt.ProgressPctText = ("{0:N1}%" -f $overallPct)
                $trayTxt = "AlphaCloudSync $([math]::Round($overallPct))% ($($script:BatchCurrentIndex)/$($script:BatchTotalFolders))"
                if ($trayTxt.Length -le 63) { $script:TrayIcon.Text = $trayTxt }
            }
            if (-not [string]::IsNullOrWhiteSpace($bytesRatioTxt)) {
                $script:LastSpeedTxt = $speedTxt; $script:LastEtaTxt = $etaTxt
                $rt.LastSpeedTxt = $speedTxt; $rt.LastEtaTxt = $etaTxt
                $folderTag = LF "islandFolderProgress" @($script:BatchCurrentIndex, [math]::Max(1, $script:BatchTotalFolders), (Wrap-Ltr $script:CurrentFolder))
                $rt.LiveTransferText = LF "liveTransferMeta" @($folderTag, (Wrap-Ltr $bytesRatioTxt), (Wrap-Ltr $speedTxt), (Wrap-Ltr $etaTxt))
            }

            if ($syncRem -eq $script:ActiveRemote) {
                $BarSyncProgress.Value  = [math]::Max(1.0, [double]$rt.LastOverallPct)
                $TxtProgressPct.Text    = $rt.ProgressPctText
                $TxtUploadCounters.Text = $rt.CountersText
                $TxtLiveTransfer.Text   = $rt.LiveTransferText
            }
            Update-SidebarSingleAccountCard -TargetRemote $syncRem
            Update-CloudIslandDisplay

            if ($script:ActiveProcess.HasExited) {
                $code = $script:ActiveProcess.ExitCode; $script:ActiveProcess = $null
                $script:BatchCompletedWeight += $script:BatchCurrentWeight
                $errDetail = ""
                if ($code -ne 0 -and $script:ActiveJobLogFile -and (Test-Path -LiteralPath $script:ActiveJobLogFile)) {
                    $tailErr = @(Read-Utf8TailLines -Path $script:ActiveJobLogFile -MaxLines 30 | Where-Object { $_ -match 'ERROR|CRITICAL|Fatal|Failed' })
                    if ($tailErr.Count -gt 0) { $errDetail = $tailErr[$tailErr.Count - 1].Trim() }
                }
                if ($script:ActiveJobLogFile -and (Test-Path -LiteralPath $script:ActiveJobLogFile)) { Remove-Item -LiteralPath $script:ActiveJobLogFile -Force -ErrorAction SilentlyContinue }
                $wasTargetedFilesSync = ($null -ne $script:ActiveFilesFromFile)
                $doneTargetFiles = $script:ActiveTargetFiles
                $script:ActiveTargetFiles = $null
                if ($script:ActiveFilesFromFile -and (Test-Path -LiteralPath $script:ActiveFilesFromFile)) {
                    Remove-Item -LiteralPath $script:ActiveFilesFromFile -Force -ErrorAction SilentlyContinue
                    $script:ActiveFilesFromFile = $null
                }
                if ($code -eq 0 -and $script:LastBatchMode -notin @("DryRun", "RestorePreview")) {
                    Complete-StuckUploadingRowsForFolder -FolderPrefix $script:CurrentFolder -TargetRemote $syncRem -ClearPendingPreview:(-not $wasTargetedFilesSync) -TargetFiles $doneTargetFiles
                }
                $folders = @(Get-SyncFolders -TargetRemote $syncRem)
                foreach ($f in $folders) {
                    $sameFolder = if (-not [string]::IsNullOrWhiteSpace($script:CurrentFolderPath)) { $f.LocalPath -ieq $script:CurrentFolderPath } else { $f.Name -eq $script:CurrentFolder }
                    if ($sameFolder) {
                        if ($script:LastBatchMode -notin @("DryRun", "RestorePreview")) {
                            $f.LastStatus = if ($code -eq 0) { "Synced " + (Format-Time12h -DateTime (Get-Date)) } else { "Exit $code" }
                        }
                    }
                }
                Save-SyncFolders -Folders $folders -TargetRemote $syncRem
                if ($syncRem -eq $script:ActiveRemote) { Update-FoldersGrid }
                if ($code -eq 0) { Write-StudioLog -Msg "[OK] Completed '$($script:CurrentFolder)' cleanly." -TargetRemote $syncRem }
                else {
                    $script:BatchHadError = $true
                    $errMsgLine = if (-not [string]::IsNullOrWhiteSpace($errDetail)) { "[WARN] '$($script:CurrentFolder)' exited with code $code -- $errDetail" } else { "[WARN] '$($script:CurrentFolder)' exited with code $code." }
                    Write-StudioLog -Msg $errMsgLine -TargetRemote $syncRem
                    Save-BackupHealth -Mode "GUI-$($script:LastBatchMode)" -Status "FAIL" -ExitCode $code -FoldersProcessed $script:BatchCurrentIndex -Summary "Folder '$($script:CurrentFolder)' exited with code $code." -TargetRemote $syncRem
                    Show-TrayToast -Title (L "toastSyncErrTitle" "AlphaCloudSync Sync Warning") -Body (LF "toastSyncErrBody" @($script:CurrentFolder, $code)) -Category "Error" -Icon ([System.Windows.Forms.ToolTipIcon]::Warning)
                }
                Start-NextStudioJob
            }
        } elseif ($script:AutoWatchEnabled -and -not $script:IsGloballyPaused -and -not $script:IsSyncRunning -and $null -ne $script:WatchHub -and $script:IsSignedIn -and [datetime]::UtcNow -ge $script:WatchResumeAfterUtc) {
            $readyBatches = @($script:WatchHub.PopSettledBatches(4.0))
            if ($readyBatches.Count -gt 0) {
                foreach ($rb in $readyBatches) {
                    $existingQ = $script:PendingAutoSyncFolders | Where-Object { $_.FolderRoot -ieq $rb.FolderRoot } | Select-Object -First 1
                    if ($null -ne $existingQ) {
                        if ($rb.FullSyncRequired) { $existingQ.FullSyncRequired = $true }
                        else {
                            $merged = @($existingQ.Files) + @($rb.Files) | Sort-Object -Unique
                            $existingQ.Files = $merged
                            if ($merged.Count -gt 20) { $existingQ.FullSyncRequired = $true }
                        }
                    } else {
                        $script:PendingAutoSyncFolders += [PSCustomObject]@{ FolderRoot = $rb.FolderRoot; Files = @($rb.Files); FullSyncRequired = [bool]$rb.FullSyncRequired }
                    }
                }
            }
            if ($script:PendingAutoSyncFolders.Count -gt 0) {
                $nextAutoBatch = $script:PendingAutoSyncFolders[0]
                if ($script:PendingAutoSyncFolders.Count -gt 1) {
                    $script:PendingAutoSyncFolders = @($script:PendingAutoSyncFolders[1..($script:PendingAutoSyncFolders.Count - 1)])
                } else {
                    $script:PendingAutoSyncFolders = @()
                }
                $nextAutoPath = $nextAutoBatch.FolderRoot
                $normTarget = if ($nextAutoPath.Length -gt 3) { $nextAutoPath.TrimEnd('\') } else { $nextAutoPath }
                $enabledMatch = @(Get-SyncFolders -TargetRemote $script:ActiveRemote | Where-Object {
                    $fp = if ($_.LocalPath.Length -gt 3) { $_.LocalPath.TrimEnd('\') } else { $_.LocalPath }
                    ($_.Enabled -ne $false) -and ($fp -ieq $normTarget)
                })
                if ($enabledMatch.Count -gt 0 -and (Test-Path -LiteralPath $nextAutoPath -PathType Container)) {
                    $leafAuto = $enabledMatch[0].Name
                    if (-not $nextAutoBatch.FullSyncRequired -and @($nextAutoBatch.Files).Count -gt 0) {
                        Start-StudioBatch -Mode "Sync" -OnlyFolderPath $enabledMatch[0].LocalPath -TargetFiles @($nextAutoBatch.Files) -PreserveFeed -IsAutoSync
                    } else {
                        Write-StudioLog -Msg "[AUTO-SYNC] Detected change/delete in '$leafAuto' -- starting automatic sync..." -TargetRemote $script:ActiveRemote
                        Start-StudioBatch -Mode "Sync" -OnlyFolderPath $enabledMatch[0].LocalPath -PreserveFeed -IsAutoSync
                    }
                }
            }
        }
    } catch { Write-StudioLog "[WARN] Monitor tick error: $($_.Exception.Message)" }
})
$timer.Start()

function Start-StudioBatch {
    param([string]$Mode, [string]$OnlyFolderPath = "", [string[]]$TargetFiles = $null, [switch]$PreserveFeed, [switch]$IsAutoSync)
    if ($script:IsSyncRunning) {
        if ($script:SyncingRemote -ne $script:ActiveRemote) {
            $busyName = Get-AccountDisplayLabel -TargetRemote $script:SyncingRemote
            Write-StudioLog -Msg "[INFO] Another backup is currently running for '$busyName'. Wait for it to finish or switch to '$busyName' to pause it." -TargetRemote $script:ActiveRemote
        } else {
            Write-StudioLog -Msg "[INFO] A sync job is already running for this account." -TargetRemote $script:ActiveRemote
        }
        return
    }
    if (-not (Test-GDriveConfigured -TargetRemote $script:ActiveRemote)) {
        Show-AlphaMessageBox -Message (L "msgNotSignedInSyncBody") -Title (L "msgNotSignedInSyncTitle") -Buttons "OK" -Icon "Warning" | Out-Null
        return
    }
    Persist-GridCheckboxChanges
    $targetRem = $script:ActiveRemote
    $folders = @(Get-SyncFolders -TargetRemote $targetRem)
    if (-not [string]::IsNullOrWhiteSpace($OnlyFolderPath)) {
        $normOnly = if ($OnlyFolderPath.Length -gt 3) { $OnlyFolderPath.TrimEnd('\') } else { $OnlyFolderPath }
        $folders = @($folders | Where-Object {
            $fp = if ($_.LocalPath.Length -gt 3) { $_.LocalPath.TrimEnd('\') } else { $_.LocalPath }
            $fp -ieq $normOnly
        })
    } else {
        $folders = @($folders | Where-Object { $_.Enabled -ne $false })
    }
    if ($folders.Count -eq 0) { Write-StudioLog -Msg "[!] No enabled folders to process." -TargetRemote $targetRem; return }

    $cfg = Get-Settings
    $cfg.ComputerLabel = if ([string]::IsNullOrWhiteSpace($TxtComputerLabel.Text)) { "My Computer" } else { $TxtComputerLabel.Text.Trim() }
    Save-Settings -Obj $cfg

    $dateStamp = (Get-Date).ToString("yyyy-MM-dd_HH-mm-ss")
    $exInfo    = Build-SafeExcludeFile -TargetRemote $targetRem
    if (-not $exInfo.Valid) {
        Write-StudioLog -Msg "[ERR] Invalid exclusion rules; sync blocked to prevent unintended uploads: $($exInfo.Error)" -TargetRemote $targetRem
        return
    }
    $exFlag    = if ($exInfo.Enabled -and $exInfo.FilterFile) { "--exclude-from $(Format-WinArg $exInfo.FilterFile)" } else { "" }
    if ([bool]$cfg.ShowFolderBadges) { $exFlag = ("$exFlag --exclude `"desktop.ini`"").Trim() }
    $spdFlags  = Get-SpeedFlagsString -Preset $cfg.SpeedPreset
    $resilient = "--retries 10 --low-level-retries 20 --retries-sleep 5s --modify-window 1s"

    $queuedJobs = @()
    foreach ($f in $folders) {
        $effRemote = Resolve-EffectiveRemotePath -FolderItem $f
        $script:JobSeq++
        $jobLog = Join-Path $env:TEMP "alphacloudsync_job_${PID}_$($script:JobSeq).log"
        $weight = if ([double]$f.LocalBytes -gt 0) { [double]$f.LocalBytes } else { 104857600.0 }
        $locArg = Format-WinArg $f.LocalPath
        $remArg = Format-WinArg "${targetRem}:$effRemote"
        $logArg = Format-WinArg $jobLog

        if ($Mode -eq "Restore") {
            if (-not (Test-Path -LiteralPath $f.LocalPath)) { New-Item -ItemType Directory -Path $f.LocalPath -Force | Out-Null }
            $localBak = Join-Path $RestoreBkDir "$(Get-SanitizedName $f.Name)\$dateStamp"
            New-Item -ItemType Directory -Path $localBak -Force | Out-Null
            $args = "copy $remArg $locArg --backup-dir $(Format-WinArg $localBak) $spdFlags $resilient --stats 1s -v --log-file $logArg $exFlag"
            $queuedJobs += [PSCustomObject]@{ Remote = $targetRem; Title = (L "jobTitleRestore"); FolderName = $f.Name; LocalPath = $f.LocalPath; TargetMode = $f.TargetMode; RemotePath = $effRemote; Arguments = $args; LogFile = $jobLog; FilesFromFile = $null; Weight = $weight }
        } elseif ($Mode -eq "RestorePreview") {
            $args = "copy $remArg $locArg --dry-run $spdFlags $resilient --stats 1s -v --log-file $logArg $exFlag"
            $queuedJobs += [PSCustomObject]@{ Remote = $targetRem; Title = (L "jobTitleRestorePreview"); FolderName = $f.Name; LocalPath = $f.LocalPath; TargetMode = $f.TargetMode; RemotePath = $effRemote; Arguments = $args; LogFile = $jobLog; FilesFromFile = $null; Weight = $weight }
        } else {
            if (-not (Test-Path -LiteralPath $f.LocalPath)) { Write-StudioLog -Msg "[GUARD] Skipped missing local folder: $($f.LocalPath)" -TargetRemote $targetRem; continue }
            $dryFlag = if ($Mode -eq "DryRun") { "--dry-run" } else { "" }
            $polName = switch ($cfg.DeletePolicy) { "Copy-Only" { L "deletePolicyCopyOnly" } "Strict Mirror" { L "deletePolicyStrictMirror" } default { L "deletePolicySafeArchive" } }
            $titleTag = if ($Mode -eq "DryRun") { L "jobTitleDryRun" } else { LF "jobTitleSync" @($polName) }

            # Fast targeted single/multi-file auto-upload (~2s! Runs BEFORE full-tree scan and filters locally so rclone --files-from never collides with --exclude-from!)
            $hasSpecialTargetPrefix = ($null -ne $TargetFiles) -and (@($TargetFiles | Where-Object { -not [string]::IsNullOrWhiteSpace($_) -and ($_.TrimStart().StartsWith("#") -or $_.TrimStart().StartsWith(";")) }).Count -gt 0)
            $canUseFilesFrom = ($Mode -eq "Sync" -and $null -ne $TargetFiles -and $TargetFiles.Count -gt 0 -and -not [bool]$exInfo.HasComplexPatterns -and -not $hasSpecialTargetPrefix)
            if ($canUseFilesFrom) {
                $exLinesArr = if ($exInfo.Enabled -and $exInfo.PSObject.Properties["Lines"]) { @($exInfo.Lines) } else { @() }
                $existingRel = @($TargetFiles | Where-Object {
                    -not [string]::IsNullOrWhiteSpace($_) -and
                    -not (Test-RelPathExcludedByRules -RelPath $_ -ExcludeLines $exLinesArr -ExcludeDesktopIni ([bool]$cfg.ShowFolderBadges)) -and
                    (Test-Path -LiteralPath (Join-Path $f.LocalPath ($_ -replace '/', '\')) -PathType Leaf)
                })
                if ($existingRel.Count -gt 0) {
                    Write-StudioLog -Msg "[AUTO-SYNC] Fast-uploading $($existingRel.Count) changed file(s) in '$($f.Name)'..." -TargetRemote $targetRem
                    $filesFromPath = Join-Path $env:TEMP "alphacloudsync_files_${PID}_$($script:JobSeq).txt"
                    [System.IO.File]::WriteAllLines($filesFromPath, $existingRel, (New-Object System.Text.UTF8Encoding($false)))
                    # Note: rclone strictly forbids mixing --files-from with --exclude-from/--exclude; exclusions were already applied locally above!
                    $args = "copy $locArg $remArg --files-from $(Format-WinArg $filesFromPath) $spdFlags $resilient --stats 1s -v --log-file $logArg"
                    $queuedJobs += [PSCustomObject]@{ Remote = $targetRem; Title = $titleTag; FolderName = $f.Name; LocalPath = $f.LocalPath; TargetMode = $f.TargetMode; RemotePath = $effRemote; Arguments = $args; LogFile = $jobLog; FilesFromFile = $filesFromPath; TargetFiles = $existingRel; Weight = $weight }
                }
                continue
            }

            $sourceCheck = Test-RcloneSourceHasIncludedFiles -LocalPath $f.LocalPath -ExcludeFlags $exFlag
            if (-not $sourceCheck.Safe) { Write-StudioLog -Msg "[ERR] Source safety check failed for '$($f.Name)': $($sourceCheck.Error)" -TargetRemote $targetRem; continue }
            if (-not $sourceCheck.HasFiles) { Write-StudioLog -Msg "[GUARD] No files remain after exclusion rules for '$($f.Name)'; remote data was left untouched." -TargetRemote $targetRem; continue }

            if ($cfg.DeletePolicy -eq "Copy-Only") {
                $args = "copy $locArg $remArg $spdFlags $resilient $dryFlag --stats 1s -v --log-file $logArg $exFlag"
            } elseif ($cfg.DeletePolicy -eq "Strict Mirror") {
                $args = "sync $locArg $remArg --drive-use-trash=true --max-delete 200 $spdFlags $resilient $dryFlag --stats 1s -v --log-file $logArg $exFlag"
            } else {
                $trash = "${targetRem}:_CloudSync_Trash_Archive/$dateStamp/$effRemote"
                $args = "sync $locArg $remArg --backup-dir $(Format-WinArg $trash) --drive-use-trash=true --max-delete 200 $spdFlags $resilient $dryFlag --stats 1s -v --log-file $logArg $exFlag"
            }
            $queuedJobs += [PSCustomObject]@{ Remote = $targetRem; Title = $titleTag; FolderName = $f.Name; LocalPath = $f.LocalPath; TargetMode = $f.TargetMode; RemotePath = $effRemote; Arguments = $args; LogFile = $jobLog; FilesFromFile = $null; Weight = $weight }
        }
    }

    if ($queuedJobs.Count -eq 0) { return }

    $rt = Get-AccountRuntime -TargetRemote $targetRem
    if ($rt.PSObject.Properties["RecentlyCompleted"] -and $null -ne $rt.RecentlyCompleted) { $rt.RecentlyCompleted.Clear() }
    $script:LastBatchMode = $Mode; $script:LastBatchOnlyFolder = $OnlyFolderPath; $script:LastBatchIsAuto = [bool]$IsAutoSync; $script:BatchHadError = $false; $script:WasPausedByUser = $false
    $script:UploadedCount = 0; $rt.UploadedCount = 0; $rt.ArchivedCount = 0; $rt.PreviewCount = 0; $rt.WasPausedByUser = $false; $rt.LastOverallPct = 0.0
    $script:JobQueue.Clear()
    if (-not $PreserveFeed -and $Mode -eq "DryRun") {
        # Clear only old Preview/Queued rows (Priority 2) before fresh Preview; keep Completed history (Priority 1) intact
        for ($i = $rt.ActivityItems.Count - 1; $i -ge 0; $i--) {
            $pri = if ($rt.ActivityItems[$i].PSObject.Properties["Priority"]) { [int]$rt.ActivityItems[$i].Priority } else { 1 }
            if ($pri -eq 2) { $rt.ActivityItems.RemoveAt($i) }
        }
    }
    if ($Mode -eq "Restore" -and $null -ne $script:WatchHub) { $script:WatchHub.Paused = $true }

    $script:SyncingRemote = $targetRem
    $script:BatchTotalFolders = $queuedJobs.Count; $script:BatchCurrentIndex = 0; $script:BatchCompletedWeight = 0.0
    $script:BatchTotalWeight  = ($queuedJobs | Measure-Object -Property Weight -Sum).Sum
    if ($script:BatchTotalWeight -le 0) { $script:BatchTotalWeight = [double]$queuedJobs.Count }
    foreach ($qj in $queuedJobs) { $script:JobQueue.Enqueue($qj) }
    Start-NextStudioJob
}

function Add-LocalFolderToList {
    param([string]$SelPath)
    if ([string]::IsNullOrWhiteSpace($SelPath) -or -not (Test-Path -LiteralPath $SelPath -PathType Container)) { return }
    $leaf = Split-Path -Path $SelPath -Leaf
    if ([string]::IsNullOrWhiteSpace($leaf)) { $leaf = ($SelPath.TrimEnd('\', ':') + "_Drive") }
    $cfg = Get-Settings
    $compLabel = if ([string]::IsNullOrWhiteSpace($cfg.ComputerLabel)) { "My Computer" } else { $cfg.ComputerLabel.Trim() }
    $modeAns = Show-AlphaMessageBox -Message (LF "msgTargetModeBody" @($leaf, $compLabel)) -Title (L "msgTargetModeTitle") -Buttons "YesNoCancel" -Icon "Question"
    if ($modeAns -eq [System.Windows.MessageBoxResult]::Cancel) { return }
    $tMode = if ($modeAns -eq [System.Windows.MessageBoxResult]::No) { "My Computer" } else { "My Drive" }

    Persist-GridCheckboxChanges
    $folders = @(Get-SyncFolders -TargetRemote $script:ActiveRemote)
    if ($folders | Where-Object { $_.LocalPath -ieq $SelPath }) { Write-StudioLog "[!] Folder already in list: $SelPath"; return }
    # Prevent cloud remote collision when two different local paths share the same leaf folder name
    $uniqueName = $leaf
    $parentDir = Split-Path -Path $SelPath -Parent
    $parentLeaf = if (-not [string]::IsNullOrWhiteSpace($parentDir)) { Split-Path -Path $parentDir -Leaf } else { "" }
    $existingNames = @($folders | ForEach-Object { $_.RemotePath.Trim('/').ToLowerInvariant() })
    if ($existingNames -contains $uniqueName.ToLowerInvariant()) {
        if (-not [string]::IsNullOrWhiteSpace($parentLeaf) -and ($existingNames -notcontains "$leaf ($parentLeaf)".ToLowerInvariant())) {
            $uniqueName = "$leaf ($parentLeaf)"
        } else {
            $n = 2
            while ($existingNames -contains "$leaf-$n".ToLowerInvariant()) { $n++ }
            $uniqueName = "$leaf-$n"
        }
    }
    $folders += [PSCustomObject]@{
        Enabled = $true; Name = $uniqueName; LocalPath = $SelPath; TargetMode = $tMode; RemotePath = $uniqueName
        LocalSize = "Click 'Scan'"; LocalBytes = 0.0; RemoteSize = "Click 'Scan'"; LastStatus = "Ready"
    }
    Save-SyncFolders -Folders $folders -TargetRemote $script:ActiveRemote
    if ([bool]$cfg.ShowFolderBadges) { $null = Set-SyncedFolderBadge -FolderPath $SelPath }
    Update-FoldersGrid
    Sync-RealTimeWatchers
    Write-StudioLog "[OK] Added folder '$uniqueName' (Target: $tMode)"
}

# ==============================================================================
# EVENT HANDLERS (STABLE TAG-BASED LOGIC + MULTI-ACCOUNT DRIVES HUB)
# ==============================================================================
function Test-EventFromInputControl {
    param($Source)
    $cur = $Source
    while ($null -ne $cur) {
        if ($cur -is [System.Windows.Controls.ComboBox] -or $cur -is [System.Windows.Controls.ComboBoxItem] -or $cur -is [System.Windows.Controls.CheckBox]) { return $true }
        try {
            if ($cur -is [System.Windows.Media.Visual] -or $cur -is [System.Windows.Media.Media3D.Visual3D]) { $cur = [System.Windows.Media.VisualTreeHelper]::GetParent($cur) }
            else { $cur = [System.Windows.LogicalTreeHelper]::GetParent($cur) }
        } catch { break }
    }
    return $false
}

function Switch-ActiveAccountRemote {
    param([string]$TargetRemote)
    if ([string]::IsNullOrWhiteSpace($TargetRemote) -or $TargetRemote -eq $script:ActiveRemote) { return }
    Persist-GridCheckboxChanges
    $script:ActiveRemote = $TargetRemote
    $cfg = Get-Settings; $cfg.ActiveRemote = $TargetRemote; Save-Settings -Obj $cfg
    Refresh-StudioHeader
    Sync-RealTimeWatchers
}

$ListSidebarAccounts.AddHandler([System.Windows.Controls.Primitives.ButtonBase]::ClickEvent, [System.Windows.RoutedEventHandler]{
    param($s, $e)
    try {
        $btn = $e.OriginalSource
        while ($null -ne $btn -and $btn -isnot [System.Windows.Controls.Button]) {
            if ($btn -is [System.Windows.Media.Visual] -or $btn -is [System.Windows.Media.Media3D.Visual3D]) { $btn = [System.Windows.Media.VisualTreeHelper]::GetParent($btn) }
            else { $btn = [System.Windows.LogicalTreeHelper]::GetParent($btn) }
        }
        if ($null -ne $btn -and $btn.Uid -eq "SidebarAccountCard" -and $btn.Tag) {
            Switch-ActiveAccountRemote -TargetRemote $btn.Tag.ToString()
        }
    } catch {}
})

$CmbLanguage.Add_SelectionChanged({
    if ($script:IsRefreshing) { return }
    try {
        if ($null -ne $CmbLanguage.SelectedItem -and $CmbLanguage.SelectedItem.Tag) {
            Apply-UiLanguage -Lang $CmbLanguage.SelectedItem.Tag.ToString()
            Refresh-StudioHeader
        }
    } catch {}
})

function Invoke-RefreshActiveUnifiedPool {
    param([switch]$ForceShow, [switch]$QuietExplorer)
    $pool = @(Get-UnifiedPoolRemotes)
    $uInfo = Get-UnifiedMountInfo
    if ($pool.Count -eq 0) {
        if ($null -ne $uInfo) { Invoke-ToggleUnifiedMount -ForceUnmount }
        return
    }
    if ($ForceShow -or $null -ne $uInfo) {
        $targetLtr = if ($null -ne $uInfo -and -not [string]::IsNullOrWhiteSpace($uInfo.Letter)) { $uInfo.Letter } else { Get-AutoUnifiedDriveLetter }
        Write-StudioLog "Updating Unified Drive ($targetLtr) with $($pool.Count) account(s)..."
        Invoke-UiPump
        Invoke-ToggleUnifiedMount -Letter $targetLtr -TargetRemotes $pool -ForceMount -QuietExplorer:$QuietExplorer
    }
}

$CmbMountMode.Add_SelectionChanged({
    if ($script:IsRefreshing) { return }
    try {
        if ($null -ne $CmbMountMode.SelectedItem -and $CmbMountMode.SelectedItem.Tag) {
            $tag = $CmbMountMode.SelectedItem.Tag.ToString()
            if ($tag -eq "Unified") {
                Set-AccountPref -Remote $script:ActiveRemote -DriveAssignment "Unified"
                $hadSep = ($null -ne (Get-MountedLetterForRemote -TargetRemote $script:ActiveRemote))
                if ($hadSep) { Invoke-ToggleMount -TargetRemote $script:ActiveRemote -ForceUnmount }
                if ($hadSep -or ($null -ne (Get-UnifiedMountInfo))) {
                    Invoke-RefreshActiveUnifiedPool -ForceShow -QuietExplorer
                }
                Refresh-StudioHeader
            } else {
                $cfg = Get-Settings
                $prevMode = $cfg.MountMode
                $cfg.MountMode = $tag
                Save-Settings -Obj $cfg
                $wasUni = ((Get-AccountDriveAssignment -TargetRemote $script:ActiveRemote) -eq "Unified")
                if ($wasUni) {
                    $uInfo = Get-UnifiedMountInfo
                    $wasInActiveUni = ($null -ne $uInfo -and ($uInfo.Remotes.Count -eq 0 -or ($uInfo.Remotes -contains $script:ActiveRemote)))
                    Set-AccountPref -Remote $script:ActiveRemote -DriveAssignment "Separate"
                    if ($wasInActiveUni) {
                        Invoke-RefreshActiveUnifiedPool -QuietExplorer
                        $prefLtr = Get-AccountPreferredDrive -TargetRemote $script:ActiveRemote -DefaultLetter ""
                        $avail = @(Get-AvailableDriveLetters -TargetRemote $script:ActiveRemote -Preferred $prefLtr)
                        if ($avail.Count -gt 0) {
                            Set-AccountPref -Remote $script:ActiveRemote -PreferredDrive $avail[0]
                            Invoke-ToggleMount -TargetRemote $script:ActiveRemote -Letter $avail[0] -ForceMount -QuietExplorer
                        }
                    }
                } elseif ($prevMode -ne $tag) {
                    $activeSep = Get-MountedLetterForRemote -TargetRemote $script:ActiveRemote
                    if ($null -ne $activeSep) {
                        Invoke-ToggleMount -TargetRemote $script:ActiveRemote -ForceUnmount
                        Invoke-ToggleMount -TargetRemote $script:ActiveRemote -Letter $activeSep -ForceMount -QuietExplorer
                    }
                }
                Refresh-StudioHeader
            }
        }
    } catch {}
})

$CmbMountScope.Add_SelectionChanged({
    if ($script:IsRefreshing) { return }
    try {
        if ($null -ne $CmbMountScope.SelectedItem -and $CmbMountScope.SelectedItem.Tag) {
            $newScope = $CmbMountScope.SelectedItem.Tag.ToString()
            $oldScope = Get-AccountMountScope -TargetRemote $script:ActiveRemote
            if ($newScope -eq $oldScope) { return }
            Set-AccountPref -Remote $script:ActiveRemote -MountScope $newScope
            $activeLtr = Get-MountedLetterForRemote -TargetRemote $script:ActiveRemote
            if ($null -ne $activeLtr) {
                $disp = Get-AccountDisplayLabel -TargetRemote $script:ActiveRemote
                Write-StudioLog "Remounting '$disp' on $activeLtr with view scope '$newScope'..."
                Invoke-UiPump
                Invoke-ToggleMount -TargetRemote $script:ActiveRemote -ForceUnmount
                Invoke-ToggleMount -TargetRemote $script:ActiveRemote -Letter $activeLtr -ForceMount -QuietExplorer
            } else {
                $uInfo = Get-UnifiedMountInfo
                if ($null -ne $uInfo -and ($uInfo.Remotes.Count -eq 0 -or ($uInfo.Remotes -contains $script:ActiveRemote))) {
                    Invoke-RefreshActiveUnifiedPool -QuietExplorer
                }
            }
            Refresh-StudioHeader
        }
    } catch {}
})

$ChkStartup.Add_Click({ try { Set-StartupEnabled -Enable ([bool]$ChkStartup.IsChecked) } catch {} })

$CmbAccountProfile.Add_SelectionChanged({
    if ($script:IsRefreshing) { return }
    try {
        if ($null -ne $CmbAccountProfile.SelectedItem) {
            $selRemote = if ($CmbAccountProfile.SelectedItem.PSObject.Properties["Tag"] -and $CmbAccountProfile.SelectedItem.Tag) { $CmbAccountProfile.SelectedItem.Tag.ToString() } else { $CmbAccountProfile.SelectedItem.ToString() }
            Switch-ActiveAccountRemote -TargetRemote $selRemote
        }
    } catch {}
})

$CmbDriveLetter.Add_SelectionChanged({
    if ($script:IsRefreshing) { return }
    try {
        if ($null -ne $CmbDriveLetter.SelectedItem) {
            $selVal = Get-SelectedDriveLetter
            if ($selVal -eq "__UNIFIED__") {
                Set-AccountPref -Remote $script:ActiveRemote -DriveAssignment "Unified"
                $hadSep = ($null -ne (Get-MountedLetterForRemote -TargetRemote $script:ActiveRemote))
                if ($hadSep) { Invoke-ToggleMount -TargetRemote $script:ActiveRemote -ForceUnmount }
                if ($hadSep -or ($null -ne (Get-UnifiedMountInfo))) {
                    Invoke-RefreshActiveUnifiedPool -ForceShow -QuietExplorer
                }
                Refresh-StudioHeader
            } else {
                $cfg = Get-Settings; $cfg.PreferredDrive = $selVal; Save-Settings -Obj $cfg
                $wasInUni = $false
                $uInfo = Get-UnifiedMountInfo
                if ($null -ne $uInfo -and ($uInfo.Remotes.Count -eq 0 -or ($uInfo.Remotes -contains $script:ActiveRemote))) { $wasInUni = $true }
                Set-AccountPref -Remote $script:ActiveRemote -DriveAssignment "Separate" -PreferredDrive $selVal
                $activeSep = Get-MountedLetterForRemote -TargetRemote $script:ActiveRemote
                if ($null -ne $activeSep -and $activeSep -ne $selVal) {
                    Invoke-ToggleMount -TargetRemote $script:ActiveRemote -ForceUnmount
                    Invoke-ToggleMount -TargetRemote $script:ActiveRemote -Letter $selVal -ForceMount -QuietExplorer
                } elseif ($wasInUni) {
                    Invoke-RefreshActiveUnifiedPool -QuietExplorer
                    Invoke-ToggleMount -TargetRemote $script:ActiveRemote -Letter $selVal -ForceMount -QuietExplorer
                }
                Refresh-StudioHeader
            }
        }
    } catch {}
})

$CmbDeletePolicy.Add_SelectionChanged({
    if ($script:IsRefreshing) { return }
    try {
        if ($null -ne $CmbDeletePolicy.SelectedItem -and $CmbDeletePolicy.SelectedItem.Tag) {
            $pol = $CmbDeletePolicy.SelectedItem.Tag.ToString()
            $cfg = Get-Settings; $cfg.DeletePolicy = $pol; Save-Settings -Obj $cfg
            Update-DeletePolicyHint -Policy $pol
        }
    } catch {}
})

$CmbDefaultTarget.Add_SelectionChanged({
    if ($script:IsRefreshing) { return }
    try {
        if ($null -ne $CmbDefaultTarget.SelectedItem -and $CmbDefaultTarget.SelectedItem.Tag) {
            $newT = $CmbDefaultTarget.SelectedItem.Tag.ToString()
            Set-AccountPref -Remote $script:ActiveRemote -DefaultTargetMode $newT
            $fList = @(Get-SyncFolders -TargetRemote $script:ActiveRemote)
            if ($fList.Count -gt 0) {
                foreach ($f in $fList) { $f.TargetMode = $newT }
                Save-SyncFolders -Folders $fList -TargetRemote $script:ActiveRemote
            }
            $disp = Get-AccountDisplayLabel -TargetRemote $script:ActiveRemote
            Write-StudioLog "[OK] Updated backup destination for '$disp' to '$newT'."
            Refresh-StudioHeader
        }
    } catch {}
})

$CmbSpeedPreset.Add_SelectionChanged({
    if ($script:IsRefreshing) { return }
    try {
        if ($null -ne $CmbSpeedPreset.SelectedItem -and $CmbSpeedPreset.SelectedItem.Tag) {
            $cfg = Get-Settings; $cfg.SpeedPreset = $CmbSpeedPreset.SelectedItem.Tag.ToString(); Save-Settings -Obj $cfg
        }
    } catch {}
})

$TxtComputerLabel.Add_LostFocus({
    try {
        $cfg = Get-Settings
        $cfg.ComputerLabel = if ([string]::IsNullOrWhiteSpace($TxtComputerLabel.Text)) { "My Computer" } else { $TxtComputerLabel.Text.Trim() }
        Save-Settings -Obj $cfg; Update-FoldersGrid
    } catch {}
})

$BtnAuthToggle.Add_Click({
    try {
        if ($script:IsSignedIn) {
            $disp = Get-AccountDisplayLabel -TargetRemote $script:ActiveRemote
            $ans = Show-AlphaMessageBox -Message (LF "msgConfirmSignOutBody" @($disp)) -Title (L "msgConfirmSignOutTitle") -Buttons "YesNo" -Icon "Question"
            if ($ans -eq [System.Windows.MessageBoxResult]::Yes) {
                $signedOutRem = $script:ActiveRemote
                if ($script:IsSyncRunning -and $script:SyncingRemote -eq $signedOutRem) {
                    Invoke-PauseOrStopSync
                }
                $uInfo = Get-UnifiedMountInfo
                $wasInUni = ($null -ne $uInfo -and ($uInfo.Remotes.Count -eq 0 -or ($uInfo.Remotes -contains $signedOutRem)))
                Invoke-ToggleMount -TargetRemote $signedOutRem -ForceUnmount
                $null = Invoke-RcloneCapture -Arguments "config delete $(Format-WinArg $signedOutRem) --quiet"
                if ($script:IdentityCache.ContainsKey($signedOutRem))  { $script:IdentityCache.Remove($signedOutRem) }
                if ($script:LastAboutCache.ContainsKey($signedOutRem)) { $script:LastAboutCache.Remove($signedOutRem) }
                $pMap = Get-AccountPrefsMap
                if ($pMap.ContainsKey($signedOutRem)) { $pMap.Remove($signedOutRem); Save-AccountPrefsMap -Map $pMap }
                if ($wasInUni) { Invoke-RefreshActiveUnifiedPool -QuietExplorer }
                $remLeft = @(Get-ConfiguredDriveRemotes)
                $script:ActiveRemote = if ($remLeft.Count -gt 0) { $remLeft[0] } else { "gdrive" }
                $cfg = Get-Settings; $cfg.ActiveRemote = $script:ActiveRemote; Save-Settings -Obj $cfg
                Refresh-StudioHeader
                Sync-RealTimeWatchers
            }
        } else {
            Invoke-UiPump; Invoke-GDriveAuth -TargetRemote $script:ActiveRemote; Refresh-StudioHeader
        }
    } catch { Write-StudioLog "[ERR] Auth error: $($_.Exception.Message)" }
})

function Apply-DriveLayoutChange {
    param([string]$NewLayout)
    if ($NewLayout -notin @("Separate", "Unified")) { return }
    $cfg = Get-Settings
    if ($cfg.DriveLayout -eq $NewLayout) { return }
    $cfg.DriveLayout = $NewLayout
    Save-Settings -Obj $cfg

    $hadUnified = ($null -ne (Get-UnifiedMountLetter))
    $hadSeparate = $false
    $remotes = @(Get-ConfiguredDriveRemotes)
    foreach ($rem in $remotes) {
        Set-AccountPref -Remote $rem -DriveAssignment $NewLayout
        if ($null -ne (Get-MountedLetterForRemote -TargetRemote $rem)) { $hadSeparate = $true }
    }
    if ($hadUnified -or $hadSeparate) {
        Invoke-ToggleUnifiedMount -ForceUnmount
        foreach ($rem in $remotes) {
            if ($null -ne (Get-MountedLetterForRemote -TargetRemote $rem)) { Invoke-ToggleMount -TargetRemote $rem -ForceUnmount }
        }
        if ($NewLayout -eq "Unified") {
            $autoU = Get-AutoUnifiedDriveLetter
            Write-StudioLog "Switching to Unified Single Drive ($autoU) for all $($remotes.Count) account(s)..."
            Invoke-UiPump
            Invoke-ToggleUnifiedMount -Letter $autoU -TargetRemotes $remotes -ForceMount -QuietExplorer
        } else {
            $reservedInBatch = @()
            foreach ($rem in $remotes) {
                $prefLtr = Get-AccountPreferredDrive -TargetRemote $rem -DefaultLetter ""
                $avail = @(Get-AvailableDriveLetters -TargetRemote $rem -Preferred $prefLtr -ReservedLetters $reservedInBatch)
                if ($avail.Count -gt 0) {
                    $pickLetter = $avail[0]
                    $reservedInBatch += $pickLetter
                    Invoke-UiPump
                    Invoke-ToggleMount -TargetRemote $rem -Letter $pickLetter -ForceMount -QuietExplorer
                }
            }
        }
    }
    Refresh-StudioHeader
}

$CmbDriveLayout.Add_SelectionChanged({
    if ($script:IsRefreshing) { return }
    try {
        if ($null -ne $CmbDriveLayout.SelectedItem -and $CmbDriveLayout.SelectedItem.Tag) {
            Apply-DriveLayoutChange -NewLayout $CmbDriveLayout.SelectedItem.Tag.ToString()
        }
    } catch {}
})

$CmbDriveLayoutSettings.Add_SelectionChanged({
    if ($script:IsRefreshing) { return }
    try {
        if ($null -ne $CmbDriveLayoutSettings.SelectedItem -and $CmbDriveLayoutSettings.SelectedItem.Tag) {
            Apply-DriveLayoutChange -NewLayout $CmbDriveLayoutSettings.SelectedItem.Tag.ToString()
        }
    } catch {}
})

# Multi-Account Simultaneous Explorer Mount / Unmount All + Hybrid Unified Pool!
$BtnMountAll.Add_Click({
    try {
        $cfg = Get-Settings
        $remotes = @(Get-ConfiguredDriveRemotes)
        $pool = @(Get-UnifiedPoolRemotes)
        if ($cfg.DriveLayout -eq "Unified" -and $pool.Count -eq 0 -and $remotes.Count -gt 0) {
            foreach ($r in $remotes) { Set-AccountPref -Remote $r -DriveAssignment "Unified" }
            $pool = $remotes
        }
        $reservedInBatch = @()
        if ($pool.Count -gt 0) {
            $autoU = Get-AutoUnifiedDriveLetter
            Write-StudioLog "Mounting Unified Single Drive ($autoU) with $($pool.Count) account(s)..."
            Invoke-UiPump
            Invoke-ToggleUnifiedMount -Letter $autoU -TargetRemotes $pool -ForceMount
            $reservedInBatch += $autoU
        } else {
            Invoke-ToggleUnifiedMount -ForceUnmount
        }
        foreach ($rem in ($remotes | Where-Object { $pool -notcontains $_ })) {
            $already = Get-MountedLetterForRemote -TargetRemote $rem
            if ($null -eq $already) {
                $prefLtr = Get-AccountPreferredDrive -TargetRemote $rem -DefaultLetter ""
                $avail = @(Get-AvailableDriveLetters -TargetRemote $rem -Preferred $prefLtr -ReservedLetters $reservedInBatch)
                if ($avail.Count -gt 0) {
                    $pickLetter = $avail[0]
                    $reservedInBatch += $pickLetter
                    $disp = Get-AccountDisplayLabel -TargetRemote $rem
                    Write-StudioLog "Mounting account '$disp' to Windows drive $pickLetter..."
                    Invoke-UiPump
                    Invoke-ToggleMount -TargetRemote $rem -Letter $pickLetter -ForceMount -QuietExplorer
                } else {
                    Write-StudioLog "[WARN] No free Windows drive letters left to mount '$rem'."
                }
            }
        }
        Refresh-StudioHeader
    } catch { Write-StudioLog "[ERR] $($_.Exception.Message)" }
})

$BtnUnmountAll.Add_Click({
    try {
        Invoke-ToggleUnifiedMount -ForceUnmount
        foreach ($rem in @(Get-ConfiguredDriveRemotes)) {
            $already = Get-MountedLetterForRemote -TargetRemote $rem
            if ($null -ne $already) { Invoke-ToggleMount -TargetRemote $rem -ForceUnmount }
        }
        Refresh-StudioHeader
    } catch { Write-StudioLog "[ERR] $($_.Exception.Message)" }
})

$BtnToggleDriveRow.Add_Click({
    try {
        $sel = $GridMultiDrives.SelectedItem
        $targetRem = if ($null -ne $sel -and -not [string]::IsNullOrWhiteSpace($sel.Remote)) { $sel.Remote } else { $script:ActiveRemote }
        $assign = Get-AccountDriveAssignment -TargetRemote $targetRem
        $activeLtr = Get-MountedLetterForRemote -TargetRemote $targetRem
        if ($null -ne $activeLtr) {
            Invoke-ToggleMount -TargetRemote $targetRem -ForceUnmount
        } elseif ($assign -eq "Unified") {
            $uInfo = Get-UnifiedMountInfo
            $inUni = ($null -ne $uInfo -and ($uInfo.Remotes.Count -eq 0 -or ($uInfo.Remotes -contains $targetRem)))
            if ($inUni) { Invoke-ToggleUnifiedMount -ForceUnmount }
            else { Invoke-RefreshActiveUnifiedPool -ForceShow }
        } else {
            $pickLtr = if ($null -ne $sel -and -not [string]::IsNullOrWhiteSpace($sel.SelectedLetter) -and $sel.SelectedLetter -match '^[A-Z]:$') { $sel.SelectedLetter } else { Get-AccountPreferredDrive -TargetRemote $targetRem -DefaultLetter "" }
            $avail = @(Get-AvailableDriveLetters -TargetRemote $targetRem -Preferred $pickLtr)
            if ($avail.Count -gt 0) {
                $ltrUse = if ($avail -contains $pickLtr) { $pickLtr } else { $avail[0] }
                Set-AccountPref -Remote $targetRem -DriveAssignment "Separate" -PreferredDrive $ltrUse
                Invoke-ToggleMount -TargetRemote $targetRem -Letter $ltrUse -ForceMount
            }
        }
        Refresh-StudioHeader
    } catch { Write-StudioLog "[ERR] $($_.Exception.Message)" }
})

$BtnRenameAccount.Add_Click({
    try {
        $sel = $GridMultiDrives.SelectedItem
        $targetRem = if ($null -ne $sel -and -not [string]::IsNullOrWhiteSpace($sel.Remote)) { $sel.Remote } else { $script:ActiveRemote }
        $curName = Get-AccountDisplayLabel -TargetRemote $targetRem
        $pTxt = [System.Security.SecurityElement]::Escape((L "renameAccPrompt"))
        $okTxt = [System.Security.SecurityElement]::Escape((L "renameAccSave"))
        $canTxt = [System.Security.SecurityElement]::Escape((L "btnCancel"))
        $body = @"
            <Grid>
                <Grid.RowDefinitions><RowDefinition Height="Auto"/><RowDefinition Height="Auto"/><RowDefinition Height="Auto"/></Grid.RowDefinitions>
                <TextBlock Grid.Row="0" Text="$pTxt" TextWrapping="Wrap" FontWeight="SemiBold" Foreground="#CBD5E1" Margin="0,0,0,8"/>
                <TextBox x:Name="TxtRenameAcc" Grid.Row="1" FlowDirection="LeftToRight" Height="32" Margin="0,0,0,16"/>
                <StackPanel Grid.Row="2" Orientation="Horizontal" HorizontalAlignment="Right">
                    <Button x:Name="BtnOkRename" Content="$okTxt" Background="#0284C7" BorderBrush="#38BDF8" Foreground="#FFFFFF" Margin="0,0,8,0"/>
                    <Button x:Name="BtnCanRename" Content="$canTxt"/>
                </StackPanel>
            </Grid>
"@
        $rw = New-AlphaModalWindow -Title (L "renameAccTitle") -ReqWidth 460 -ReqHeight 225 -Resizable $false -BodyXaml $body
        $tb = $rw.FindName("TxtRenameAcc")
        $tb.Text = $curName
        $doRename = {
            $newLabel = $tb.Text.Trim()
            $rw.Close()
            Set-AccountPref -Remote $targetRem -CustomName $newLabel
            if ([string]::IsNullOrWhiteSpace($newLabel)) { Ensure-RemoteAutoNameCached -TargetRemote $targetRem }
            $uInfo = Get-UnifiedMountInfo
            if ($null -ne $uInfo -and ($uInfo.Remotes.Count -eq 0 -or ($uInfo.Remotes -contains $targetRem))) {
                Invoke-RefreshActiveUnifiedPool -QuietExplorer
            } else {
                $sepLtr = Get-MountedLetterForRemote -TargetRemote $targetRem
                if ($null -ne $sepLtr) {
                    Invoke-ToggleMount -TargetRemote $targetRem -ForceUnmount -SilentToast
                    Invoke-ToggleMount -TargetRemote $targetRem -Letter $sepLtr -ForceMount -QuietExplorer
                }
            }
            Refresh-StudioHeader
        }
        $rw.FindName("BtnCanRename").Add_Click({ $rw.Close() })
        $rw.FindName("BtnOkRename").Add_Click($doRename)
        $rw.Add_KeyDown({
            param($s, $ke)
            if ($ke.Key -eq [System.Windows.Input.Key]::Escape) { $rw.Close() }
            elseif ($ke.Key -eq [System.Windows.Input.Key]::Enter) { & $doRename }
        })
        $rw.Add_ContentRendered({ try { $null = $tb.Focus(); $tb.SelectAll() } catch {} })
        [void]$rw.ShowDialog()
    } catch { Write-StudioLog "[ERR] $($_.Exception.Message)" }
})

$GridMultiDrives.AddHandler([System.Windows.Controls.Primitives.Selector]::SelectionChangedEvent, [System.Windows.Controls.SelectionChangedEventHandler]{
    param($s, $e)
    if ($script:IsRefreshing) { return }
    if ($e.OriginalSource -isnot [System.Windows.Controls.ComboBox]) { return }
    if ($e.RemovedItems.Count -eq 0) { return }
    try {
        $cb = [System.Windows.Controls.ComboBox]$e.OriginalSource
        $rem = if ($cb.Tag) { $cb.Tag.ToString() } else { "" }
        if ([string]::IsNullOrWhiteSpace($rem)) { return }
        $row = $script:MultiDriveItems | Where-Object { $_.Remote -eq $rem } | Select-Object -First 1
        if ($null -eq $row) { return }
        $disp = Get-AccountDisplayLabel -TargetRemote $rem

        if ($cb.Uid -eq "DriveLetter") {
            $newLtrRaw = if ($null -ne $cb.SelectedItem) { $cb.SelectedItem.ToString() } else { "" }
            if ([string]::IsNullOrWhiteSpace($newLtrRaw) -or $newLtrRaw -eq $row.SelectedLetter) { return }
            $starCh = [string][char]0x2605
            if ($newLtrRaw.StartsWith($starCh)) {
                Set-AccountPref -Remote $rem -DriveAssignment "Unified"
                $activeLtr = Get-MountedLetterForRemote -TargetRemote $rem
                if ($null -ne $activeLtr) { Invoke-ToggleMount -TargetRemote $rem -ForceUnmount }
                if ($null -ne $activeLtr -or ($null -ne (Get-UnifiedMountInfo))) {
                    Invoke-RefreshActiveUnifiedPool -ForceShow -QuietExplorer
                }
                Refresh-StudioHeader
            } else {
                $newLtr = $newLtrRaw.ToUpperInvariant()
                $uInfo = Get-UnifiedMountInfo
                $wasInUni = ($null -ne $uInfo -and ($uInfo.Remotes.Count -eq 0 -or ($uInfo.Remotes -contains $rem)))
                Set-AccountPref -Remote $rem -DriveAssignment "Separate" -PreferredDrive $newLtr
                if ($rem -eq $script:ActiveRemote) { $cfg = Get-Settings; $cfg.PreferredDrive = $newLtr; Save-Settings -Obj $cfg }
                $activeLtr = Get-MountedLetterForRemote -TargetRemote $rem
                if ($null -ne $activeLtr -and $activeLtr -ne $newLtr) {
                    Write-StudioLog "Moving '$disp' Windows drive from $activeLtr to $newLtr..."
                    Invoke-UiPump
                    Invoke-ToggleMount -TargetRemote $rem -ForceUnmount
                    Invoke-ToggleMount -TargetRemote $rem -Letter $newLtr -ForceMount -QuietExplorer
                } elseif ($wasInUni) {
                    Write-StudioLog "Moving '$disp' out of Unified Drive to standalone drive $newLtr..."
                    Invoke-UiPump
                    Invoke-RefreshActiveUnifiedPool -QuietExplorer
                    Invoke-ToggleMount -TargetRemote $rem -Letter $newLtr -ForceMount -QuietExplorer
                }
                Refresh-StudioHeader
            }
        } elseif ($cb.Uid -eq "BackupTarget") {
            $selObj = $cb.SelectedItem
            if ($null -eq $selObj -or -not $selObj.PSObject.Properties["Value"]) { return }
            $newT = $selObj.Value.ToString()
            if ($newT -eq "Mixed" -or $newT -eq $row.SelectedTargetValue) { return }
            Set-AccountPref -Remote $rem -DefaultTargetMode $newT
            $fList = @(Get-SyncFolders -TargetRemote $rem)
            if ($fList.Count -gt 0) {
                foreach ($f in $fList) { $f.TargetMode = $newT }
                Save-SyncFolders -Folders $fList -TargetRemote $rem
            }
            Write-StudioLog -Msg "[OK] Updated backup destination for '$disp' to '$newT' ($($fList.Count) folder(s))." -TargetRemote $rem
            Refresh-StudioHeader
        } elseif ($cb.Uid -eq "MountScope") {
            $selObj = $cb.SelectedItem
            if ($null -eq $selObj -or -not $selObj.PSObject.Properties["Value"]) { return }
            $newSc = $selObj.Value.ToString()
            if ($newSc -eq $row.SelectedScopeValue) { return }
            Set-AccountPref -Remote $rem -MountScope $newSc
            $activeLtr = Get-MountedLetterForRemote -TargetRemote $rem
            if ($null -ne $activeLtr) {
                Write-StudioLog -Msg "Remounting '$disp' on $activeLtr with view scope '$newSc'..." -TargetRemote $rem
                Invoke-UiPump
                Invoke-ToggleMount -TargetRemote $rem -ForceUnmount
                Invoke-ToggleMount -TargetRemote $rem -Letter $activeLtr -ForceMount -QuietExplorer
            } else {
                $uInfo = Get-UnifiedMountInfo
                if ($null -ne $uInfo -and ($uInfo.Remotes.Count -eq 0 -or ($uInfo.Remotes -contains $rem))) {
                    Invoke-RefreshActiveUnifiedPool -QuietExplorer
                }
            }
            Refresh-StudioHeader
        }
    } catch {}
})

$GridMultiDrives.Add_MouseDoubleClick({
    param($s, $e)
    try {
        if (Test-EventFromInputControl -Source $e.OriginalSource) { return }
        $sel = $GridMultiDrives.SelectedItem
        if ($null -eq $sel) { return }
        if (-not [string]::IsNullOrWhiteSpace($sel.Letter) -and (Test-Path -LiteralPath "$($sel.Letter)\")) {
            if ($sel.IsUnifiedRow) {
                $safeFolder = (($sel.DisplayName -replace '["=\\/:*?<>|]', '').Trim())
                $subDir = if (-not [string]::IsNullOrWhiteSpace($safeFolder)) { Join-Path "$($sel.Letter)\" $safeFolder } else { "" }
                if (-not [string]::IsNullOrWhiteSpace($subDir) -and (Test-Path -LiteralPath $subDir)) { Start-Process "explorer.exe" -ArgumentList "`"$subDir`"" }
                else { Start-Process "explorer.exe" -ArgumentList "$($sel.Letter)\" }
            } else {
                Start-Process "explorer.exe" -ArgumentList "$($sel.Letter)\"
            }
        } elseif (-not [string]::IsNullOrWhiteSpace($sel.Remote)) {
            if ((Get-AccountDriveAssignment -TargetRemote $sel.Remote) -eq "Unified") {
                Invoke-RefreshActiveUnifiedPool -ForceShow
                Refresh-StudioHeader
            } else {
                $prefLtr = if ($sel.SelectedLetter -match '^[A-Z]:$') { $sel.SelectedLetter } else { Get-AccountPreferredDrive -TargetRemote $sel.Remote -DefaultLetter "" }
                $avail = @(Get-AvailableDriveLetters -TargetRemote $sel.Remote -Preferred $prefLtr)
                if ($avail.Count -gt 0) {
                    $disp = Get-AccountDisplayLabel -TargetRemote $sel.Remote
                    Write-StudioLog "Mounting account '$disp' to Windows drive $($avail[0])..."
                    Invoke-UiPump
                    Invoke-ToggleMount -TargetRemote $sel.Remote -Letter $avail[0] -ForceMount
                    Refresh-StudioHeader
                }
            }
        }
    } catch {}
})

# ==============================================================================
# ALL 6 LOCALIZED NATIVE-DARK MODALS
# ==============================================================================
$BtnAddAccount.Add_Click({
    try {
        $pTxt = [System.Security.SecurityElement]::Escape((L "addAccPrompt"))
        $okTxt = [System.Security.SecurityElement]::Escape((L "addAccContinue"))
        $canTxt = [System.Security.SecurityElement]::Escape((L "btnCancel"))
        $body = @"
            <Grid>
                <Grid.RowDefinitions><RowDefinition Height="Auto"/><RowDefinition Height="Auto"/><RowDefinition Height="Auto"/></Grid.RowDefinitions>
                <TextBlock Grid.Row="0" Text="$pTxt" TextWrapping="Wrap" FontWeight="SemiBold" Foreground="#CBD5E1" Margin="0,0,0,8"/>
                <TextBox x:Name="TxtNewProf" Grid.Row="1" FlowDirection="LeftToRight" Text="" Height="32" Margin="0,0,0,16"/>
                <StackPanel Grid.Row="2" Orientation="Horizontal" HorizontalAlignment="Right">
                    <Button x:Name="BtnOkProf" Content="$okTxt" Background="#0284C7" BorderBrush="#38BDF8" Foreground="#FFFFFF" Margin="0,0,8,0"/>
                    <Button x:Name="BtnCanProf" Content="$canTxt"/>
                </StackPanel>
            </Grid>
"@
        $aw = New-AlphaModalWindow -Title (L "addAccTitle") -ReqWidth 460 -ReqHeight 225 -Resizable $false -BodyXaml $body
        $tb = $aw.FindName("TxtNewProf")
        $doAddAcc = {
            $typedName = $tb.Text.Trim()
            $prevRem   = $script:ActiveRemote
            $newRemId  = Get-NextUniqueRemoteId -UserInput $typedName
            $aw.Close()
            $authOk = Invoke-GDriveAuth -TargetRemote $newRemId
            if ($authOk) {
                $curLayout = (Get-Settings).DriveLayout
                Set-AccountPref -Remote $newRemId -UseJsonRules $false -JsonRulesPath (Get-DefaultPresetPath) -DriveAssignment $(if ($curLayout -eq "Unified") { "Unified" } else { "Separate" })
                if (-not [string]::IsNullOrWhiteSpace($typedName)) {
                    Set-AccountPref -Remote $newRemId -CustomName $typedName
                } else {
                    Ensure-RemoteAutoNameCached -TargetRemote $newRemId
                }
                $script:ActiveRemote = $newRemId
                $cfg = Get-Settings; $cfg.ActiveRemote = $newRemId; Save-Settings -Obj $cfg
                if ($curLayout -eq "Unified" -and $null -ne (Get-UnifiedMountInfo)) {
                    Invoke-RefreshActiveUnifiedPool -ForceShow -QuietExplorer
                }
                Refresh-StudioHeader
                Sync-RealTimeWatchers
            } else {
                $script:ActiveRemote = $prevRem
                Refresh-StudioHeader
            }
        }
        $aw.FindName("BtnCanProf").Add_Click({ $aw.Close() })
        $aw.FindName("BtnOkProf").Add_Click($doAddAcc)
        $aw.Add_KeyDown({
            param($s, $ke)
            if ($ke.Key -eq [System.Windows.Input.Key]::Escape) { $aw.Close() }
            elseif ($ke.Key -eq [System.Windows.Input.Key]::Enter) { & $doAddAcc }
        })
        $aw.Add_ContentRendered({ try { $null = $tb.Focus() } catch {} })
        [void]$aw.ShowDialog()
    } catch { Write-StudioLog "[ERR] $($_.Exception.Message)" }
})

$BtnCustomClientId.Add_Click({
    try {
        if (-not (Test-GDriveConfigured -TargetRemote $script:ActiveRemote)) {
            Show-AlphaMessageBox -Message (L "msgSignInRequiredBody") -Title (L "msgSignInRequiredTitle") -Buttons "OK" -Icon "Information" | Out-Null
            return
        }
        $descT = [System.Security.SecurityElement]::Escape((L "apiKeyModalDesc"))
        $idT   = [System.Security.SecurityElement]::Escape((L "apiKeyClientIdLabel"))
        $secT  = [System.Security.SecurityElement]::Escape((L "apiKeySecretLabel"))
        $okT   = [System.Security.SecurityElement]::Escape((L "apiKeyApplyBtn"))
        $canT  = [System.Security.SecurityElement]::Escape((L "btnCancel"))
        $body = @"
            <Grid>
                <Grid.RowDefinitions><RowDefinition Height="Auto"/><RowDefinition Height="Auto"/><RowDefinition Height="Auto"/><RowDefinition Height="Auto"/><RowDefinition Height="Auto"/><RowDefinition Height="Auto"/></Grid.RowDefinitions>
                <TextBlock Grid.Row="0" Text="$descT" TextWrapping="Wrap" Foreground="#94A3B8" FontSize="12" Margin="0,0,0,12"/>
                <TextBlock Grid.Row="1" Text="$idT" FontWeight="SemiBold" Foreground="#CBD5E1" Margin="0,0,0,4"/>
                <TextBox x:Name="TxtCid" Grid.Row="2" FlowDirection="LeftToRight" Height="32" Margin="0,0,0,10"/>
                <TextBlock Grid.Row="3" Text="$secT" FontWeight="SemiBold" Foreground="#CBD5E1" Margin="0,0,0,4"/>
                <PasswordBox x:Name="TxtCsec" Grid.Row="4" FlowDirection="LeftToRight" Height="32" Background="#0D1525" Foreground="#E2E8F0" BorderBrush="#243550" BorderThickness="1" Padding="7,4" VerticalContentAlignment="Center" CaretBrush="#38BDF8" Margin="0,0,0,16"/>
                <StackPanel Grid.Row="5" Orientation="Horizontal" HorizontalAlignment="Right">
                    <Button x:Name="BtnApplyCid" Content="$okT" Background="#10B981" BorderBrush="#34D399" Foreground="#FFFFFF" Margin="0,0,8,0"/>
                    <Button x:Name="BtnCloseCid" Content="$canT"/>
                </StackPanel>
            </Grid>
"@
        $cw = New-AlphaModalWindow -Title (L "apiKeyModalTitle") -ReqWidth 550 -ReqHeight 365 -Resizable $true -BodyXaml $body
        $tId = $cw.FindName("TxtCid"); $tSec = $cw.FindName("TxtCsec")
        $cw.FindName("BtnCloseCid").Add_Click({ $cw.Close() })
        $cw.FindName("BtnApplyCid").Add_Click({
            $cid = $tId.Text.Trim(); $csc = $tSec.Password.Trim()
            if ([string]::IsNullOrWhiteSpace($cid) -or [string]::IsNullOrWhiteSpace($csc) -or $cid -match '[\s"''\r\n]' -or $csc -match '[\s"''\r\n]') {
                Show-AlphaMessageBox -Message (L "msgMissingFieldsBody") -Title (L "msgMissingFieldsTitle") -Buttons "OK" -Icon "Warning" | Out-Null; return
            }
            $cw.Close()
            $null = Invoke-RcloneCapture -Arguments "config update $(Format-WinArg $script:ActiveRemote) client_id $(Format-WinArg $cid) client_secret $(Format-WinArg $csc) --non-interactive" -TimeoutMs 15000
            Invoke-GDriveAuth -TargetRemote $script:ActiveRemote; Refresh-StudioHeader
        })
        [void]$cw.ShowDialog()
    } catch { Write-StudioLog "[ERR] $($_.Exception.Message)" }
})

$BtnMount.Add_Click({
    try {
        if (-not (Test-GDriveConfigured -TargetRemote $script:ActiveRemote)) {
            $okAuth = Invoke-GDriveAuth -TargetRemote $script:ActiveRemote
            if (-not $okAuth) { Refresh-StudioHeader; return }
        }
        $letter = Get-SelectedDriveLetter
        $activeSep = Get-MountedLetterForRemote -TargetRemote $script:ActiveRemote
        $assign = Get-AccountDriveAssignment -TargetRemote $script:ActiveRemote
        if ($null -ne $activeSep) {
            Invoke-ToggleMount -TargetRemote $script:ActiveRemote -ForceUnmount
        } elseif ($letter -eq "__UNIFIED__" -or $assign -eq "Unified") {
            Set-AccountPref -Remote $script:ActiveRemote -DriveAssignment "Unified"
            $uInfo = Get-UnifiedMountInfo
            $pool  = @(Get-UnifiedPoolRemotes)
            $inUni = ($null -ne $uInfo -and ($uInfo.Remotes.Count -eq 0 -or ($uInfo.Remotes -contains $script:ActiveRemote)))
            $allPoolInUni = ($inUni -and ($uInfo.Remotes.Count -eq 0 -or $uInfo.Remotes.Count -ge $pool.Count))
            if ($allPoolInUni) {
                Invoke-ToggleUnifiedMount -ForceUnmount
            } else {
                Invoke-RefreshActiveUnifiedPool -ForceShow
            }
        } else {
            Set-AccountPref -Remote $script:ActiveRemote -DriveAssignment "Separate" -PreferredDrive $letter
            Invoke-ToggleMount -TargetRemote $script:ActiveRemote -Letter $letter -ForceMount
        }
        Refresh-StudioHeader
    } catch { Write-StudioLog "[ERR] $($_.Exception.Message)" }
})

$BtnRefreshQuota.Add_Click({ try { Invoke-ScanFolderSizes } catch { Write-StudioLog "[ERR] $($_.Exception.Message)" } })

$BtnEmptyDriveTrash.Add_Click({
    try {
        if (-not (Test-GDriveConfigured -TargetRemote $script:ActiveRemote)) { return }
        $dispTrash = Get-AccountDisplayLabel -TargetRemote $script:ActiveRemote
        $warnT = [System.Security.SecurityElement]::Escape((LF "emptyTrashModalWarning" @($dispTrash)))
        $prmT  = [System.Security.SecurityElement]::Escape((L "emptyTrashModalPrompt"))
        $okT   = [System.Security.SecurityElement]::Escape((L "emptyTrashConfirmBtn"))
        $canT  = [System.Security.SecurityElement]::Escape((L "btnCancel"))
        $body = @"
            <Grid>
                <Grid.RowDefinitions><RowDefinition Height="Auto"/><RowDefinition Height="Auto"/><RowDefinition Height="Auto"/><RowDefinition Height="Auto"/></Grid.RowDefinitions>
                <TextBlock Grid.Row="0" Text="$warnT" TextWrapping="Wrap" Foreground="#FCA5A5" FontWeight="Bold" FontSize="12.5" Margin="0,0,0,10"/>
                <TextBlock Grid.Row="1" Text="$prmT" TextWrapping="Wrap" Foreground="#CBD5E1" Margin="0,0,0,6"/>
                <TextBox x:Name="TxtConfirmEmpty" Grid.Row="2" FlowDirection="LeftToRight" Height="32" BorderBrush="#DC2626" Foreground="#FBBF24" Margin="0,0,0,16"/>
                <StackPanel Grid.Row="3" Orientation="Horizontal" HorizontalAlignment="Right">
                    <Button x:Name="BtnDoEmpty" Content="$okT" Background="#DC2626" BorderBrush="#F87171" Foreground="#FFFFFF" Margin="0,0,8,0" IsEnabled="False"/>
                    <Button x:Name="BtnCancelEmpty" Content="$canT"/>
                </StackPanel>
            </Grid>
"@
        $tw = New-AlphaModalWindow -Title (L "emptyTrashModalTitle") -ReqWidth 480 -ReqHeight 265 -Resizable $false -BodyXaml $body
        $tbConf = $tw.FindName("TxtConfirmEmpty"); $btnDo = $tw.FindName("BtnDoEmpty")
        $tbConf.Add_TextChanged({ $btnDo.IsEnabled = ($tbConf.Text.Trim() -ceq "EMPTY") })
        $tw.FindName("BtnCancelEmpty").Add_Click({ $tw.Close() })
        $btnDo.Add_Click({
            $tw.Close(); Invoke-UiPump
            $r = Invoke-RcloneCapture -Arguments "cleanup `"$($script:ActiveRemote):`" --quiet" -TimeoutMs 60000
            if ($r.ExitCode -eq 0) {
                Update-DriveQuotaDisplay
                Show-TrayToast -Title (L "toastTrashEmptyTitle") -Body (LF "toastTrashEmptyBody" @($dispTrash))
            }
        })
        [void]$tw.ShowDialog()
    } catch { Write-StudioLog "[ERR] $($_.Exception.Message)" }
})

$BtnCleanArchive.Add_Click({
    try {
        if (-not (Test-GDriveConfigured -TargetRemote $script:ActiveRemote)) { return }
        Invoke-UiPump
        $szRes = Invoke-RcloneCapture -Arguments "size `"$($script:ActiveRemote):_CloudSync_Trash_Archive`" --min-age 30d --json --quiet" -TimeoutMs 30000
        if ($szRes.ExitCode -ne 0 -or [string]::IsNullOrWhiteSpace($szRes.StdOut)) {
            Show-AlphaMessageBox -Message (L "msgArchiveNoneBody") -Title (L "msgArchiveCleanTitle") -Buttons "OK" -Icon "Information" | Out-Null; return
        }
        $szObj = $szRes.StdOut | ConvertFrom-Json
        if ([int]$szObj.count -eq 0) {
            Show-AlphaMessageBox -Message (L "msgArchiveZeroBody") -Title (L "msgArchiveCleanTitle") -Buttons "OK" -Icon "Information" | Out-Null; return
        }
        $szFmt = Format-ByteSize ([double]$szObj.bytes)
        $ans = Show-AlphaMessageBox -Message (LF "msgArchiveConfirmBody" @($szObj.count, $szFmt)) -Title (L "msgArchiveConfirmTitle") -Buttons "YesNo" -Icon "Warning"
        if ($ans -eq [System.Windows.MessageBoxResult]::Yes) {
            Invoke-UiPump
            $delRes = Invoke-RcloneCapture -Arguments "delete `"$($script:ActiveRemote):_CloudSync_Trash_Archive`" --min-age 30d --quiet" -TimeoutMs 90000
            $rmdRes = Invoke-RcloneCapture -Arguments "rmdirs `"$($script:ActiveRemote):_CloudSync_Trash_Archive`" --leave-root --quiet" -TimeoutMs 30000
            if ($delRes.ExitCode -eq 0 -and $rmdRes.ExitCode -eq 0) { Update-DriveQuotaDisplay }
            else {
                $errCode = if ($delRes.ExitCode -ne 0) { $delRes.ExitCode } else { $rmdRes.ExitCode }
                Show-AlphaMessageBox -Message (LF "msgArchiveErrBody" @($errCode)) -Title (L "msgArchiveErrTitle") -Buttons "OK" -Icon "Error" | Out-Null
            }
        }
    } catch { Write-StudioLog "[ERR] $($_.Exception.Message)" }
})

$BtnOpenDriveWeb.Add_Click({ Start-Process "https://drive.google.com/drive/my-drive" })

$GridFolders.Add_Drop({
    param($sender, $e)
    try {
        if ($e.Data.GetDataPresent([System.Windows.DataFormats]::FileDrop)) {
            foreach ($p in $e.Data.GetData([System.Windows.DataFormats]::FileDrop)) {
                if (Test-Path -LiteralPath $p -PathType Container) { Add-LocalFolderToList -SelPath $p }
            }
        }
    } catch {}
})

$GridFolders.Add_SelectionChanged({
    $hasSel = ($null -ne $GridFolders.SelectedItem)
    $BtnRemoveFolder.IsEnabled = $hasSel; $BtnToggleTarget.IsEnabled = $hasSel; $BtnSyncSelected.IsEnabled = ($hasSel -and -not $script:IsSyncRunning)
})

$GridFolders.AddHandler([System.Windows.Controls.Primitives.ButtonBase]::ClickEvent, [System.Windows.RoutedEventHandler]{
    param($s, $e)
    if ($script:IsRefreshing) { return }
    if ($e.OriginalSource -is [System.Windows.Controls.CheckBox]) {
        try {
            $window.Dispatcher.BeginInvoke([Action]{
                try { Persist-GridCheckboxChanges; Sync-RealTimeWatchers } catch {}
            }, [System.Windows.Threading.DispatcherPriority]::Background) | Out-Null
        } catch {}
    }
})

$GridFolders.AddHandler([System.Windows.Controls.Primitives.Selector]::SelectionChangedEvent, [System.Windows.Controls.SelectionChangedEventHandler]{
    param($s, $e)
    if ($script:IsRefreshing) { return }
    if ($e.OriginalSource -isnot [System.Windows.Controls.ComboBox]) { return }
    if ($e.RemovedItems.Count -eq 0) { return }
    try {
        $cb = [System.Windows.Controls.ComboBox]$e.OriginalSource
        if ($cb.Uid -ne "FolderTarget") { return }
        $locPath = if ($cb.Tag) { $cb.Tag.ToString() } else { "" }
        $selObj  = $cb.SelectedItem
        if ([string]::IsNullOrWhiteSpace($locPath) -or $null -eq $selObj -or -not $selObj.PSObject.Properties["Value"]) { return }
        $newMode = $selObj.Value.ToString()
        Persist-GridCheckboxChanges
        $folders = @(Get-SyncFolders -TargetRemote $script:ActiveRemote)
        $changed = $false
        foreach ($f in $folders) {
            if ($f.LocalPath -ieq $locPath -and $f.TargetMode -ne $newMode) { $f.TargetMode = $newMode; $changed = $true }
        }
        if ($changed) {
            Save-SyncFolders -Folders $folders -TargetRemote $script:ActiveRemote
            Refresh-StudioHeader
        }
    } catch {}
})

$GridFolders.Add_MouseDoubleClick({
    param($s, $e)
    try {
        if (Test-EventFromInputControl -Source $e.OriginalSource) { return }
        $sel = $GridFolders.SelectedItem
        if ($null -ne $sel -and (Test-Path -LiteralPath $sel.LocalPath)) { Start-Process "explorer.exe" -ArgumentList "`"$($sel.LocalPath)`"" }
    } catch {}
})

$CtxSyncFolder.Add_Click({ if ($GridFolders.SelectedItem) { if ($script:IsGloballyPaused) { Set-GlobalSyncPaused -Paused $false -Silent }; Start-StudioBatch -Mode "Sync" -OnlyFolderPath $GridFolders.SelectedItem.LocalPath } })
$CtxDryRunFolder.Add_Click({ if ($GridFolders.SelectedItem) { Start-StudioBatch -Mode "DryRun" -OnlyFolderPath $GridFolders.SelectedItem.LocalPath } })
$CtxRestoreFolder.Add_Click({ if ($GridFolders.SelectedItem) { Invoke-SafeRestoreDialog -OnlyFolderPath $GridFolders.SelectedItem.LocalPath } })
$CtxOpenLocal.Add_Click({ if ($GridFolders.SelectedItem -and (Test-Path -LiteralPath $GridFolders.SelectedItem.LocalPath)) { Start-Process "explorer.exe" -ArgumentList "`"$($GridFolders.SelectedItem.LocalPath)`"" } })
$CtxSwitchTarget.Add_Click({ $BtnToggleTarget.RaiseEvent((New-Object System.Windows.RoutedEventArgs([System.Windows.Controls.Primitives.ButtonBase]::ClickEvent))) })
$CtxRemoveFolder.Add_Click({ $BtnRemoveFolder.RaiseEvent((New-Object System.Windows.RoutedEventArgs([System.Windows.Controls.Primitives.ButtonBase]::ClickEvent))) })

$BtnSyncSelected.Add_Click({ try { if ($GridFolders.SelectedItem) { if ($script:IsGloballyPaused) { Set-GlobalSyncPaused -Paused $false -Silent }; Start-StudioBatch -Mode "Sync" -OnlyFolderPath $GridFolders.SelectedItem.LocalPath } } catch {} })

$BtnToggleTarget.Add_Click({
    try {
        $sel = $GridFolders.SelectedItem; if ($null -eq $sel) { return }
        Persist-GridCheckboxChanges
        $folders = @(Get-SyncFolders -TargetRemote $script:ActiveRemote)
        foreach ($f in $folders) {
            if ($f.LocalPath -ieq $sel.LocalPath) { $f.TargetMode = if ($f.TargetMode -eq "My Computer") { "My Drive" } else { "My Computer" } }
        }
        Save-SyncFolders -Folders $folders -TargetRemote $script:ActiveRemote; Refresh-StudioHeader
    } catch {}
})

$BtnAddFolder.Add_Click({
    try {
        $dlg = New-Object System.Windows.Forms.FolderBrowserDialog
        $dlg.Description = L "browseFolderDesc"
        if ($dlg.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) { Add-LocalFolderToList -SelPath $dlg.SelectedPath }
    } catch {}
})

$BtnRemoveFolder.Add_Click({
    try {
        $sel = $GridFolders.SelectedItem; if ($null -eq $sel) { return }
        Persist-GridCheckboxChanges
        $folders = @(Get-SyncFolders -TargetRemote $script:ActiveRemote | Where-Object { $_.LocalPath -ine $sel.LocalPath })
        Save-SyncFolders -Folders $folders -TargetRemote $script:ActiveRemote
        $stillUsedElsewhere = $false
        foreach ($otherRem in @(Get-ConfiguredDriveRemotes | Where-Object { $_ -ne $script:ActiveRemote })) {
            if (@(Get-SyncFolders -TargetRemote $otherRem | Where-Object { $_.LocalPath -ieq $sel.LocalPath }).Count -gt 0) {
                $stillUsedElsewhere = $true; break
            }
        }
        if (-not $stillUsedElsewhere) { $null = Clear-SyncedFolderBadge -FolderPath $sel.LocalPath }
        Update-FoldersGrid
        Sync-RealTimeWatchers
    } catch {}
})

$ChkJsonRules.Add_Click({
    $curRules = Get-AccountRulesConfig -TargetRemote $script:ActiveRemote
    Set-AccountPref -Remote $script:ActiveRemote -UseJsonRules ([bool]$ChkJsonRules.IsChecked) -JsonRulesPath $curRules.JsonRulesPath
    Refresh-JsonRulesBanner
})

$CmbJsonPreset.Add_SelectionChanged({
    if ($script:IsRefreshing) { return }
    try {
        $tag = if ($CmbJsonPreset.SelectedItem -and $CmbJsonPreset.SelectedItem.Tag) { $CmbJsonPreset.SelectedItem.Tag.ToString() } else { "" }
        $targetFile = switch ($tag) { "dev" { Join-Path $PresetsDir "developer-default.json" } "creative" { Join-Path $PresetsDir "creative-media.json" } "general" { Join-Path $PresetsDir "general-backup.json" } default { $null } }
        if ($targetFile -and (Test-Path -LiteralPath $targetFile)) {
            Set-AccountPref -Remote $script:ActiveRemote -UseJsonRules $true -JsonRulesPath $targetFile
            $ChkJsonRules.IsChecked = $true; Refresh-JsonRulesBanner
        }
    } catch {}
})

$BtnLoadJsonRules.Add_Click({
    try {
        $ofd = New-Object System.Windows.Forms.OpenFileDialog
        $ofd.Title = L "openRulesTitle"; $ofd.Filter = L "openRulesFilter"; $ofd.InitialDirectory = $PresetsDir
        if ($ofd.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
            Set-AccountPref -Remote $script:ActiveRemote -UseJsonRules $true -JsonRulesPath $ofd.FileName
            $ChkJsonRules.IsChecked = $true; $script:IsRefreshing = $true; $CmbJsonPreset.SelectedIndex = 3; $script:IsRefreshing = $false
            Refresh-JsonRulesBanner
        }
    } catch {}
})

$BtnEditJsonRules.Add_Click({
    try {
        $rCfg = Get-AccountRulesConfig -TargetRemote $script:ActiveRemote
        $rulesPath = $rCfg.JsonRulesPath
        if (-not (Test-Path -LiteralPath $rulesPath)) { $rulesPath = Get-DefaultPresetPath }
        $hdrT = [System.Security.SecurityElement]::Escape((L "rulesEditorHeader"))
        $savT = [System.Security.SecurityElement]::Escape((L "rulesEditorSave"))
        $canT = [System.Security.SecurityElement]::Escape((L "btnCancel"))
        $body = @"
            <Grid>
                <Grid.RowDefinitions><RowDefinition Height="Auto"/><RowDefinition Height="*"/><RowDefinition Height="Auto"/></Grid.RowDefinitions>
                <TextBlock Grid.Row="0" Text="$hdrT" TextWrapping="Wrap" FontSize="12" FontWeight="Bold" Foreground="#38BDF8" Margin="0,0,0,10"/>
                <TextBox x:Name="TxtJsonEditor" Grid.Row="1" FlowDirection="LeftToRight" TextAlignment="Left" VerticalContentAlignment="Top" MinHeight="340" Background="#070C15" Foreground="#4ADE80"
                         FontFamily="Consolas" FontSize="12" AcceptsReturn="True" TextWrapping="NoWrap" VerticalScrollBarVisibility="Auto" HorizontalScrollBarVisibility="Auto" Padding="10"/>
                <StackPanel Grid.Row="2" Orientation="Horizontal" HorizontalAlignment="Right" Margin="0,12,0,0">
                    <Button x:Name="BtnSaveJson" Content="$savT" Background="#10B981" BorderBrush="#34D399" Foreground="#FFFFFF" Margin="0,0,10,0"/>
                    <Button x:Name="BtnCancelJson" Content="$canT"/>
                </StackPanel>
            </Grid>
"@
        $edWin = New-AlphaModalWindow -Title (LF "rulesEditorTitle" @((Split-Path -Leaf $rulesPath))) -ReqWidth 700 -ReqHeight 540 -Resizable $true -BodyXaml $body
        $txtEd = $edWin.FindName("TxtJsonEditor")
        if (Test-Path -LiteralPath $rulesPath) { $txtEd.Text = [System.IO.File]::ReadAllText($rulesPath, [System.Text.Encoding]::UTF8) }
        $edWin.FindName("BtnSaveJson").Add_Click({
            try {
                $null = $txtEd.Text | ConvertFrom-Json
                $savePath = $rulesPath
                $isBundled = (-not [string]::IsNullOrWhiteSpace($PresetsDir) -and $rulesPath.StartsWith($PresetsDir, [System.StringComparison]::OrdinalIgnoreCase))
                if ($isBundled) {
                    $savePath = Join-Path $AppDataDir "rules-$(Get-SanitizedName $script:ActiveRemote).json"
                }
                [System.IO.File]::WriteAllText($savePath, $txtEd.Text, (New-Object System.Text.UTF8Encoding($false)))
                if ($isBundled) {
                    Set-AccountPref -Remote $script:ActiveRemote -UseJsonRules $true -JsonRulesPath $savePath
                    $ChkJsonRules.IsChecked = $true
                    $script:IsRefreshing = $true; $CmbJsonPreset.SelectedIndex = 3; $script:IsRefreshing = $false
                }
                Refresh-JsonRulesBanner; $edWin.Close()
            } catch { Show-AlphaMessageBox -Message (LF "msgRulesSyntaxErrBody" @($_.Exception.Message)) -Title (L "msgRulesSyntaxErrTitle") -Buttons "OK" -Icon "Error" | Out-Null }
        })
        $edWin.FindName("BtnCancelJson").Add_Click({ $edWin.Close() })
        [void]$edWin.ShowDialog()
    } catch {}
})

$BtnOpenScheduler.Add_Click({
    try {
        $e = { param($k) [System.Security.SecurityElement]::Escape((L $k)) }
        $body = @"
            <Grid>
                <Grid.RowDefinitions>
                    <RowDefinition Height="Auto"/><RowDefinition Height="Auto"/><RowDefinition Height="Auto"/>
                    <RowDefinition Height="Auto"/><RowDefinition Height="Auto"/><RowDefinition Height="Auto"/>
                </Grid.RowDefinitions>
                <TextBlock Grid.Row="0" Text="$(& $e 'schedModalHeader')" TextWrapping="Wrap" FontSize="13.5" FontWeight="Bold" Foreground="#38BDF8" Margin="0,0,0,12"/>
                <StackPanel Grid.Row="1" Orientation="Horizontal" Margin="0,0,0,10">
                    <TextBlock Text="$(& $e 'schedTypeLabel')" Width="125" VerticalAlignment="Center" Foreground="#CBD5E1" FontWeight="SemiBold"/>
                    <ComboBox x:Name="CmbModalMode" Width="280" SelectedIndex="0">
                        <ComboBoxItem Content="$(& $e 'schedModeDaily')"/>
                        <ComboBoxItem Content="$(& $e 'schedModeOnce')"/>
                        <ComboBoxItem Content="$(& $e 'schedModeWeekly')"/>
                        <ComboBoxItem Content="$(& $e 'schedModeHourly')"/>
                    </ComboBox>
                </StackPanel>
                <StackPanel x:Name="PnlDate" Grid.Row="2" Orientation="Horizontal" Margin="0,0,0,10" Visibility="Collapsed">
                    <TextBlock Text="$(& $e 'schedDateLabel')" Width="125" VerticalAlignment="Center" Foreground="#CBD5E1" FontWeight="SemiBold"/>
                    <DatePicker x:Name="DpModalDate" FlowDirection="LeftToRight" Width="180" Height="30"/>
                </StackPanel>
                <DockPanel x:Name="PnlDays" Grid.Row="2" Margin="0,0,0,10" Visibility="Collapsed">
                    <TextBlock DockPanel.Dock="Left" Text="$(& $e 'schedDaysLabel')" Width="125" VerticalAlignment="Center" Foreground="#CBD5E1" FontWeight="SemiBold"/>
                    <WrapPanel Orientation="Horizontal" VerticalAlignment="Center">
                        <CheckBox x:Name="ChkMon" Content="$(& $e 'dayMon')" Margin="0,2,8,2" IsChecked="True"/>
                        <CheckBox x:Name="ChkTue" Content="$(& $e 'dayTue')" Margin="0,2,8,2"/>
                        <CheckBox x:Name="ChkWed" Content="$(& $e 'dayWed')" Margin="0,2,8,2"/>
                        <CheckBox x:Name="ChkThu" Content="$(& $e 'dayThu')" Margin="0,2,8,2" IsChecked="True"/>
                        <CheckBox x:Name="ChkFri" Content="$(& $e 'dayFri')" Margin="0,2,8,2"/>
                        <CheckBox x:Name="ChkSat" Content="$(& $e 'daySat')" Margin="0,2,8,2"/>
                        <CheckBox x:Name="ChkSun" Content="$(& $e 'daySun')" Margin="0,2,0,2"/>
                    </WrapPanel>
                </DockPanel>
                <StackPanel x:Name="PnlHours" Grid.Row="2" Orientation="Horizontal" Margin="0,0,0,10" Visibility="Collapsed">
                    <TextBlock Text="$(& $e 'schedRepeatLabel')" Width="125" VerticalAlignment="Center" Foreground="#CBD5E1" FontWeight="SemiBold"/>
                    <ComboBox x:Name="CmbInterval" Width="160" SelectedIndex="1">
                        <ComboBoxItem Content="$(& $e 'interval1h')"/>
                        <ComboBoxItem Content="$(& $e 'interval2h')"/>
                        <ComboBoxItem Content="$(& $e 'interval4h')"/>
                        <ComboBoxItem Content="$(& $e 'interval6h')"/>
                        <ComboBoxItem Content="$(& $e 'interval12h')"/>
                    </ComboBox>
                </StackPanel>
                <StackPanel Grid.Row="3" Orientation="Horizontal" Margin="0,0,0,12">
                    <TextBlock Text="$(& $e 'schedTimeLabel')" Width="125" VerticalAlignment="Center" Foreground="#CBD5E1" FontWeight="SemiBold" TextWrapping="Wrap"/>
                    <StackPanel Orientation="Horizontal" FlowDirection="LeftToRight" VerticalAlignment="Center">
                        <ComboBox x:Name="CmbHour12" Width="64"/>
                        <TextBlock Text=" : " FontSize="15" FontWeight="Bold" Foreground="#38BDF8" VerticalAlignment="Center"/>
                        <ComboBox x:Name="CmbMinute" Width="64"/>
                        <ComboBox x:Name="CmbAmPm" Width="74" Margin="8,0,0,0">
                            <ComboBoxItem Content="AM" Tag="AM"/>
                            <ComboBoxItem Content="PM" Tag="PM"/>
                        </ComboBox>
                    </StackPanel>
                </StackPanel>
                <TextBlock Grid.Row="4" Text="$(& $e 'schedBgNote')" TextWrapping="Wrap" Foreground="#94A3B8" FontSize="11.5" Margin="0,0,0,16"/>
                <StackPanel Grid.Row="5" Orientation="Horizontal" HorizontalAlignment="Right">
                    <Button x:Name="BtnApplySched" Content="$(& $e 'schedBtnSave')" Background="#10B981" BorderBrush="#34D399" Foreground="#FFFFFF" Margin="0,0,8,0"/>
                    <Button x:Name="BtnCancelSched" Content="$(& $e 'btnCancel')"/>
                </StackPanel>
            </Grid>
"@
        $sw = New-AlphaModalWindow -Title (L "schedModalTitle") -ReqWidth 540 -ReqHeight 410 -Resizable $false -BodyXaml $body
        $cmbM = $sw.FindName("CmbModalMode"); $pDate = $sw.FindName("PnlDate"); $pDays = $sw.FindName("PnlDays"); $pHrs = $sw.FindName("PnlHours")
        $dp = $sw.FindName("DpModalDate"); $dp.SelectedDate = (Get-Date); $dp.DisplayDateStart = (Get-Date)
        $cmbH = $sw.FindName("CmbHour12"); $cmbMn = $sw.FindName("CmbMinute"); $cmbAP = $sw.FindName("CmbAmPm"); $cmbInt = $sw.FindName("CmbInterval")
        foreach ($hr in 1..12) { [void]$cmbH.Items.Add(("{0:D2}" -f $hr)) }
        foreach ($mn in 0..59) { [void]$cmbMn.Items.Add(("{0:D2}" -f $mn)) }
        $cmbH.SelectedIndex = 10; $cmbMn.SelectedIndex = 0; $cmbAP.SelectedIndex = 1

        $cmbM.Add_SelectionChanged({
            $pDate.Visibility = if ($cmbM.SelectedIndex -eq 1) { "Visible" } else { "Collapsed" }
            $pDays.Visibility = if ($cmbM.SelectedIndex -eq 2) { "Visible" } else { "Collapsed" }
            $pHrs.Visibility  = if ($cmbM.SelectedIndex -eq 3) { "Visible" } else { "Collapsed" }
        })
        $sw.FindName("BtnCancelSched").Add_Click({ $sw.Close() })
        $sw.FindName("BtnApplySched").Add_Click({
            $h12 = [int]$cmbH.SelectedItem; $min = [int]$cmbMn.SelectedItem; $ampm = $cmbAP.SelectedItem.Tag.ToString()
            $time24 = Convert-Time12hTo24h -Hour12 $h12 -Minute $min -Period $ampm
            if ([string]::IsNullOrWhiteSpace($time24)) { Show-AlphaMessageBox -Message (L "schedInvalidTimeMsg") -Title (L "schedInvalidTimeTitle") -Buttons "OK" -Icon "Warning" | Out-Null; return }
            $idx = $cmbM.SelectedIndex
            $tp = $time24 -split ':'
            $baseDate = if ($idx -eq 1 -and $null -ne $dp.SelectedDate) { $dp.SelectedDate.Date } else { (Get-Date).Date }
            $startDt = $baseDate.AddHours([int]$tp[0]).AddMinutes([int]$tp[1])
            $daysBitmask = 0
            if ($idx -eq 2) {
                if ($sw.FindName("ChkSun").IsChecked) { $daysBitmask = $daysBitmask -bor 1 }
                if ($sw.FindName("ChkMon").IsChecked) { $daysBitmask = $daysBitmask -bor 2 }
                if ($sw.FindName("ChkTue").IsChecked) { $daysBitmask = $daysBitmask -bor 4 }
                if ($sw.FindName("ChkWed").IsChecked) { $daysBitmask = $daysBitmask -bor 8 }
                if ($sw.FindName("ChkThu").IsChecked) { $daysBitmask = $daysBitmask -bor 16 }
                if ($sw.FindName("ChkFri").IsChecked) { $daysBitmask = $daysBitmask -bor 32 }
                if ($sw.FindName("ChkSat").IsChecked) { $daysBitmask = $daysBitmask -bor 64 }
                if ($daysBitmask -eq 0) { $daysBitmask = 2 }
            }
            $hrsMap = @(1, 2, 4, 6, 12)
            $hrInt = if ($cmbInt.SelectedIndex -ge 0 -and $cmbInt.SelectedIndex -lt $hrsMap.Count) { $hrsMap[$cmbInt.SelectedIndex] } else { 2 }
            $schedRes = Set-AutoBackupScheduledTask -TargetRemote $script:ActiveRemote -ModeIndex $idx -StartDateTime $startDt -DaysBitmask $daysBitmask -HourlyInterval $hrInt
            if (-not $schedRes.Ok) {
                Write-StudioLog "[ERR] Schedule registration failed: $($schedRes.Error)"
                Show-AlphaMessageBox -Message $schedRes.Error -Title (L "schedModalTitle") -Buttons "OK" -Icon "Error" | Out-Null
                return
            }
            $sw.Close(); Refresh-StudioHeader
        })
        [void]$sw.ShowDialog()
    } catch {}
})

$BtnDisableSchedule.Add_Click({
    try { $null = Remove-AutoBackupScheduledTask -TargetRemote $script:ActiveRemote; Refresh-StudioHeader } catch {}
})

$BtnSyncToggle.Add_Click({
    try {
        if ($script:IsSyncRunning -and $script:SyncingRemote -eq $script:ActiveRemote) { Invoke-PauseOrStopSync }
        else {
            if ($script:IsGloballyPaused) { Set-GlobalSyncPaused -Paused $false -Silent }
            Start-StudioBatch -Mode "Sync"
        }
    } catch {}
})

function Invoke-HandleContextCommand {
    param([string]$ContextAction, [string]$FolderPath)
    try {
        if ([string]::IsNullOrWhiteSpace($FolderPath)) { return }
        $rawCtxPath = $FolderPath.Trim().Trim('"')
        try { $cleanPath = [System.IO.Path]::GetFullPath($rawCtxPath) } catch { $cleanPath = $rawCtxPath }
        if ($cleanPath.Length -gt 3) { $cleanPath = $cleanPath.TrimEnd('\') }
        if (-not (Test-Path -LiteralPath $cleanPath -PathType Container)) { return }

        # Helper to find which configured account currently tracks this folder
        $findTrackingRemote = {
            param([string]$TargetDir)
            $candRems = @($script:ActiveRemote) + @(Get-ConfiguredDriveRemotes | Where-Object { $_ -ne $script:ActiveRemote })
            foreach ($r in $candRems) {
                $hit = @(Get-SyncFolders -TargetRemote $r | Where-Object {
                    $fp = if ($_.LocalPath.Length -gt 3) { $_.LocalPath.TrimEnd('\') } else { $_.LocalPath }
                    $fp -ieq $TargetDir
                })
                if ($hit.Count -gt 0) { return $r }
            }
            return $null
        }

        if ($ContextAction -eq "ContextAdd") {
            $remotes = @(Get-ConfiguredDriveRemotes)
            if ($remotes.Count -eq 0) {
                Show-AlphaMessageBox -Message (L "msgNotConnectedBody") -Title (L "msgNotConnectedTitle") -Buttons "OK" -Icon "Warning" | Out-Null
                return
            }
            $cfg = Get-Settings
            $compLbl = if ([string]::IsNullOrWhiteSpace($cfg.ComputerLabel)) { "My Computer" } else { $cfg.ComputerLabel.Trim() }
            $accT  = [System.Security.SecurityElement]::Escape((L "ctxAddModalAccount" "Select Cloud Account:"))
            $dstT  = [System.Security.SecurityElement]::Escape((L "ctxAddModalDest" "Backup Destination:"))
            $d1T   = [System.Security.SecurityElement]::Escape((L "targetMyDrive" "My Drive"))
            $tCompLoc = L "targetMyComputer" "My Computer"
            $d2Raw = if ($compLbl -ine "My Computer" -and $compLbl -ine $tCompLoc) { "$tCompLoc ($compLbl)" } else { $tCompLoc }
            $d2T   = [System.Security.SecurityElement]::Escape($d2Raw)
            $okT   = [System.Security.SecurityElement]::Escape((L "addFolder" "+ Add Folder"))
            $canT  = [System.Security.SecurityElement]::Escape((L "btnCancel" "Cancel"))
            $pthE  = [System.Security.SecurityElement]::Escape($cleanPath)
            $body = @"
                <Grid>
                    <Grid.RowDefinitions>
                        <RowDefinition Height="Auto"/><RowDefinition Height="Auto"/><RowDefinition Height="Auto"/>
                        <RowDefinition Height="Auto"/><RowDefinition Height="Auto"/><RowDefinition Height="Auto"/>
                    </Grid.RowDefinitions>
                    <Border Grid.Row="0" Background="#0F1829" BorderBrush="#1E2C42" BorderThickness="1" CornerRadius="6" Padding="10,7" Margin="0,0,0,12">
                        <TextBlock Text="$pthE" FlowDirection="LeftToRight" Foreground="#38BDF8" FontFamily="Consolas" FontSize="11.5" TextTrimming="CharacterEllipsis" ToolTip="$pthE"/>
                    </Border>
                    <TextBlock Grid.Row="1" Text="$accT" FontWeight="SemiBold" Foreground="#CBD5E1" Margin="0,0,0,5"/>
                    <ComboBox x:Name="CmbCtxAcc" Grid.Row="2" Height="32" Margin="0,0,0,12"/>
                    <TextBlock Grid.Row="3" Text="$dstT" FontWeight="SemiBold" Foreground="#CBD5E1" Margin="0,0,0,5"/>
                    <ComboBox x:Name="CmbCtxDst" Grid.Row="4" Height="32" SelectedIndex="0" Margin="0,0,0,16">
                        <ComboBoxItem Content="$d1T" Tag="My Drive"/>
                        <ComboBoxItem Content="$d2T" Tag="My Computer"/>
                    </ComboBox>
                    <StackPanel Grid.Row="5" Orientation="Horizontal" HorizontalAlignment="Right">
                        <Button x:Name="BtnCtxOk" Content="$okT" Background="#0284C7" BorderBrush="#38BDF8" Foreground="#FFFFFF" Margin="0,0,8,0"/>
                        <Button x:Name="BtnCtxCancel" Content="$canT"/>
                    </StackPanel>
                </Grid>
"@
            $mw = New-AlphaModalWindow -Title (L "ctxAddModalTitle" "Add Folder to AlphaCloudSync") -ReqWidth 500 -ReqHeight 305 -Resizable $false -BodyXaml $body
            $cbA = $mw.FindName("CmbCtxAcc")
            $cbD = $mw.FindName("CmbCtxDst")
            $selIdx = 0; $iAcc = 0
            foreach ($rm in $remotes) {
                $ci = New-Object System.Windows.Controls.ComboBoxItem
                $ci.Content = Get-AccountDisplayLabel -TargetRemote $rm
                $ci.Tag = $rm
                $ci.FlowDirection = "LeftToRight"
                [void]$cbA.Items.Add($ci)
                if ($rm -eq $script:ActiveRemote) { $selIdx = $iAcc }
                $iAcc++
            }
            $cbA.SelectedIndex = $selIdx
            $mw.FindName("BtnCtxCancel").Add_Click({ $mw.Close() })
            $mw.FindName("BtnCtxOk").Add_Click({
                $chosenRem = if ($cbA.SelectedItem -and $cbA.SelectedItem.Tag) { $cbA.SelectedItem.Tag.ToString() } else { $script:ActiveRemote }
                $chosenDst = if ($cbD.SelectedItem -and $cbD.SelectedItem.Tag) { $cbD.SelectedItem.Tag.ToString() } else { "My Drive" }
                $mw.Close()
                if ($chosenRem -ne $script:ActiveRemote) { Switch-ActiveAccountRemote -TargetRemote $chosenRem }
                $folders = @(Get-SyncFolders -TargetRemote $chosenRem)
                $alreadyTracked = @($folders | Where-Object {
                    $fp = if ($_.LocalPath.Length -gt 3) { $_.LocalPath.TrimEnd('\') } else { $_.LocalPath }
                    $fp -ieq $cleanPath
                }).Count -gt 0
                if (-not $alreadyTracked) {
                    $leaf = Split-Path -Path $cleanPath -Leaf
                    if ([string]::IsNullOrWhiteSpace($leaf)) { $leaf = ($cleanPath.TrimEnd('\', ':') + "_Drive") }
                    $uniqueName = $leaf
                    $parentDir = Split-Path -Path $cleanPath -Parent
                    $parentLeaf = if (-not [string]::IsNullOrWhiteSpace($parentDir)) { Split-Path -Path $parentDir -Leaf } else { "" }
                    $existingNames = @($folders | ForEach-Object { $_.RemotePath.Trim('/').ToLowerInvariant() })
                    if ($existingNames -contains $uniqueName.ToLowerInvariant()) {
                        if (-not [string]::IsNullOrWhiteSpace($parentLeaf) -and ($existingNames -notcontains "$leaf ($parentLeaf)".ToLowerInvariant())) { $uniqueName = "$leaf ($parentLeaf)" }
                        else { $n = 2; while ($existingNames -contains "$leaf-$n".ToLowerInvariant()) { $n++ }; $uniqueName = "$leaf-$n" }
                    }
                    $folders += [PSCustomObject]@{
                        Enabled = $true; Name = $uniqueName; LocalPath = $cleanPath; TargetMode = $chosenDst; RemotePath = $uniqueName
                        LocalSize = "Click 'Scan'"; LocalBytes = 0.0; RemoteSize = "Click 'Scan'"; LastStatus = "Ready"
                    }
                    Save-SyncFolders -Folders $folders -TargetRemote $chosenRem
                    if ([bool](Get-Settings).ShowFolderBadges) { $null = Set-SyncedFolderBadge -FolderPath $cleanPath }
                    Update-FoldersGrid
                    Sync-RealTimeWatchers
                    Select-StudioTab "Folders"
                    Write-StudioLog -Msg "[OK] Added folder '$uniqueName' via Explorer right-click (Account: $(Get-AccountDisplayLabel -TargetRemote $chosenRem), Target: $chosenDst)." -TargetRemote $chosenRem
                }
            })
            [void]$mw.ShowDialog()
            return
        }

        $ownerRem = & $findTrackingRemote $cleanPath
        if ([string]::IsNullOrWhiteSpace($ownerRem)) {
            Show-AlphaMessageBox -Message (L "ctxFolderNotTracked" "This folder is not currently in your AlphaCloudSync backup list.") -Title "AlphaCloudSync" -Buttons "OK" -Icon "Information" | Out-Null
            return
        }
        if ($ownerRem -ne $script:ActiveRemote) { Switch-ActiveAccountRemote -TargetRemote $ownerRem }
        if ($ContextAction -eq "ContextSync") {
            if ($script:IsGloballyPaused) { Set-GlobalSyncPaused -Paused $false -Silent }
            Select-StudioTab "Activity"
            Start-StudioBatch -Mode "Sync" -OnlyFolderPath $cleanPath
        } elseif ($ContextAction -eq "ContextPreview") {
            Select-StudioTab "Activity"
            Start-StudioBatch -Mode "DryRun" -OnlyFolderPath $cleanPath
        } elseif ($ContextAction -eq "ContextRemove") {
            $folders = @(Get-SyncFolders -TargetRemote $ownerRem | Where-Object {
                $fp = if ($_.LocalPath.Length -gt 3) { $_.LocalPath.TrimEnd('\') } else { $_.LocalPath }
                $fp -ine $cleanPath
            })
            Save-SyncFolders -Folders $folders -TargetRemote $ownerRem
            $stillUsed = $false
            foreach ($otherRem in @(Get-ConfiguredDriveRemotes | Where-Object { $_ -ne $ownerRem })) {
                if (@(Get-SyncFolders -TargetRemote $otherRem | Where-Object {
                    $fp = if ($_.LocalPath.Length -gt 3) { $_.LocalPath.TrimEnd('\') } else { $_.LocalPath }
                    $fp -ieq $cleanPath
                }).Count -gt 0) { $stillUsed = $true; break }
            }
            if (-not $stillUsed) { $null = Clear-SyncedFolderBadge -FolderPath $cleanPath }
            Update-FoldersGrid
            Sync-RealTimeWatchers
            Select-StudioTab "Folders"
            Write-StudioLog -Msg "[OK] Removed folder '$cleanPath' from sync via Explorer right-click." -TargetRemote $ownerRem
        }
    } catch { Write-StudioLog "[ERR] Context action error: $($_.Exception.Message)" }
}

function Invoke-SafeRestoreDialog {
    param([string]$OnlyFolderPath = "")
    if (-not (Test-GDriveConfigured -TargetRemote $script:ActiveRemote)) {
        Show-AlphaMessageBox -Message (L "msgNotConnectedBody") -Title (L "msgNotConnectedTitle") -Buttons "OK" -Icon "Warning" | Out-Null; return
    }
    Persist-GridCheckboxChanges
    $targets = @(Get-SyncFolders -TargetRemote $script:ActiveRemote)
    if (-not [string]::IsNullOrWhiteSpace($OnlyFolderPath)) { $targets = @($targets | Where-Object { $_.LocalPath -ieq $OnlyFolderPath }) }
    else { $targets = @($targets | Where-Object { $_.Enabled -ne $false }) }
    if ($targets.Count -eq 0) { return }

    $hdrT  = [System.Security.SecurityElement]::Escape((L "restoreModalHeader"))
    $protT = [System.Security.SecurityElement]::Escape((L "restoreModalProtectionNotice"))
    $prvT  = [System.Security.SecurityElement]::Escape((L "restoreModalPreviewBtn"))
    $strT  = [System.Security.SecurityElement]::Escape((L "restoreModalStartBtn"))
    $canT  = [System.Security.SecurityElement]::Escape((L "btnCancel"))
    $body = @"
        <Grid>
            <Grid.RowDefinitions><RowDefinition Height="Auto"/><RowDefinition Height="*"/><RowDefinition Height="Auto"/><RowDefinition Height="Auto"/></Grid.RowDefinitions>
            <TextBlock Grid.Row="0" Text="$hdrT" TextWrapping="Wrap" FontSize="13.5" FontWeight="Bold" Foreground="#38BDF8" Margin="0,0,0,8"/>
            <Border Grid.Row="1" Background="#0F1829" BorderBrush="#1E2C42" BorderThickness="1" CornerRadius="8" Padding="11" Margin="0,0,0,10" MinHeight="100">
                <ScrollViewer VerticalScrollBarVisibility="Auto">
                    <StackPanel Orientation="Vertical">
                        <TextBlock x:Name="TxtRestoreIntro" TextWrapping="Wrap" Foreground="#CBD5E1" FontWeight="SemiBold" FontSize="12" Margin="0,0,0,6"/>
                        <TextBlock x:Name="TxtRestoreList" FlowDirection="LeftToRight" TextWrapping="Wrap" Foreground="#E2E8F0" FontSize="11.5" FontFamily="Consolas"/>
                    </StackPanel>
                </ScrollViewer>
            </Border>
            <Border Grid.Row="2" Background="#0F291E" BorderBrush="#10B981" BorderThickness="1" CornerRadius="6" Padding="10,7" Margin="0,0,0,14">
                <TextBlock Text="$protT" TextWrapping="Wrap" Foreground="#4ADE80" FontSize="11.5"/>
            </Border>
            <WrapPanel Grid.Row="3" Orientation="Horizontal" HorizontalAlignment="Right">
                <Button x:Name="BtnResPreview" Content="$prvT" Margin="0,2,8,2"/>
                <Button x:Name="BtnResStart" Content="$strT" Background="#0284C7" BorderBrush="#38BDF8" Foreground="#FFFFFF" Margin="0,2,8,2"/>
                <Button x:Name="BtnResCancel" Content="$canT" Margin="0,2,0,2"/>
            </WrapPanel>
        </Grid>
"@
    $rw = New-AlphaModalWindow -Title (L "restoreModalTitle") -ReqWidth 620 -ReqHeight 390 -Resizable $true -BodyXaml $body
    $rw.FindName("TxtRestoreIntro").Text = LF "restoreModalListHeader" @($targets.Count)
    $rw.FindName("TxtRestoreList").Text  = ($targets | ForEach-Object { $effR = Resolve-EffectiveRemotePath $_; $pfx = if ($_.TargetMode -eq "My Computer") { "" } else { "My Drive/" }; "$([char]0x2022) $($_.Name)`r`n    ${pfx}${effR}  -->  $($_.LocalPath)" }) -join "`r`n"
    $rw.FindName("BtnResCancel").Add_Click({ $rw.Close() })
    $rw.FindName("BtnResPreview").Add_Click({ $rw.Close(); Start-StudioBatch -Mode "RestorePreview" -OnlyFolderPath $OnlyFolderPath })
    $rw.FindName("BtnResStart").Add_Click({ $rw.Close(); Start-StudioBatch -Mode "Restore" -OnlyFolderPath $OnlyFolderPath })
    [void]$rw.ShowDialog()
}

$BtnDryRun.Add_Click({ try { Start-StudioBatch -Mode "DryRun" } catch {} })
$BtnRestore.Add_Click({ try { Invoke-SafeRestoreDialog } catch {} })
$BtnClearLog.Add_Click({
    $rt = Get-AccountRuntime -TargetRemote $script:ActiveRemote
    $null = $rt.LogBuilder.Clear()
    $rt.ActivityItems.Clear()
    $TxtLog.Clear()
    $disp = Get-AccountDisplayLabel -TargetRemote $script:ActiveRemote
    Write-StudioLog -Msg "Activity feed and console cleared for '$disp'." -TargetRemote $script:ActiveRemote
})
