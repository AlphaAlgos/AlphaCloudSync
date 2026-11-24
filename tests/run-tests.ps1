# AlphaCloudSync -- Automated Release-Gate & Integration Test Suite
# Runs standalone with zero external dependencies: powershell -NoProfile -ExecutionPolicy Bypass -File .\tests\run-tests.ps1
[CmdletBinding()]
param(
    [switch]$SkipRcloneIntegration
)

$ErrorActionPreference = "Stop"
$ProjectRoot = Split-Path -Parent $PSScriptRoot
$results = New-Object System.Collections.Generic.List[object]

function Add-TestResult {
    param([string]$Id, [string]$Name, [bool]$Passed, [string]$Details, [switch]$Skipped)
    $status = if ($Skipped) { "SKIP" } elseif ($Passed) { "PASS" } else { "FAIL" }
    $results.Add([PSCustomObject]@{ Id = $Id; Name = $Name; Status = $status; Passed = ($status -eq "PASS"); Skipped = ($status -eq "SKIP"); Details = $Details })
    $tag = "[$status]"
    $clr = switch ($status) { "PASS" { "Green" } "SKIP" { "Yellow" } default { "Red" } }
    Write-Host (" {0} {1} {2} -- {3}" -f $tag, $Id, $Name, $Details) -ForegroundColor $clr
}

Write-Host "========================================================================" -ForegroundColor Cyan
Write-Host " AlphaCloudSync Automated Release-Gate Test Suite" -ForegroundColor Cyan
Write-Host " Root: $ProjectRoot"
Write-Host "========================================================================" -ForegroundColor Cyan

# Pre-load combined source AST across src\AlphaCloudSync.ps1 + all src\modules\**\*.ps1 (faster & module-aware!)
$script:AllSrcFiles     = @(Get-ChildItem -LiteralPath (Join-Path $ProjectRoot "src") -Recurse -Filter "*.ps1" -File | Sort-Object FullName)
$script:CombinedSrcText = (@($script:AllSrcFiles | ForEach-Object { [System.IO.File]::ReadAllText($_.FullName, [System.Text.Encoding]::UTF8) }) -join "`r`n")
$script:CombinedSrcAst  = [System.Management.Automation.Language.Parser]::ParseInput($script:CombinedSrcText, [ref]$null, [ref]$null)

# T01: PowerShell AST Syntax Validation across all .ps1 files
try {
    $psFiles = Get-ChildItem -LiteralPath $ProjectRoot -Recurse -Filter "*.ps1" -File
    $astFails = @()
    foreach ($f in $psFiles) {
        $tokens = $null; $errs = $null
        $null = [System.Management.Automation.Language.Parser]::ParseFile($f.FullName, [ref]$tokens, [ref]$errs)
        if ($errs.Count -gt 0) { $astFails += "$($f.Name): $($errs[0].Message)" }
    }
    Add-TestResult "T01" "PowerShell AST Syntax ($($psFiles.Count) scripts)" ($astFails.Count -eq 0) $(if ($astFails.Count -eq 0) { "0 syntax errors" } else { $astFails -join "; " })
} catch { Add-TestResult "T01" "PowerShell AST Syntax" $false $_.Exception.Message }

# T02: Standard UTF-8 (No BOM), No UTF-16LE, No Arabic ???? Corruption
try {
    $textExts = @('.ps1','.cs','.json','.md','.yaml','.yml','.txt')
    $badEnc = @()
    foreach ($f in (Get-ChildItem -LiteralPath $ProjectRoot -Recurse -File)) {
        if ($f.FullName -match '\\dist\\') { continue }
        if ($textExts -contains $f.Extension.ToLowerInvariant()) {
            $b = [System.IO.File]::ReadAllBytes($f.FullName)
            if ($b.Length -ge 2 -and (($b[0] -eq 0xFF -and $b[1] -eq 0xFE) -or ($b[0] -eq 0xFE -and $b[1] -eq 0xFF))) {
                $badEnc += "UTF16:$($f.Name)"
            }
            if ($b.Length -ge 3 -and $b[0] -eq 0xEF -and $b[1] -eq 0xBB -and $b[2] -eq 0xBF) {
                $badEnc += "BOM:$($f.Name)"
            }
            $txt = [System.IO.File]::ReadAllText($f.FullName, [System.Text.Encoding]::UTF8)
            if ($f.Name -ne 'run-tests.ps1' -and $txt -match '\?\?\?\?') {
                $badEnc += "CORRUPT:$($f.Name)"
            }
        }
    }
    Add-TestResult "T02" "UTF-8 No-BOM & Text Integrity" ($badEnc.Count -eq 0) $(if ($badEnc.Count -eq 0) { "100% Standard UTF-8 without BOM" } else { $badEnc -join ", " })
} catch { Add-TestResult "T02" "UTF-8 No-BOM & Text Integrity" $false $_.Exception.Message }

# T03: 7-Language Exact Key Parity + Placeholder Parity + Zero "Dry Run" Developer Jargon
try {
    $locDir = Join-Path $ProjectRoot "locales"
    $locFiles = Get-ChildItem -LiteralPath $locDir -Filter "*.json" | Sort-Object Name
    $enObj = [System.IO.File]::ReadAllText((Join-Path $locDir "en.json"), [System.Text.Encoding]::UTF8) | ConvertFrom-Json
    $enKeys = @($enObj.PSObject.Properties.Name | Sort-Object)
    $enPlaceholders = @{}
    foreach ($k in $enKeys) {
        $enPlaceholders[$k] = (@([regex]::Matches("$($enObj.$k)", '\{\d+\}') | ForEach-Object { $_.Value } | Sort-Object -Unique) -join ',')
    }
    $locIssues = @()
    if ($locFiles.Count -ne 7) { $locIssues += "Expected 7 locale files, found $($locFiles.Count)" }
    foreach ($lf in $locFiles) {
        $obj = [System.IO.File]::ReadAllText($lf.FullName, [System.Text.Encoding]::UTF8) | ConvertFrom-Json
        $ks = @($obj.PSObject.Properties.Name | Sort-Object)
        $miss = @($enKeys | Where-Object { $ks -notcontains $_ })
        $extr = @($ks | Where-Object { $enKeys -notcontains $_ })
        $jarg = @($obj.PSObject.Properties | Where-Object { "$($_.Value)" -match '(?i)dry[\s-]?run' })
        $phBad = @()
        foreach ($k in $enKeys) {
            if ($ks -contains $k) {
                $ph = (@([regex]::Matches("$($obj.$k)", '\{\d+\}') | ForEach-Object { $_.Value } | Sort-Object -Unique) -join ',')
                if ($ph -ne $enPlaceholders[$k]) { $phBad += "$k($ph!=$($enPlaceholders[$k]))" }
            }
        }
        if ($miss.Count -gt 0) { $locIssues += "$($lf.Name) missing $($miss.Count)" }
        if ($extr.Count -gt 0) { $locIssues += "$($lf.Name) extra $($extr.Count)" }
        if ($jarg.Count -gt 0) { $locIssues += "$($lf.Name) contains Dry-Run jargon" }
        if ($phBad.Count -gt 0) { $locIssues += "$($lf.Name) placeholder mismatch: $($phBad -join ',')" }
    }
    Add-TestResult "T03" "7-Language Parity & Zero Jargon" ($locIssues.Count -eq 0) $(if ($locIssues.Count -eq 0) { "7 languages x $($enKeys.Count) keys & placeholders identical, 0 Dry-Run jargon" } else { $locIssues -join "; " })
} catch { Add-TestResult "T03" "7-Language Parity & Zero Jargon" $false $_.Exception.Message }

# T04: Official Brand Assets Integrity & Zero Legacy Logo References
try {
    $reqAssets = @("AlphaCloudSync-icon.ico","AlphaCloudSync-folder.ico","AlphaCloudSync-icon.png","AlphaCloudSync-icon.svg","AlphaCloudSync-wordmark.png")
    $aIssues = @()
    foreach ($a in $reqAssets) {
        if (-not (Test-Path -LiteralPath (Join-Path $ProjectRoot "assets\$a"))) { $aIssues += "Missing assets\$a" }
    }
    $legacyRef = Select-String -Path @(
        (Join-Path $ProjectRoot "build\build-release.ps1"),
        (Join-Path $ProjectRoot "src\AlphaCloudSync.ps1"),
        (Join-Path $ProjectRoot "README.md"),
        (Join-Path $ProjectRoot "README.ar.md")
    ) -Pattern 'AlphaCloudSync-logo\.png|assets[\\/]AlphaCloudSync\.ico' -ErrorAction SilentlyContinue
    if ($legacyRef) { $aIssues += "Legacy asset reference found in $($legacyRef[0].Filename)" }
    Add-TestResult "T04" "Official Brand Assets Wired" ($aIssues.Count -eq 0) $(if ($aIssues.Count -eq 0) { "5/5 official assets present, 0 legacy refs" } else { $aIssues -join "; " })
} catch { Add-TestResult "T04" "Official Brand Assets Wired" $false $_.Exception.Message }

# T05: install.ps1 Fail-Closed SHA-256 Security Verification (4 Negative/Positive Cases)
try {
    . (Join-Path $ProjectRoot "install.ps1") -LoadFunctionsOnly
    $tmp = Join-Path $env:TEMP "acs_test_sha_$PID"
    New-Item -ItemType Directory -Path $tmp -Force | Out-Null
    try {
        $fakeExe = Join-Path $tmp "AlphaCloudSync.exe"
        $sumsFile = Join-Path $tmp "SHA256SUMS.txt"

        # Case A: Missing SHA256SUMS.txt -> MUST throw and delete downloaded binary
        [System.IO.File]::WriteAllText($fakeExe, "test-binary-payload-A")
        $threwMissing = $false
        try { $null = Assert-ReleaseChecksum -FilePath $fakeExe -SumsPath $sumsFile } catch { $threwMissing = $true }
        $deletedA = -not (Test-Path -LiteralPath $fakeExe)

        # Case B: Malformed / missing entry in SHA256SUMS.txt -> MUST throw and delete binary
        [System.IO.File]::WriteAllText($fakeExe, "test-binary-payload-B")
        [System.IO.File]::WriteAllText($sumsFile, "not-a-valid-hash  AlphaCloudSync.exe`r`n")
        $threwMalformed = $false
        try { $null = Assert-ReleaseChecksum -FilePath $fakeExe -SumsPath $sumsFile } catch { $threwMalformed = $true }
        $deletedB = -not (Test-Path -LiteralPath $fakeExe)

        # Case C: Hash mismatch -> MUST throw and delete binary
        [System.IO.File]::WriteAllText($fakeExe, "test-binary-payload-C")
        [System.IO.File]::WriteAllText($sumsFile, ("0" * 64) + "  AlphaCloudSync.exe`r`n")
        $threwMismatch = $false
        try { $null = Assert-ReleaseChecksum -FilePath $fakeExe -SumsPath $sumsFile } catch { $threwMismatch = $true }
        $deletedC = -not (Test-Path -LiteralPath $fakeExe)

        # Case D: Exact valid hash -> MUST pass and return lowercase hash
        [System.IO.File]::WriteAllText($fakeExe, "test-binary-payload-D")
        $goodHash = (Get-FileHash -LiteralPath $fakeExe -Algorithm SHA256).Hash.ToLowerInvariant()
        [System.IO.File]::WriteAllText($sumsFile, "$goodHash  AlphaCloudSync.exe`r`n")
        $verified = Assert-ReleaseChecksum -FilePath $fakeExe -SumsPath $sumsFile
        $passD = ($verified -eq $goodHash) -and (Test-Path -LiteralPath $fakeExe)

        $allSha = $threwMissing -and $deletedA -and $threwMalformed -and $deletedB -and $threwMismatch -and $deletedC -and $passD
        Add-TestResult "T05" "Installer Fail-Closed SHA-256 (4/4)" $allSha "Missing=$threwMissing Malformed=$threwMalformed Mismatch=$threwMismatch Valid=$passD"
    } finally {
        Remove-Item -LiteralPath $tmp -Recurse -Force -ErrorAction SilentlyContinue
    }
} catch { Add-TestResult "T05" "Installer Fail-Closed SHA-256" $false $_.Exception.Message }

# T06: build-release.ps1 Non-Destructive Guard (Zero Stop-Process -Force)
try {
    $buildSrc = [System.IO.File]::ReadAllText((Join-Path $ProjectRoot "build\build-release.ps1"), [System.Text.Encoding]::UTF8)
    $hasForceKill = ($buildSrc -match 'Stop-Process')
    $hasSafeGuard = ($buildSrc -match 'BUILD REFUSED \(SAFETY GUARD\)')
    Add-TestResult "T06" "Build Script Non-Destructive Guard" ((-not $hasForceKill) -and $hasSafeGuard) "Stop-Process=$hasForceKill, SafetyGuard=$hasSafeGuard"
} catch { Add-TestResult "T06" "Build Script Non-Destructive Guard" $false $_.Exception.Message }

# T07: Pure Unit Tests (12h->24h Time, Overall Multi-Folder Progress, Multi-DPI WorkArea Clamping)
try {
    $fnNames = @("Convert-Time12hTo24h","Compute-OverallBatchProgress","Compute-ClampedWindowBounds")
    foreach ($fn in $script:CombinedSrcAst.FindAll({ param($n) $n -is [System.Management.Automation.Language.FunctionDefinitionAst] -and ($fnNames -contains $n.Name) }, $true)) {
        Invoke-Expression $fn.Extent.Text
    }

    $t12Ok = ((Convert-Time12hTo24h 12 0 "AM") -eq "00:00") -and
             ((Convert-Time12hTo24h 12 30 "PM") -eq "12:30") -and
             ((Convert-Time12hTo24h 11 45 "PM") -eq "23:45") -and
             ((Convert-Time12hTo24h 1 5 "AM")   -eq "01:05") -and
             ($null -eq (Convert-Time12hTo24h 13 0 "PM"))

    $pOk = ((Compute-OverallBatchProgress 0 100 200 50)   -eq 25.0) -and
           ((Compute-OverallBatchProgress 100 100 200 50) -eq 75.0) -and
           ((Compute-OverallBatchProgress 100 100 200 100)-eq 100.0)

    # Test WorkArea clamping across 6 monitor profiles including 150%-scaled laptops & disconnected monitors (-3000,-900)
    $screens = @(
        @{ W=1280; H=680  },
        @{ W=1366; H=728  },
        @{ W=1280; H=829.3 },
        @{ W=1920; H=1040 },
        @{ W=2560; H=1400 },
        @{ W=800;  H=560  }
    )
    $clampOk = $true
    foreach ($sc in $screens) {
        $b = Compute-ClampedWindowBounds -WorkLeft 0 -WorkTop 0 -WorkWidth $sc.W -WorkHeight $sc.H -SavedLeft -3000 -SavedTop -900 -SavedWidth 2000 -SavedHeight 1800 -UseSavedPosition $true
        if ($b.Top -lt 0 -or $b.Left -lt 0 -or ($b.Top + $b.Height) -gt ($sc.H + 0.5) -or ($b.Left + $b.Width) -gt ($sc.W + 0.5)) {
            $clampOk = $false
        }
    }
    Add-TestResult "T07" "Unit Tests (12h Time, Overall %, WorkArea)" ($t12Ok -and $pOk -and $clampOk) "12h=$t12Ok BatchPct=$pOk Clamping(6 screens)=$clampOk"
} catch { Add-TestResult "T07" "Unit Tests (12h Time, Overall %, WorkArea)" $false $_.Exception.Message }

# T08 - T11: Real Local rclone Integration Tests (100% Isolated Temp Folders -- Zero Impact on Google Drive!)
$rcloneExe = (Get-Command rclone -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Source)
if (-not $rcloneExe) {
    $wgRoot = Join-Path $env:LOCALAPPDATA "Microsoft\WinGet\Packages"
    if (Test-Path -LiteralPath $wgRoot) {
        $rcloneExe = Get-ChildItem -LiteralPath $wgRoot -Filter "rclone.exe" -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1 -ExpandProperty FullName
    }
}

if (-not $SkipRcloneIntegration -and $rcloneExe -and (Test-Path -LiteralPath $rcloneExe)) {
    $sand = Join-Path $env:TEMP "acs_rclone_it_$PID"
    New-Item -ItemType Directory -Path $sand -Force | Out-Null
    try {
        # T08: Safe Archive Sync Policy
        $src = Join-Path $sand "src"; $dst = Join-Path $sand "dst"; $arch = Join-Path $sand "archive"
        New-Item -ItemType Directory -Path $src, $dst, $arch -Force | Out-Null
        [System.IO.File]::WriteAllText((Join-Path $src "keep.txt"), "keep-v1")
        [System.IO.File]::WriteAllText((Join-Path $src "delete-me.txt"), "important-data")
        & $rcloneExe sync $src $dst --backup-dir $arch --quiet
        Remove-Item -LiteralPath (Join-Path $src "delete-me.txt") -Force
        & $rcloneExe sync $src $dst --backup-dir $arch --quiet
        $t08 = (Test-Path -LiteralPath (Join-Path $dst "keep.txt")) -and (-not (Test-Path -LiteralPath (Join-Path $dst "delete-me.txt"))) -and (Test-Path -LiteralPath (Join-Path $arch "delete-me.txt"))
        Add-TestResult "T08" "rclone Safe Archive Policy (Real)" $t08 "Deleted file preserved safely in archive dir"

        # T09: Copy-Only & Strict Mirror Policies
        $dstCopy = Join-Path $sand "dst_copy"; $dstMir = Join-Path $sand "dst_mirror"
        New-Item -ItemType Directory -Path $dstCopy, $dstMir -Force | Out-Null
        [System.IO.File]::WriteAllText((Join-Path $src "extra.txt"), "extra")
        & $rcloneExe copy $src $dstCopy --quiet
        & $rcloneExe sync $src $dstMir --quiet
        Remove-Item -LiteralPath (Join-Path $src "extra.txt") -Force
        & $rcloneExe copy $src $dstCopy --quiet
        & $rcloneExe sync $src $dstMir --quiet
        $t09 = (Test-Path -LiteralPath (Join-Path $dstCopy "extra.txt")) -and (-not (Test-Path -LiteralPath (Join-Path $dstMir "extra.txt")))
        Add-TestResult "T09" "rclone Copy-Only & Strict Mirror (Real)" $t09 "Copy-Only retained deleted file; Mirror removed it"

        # T10: Safe Restore Preview (--dry-run) + Overwrite Backup (--backup-dir)
        $cloudDir = Join-Path $sand "cloud"; $localDir = Join-Path $sand "local"; $resBak = Join-Path $sand "restore_bak"
        New-Item -ItemType Directory -Path $cloudDir, $localDir, $resBak -Force | Out-Null
        [System.IO.File]::WriteAllText((Join-Path $cloudDir "doc.txt"), "CLOUD-VERSION-NEW-DATA")
        [System.IO.File]::WriteAllText((Join-Path $localDir "doc.txt"), "LOCAL-ORIGINAL-VALUE")
        # Preview first -> MUST NOT overwrite local file!
        & $rcloneExe copy $cloudDir $localDir --dry-run --quiet
        $afterPreview = [System.IO.File]::ReadAllText((Join-Path $localDir "doc.txt"))
        # Real Safe Restore -> overwrites local file AND backs up original to $resBak!
        & $rcloneExe copy $cloudDir $localDir --backup-dir $resBak --quiet
        $afterRestore = [System.IO.File]::ReadAllText((Join-Path $localDir "doc.txt"))
        $backupSaved  = if (Test-Path -LiteralPath (Join-Path $resBak "doc.txt")) { [System.IO.File]::ReadAllText((Join-Path $resBak "doc.txt")) } else { "" }
        $t10 = ($afterPreview -eq "LOCAL-ORIGINAL-VALUE") -and ($afterRestore -eq "CLOUD-VERSION-NEW-DATA") -and ($backupSaved -eq "LOCAL-ORIGINAL-VALUE")
        Add-TestResult "T10" "Safe Restore Preview & Overwrite Backup" $t10 "Preview untouched=$true, Original saved in restore-backups=$true"

        # T11: JSON Exclusions (--exclude-from) Real Filter Test
        $fSrc = Join-Path $sand "fsrc"; $fDst = Join-Path $sand "fdst"
        New-Item -ItemType Directory -Path (Join-Path $fSrc "node_modules\pkg"), (Join-Path $fSrc "src"), $fDst -Force | Out-Null
        [System.IO.File]::WriteAllText((Join-Path $fSrc "node_modules\pkg\junk.js"), "junk")
        [System.IO.File]::WriteAllText((Join-Path $fSrc "src\app.js"), "real-code")
        [System.IO.File]::WriteAllText((Join-Path $fSrc "temp.tmp"), "temp")
        $exFile = Join-Path $sand "excludes.txt"
        [System.IO.File]::WriteAllLines($exFile, @("node_modules/**", "*.tmp"), (New-Object System.Text.UTF8Encoding($false)))
        & $rcloneExe sync $fSrc $fDst --exclude-from $exFile --quiet
        $t11 = (Test-Path -LiteralPath (Join-Path $fDst "src\app.js")) -and (-not (Test-Path -LiteralPath (Join-Path $fDst "node_modules\pkg\junk.js"))) -and (-not (Test-Path -LiteralPath (Join-Path $fDst "temp.tmp")))
        Add-TestResult "T11" "JSON Exclusion Rules Filter (Real)" $t11 "Skipped node_modules/ & *.tmp; synced src/app.js"
    } finally {
        Remove-Item -LiteralPath $sand -Recurse -Force -ErrorAction SilentlyContinue
    }
} else {
    Add-TestResult "T08-T11" "rclone Local Integration Tests" $false "Skipped (rclone not available or -SkipRcloneIntegration)" -Skipped
}

# T12: Zero Privacy Leaks or Secrets across ALL Public Repo Files
try {
    $leaks = @()
    $allowedEmails = @('alice.dev@gmail.com', 'you@gmail.com', 'user@example.com', 'security@example.com', 'noreply@github.com')
    foreach ($f in (Get-ChildItem -LiteralPath $ProjectRoot -Recurse -File)) {
        if ($f.FullName -match '\\dist\\') { continue }
        if (@('.ps1','.cs','.json','.md','.yaml','.yml','.txt') -contains $f.Extension.ToLowerInvariant()) {
            $txt = [System.IO.File]::ReadAllText($f.FullName, [System.Text.Encoding]::UTF8)
            if ($txt -match '(?i)[A-Z]:\\Users\\(?!YourName|Alice|User|Example|<)[A-Za-z0-9._-]+\\') {
                $leaks += "UserPath:$($f.Name)"
            }
            if ($txt -match 'ya29\.[A-Za-z0-9_-]{10,}|GOCSPX-[A-Za-z0-9_-]{10,}|1//[A-Za-z0-9_-]{20,}|AIza[0-9A-Za-z_-]{35}|ghp_[A-Za-z0-9]{36}') {
                $leaks += "Secret:$($f.Name)"
            }
            foreach ($em in [regex]::Matches($txt, '[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}')) {
                $ev = $em.Value.ToLowerInvariant()
                if (($allowedEmails -notcontains $ev) -and ($ev -notlike '*@example.com')) {
                    $leaks += "Email($ev):$($f.Name)"
                }
            }
        }
    }
    $leaks = @($leaks | Sort-Object -Unique)
    Add-TestResult "T12" "Public Repo Privacy & Secret Guard" ($leaks.Count -eq 0) $(if ($leaks.Count -eq 0) { "0 private paths, emails, or tokens across all repo files" } else { "Leaks: $($leaks -join ', ')" })
} catch { Add-TestResult "T12" "Public Repo Privacy & Secret Guard" $false $_.Exception.Message }

# T13: Multi-Account Collision-Free Drive Letters + Real Simultaneous Dual-Mount (rclone + WinFsp)
try {
    $psText = $script:CombinedSrcText
    $fnAst  = $script:CombinedSrcAst
    $selFn  = $fnAst.Find({ param($n) $n -is [System.Management.Automation.Language.FunctionDefinitionAst] -and $n.Name -eq 'Select-AvailableDriveLetters' }, $true)
    if ($null -eq $selFn) { throw "Select-AvailableDriveLetters function not found" }
    Invoke-Expression $selFn.Extent.Text

    # Simulate 5 accounts when C: and G: (account #1) are already in use
    $usedSim = @("C:", "G:")
    $reserved = @()
    $assigned = @()
    for ($i = 2; $i -le 6; $i++) {
        $availSim = @(Select-AvailableDriveLetters -UsedLetters $usedSim -OwnedLetter "" -Preferred "G:" -ReservedLetters $reserved)
        $pick = $availSim[0]
        $reserved += $pick
        $assigned += $pick
    }
    $assignOk = (($assigned -join ',') -eq 'H:,I:,J:,K:,L:')

    # Real dual simultaneous Windows Explorer mount test (if rclone + WinFsp are available)
    $dualMountNote = "Unit=OK"
    $dualOk = $true
    if (-not $SkipRcloneIntegration -and $rcloneExe -and (Test-Path -LiteralPath "C:\Program Files (x86)\WinFsp")) {
        $liveUsed = @([System.IO.DriveInfo]::GetDrives() | ForEach-Object { $_.Name.Substring(0, 2).ToUpperInvariant() })
        $freeLive = @(Select-AvailableDriveLetters -UsedLetters $liveUsed)
        if ($freeLive.Count -ge 2) {
            # Pick last two free letters (e.g., Y:, Z:) so we never collide with user's G:
            $d1 = $freeLive[$freeLive.Count - 2]
            $d2 = $freeLive[$freeLive.Count - 1]
            $msand = Join-Path $env:TEMP ("acs_dualmount_" + [guid]::NewGuid().ToString("N").Substring(0, 8))
            $a1 = Join-Path $msand "acct1"; $a2 = Join-Path $msand "acct2"
            New-Item -ItemType Directory -Path $a1, $a2 -Force | Out-Null
            [System.IO.File]::WriteAllText((Join-Path $a1 "only_acct1.txt"), "account-one-data")
            [System.IO.File]::WriteAllText((Join-Path $a2 "only_acct2.txt"), "account-two-data")
            $p1 = $null; $p2 = $null
            try {
                $p1 = Start-Process -FilePath $rcloneExe -ArgumentList "mount `"$a1`" $d1 --volname `"ACS-Test1`"" -PassThru -WindowStyle Hidden
                $p2 = Start-Process -FilePath $rcloneExe -ArgumentList "mount `"$a2`" $d2 --volname `"ACS-Test2`"" -PassThru -WindowStyle Hidden
                for ($w = 0; $w -lt 10; $w++) {
                    if ((Test-Path -LiteralPath "${d1}\only_acct1.txt") -and (Test-Path -LiteralPath "${d2}\only_acct2.txt")) { break }
                    Start-Sleep -Milliseconds 700
                }
                $iso1 = (Test-Path -LiteralPath "${d1}\only_acct1.txt") -and (-not (Test-Path -LiteralPath "${d1}\only_acct2.txt"))
                $iso2 = (Test-Path -LiteralPath "${d2}\only_acct2.txt") -and (-not (Test-Path -LiteralPath "${d2}\only_acct1.txt"))
                $dualOk = ($iso1 -and $iso2)
                $dualMountNote = "Unit=OK, RealDualMount(${d1}+${d2})=$dualOk"
            } finally {
                if ($null -ne $p1 -and -not $p1.HasExited) { Stop-Process -Id $p1.Id -Force -ErrorAction SilentlyContinue }
                if ($null -ne $p2 -and -not $p2.HasExited) { Stop-Process -Id $p2.Id -Force -ErrorAction SilentlyContinue }
                Start-Sleep -Milliseconds 600
                Remove-Item -LiteralPath $msand -Recurse -Force -ErrorAction SilentlyContinue
            }
        }
    }
    Add-TestResult "T13" "Multi-Account Drive Letters & Dual Mount" ($assignOk -and $dualOk) "$dualMountNote (Assigned: $($assigned -join ','))"
} catch { Add-TestResult "T13" "Multi-Account Drive Letters & Dual Mount" $false $_.Exception.Message }

# T14: Friendly Email Labels, 1-Line Explorer Drive Titles, Mount Scopes & Unified Combine Builder
try {
    $psText = $script:CombinedSrcText
    $fnAst  = $script:CombinedSrcAst
    foreach ($fnName in @('Format-EmailUsername', 'Match-MountCommandLineForRemote', 'Build-MountCommandArgs', 'Build-UnifiedMountCommandArgs')) {
        $fNode = $fnAst.Find({ param($n) $n -is [System.Management.Automation.Language.FunctionDefinitionAst] -and $n.Name -eq $fnName }, $true)
        if ($null -eq $fNode) { throw "Function '$fnName' not found" }
        Invoke-Expression $fNode.Extent.Text
    }

    $e1 = (Format-EmailUsername -Email "alice.dev@gmail.com" -FallbackRemote "gdrive") -eq "alice.dev"
    $e2 = (Format-EmailUsername -Email "" -FallbackRemote "gdrive-work") -eq "gdrive-work"

    $aDrive = Build-MountCommandArgs -TargetRemote "gdrive" -Letter "G:" -MountMode "Stream" -MountScope "MyDrive" -ComputerLabel "My Computer" -VfsCacheDir "C:\tmp\c" -VolumeDisplayName "alice.dev"
    $aComp  = Build-MountCommandArgs -TargetRemote "gdrive" -Letter "G:" -MountMode "Mirror" -MountScope "MyComputer" -ComputerLabel "My Computer" -VfsCacheDir "C:\tmp\c" -VolumeDisplayName "VeryLongAccountName12345"
    $aBoth  = Build-MountCommandArgs -TargetRemote "gdrive" -Letter "G:" -MountMode "Stream" -MountScope "Both" -ComputerLabel "My Computer" -VfsCacheDir "C:\tmp\c" -VolumeDisplayName "alice.dev"
    $aUni   = Build-UnifiedMountCommandArgs -RemotePairs @(
        [PSCustomObject]@{ Remote = "gdrive";      Label = "alpha"; Scope = "MyDrive" },
        [PSCustomObject]@{ Remote = "gdrive-work"; Label = "alpha"; Scope = "MyComputer" }
    ) -Letter "G:" -MountMode "Stream" -ComputerLabel "My Computer" -VfsCacheDir "C:\tmp\u"

    $mOk1 = (Match-MountCommandLineForRemote -CommandLine $aDrive -TargetRemote "gdrive") -eq "G:"
    $mOk2 = (Match-MountCommandLineForRemote -CommandLine $aComp  -TargetRemote "gdrive") -eq "G:"
    $mOk3 = (Match-MountCommandLineForRemote -CommandLine $aBoth  -TargetRemote "gdrive") -eq "G:"
    $mOk4 = (Match-MountCommandLineForRemote -CommandLine 'mount gdrive: H: --volname "Test"' -TargetRemote "gdrive") -eq "H:"

    # Verify 1-line Explorer volume labels (<= 24 chars so Windows Explorer NEVER hides "X TB free of Y TB")
    $volStream = ($aDrive -match '--volname "([^"]+)"') -and ($Matches[1] -eq "Drive - alice.dev") -and ($Matches[1].Length -le 21)
    $volMirror = ($aComp  -match '--volname "([^"]+)"') -and ($Matches[1].Length -le 21)
    $volUnified = ($aUni  -match '--volname "([^"]+)"') -and ($Matches[1] -eq "AlphaCloudSync Unified") -and ($Matches[1].Length -le 24)
    $aUniCustom = Build-UnifiedMountCommandArgs -RemotePairs @([PSCustomObject]@{ Remote = "gdrive"; Label = "alpha"; Scope = "MyDrive" }) -Letter "G:" -VolumeLabel "AlphaCloudSync Unido"
    $volUniLoc = ($aUniCustom -match '--volname "([^"]+)"') -and ($Matches[1] -eq "AlphaCloudSync Unido")
    $uniDedup  = ($aUni -match 'alpha=gdrive:') -and ($aUni -match 'alpha \(2\)=gdrive-work:My Computer') -and $volUnified -and $volUniLoc

    # Real local rclone :combine: mount test (verifies Unified/Both multi-folder mount works on WinFsp!)
    $combMountOk = $true
    if (-not $SkipRcloneIntegration -and $rcloneExe -and (Test-Path -LiteralPath "C:\Program Files (x86)\WinFsp")) {
        $liveUsed = @([System.IO.DriveInfo]::GetDrives() | ForEach-Object { $_.Name.Substring(0, 2).ToUpperInvariant() })
        $freeLive = @(Select-AvailableDriveLetters -UsedLetters $liveUsed)
        if ($freeLive.Count -ge 1) {
            $dz = $freeLive[$freeLive.Count - 1]
            $csand = Join-Path $env:TEMP ("acs_combine_" + [guid]::NewGuid().ToString("N").Substring(0, 8))
            $c1 = Join-Path $csand "d1"; $c2 = Join-Path $csand "d2"; $cc = Join-Path $csand "vc"
            New-Item -ItemType Directory -Path $c1, $c2, $cc -Force | Out-Null
            [System.IO.File]::WriteAllText((Join-Path $c1 "f1.txt"), "one")
            [System.IO.File]::WriteAllText((Join-Path $c2 "f2.txt"), "two")
            $pc = $null
            try {
                $upRaw = "`"AccountA=$c1`" `"AccountB=$c2`""
                $upEsc = $upRaw.Replace('"', '\"')
                $pc = Start-Process -FilePath $rcloneExe -ArgumentList "mount :combine: $dz --combine-upstreams `"$upEsc`" --vfs-cache-mode writes --cache-dir `"$cc`" --volname `"Google Drive (Stream)`"" -PassThru -WindowStyle Hidden
                for ($w = 0; $w -lt 10; $w++) {
                    if ((Test-Path -LiteralPath "${dz}\AccountA\f1.txt") -and (Test-Path -LiteralPath "${dz}\AccountB\f2.txt")) { break }
                    Start-Sleep -Milliseconds 700
                }
                $combMountOk = (Test-Path -LiteralPath "${dz}\AccountA\f1.txt") -and (Test-Path -LiteralPath "${dz}\AccountB\f2.txt")
            } finally {
                if ($null -ne $pc -and -not $pc.HasExited) { Stop-Process -Id $pc.Id -Force -ErrorAction SilentlyContinue }
                Start-Sleep -Milliseconds 600
                Remove-Item -LiteralPath $csand -Recurse -Force -ErrorAction SilentlyContinue
            }
        }
    }
    $t14 = $e1 -and $e2 -and $mOk1 -and $mOk2 -and $mOk3 -and $mOk4 -and $volStream -and $volMirror -and $uniDedup -and $combMountOk
    Add-TestResult "T14" "Account Labels, 1-Line VolName & Combine Mount" $t14 "Email=$e1/$e2, Match=$mOk1/$mOk2/$mOk3/$mOk4, Vol1Line=$volStream/$volMirror, UnifiedDedup=$uniDedup, RealCombineMount=$combMountOk"
} catch { Add-TestResult "T14" "Account Labels, 1-Line VolName & Combine Mount" $false $_.Exception.Message }

# T15: Synced Folder Badges (.git dir & worktree + Non-Destructive Guard), Safe Names, WinArg & Zero CMD Flash
try {
    $psText = $script:CombinedSrcText
    $fnAst  = $script:CombinedSrcAst
    foreach ($fnName in @('Format-WinArg', 'Get-SanitizedName', 'Get-NextUniqueRemoteId', 'Ensure-GitExcludeDesktopIni', 'Set-SyncedFolderBadge', 'Clear-SyncedFolderBadge')) {
        $fNode = $fnAst.Find({ param($n) $n -is [System.Management.Automation.Language.FunctionDefinitionAst] -and $n.Name -eq $fnName }, $true)
        if ($null -eq $fNode) { throw "Function '$fnName' not found" }
        Invoke-Expression $fNode.Extent.Text
    }

    # Zero CMD / visible terminal flashes
    $zeroCmd    = ([regex]::Matches($psText, '\bcmd\s+/c\b')).Count -eq 0
    $zeroNormal = ([regex]::Matches($psText, '-WindowStyle\s+Normal')).Count -eq 0

    # Safe remote name sanitization (blocks leading dashes & reserved __UNIFIED__) + Win32 quoting
    $sanDash = (Get-SanitizedName -Name "--help") -eq "help"
    $sanResv = (Get-SanitizedName -Name "__UNIFIED__") -ne "__UNIFIED__"
    $winArgOk = ((Format-WinArg "C:\My Folder\") -eq '"C:\My Folder\\"') -and ((Format-WinArg 'a"b') -eq '"a\"b"')

    # Unique auto-generated remote IDs when blank or colliding
    $idBlank1 = (Get-NextUniqueRemoteId -UserInput "" -ExistingRemotes @()) -eq "gdrive"
    $idBlank2 = (Get-NextUniqueRemoteId -UserInput "" -ExistingRemotes @("gdrive")) -eq "gdrive-2"
    $idBlank3 = (Get-NextUniqueRemoteId -UserInput "" -ExistingRemotes @("gdrive","gdrive-2")) -eq "gdrive-3"
    $idCustom = (Get-NextUniqueRemoteId -UserInput "work" -ExistingRemotes @("gdrive","work")) -eq "work-2"

    # Folder badge creation, .git/info/exclude safety (standard + worktree file), non-destructive guard, and clean removal
    $bsand = Join-Path $env:TEMP ("acs_badge_it_" + [guid]::NewGuid().ToString("N").Substring(0, 8))
    $gitRepo = Join-Path $bsand "repo"
    $wtRepo  = Join-Path $bsand "wt_repo"
    $wtRealGit = Join-Path $bsand "real_gitdir"
    $userCustomDir = Join-Path $bsand "custom_ini"
    New-Item -ItemType Directory -Path (Join-Path $gitRepo ".git\info"), $wtRepo, (Join-Path $wtRealGit "info"), $userCustomDir -Force | Out-Null
    [System.IO.File]::WriteAllText((Join-Path $wtRepo ".git"), "gitdir: $wtRealGit`r`n", (New-Object System.Text.UTF8Encoding($false)))
    $StableFolderIconPath = Join-Path $ProjectRoot "assets\AlphaCloudSync-folder.ico"
    $FolderIconPath = $StableFolderIconPath
    try {
        $setOk = Set-SyncedFolderBadge -FolderPath $gitRepo
        $iniPath = Join-Path $gitRepo "desktop.ini"
        $iniExists = Test-Path -LiteralPath $iniPath
        $iniTxt = if ($iniExists) { [System.IO.File]::ReadAllText($iniPath) } else { "" }
        $iniMarked = ($iniTxt -match 'Managed by AlphaCloudSync') -and ($iniTxt -match 'AlphaCloudSync-folder\.ico')
        $gitExcl = Join-Path $gitRepo ".git\info\exclude"
        $gitProtected = (Test-Path -LiteralPath $gitExcl) -and ([System.IO.File]::ReadAllText($gitExcl, [System.Text.Encoding]::UTF8) -match '(?m)^desktop\.ini\r?$')

        # Worktree/submodule .git file test
        Ensure-GitExcludeDesktopIni -FolderPath $wtRepo
        $wtExcl = Join-Path $wtRealGit "info\exclude"
        $wtProtected = (Test-Path -LiteralPath $wtExcl) -and ([System.IO.File]::ReadAllText($wtExcl, [System.Text.Encoding]::UTF8) -match '(?m)^desktop\.ini\r?$')

        # Non-destructive guard: NEVER overwrite user's own desktop.ini
        $uIni = Join-Path $userCustomDir "desktop.ini"
        [System.IO.File]::WriteAllText($uIni, "[.ShellClassInfo]`r`nIconResource=custom.ico,0`r`n", (New-Object System.Text.UTF8Encoding($false)))
        $refusedOverwrite = -not (Set-SyncedFolderBadge -FolderPath $userCustomDir)
        $userIniIntact = ([System.IO.File]::ReadAllText($uIni, [System.Text.Encoding]::UTF8) -match 'custom\.ico')

        # Clean badge removal
        $clrOk = Clear-SyncedFolderBadge -FolderPath $gitRepo
        $iniRemoved = -not (Test-Path -LiteralPath $iniPath)

        $t15 = $zeroCmd -and $zeroNormal -and $sanDash -and $sanResv -and $winArgOk -and $idBlank1 -and $idBlank2 -and $idBlank3 -and $idCustom -and $setOk -and $iniMarked -and $gitProtected -and $wtProtected -and $refusedOverwrite -and $userIniIntact -and $clrOk -and $iniRemoved
        Add-TestResult "T15" "Folder Badges, Git Exclude, Safe Names & Zero CMD" $t15 "ZeroCMD=$zeroCmd/$zeroNormal, San=$sanDash/$sanResv, WinArg=$winArgOk, IDs=$idBlank1/$idBlank2/$idBlank3/$idCustom, Badge=$setOk/$iniMarked, GitExcl=$gitProtected/$wtProtected, SafeGuard=$refusedOverwrite/$userIniIntact, Clear=$clrOk/$iniRemoved"
    } finally {
        Remove-Item -LiteralPath $bsand -Recurse -Force -ErrorAction SilentlyContinue
    }
} catch { Add-TestResult "T15" "Folder Badges, Git Exclude, Safe Names & Zero CMD" $false $_.Exception.Message }

# T16: Filter-Aware Empty-Source Guard (prevents filtered-only source from deleting remote data)
try {
    $psText = $script:CombinedSrcText
    $fnAst  = $script:CombinedSrcAst
    foreach ($fnName in @('Format-WinArg', 'Invoke-RcloneCapture', 'Test-RcloneSourceHasIncludedFiles')) {
        $fNode = $fnAst.Find({ param($n) $n -is [System.Management.Automation.Language.FunctionDefinitionAst] -and $n.Name -eq $fnName }, $true)
        if ($null -eq $fNode) { throw "Function '$fnName' not found" }
        Invoke-Expression $fNode.Extent.Text
    }

    $rcloneExe = (Get-Command rclone -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Source)
    if (-not $rcloneExe) {
        $wgRoot = Join-Path $env:LOCALAPPDATA "Microsoft\WinGet\Packages"
        if (Test-Path -LiteralPath $wgRoot) { $rcloneExe = Get-ChildItem -LiteralPath $wgRoot -Filter "rclone.exe" -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1 -ExpandProperty FullName }
    }
    if ($SkipRcloneIntegration -or -not $rcloneExe -or -not (Test-Path -LiteralPath $rcloneExe)) {
        Add-TestResult "T16" "Filter-Aware Empty-Source Data-Loss Guard" $false "Skipped (rclone not available or -SkipRcloneIntegration)" -Skipped
    } else {
    $script:RcloneExe = $rcloneExe

    $guardSand = Join-Path $env:TEMP ("acs_filter_guard_" + [guid]::NewGuid().ToString("N"))
    $guardSrc = Join-Path $guardSand "src"
    $guardDst = Join-Path $guardSand "dst"
    $guardRules = Join-Path $guardSand "exclude.txt"
    New-Item -ItemType Directory -Path (Join-Path $guardSrc "node_modules\pkg"), $guardDst -Force | Out-Null
    [System.IO.File]::WriteAllText((Join-Path $guardSrc "node_modules\pkg\only-junk.js"), "excluded")
    [System.IO.File]::WriteAllText((Join-Path $guardDst "important-cloud-file.txt"), "KEEP")
    [System.IO.File]::WriteAllLines($guardRules, @("node_modules/**"), (New-Object System.Text.UTF8Encoding($false)))
    try {
        $excludeFlags = "--exclude-from $(Format-WinArg $guardRules)"
        $filteredCheck = Test-RcloneSourceHasIncludedFiles -LocalPath $guardSrc -ExcludeFlags $excludeFlags
        $blockedSync = ($filteredCheck.Safe -and -not $filteredCheck.HasFiles)
        if ($filteredCheck.Safe -and $filteredCheck.HasFiles) {
            & $rcloneExe sync $guardSrc $guardDst --exclude-from $guardRules --quiet
        }
        $destinationPreserved = Test-Path -LiteralPath (Join-Path $guardDst "important-cloud-file.txt")

        [System.IO.File]::WriteAllText((Join-Path $guardSrc "keep.txt"), "included")
        $includedCheck = Test-RcloneSourceHasIncludedFiles -LocalPath $guardSrc -ExcludeFlags $excludeFlags
        $includedDetected = ($includedCheck.Safe -and $includedCheck.HasFiles -and $includedCheck.FileCount -eq 1)

        $missingCheck = Test-RcloneSourceHasIncludedFiles -LocalPath (Join-Path $guardSand "missing") -ExcludeFlags $excludeFlags
        $missingFailsClosed = (-not $missingCheck.Safe)
        $t16 = $blockedSync -and $destinationPreserved -and $includedDetected -and $missingFailsClosed
        Add-TestResult "T16" "Filter-Aware Empty-Source Data-Loss Guard" $t16 "FilteredOnlyBlocked=$blockedSync DestinationPreserved=$destinationPreserved IncludedDetected=$includedDetected MissingFailsClosed=$missingFailsClosed"
    } finally {
        Remove-Item -LiteralPath $guardSand -Recurse -Force -ErrorAction SilentlyContinue
    }
    }
} catch { Add-TestResult "T16" "Filter-Aware Empty-Source Data-Loss Guard" $false $_.Exception.Message }

# T17: Invalid or Missing Enabled Exclusion Rules Must Fail Closed
try {
    $psText = $script:CombinedSrcText
    $fnAst  = $script:CombinedSrcAst
    foreach ($fnName in @('Get-SanitizedName', 'Get-AccountRulesConfig', 'Build-SafeExcludeFile')) {
        $fNode = $fnAst.Find({ param($n) $n -is [System.Management.Automation.Language.FunctionDefinitionAst] -and $n.Name -eq $fnName }, $true)
        if ($null -eq $fNode) { throw "Function '$fnName' not found" }
        Invoke-Expression $fNode.Extent.Text
    }
    function Get-AccountPrefsMap { return $script:MockPrefsMap }
    function Get-DefaultPresetPath { return (Join-Path $script:PresetsDir "general-backup.json") }
    function Set-AccountPref { param([string]$Remote, [object]$UseJsonRules, [string]$JsonRulesPath) }
    function L { param([string]$Key, [string]$Fallback = ""); return $Fallback }

    $rulesSand = Join-Path $env:TEMP ("acs_rules_failclosed_" + [guid]::NewGuid().ToString("N"))
    New-Item -ItemType Directory -Path $rulesSand -Force | Out-Null
    $script:AppDataDir = $rulesSand
    $script:PresetsDir = Join-Path $ProjectRoot "presets"
    try {
        $missingPath = Join-Path $rulesSand "missing-rules.json"
        $script:MockPrefsMap = @{ test = [PSCustomObject]@{ HasRulesPref = $true; UseJsonRules = $true; JsonRulesPath = $missingPath } }
        $missingRules = Build-SafeExcludeFile -TargetRemote "test"

        # A deleted custom file named like a bundled preset must NOT silently switch to that preset.
        $missingCustomPath = Join-Path $rulesSand "general-backup.json"
        $script:MockPrefsMap = @{ test = [PSCustomObject]@{ HasRulesPref = $true; UseJsonRules = $true; JsonRulesPath = $missingCustomPath } }
        $customConfig = Get-AccountRulesConfig -TargetRemote "test"
        $customRulesBlocked = Build-SafeExcludeFile -TargetRemote "test"
        $customPathPreserved = ($customConfig.JsonRulesPath -eq $missingCustomPath)

        $badPath = Join-Path $rulesSand "malformed-rules.json"
        [System.IO.File]::WriteAllText($badPath, '{ invalid json', (New-Object System.Text.UTF8Encoding($false)))
        $script:MockPrefsMap = @{ test = [PSCustomObject]@{ HasRulesPref = $true; UseJsonRules = $true; JsonRulesPath = $badPath } }
        $malformedRules = Build-SafeExcludeFile -TargetRemote "test"

        $disabledPath = Join-Path $rulesSand "disabled-rules.json"
        [System.IO.File]::WriteAllText($disabledPath, '{"enabled":false}', (New-Object System.Text.UTF8Encoding($false)))
        $script:MockPrefsMap = @{ test = [PSCustomObject]@{ HasRulesPref = $true; UseJsonRules = $true; JsonRulesPath = $disabledPath } }
        $intentionallyDisabled = Build-SafeExcludeFile -TargetRemote "test"

        $missingFailsClosed = ($missingRules.Valid -eq $false)
        $malformedFailsClosed = ($malformedRules.Valid -eq $false)
        $explicitDisableAllowed = ($intentionallyDisabled.Valid -eq $true -and $intentionallyDisabled.Enabled -eq $false)
        $customMissingFailsClosed = ($customPathPreserved -and -not $customRulesBlocked.Valid)
        $t17 = $missingFailsClosed -and $malformedFailsClosed -and $explicitDisableAllowed -and $customMissingFailsClosed
        Add-TestResult "T17" "Invalid Exclusion Rules Fail Closed" $t17 "MissingBlocked=$missingFailsClosed MalformedBlocked=$malformedFailsClosed ExplicitDisableAllowed=$explicitDisableAllowed CustomPathPreserved=$customPathPreserved CustomMissingBlocked=$customMissingFailsClosed"
    } finally {
        Remove-Item -LiteralPath $rulesSand -Recurse -Force -ErrorAction SilentlyContinue
    }
} catch { Add-TestResult "T17" "Invalid Exclusion Rules Fail Closed" $false $_.Exception.Message }

# T18: Corrupt Account Preferences Must Not Silently Disable Per-Account Skip Rules
try {
    $psText = $script:CombinedSrcText
    $fnAst  = $script:CombinedSrcAst
    foreach ($fnName in @('Get-SanitizedName', 'Get-AccountPrefsMap', 'Get-AccountRulesConfig', 'Build-SafeExcludeFile')) {
        $fNode = $fnAst.Find({ param($n) $n -is [System.Management.Automation.Language.FunctionDefinitionAst] -and $n.Name -eq $fnName }, $true)
        if ($null -eq $fNode) { throw "Function '$fnName' not found" }
        Invoke-Expression $fNode.Extent.Text
    }
    function Get-DefaultPresetPath { return (Join-Path $script:PresetsDir "general-backup.json") }
    function L { param([string]$Key, [string]$Fallback = ""); return $Fallback }

    $prefsSand = Join-Path $env:TEMP ("acs_prefs_failclosed_" + [guid]::NewGuid().ToString("N"))
    New-Item -ItemType Directory -Path $prefsSand -Force | Out-Null
    $script:AccountPrefsFile = Join-Path $prefsSand "account-prefs.json"
    $script:AppDataDir = $prefsSand
    $script:PresetsDir = Join-Path $ProjectRoot "presets"
    $AccountPrefsFile = $script:AccountPrefsFile
    $AppDataDir = $script:AppDataDir
    $PresetsDir = $script:PresetsDir
    try {
        [System.IO.File]::WriteAllText($script:AccountPrefsFile, '{ malformed account preferences', (New-Object System.Text.UTF8Encoding($false)))
        $rulesConfig = Get-AccountRulesConfig -TargetRemote "work"
        $rulesCheck = Build-SafeExcludeFile -TargetRemote "work"
        $blockedOnCorruptPrefs = ($rulesConfig.UseJsonRules -and [string]::IsNullOrWhiteSpace($rulesConfig.JsonRulesPath) -and -not $rulesCheck.Valid)
        Add-TestResult "T18" "Corrupt Account Preferences Fail Closed" $blockedOnCorruptPrefs "RulesForcedOn=$($rulesConfig.UseJsonRules) EmptyPath=$([string]::IsNullOrWhiteSpace($rulesConfig.JsonRulesPath)) SyncBlocked=$(-not $rulesCheck.Valid)"
    } finally {
        Remove-Item -LiteralPath $prefsSand -Recurse -Force -ErrorAction SilentlyContinue
    }
} catch { Add-TestResult "T18" "Corrupt Account Preferences Fail Closed" $false $_.Exception.Message }

# T19: Runtime Extraction Mutex Timeout Must Fail Closed
try {
    $csText = [System.IO.File]::ReadAllText((Join-Path $ProjectRoot "src\AlphaCloudSyncLauncher.cs"), [System.Text.Encoding]::UTF8)
    $waitPos = $csText.IndexOf("acquired = extractMutex.WaitOne(15000);", [System.StringComparison]::Ordinal)
    $guardPos = -1; $assemblyPos = -1; $timeoutPos = -1
    if ($waitPos -ge 0) {
        $guardPos = $csText.IndexOf("if (!acquired)", $waitPos, [System.StringComparison]::Ordinal)
        $assemblyPos = $csText.IndexOf("Assembly asm = Assembly.GetExecutingAssembly();", $waitPos, [System.StringComparison]::Ordinal)
        if ($guardPos -ge 0) { $timeoutPos = $csText.IndexOf("throw new TimeoutException", $guardPos, [System.StringComparison]::Ordinal) }
    }
    $throwsTimeout = ($guardPos -ge 0) -and ($timeoutPos -ge $guardPos)
    $t19 = ($waitPos -ge 0) -and ($guardPos -gt $waitPos) -and ($assemblyPos -gt $guardPos) -and $throwsTimeout
    Add-TestResult "T19" "Runtime Extraction Mutex Timeout Fail Closed" $t19 "LockWaitFound=$($waitPos -ge 0) TimeoutGuardBeforeExtraction=$($guardPos -gt $waitPos -and $guardPos -lt $assemblyPos) ThrowsTimeout=$throwsTimeout"
} catch { Add-TestResult "T19" "Runtime Extraction Mutex Timeout Fail Closed" $false $_.Exception.Message }

# T20: Corrupt Global Settings Must Not Replace Custom Rules With a Default Preset
try {
    $psText = $script:CombinedSrcText
    $fnAst  = $script:CombinedSrcAst
    foreach ($fnName in @('Get-SanitizedName', 'Get-AccountRulesConfig', 'Build-SafeExcludeFile')) {
        $fNode = $fnAst.Find({ param($n) $n -is [System.Management.Automation.Language.FunctionDefinitionAst] -and $n.Name -eq $fnName }, $true)
        if ($null -eq $fNode) { throw "Function '$fnName' not found" }
        Invoke-Expression $fNode.Extent.Text
    }
    function Get-AccountPrefsMap { $script:AccountPrefsLoadError = ""; return @{} }
    function Get-Settings {
        $script:SettingsLoadError = "Malformed settings JSON"
        return [PSCustomObject]@{ UseJsonRules = $true; JsonRulesPath = (Join-Path $script:PresetsDir "developer-default.json") }
    }
    function Get-DefaultPresetPath { return (Join-Path $script:PresetsDir "developer-default.json") }
    function Set-AccountPref { param([string]$Remote, [object]$UseJsonRules, [string]$JsonRulesPath) }
    function L { param([string]$Key, [string]$Fallback = ""); return $Fallback }

    $script:PresetsDir = Join-Path $ProjectRoot "presets"
    $script:AppDataDir = Join-Path $env:TEMP ("acs_settings_failclosed_" + [guid]::NewGuid().ToString("N"))
    New-Item -ItemType Directory -Path $script:AppDataDir -Force | Out-Null
    $AppDataDir = $script:AppDataDir; $PresetsDir = $script:PresetsDir; $RemoteName = "gdrive"
    $script:AccountPrefsLoadError = ""
    try {
        $rulesConfig = Get-AccountRulesConfig -TargetRemote "gdrive"
        $rulesCheck = Build-SafeExcludeFile -TargetRemote "gdrive"
        $blockedOnCorruptSettings = ($rulesConfig.UseJsonRules -and [string]::IsNullOrWhiteSpace($rulesConfig.JsonRulesPath) -and -not $rulesCheck.Valid)
        Add-TestResult "T20" "Corrupt Global Settings Fail Closed" $blockedOnCorruptSettings "RulesForcedOn=$($rulesConfig.UseJsonRules) EmptyPath=$([string]::IsNullOrWhiteSpace($rulesConfig.JsonRulesPath)) SyncBlocked=$(-not $rulesCheck.Valid)"
    } finally {
        Remove-Item -LiteralPath $script:AppDataDir -Recurse -Force -ErrorAction SilentlyContinue
    }
} catch { Add-TestResult "T20" "Corrupt Global Settings Fail Closed" $false $_.Exception.Message }

# T21: Mount Process Identity Guard (Prevents Killing Reused PIDs / Wrong rclone Operations)
try {
    $psText = $script:CombinedSrcText
    $fnAst  = $script:CombinedSrcAst
    foreach ($fnName in @('Match-MountCommandLineForRemote', 'Test-MountCommandLineMatchesEntry')) {
        $fNode = $fnAst.Find({ param($n) $n -is [System.Management.Automation.Language.FunctionDefinitionAst] -and $n.Name -eq $fnName }, $true)
        if ($null -eq $fNode) { throw "Function '$fnName' not found" }
        Invoke-Expression $fNode.Extent.Text
    }
    $okSep      = Test-MountCommandLineMatchesEntry -CommandLine 'rclone.exe mount "gdrive:" G: --volname "Drive - alice"' -TargetRemote "gdrive" -Letter "G:"
    $okUni      = Test-MountCommandLineMatchesEntry -CommandLine 'rclone.exe mount :combine: H: --combine-upstreams "a=gdrive:" --cache-dir "C:\tmp\vfs-cache\unified-all"' -TargetRemote "__UNIFIED__" -Letter "H:"
    $noUserHit  = -not (Test-MountCommandLineMatchesEntry -CommandLine 'rclone.exe mount :combine: H: --combine-upstreams "a=gdrive:" --cache-dir "C:\Users\Example\unified-all\vfs-cache\gdrive"' -TargetRemote "__UNIFIED__" -Letter "H:")
    $noSyncPid  = -not (Test-MountCommandLineMatchesEntry -CommandLine 'rclone.exe sync "C:\Data" "gdrive:Data" --fast-list' -TargetRemote "gdrive" -Letter "G:")
    $noWrongRem = -not (Test-MountCommandLineMatchesEntry -CommandLine 'rclone.exe mount "gdrive-2:" G: --volname "Drive - bob"' -TargetRemote "gdrive" -Letter "G:")
    $noWrongLtr = -not (Test-MountCommandLineMatchesEntry -CommandLine 'rclone.exe mount "gdrive:" H: --volname "Drive - alice"' -TargetRemote "gdrive" -Letter "G:")
    $noSepAsUni = -not (Test-MountCommandLineMatchesEntry -CommandLine 'rclone.exe mount "gdrive:" H: --volname "Drive - alice"' -TargetRemote "__UNIFIED__" -Letter "H:")
    $t21 = $okSep -and $okUni -and $noUserHit -and $noSyncPid -and $noWrongRem -and $noWrongLtr -and $noSepAsUni
    Add-TestResult "T21" "Mount PID Identity & Reuse Safety Guard" $t21 "Sep=$okSep Uni=$okUni RejectUserColl=$noUserHit RejectSync=$noSyncPid RejectRem=$noWrongRem RejectLtr=$noWrongLtr RejectMix=$noSepAsUni"
} catch { Add-TestResult "T21" "Mount PID Identity & Reuse Safety Guard" $false $_.Exception.Message }

# T22: Fast Auto-Upload Local Exclusion Filter & Zero --files-from / --exclude-from Collision
try {
    $psText = $script:CombinedSrcText
    $fnAst  = $script:CombinedSrcAst
    $fNode  = $fnAst.Find({ param($n) $n -is [System.Management.Automation.Language.FunctionDefinitionAst] -and $n.Name -eq 'Test-RelPathExcludedByRules' }, $true)
    if ($null -eq $fNode) { throw "Function 'Test-RelPathExcludedByRules' not found" }
    Invoke-Expression $fNode.Extent.Text

    $pats = @("node_modules/**", "android/build/**", "*.tmp", "Thumbs.db")
    $ex1 = Test-RelPathExcludedByRules -RelPath "projects/app/node_modules/pkg/index.js" -ExcludeLines $pats -ExcludeDesktopIni $true
    $ex2 = Test-RelPathExcludedByRules -RelPath "mobile/android/build/app.apk" -ExcludeLines $pats -ExcludeDesktopIni $true
    $ex3 = Test-RelPathExcludedByRules -RelPath "docs/draft.tmp" -ExcludeLines $pats -ExcludeDesktopIni $true
    $ex4 = Test-RelPathExcludedByRules -RelPath "desktop.ini" -ExcludeLines $pats -ExcludeDesktopIni $true
    $in1 = -not (Test-RelPathExcludedByRules -RelPath "002.mp3" -ExcludeLines $pats -ExcludeDesktopIni $true)
    $in2 = -not (Test-RelPathExcludedByRules -RelPath "src/AlphaCloudSync.ps1" -ExcludeLines $pats -ExcludeDesktopIni $true)
    $filesFromLines = @($psText -split "`r?`n" | Where-Object { $_ -match '--files-from' -and $_ -notmatch '^\s*#' })
    $noCollision = ($filesFromLines.Count -gt 0) -and (@($filesFromLines | Where-Object { $_ -match '\$exFlag|--exclude' }).Count -eq 0)
    $t22 = $ex1 -and $ex2 -and $ex3 -and $ex4 -and $in1 -and $in2 -and $noCollision
    Add-TestResult "T22" "Fast Auto-Upload Filter & --files-from Safety" $t22 "Excluded=$ex1/$ex2/$ex3/$ex4 Included=$in1/$in2 NoFilterCollision=$noCollision"
} catch { Add-TestResult "T22" "Fast Auto-Upload Filter & --files-from Safety" $false $_.Exception.Message }

# T23: Modular Architecture, Cloud Provider Registry, Global Pause & Windows Explorer Context Menu
try {
    $entryLines = ([System.IO.File]::ReadAllLines((Join-Path $ProjectRoot "src\AlphaCloudSync.ps1"), [System.Text.Encoding]::UTF8)).Length
    $thinEntry  = ($entryLines -le 250)
    $reqMods = @(
        "src\modules\Core.Helpers.ps1",
        "src\modules\Core.Config.ps1",
        "src\modules\Core.Rclone.ps1",
        "src\modules\Core.Shell.ps1",
        "src\modules\Providers\Provider.Registry.ps1",
        "src\modules\Providers\Provider.GoogleDrive.ps1",
        "src\modules\Engine.Mount.ps1",
        "src\modules\Engine.Headless.ps1",
        "src\modules\UI.Interop.ps1",
        "src\modules\UI.ThemeAndLayout.ps1",
        "src\modules\UI.ShellAndIsland.ps1",
        "src\modules\UI.Presenter.ps1",
        "src\modules\UI.SyncAndHandlers.ps1"
    )
    $allModsPresent = (@($reqMods | Where-Object { -not (Test-Path -LiteralPath (Join-Path $ProjectRoot $_)) }).Count -eq 0)

    # Load Provider Registry + Google Drive module in isolation and test extensible provider registration (e.g., future OneDrive)
    . (Join-Path $ProjectRoot "src\modules\Providers\Provider.Registry.ps1")
    . (Join-Path $ProjectRoot "src\modules\Providers\Provider.GoogleDrive.ps1")
    $hasGDrive = ($null -ne (Get-CloudProvider -Id "drive")) -and ((Get-CloudProvider -Id "drive").RcloneType -eq "drive")
    Register-CloudProvider -Id "onedrive" -DisplayName "Microsoft OneDrive" -RcloneType "onedrive" -DefaultRemotePrefix "onedrive"
    $extensibleOk = ($null -ne (Get-CloudProvider -Id "onedrive")) -and (@(Get-RegisteredCloudProviders).Count -ge 2)

    $hasGlobalPause  = $script:CombinedSrcText -match 'function Set-GlobalSyncPaused'
    $hasExplorerMenu = $script:CombinedSrcText -match 'function Set-ExplorerContextMenuEnabled'
    $hasContextIpc   = $script:CombinedSrcText -match 'function Invoke-HandleContextCommand'
    $t23 = $thinEntry -and $allModsPresent -and $hasGDrive -and $extensibleOk -and $hasGlobalPause -and $hasExplorerMenu -and $hasContextIpc
    Add-TestResult "T23" "Modular Architecture, Provider Registry, Pause & Menu" $t23 "EntryLines=$entryLines, Mods(13)=$allModsPresent, Providers=$hasGDrive/$extensibleOk, GlobalPause=$hasGlobalPause, ExplorerMenu=$hasExplorerMenu/$hasContextIpc"
} catch { Add-TestResult "T23" "Modular Architecture, Provider Registry, Pause & Menu" $false $_.Exception.Message }

# T24: Audit Regression Guards (Dir/** File Safety, "%V\." + RTL Menu, Atomic IPC Queue, Pulsing Green Upload Dot)
try {
    $fnAst = $script:CombinedSrcAst
    $fNode = $fnAst.Find({ param($n) $n -is [System.Management.Automation.Language.FunctionDefinitionAst] -and $n.Name -eq 'Test-RelPathExcludedByRules' }, $true)
    if ($null -eq $fNode) { throw "Function 'Test-RelPathExcludedByRules' not found" }
    Invoke-Expression $fNode.Extent.Text

    $dirPats = @("build/**", "dist/**", "a/b/**")
    $fileBuildKept = -not (Test-RelPathExcludedByRules -RelPath "build" -ExcludeLines $dirPats -ExcludeDesktopIni $true)
    $fileDistKept  = -not (Test-RelPathExcludedByRules -RelPath "src/dist" -ExcludeLines $dirPats -ExcludeDesktopIni $true)
    $fileABKept    = -not (Test-RelPathExcludedByRules -RelPath "a/b" -ExcludeLines $dirPats -ExcludeDesktopIni $true)
    $dirBuildExcl  = Test-RelPathExcludedByRules -RelPath "build/app.exe" -ExcludeLines $dirPats -ExcludeDesktopIni $true
    $dirDistExcl   = Test-RelPathExcludedByRules -RelPath "web/dist/bundle.js" -ExcludeLines $dirPats -ExcludeDesktopIni $true
    $dirABExcl     = Test-RelPathExcludedByRules -RelPath "x/a/b/c.txt" -ExcludeLines $dirPats -ExcludeDesktopIni $true

    $shellTxt = [System.IO.File]::ReadAllText((Join-Path $ProjectRoot "src\modules\Core.Shell.ps1"), [System.Text.Encoding]::UTF8)
    $ctxSafeArg = ($shellTxt -match '%V\\\.`"') -and ($shellTxt -match '0x202B') -and ($shellTxt -match '0x202C')
    $normDriveRoot = ([System.IO.Path]::GetFullPath("C:\.") -eq "C:\")

    $themeTxt = [System.IO.File]::ReadAllText((Join-Path $ProjectRoot "src\modules\UI.ThemeAndLayout.ps1"), [System.Text.Encoding]::UTF8)
    $islTxt   = [System.IO.File]::ReadAllText((Join-Path $ProjectRoot "src\modules\UI.ShellAndIsland.ps1"), [System.Text.Encoding]::UTF8)
    $greenPulseOk = ($themeTxt -match 'DotNavActivityLive.*Fill="#22C55E".*Visibility="Collapsed"') -and ($islTxt -match 'function Update-ActivityLiveDotState') -and ($islTxt -match 'DoubleAnimation') -and ($islTxt -match 'RepeatBehavior\]::Forever')

    $csText = [System.IO.File]::ReadAllText((Join-Path $ProjectRoot "src\AlphaCloudSyncLauncher.cs"), [System.Text.Encoding]::UTF8)
    $ipcAtomicOk = ($csText -match 'ipc-queue') -and ($csText -match 'EscapeJsonString') -and ($csText -match 'AttachConsole') -and ($islTxt -match 'function Invoke-DrainIpcQueue')

    $t24 = $fileBuildKept -and $fileDistKept -and $fileABKept -and $dirBuildExcl -and $dirDistExcl -and $dirABExcl -and $ctxSafeArg -and $normDriveRoot -and $greenPulseOk -and $ipcAtomicOk
    Add-TestResult "T24" "Audit Regression Guards (Dir/**, Context RTL, IPC, Pulse)" $t24 "FilesKept=$fileBuildKept/$fileDistKept/$fileABKept DirsExcl=$dirBuildExcl/$dirDistExcl/$dirABExcl CtxSafe=$ctxSafeArg/$normDriveRoot GreenPulse=$greenPulseOk AtomicIPC=$ipcAtomicOk"
} catch { Add-TestResult "T24" "Audit Regression Guards (Dir/**, Context RTL, IPC, Pulse)" $false $_.Exception.Message }

# T25: Instant Startup, Localized Splash Launcher, Foreground Enforcement & Sequential Account Hydration
try {
    $csText   = [System.IO.File]::ReadAllText((Join-Path $ProjectRoot "src\AlphaCloudSyncLauncher.cs"), [System.Text.Encoding]::UTF8)
    $entryTxt = [System.IO.File]::ReadAllText((Join-Path $ProjectRoot "src\AlphaCloudSync.ps1"), [System.Text.Encoding]::UTF8)
    $islTxt   = [System.IO.File]::ReadAllText((Join-Path $ProjectRoot "src\modules\UI.ShellAndIsland.ps1"), [System.Text.Encoding]::UTF8)
    $presTxt  = [System.IO.File]::ReadAllText((Join-Path $ProjectRoot "src\modules\UI.Presenter.ps1"), [System.Text.Encoding]::UTF8)
    $intTxt   = [System.IO.File]::ReadAllText((Join-Path $ProjectRoot "src\modules\UI.Interop.ps1"), [System.Text.Encoding]::UTF8)
    $gdTxt    = [System.IO.File]::ReadAllText((Join-Path $ProjectRoot "src\modules\Providers\Provider.GoogleDrive.ps1"), [System.Text.Encoding]::UTF8)
    $mntTxt   = [System.IO.File]::ReadAllText((Join-Path $ProjectRoot "src\modules\Engine.Mount.ps1"), [System.Text.Encoding]::UTF8)

    $splashOk = ($csText -match 'class AlphaSplashForm') -and ($csText -match 'LoadSplashLocale') -and ($csText -match 'AllowSetForegroundWindow') -and ($entryTxt -match 'Set-SplashStage "3"') -and ($entryTxt -match 'Set-SplashStage "4"') -and ($entryTxt -match 'Set-SplashStage "5"') -and ($entryTxt -match 'Set-SplashStage "DONE"')
    $fgOk     = ($intTxt -match 'AttachThreadInput') -and ($islTxt -match 'function Bring-MainWindowToForeground') -and ($entryTxt -match 'Bring-MainWindowToForeground -InitialLaunch') -and ($entryTxt -match '\$window\.Topmost = \$true')
    $seqOk    = ($islTxt -match 'function Start-SequentialAccountHydration') -and ($islTxt -match 'function Promote-AccountInHydrationQueue') -and ($islTxt -match 'function Stop-SequentialAccountHydration')
    $cacheOk  = ($gdTxt -match 'function Get-RcloneConfigDumpCached') -and ($gdTxt -match 'function Load-UiAccountCache') -and ($mntTxt -match 'function Get-RcloneProcessesCached') -and ($entryTxt -match 'Refresh-StudioHeader -FastLocalOnly')
    # Ensure Refresh-ProfilesDropdown NEVER calls Ensure-RemoteAutoNameCached synchronously!
    $profFn   = $script:CombinedSrcAst.Find({ param($n) $n -is [System.Management.Automation.Language.FunctionDefinitionAst] -and $n.Name -eq 'Refresh-ProfilesDropdown' }, $true)
    $noSyncLoop = ($null -ne $profFn) -and ($profFn.Extent.Text -notmatch 'Ensure-RemoteAutoNameCached')

    $t25 = $splashOk -and $fgOk -and $seqOk -and $cacheOk -and $noSyncLoop
    Add-TestResult "T25" "Instant Launch, Splash Card, Foreground & Seq Accounts" $t25 "Splash=$splashOk Foreground=$fgOk SeqHydration=$seqOk Caches=$cacheOk NoSyncDropdownLoop=$noSyncLoop"
} catch { Add-TestResult "T25" "Instant Launch, Splash Card, Foreground & Seq Accounts" $false $_.Exception.Message }

# T26: v1.1.0 Feature Gate (Uncapped Safe Archive, Friendly Error Translator, 5-Tab Settings, In-App Updater & Cloud-to-Cloud Transfer)
try {
    foreach ($fnName in @('Get-MaxDeleteFlagString', 'Resolve-FriendlySyncError', 'Test-IsNewerReleaseVersion')) {
        $fNode = $script:CombinedSrcAst.Find({ param($n) $n -is [System.Management.Automation.Language.FunctionDefinitionAst] -and $n.Name -eq $fnName }, $true)
        if ($null -eq $fNode) { throw "Function '$fnName' not found" }
        Invoke-Expression $fNode.Extent.Text
    }
    function L { param([string]$Key, [string]$Fallback = ""); return $Key }
    function LF { param([string]$Key, [array]$ArgsList); return "$Key($($ArgsList -join ','))" }

    $safeNoLimit   = ((Get-MaxDeleteFlagString -Policy "Safe Archive"  -Limit 200) -eq "")
    $copyNoLimit   = ((Get-MaxDeleteFlagString -Policy "Copy-Only"     -Limit 200) -eq "")
    $mirrorUnlim   = ((Get-MaxDeleteFlagString -Policy "Strict Mirror" -Limit 0)   -eq "")
    $mirrorCapped  = ((Get-MaxDeleteFlagString -Policy "Strict Mirror" -Limit 500) -eq "--max-delete 500")
    $maxDelOk      = $safeNoLimit -and $copyNoLimit -and $mirrorUnlim -and $mirrorCapped

    $eMaxDel = Resolve-FriendlySyncError -FolderName "Docs" -ExitCode 7 -RawError "Fatal error: --max-delete threshold reached"
    $eQuota  = Resolve-FriendlySyncError -FolderName "Docs" -ExitCode 1 -RawError "googleapi: Error 403: storageQuotaExceeded"
    $eAuth   = Resolve-FriendlySyncError -FolderName "Docs" -ExitCode 1 -RawError "oauth2: token expired and refresh token is invalid_grant"
    $ePath   = Resolve-FriendlySyncError -FolderName "Docs" -ExitCode 3 -RawError "directory not found"
    $eNet    = Resolve-FriendlySyncError -FolderName "Docs" -ExitCode 1 -RawError "dial tcp: lookup www.googleapis.com: no such host"
    $errOk   = ($eMaxDel.StatusToken -eq "Err:MaxDelete") -and ($eQuota.StatusToken -eq "Err:QuotaFull") -and ($eAuth.StatusToken -eq "Err:AuthExpired") -and ($ePath.StatusToken -eq "Err:PathOrAccess") -and ($eNet.StatusToken -eq "Err:Network")

    $verNewer = (Test-IsNewerReleaseVersion -CurrentVer "1.1.0" -RemoteTag "v1.2.0") -and (-not (Test-IsNewerReleaseVersion -CurrentVer "1.1.0" -RemoteTag "v1.1.0")) -and (-not (Test-IsNewerReleaseVersion -CurrentVer "1.1.0" -RemoteTag "v1.0.0"))

    $tabsOk = ($script:CombinedSrcText -match 'function Select-SettingsSubTab') -and ($script:CombinedSrcText -match 'CardSetAccounts') -and ($script:CombinedSrcText -match 'CardSetSync') -and ($script:CombinedSrcText -match 'CardSetBackup') -and ($script:CombinedSrcText -match 'CardSetGeneral') -and ($script:CombinedSrcText -match 'CardSetNotif')
    $updOk  = ($script:CombinedSrcText -match 'function Start-BackgroundUpdateCheck') -and ($script:CombinedSrcText -match 'function Invoke-AppSelfUpdate') -and ($script:CombinedSrcText -match 'BtnUpdateBanner')
    $c2cOk  = ($script:CombinedSrcText -match 'function Start-CloudToCloudBatch') -and ($script:CombinedSrcText -match 'function Invoke-CloudToCloudTransferDialog') -and ($script:CombinedSrcText -match 'drive-server-side-across-configs=true')

    $t26 = $maxDelOk -and $errOk -and $verNewer -and $tabsOk -and $updOk -and $c2cOk
    Add-TestResult "T26" "v1.1.0 Uncapped Archive, Error Translator, Tabs, Updater & C2C" $t26 "MaxDel=$maxDelOk FriendlyErr=$errOk SemVer=$verNewer SettingsTabs=$tabsOk InAppUpdater=$updOk CloudToCloud=$c2cOk"
} catch { Add-TestResult "T26" "v1.1.0 Uncapped Archive, Error Translator, Tabs, Updater & C2C" $false $_.Exception.Message }

$passedCount  = @($results | Where-Object { $_.Status -eq "PASS" }).Count
$skippedCount = @($results | Where-Object { $_.Status -eq "SKIP" }).Count
$failedCount  = @($results | Where-Object { $_.Status -eq "FAIL" }).Count
Write-Host "========================================================================" -ForegroundColor Cyan
Write-Host (" SUMMARY: PASS={0} | SKIP={1} | FAIL={2} | TOTAL={3}" -f $passedCount, $skippedCount, $failedCount, $results.Count) -ForegroundColor $(if ($failedCount -eq 0) { "Green" } else { "Red" })
Write-Host "========================================================================" -ForegroundColor Cyan
if ($failedCount -gt 0) { exit 1 } else { exit 0 }
