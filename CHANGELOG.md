# Changelog

All notable changes to **AlphaCloudSync** are documented in this file.

## [1.2.8] - 2026-11-26
### Added
- **Per-File Upload Progress Bar Inside Every Queue Row (`GridActivity` → `Progress` column):**
  - Each row now shows a slim, rounded, luminous progress bar plus its exact percentage (`0% → 100%`), so you can watch a single file climb in real time instead of reading a text-only stat.
  - Colors follow the Obsidian Dark identity: cyan gradient while uploading, emerald at `100%`, muted slate for queued previews.
  - New `colProgress` key added across all 7 languages (`Arabic · English · Español · Français · Deutsch · 中文 · Bahasa Indonesia`).
### Fixed
- **Zero-Jump Live Queue (Scroll Anchor — the queue never slides under your cursor anymore):**
  - Rows are now updated **in place** (`ActivityItems[index] = row`) instead of being removed and re-inserted at the top on every 1-second rclone stats tick. The percentage climbs where you are already looking, and the queue no longer shoves itself downward while you read it.
  - Added a real viewport anchor (`Get-ActivityScrollAnchor` / `Restore-ActivityScrollAnchor`): if you pin the top, the top stays pinned; if you scroll down, the row you are reading stays exactly under your cursor while new uploads are inserted, promoted to `100%`, or auto-dismissed after 3.5s.
  - Removed the unconditional `ScrollIntoView(top)` that yanked the wheel away from the user on every upload event.
### Changed
- **Single-Hue Signature Progress Bar (No More Rainbow Spectrum):**
  - The main overall progress bar (`BarSyncProgress`), the sidebar per-account bar, and the in-row bars now share one deep-azure → sky gradient (`#0B6E99 → #2196C9 → #38BDF8 → #8BE0FF`) that matches the Obsidian Dark accent instead of the multi-color cyan/purple/pink/green spectrum.


## [1.2.7] - 2026-11-25
### Fixed
- **Instant Early-Stop Source Safety Guard (`Test-RcloneSourceHasIncludedFiles` — Eliminates 60s Timeouts on Large Folders):**
  - Replaced full-tree blocking `rclone lsf --recursive` enumeration with a shallow root probe + streaming early-stop check that exits the instant the first non-excluded file is detected (`~0.2–2.5s` even on 100,000+ file repositories instead of timing out at 60s and skipping the folder!).
  - Retains 100% fail-closed protection when a folder is missing or contains only excluded files.
- **Authoritative Full-Log Scan on Job Exit (100% Exact Preview & Sync File Counts):**
  - Before deleting the temporary job log upon completion, AlphaCloudSync now performs a full streaming scan of the entire log file so rapid bursts of >85 files or trailing directory-mtime notices can never cause pending preview counts (`Pending Sync: N file(s)`) or uploaded counts to under-report `0`.
- **Visible Warning on Pre-Check Failure:**
  - If any folder fails its source safety check, the batch immediately flags an error and displays a clear warning notification instead of silently skipping the folder and reporting 100% / 0 pending files.

## [1.2.6] - 2026-11-25
### Added
- **Per-Account Persistent Local Cloud Profile History (Last Preview, Sync Stats & Activity Log — 7 Languages x 435 Keys):**
  - Every connected Google Drive account now saves its own last **Preview (Dry-Run)** and **Sync** summary locally (`profiles\last-summary-<remote>.json`) and inside its email-bound profile snapshot (`profiles\email-archive\`).
  - Closing and reopening AlphaCloudSync — or switching between accounts or UI languages — preserves each account's exact last progress bar (`100.0%`), pending upload file count (`Pending Sync: N file(s)`), date/time reference (`Last preview (dd/MM hh:mm AM)` / `Last sync (...)`), pending preview file queue, and recent activity console log.
  - Saved statistics stay pinned as a clear reminder and update **only** when a new Preview or a Sync runs for that account.

## [1.2.5] - 2026-11-25
### Added & Improved
- **Per-Account Hide / Exclude, Unified, or Separate Windows Drive Control (7 Languages x 432 Keys):**
  - Selecting any account in the **Sidebar Accounts Overview** and clicking the drive action button underneath (`$BtnMount`) now hides or shows **ONLY that selected account** — excluding it cleanly from the Unified Drive (`★ H:`) while keeping all other accounts mounted and untouched!
  - Added a dedicated **`⊘ Hidden / Off`** (`DriveAssignment = "Hidden"`) option directly inside both the **Sidebar Drive Letter & Mode dropdowns** AND every row's **Drive Letter dropdown** in the **Drive & Storage** table (`GridMultiDrives`), allowing instant per-account switching between **Unified Drive (`★`)**, **Separate individual drive letter**, or **Hidden / Excluded from Windows Explorer**.
  - Added a native dark **Right-Click Context Menu (`CtxMenuDrives`)** on `GridMultiDrives` with auto-row selection (`Show / Hide This Account Only`, `Show in Unified Drive (★)`, `Show as Separate Drive`, `Hide / Exclude from Windows`, `Rename Account`).
  - Preserved per-account `Hidden` exclusions across global layout switches (`Apply-DriveLayoutChange`), `Mount All`, and email-bound profile snapshots (`Save-AccountEmailSnapshot` / `Restore-AccountEmailSnapshot`).

## [1.2.4] - 2026-11-25
### Added
- **Interactive Account Connection Status Button (`BtnReconnectAccount`) & Live Red/Amber/Green Health Dots (7 Languages x 422 Keys):**
  - Every account card now displays a live clickable connection status button (`✓ Connected` in green, `↻ Refresh Sign-In` in amber while checking, or `↻ Disconnected — Reconnect` in bright red with red border & red status dot when OAuth expires).
  - Clicking the status button directly refreshes Google Sign-In for that exact existing account and flips its status dot straight to emerald green (`#10B981`) without losing folders or settings.
  - Background account hydration and sync runs automatically detect expired/revoked OAuth tokens and flag the account in red immediately across both Settings and Sidebar account cards.
- **Smart Email Deduplication & Persistent Email-Bound Account Profiles (`Save-AccountEmailSnapshot` & `Restore-AccountEmailSnapshot`):**
  - Every Google account maintains its own completely isolated sync folder list, custom JSON exclusion rules, and drive/scope preferences.
  - Signing out automatically archives the account's full profile snapshot under its Google email (`profiles\email-archive\`); signing back into that email later automatically restores all its folders, JSON exclusions, and settings intact.
  - Signing into a Google email that is already connected automatically refreshes the existing account's OAuth token (preserving all synced folders, rules, and drive assignments) instead of creating a duplicate entry.
- **Faster Mode Safe Rollback & One-Click Remove Custom Key (`BtnResetCid`):**
  - Cancelling browser sign-in after entering custom credentials automatically rolls back to the previous configuration so the account is never left broken, and an explicit **Remove Custom Key** button lets users revert to standard mode in one click.

## [1.2.3] - 2026-11-24
### Improved
- **100% Native C# Atomic Self-Update (`--apply-update`, Zero Hidden PowerShell / Zero Defender False Positives):**
  - Eliminated all hidden PowerShell update helper scripts (`irm | iex` and temp `.ps1` swap files) that could trigger Windows Defender `Trojan:Win32/Commando.B!ml` heuristics.
  - The SHA-256 verified binary now performs the atomic swap and clean Splash Screen relaunch natively in C# (`AlphaCloudSyncLauncher.cs`).
- **Clean Multi-Line Numbered Steps in Faster Mode Dialog (`PnlGcpSteps`):**
  - Fixed XML attribute newline collapsing in the Google Cloud personal key guide by rendering each step (`1`, `2`, `3`) on its own cleanly spaced row with numbered cyan pill badges for effortless reading across all 7 languages (including RTL Arabic).

## [1.2.2] - 2026-11-24
### Added
- **Live In-App Self-Updater Progress Modal (`Invoke-AppSelfUpdate`, 7 Languages x 414 Keys):**
  - Replaced the silent background update flow with a live Obsidian-dark modal displaying the version transition (`vCur → vNew`), real-time async download progress bar (`0% → 100%` + downloaded KB/MB), Fail-Closed SHA-256 checksum verification status, and zero UI freeze.
  - Performs a clean graceful app shutdown (keeping all mounted virtual drives untouched), atomic verified EXE swap, and visible `-WindowStyle Normal` relaunch so the 5-stage startup splash screen (`AlphaSplashForm`) appears front-and-center immediately.

## [1.2.1] - 2026-11-24
### Fixed
- **Root-Cause Fix for Sidebar Accounts Overview & Mount Status Display (`Refresh-StudioHeader`):**
  - Removed 3 orphaned XAML element lookups (`TxtSettingsAccount`, `DotSettingsAccount`, `BtnAuthToggle`) that threw null-reference exceptions halfway through `Refresh-StudioHeader`, preventing the sidebar account cards (`ListSidebarAccounts`), account counter (`TxtSidebarAccountsCount`), mount status text, and drive button label from updating.
- **Root-Cause Fix for Modal Close (`✕`), Title-Bar Drag & `Escape` Key Across All Dialogs (`New-AlphaModalWindow` & `Show-AlphaMessageBox`):**
  - Fixed PowerShell local-variable scope loss where `$mw` became `$null` inside event handlers after `New-AlphaModalWindow` returned. All modal `✕` close buttons, drag-move handlers, and `Escape` key handlers now resolve the parent WPF window directly via `[System.Windows.Window]::GetWindow($s)` / `$s.Close()`.

### Added
- **Built-In 1-2-3 Step Guide in Faster Mode Dialog (`apiKeyStepsGuide`, 7 Languages x 408 Keys):**
  - Added a clear 3-step visual guide inside the Google Cloud personal key dialog walking users through enabling Google Drive API, creating an `OAuth client ID` of type `Desktop app`, and pasting their credentials.

## [1.2.0] - 2026-11-24
### Added
- **All-Stages Visible Startup Splash Screen (`AlphaSplashForm`):**
  - All 5 startup stages are visible from the instant the launcher opens, providing users with a clear roadmap of the initialization sequence.
  - Features 3 distinct visual states: **Completed** (emerald ring with crisp checkmark `✓`), **Active In-Progress** (glowing pulsing cyan wave & bold text), and **Pending** (subtle muted dark ring with dimmed slate text indicating queued status).
  - Added early stage-2 dispatch in PowerShell runtime (`Set-SplashStage "2"`) for smooth, real-time stage transitions.
- **Manual Multi-Selection Exclusion for Files & Folders (`BtnPickExclusions`):**
  - Added a dedicated, user-friendly second method to exclude files and folders directly from Windows Explorer dialogs with multi-select support (`+ استثناء يدوي (ملفات ومجلدات)...`).
  - Supports selecting multiple files simultaneously (`OpenFileDialog.Multiselect = $true`), picking entire directories, or adding custom patterns.
  - Automatically updates the account's active JSON exclusion rules file (`excludeFiles` / `excludeDirectories`), sets `UseJsonRules = $true`, updates the counter, and activates immediately.
- **Faster Mode Direct GCP Credentials Link (`BtnOpenGcpConsole`):**
  - Added direct helper link inside Faster Mode dialog `[🔗 فتح Google Cloud Console لإنشاء أو إيجاد المفتاح]` to quickly open Google Cloud Console credentials page.
- **Stacked Accounts List & Real-Time Dynamic Sync:**
  - Redesigned the Accounts & Connections tab to display all connected accounts in a clean vertical stack.
  - Disconnecting ("تسجيل الخروج") or adding accounts immediately reflects in real-time across Settings Accounts, Sidebar Accounts, and Profile Switcher without stale cache.
  - The active default account features an exclusive glowing cyan border (`#38BDF8`), deep navy background (`#112240`), and `[✓ Default Account]` badge.
  - Non-default accounts feature a one-click `[Set as Default]` button to switch active accounts seamlessly.
- **Persistent OAuth Google Sign-In Success Page:**
  - Removed premature browser auto-close timeout in Google Drive OAuth flow so the branded confirmation page remains visible to reassure the user.
- **Bulletproof Modal Dialog Close Architecture (`New-AlphaModalWindow` & `Show-AlphaMessageBox`):**
  - Resolved non-client hit-test collision in RTL layouts by setting `WindowChrome CaptionHeight="0"` and `WindowChrome.IsHitTestVisibleInChrome="True"`, ensuring 100% WPF client area hit-testing for close buttons.
  - Added redundant `Click`, `PreviewMouseLeftButtonDown`, and `PreviewMouseLeftButtonUp` handlers, and `Escape` key dismissal across all modal dialogs.
- **Full 7-Language Parity (407 Keys Across All Locales):**
  - Localized all new exclusion, modal, and account controls across Arabic, English, German, Spanish, French, Indonesian, and Chinese with 100% key and placeholder parity.

## [1.1.0] - 2026-11-24
### Added
- **5-Tab Organized Settings Control Center (`Select-SettingsSubTab`):**
  - Redesigned the Settings view into 5 clean horizontal sub-tabs (**Accounts & Connections**, **Sync Safety & Performance**, **Schedule & Skip Rules**, **General & Interface**, and **Windows Notifications**) so each category opens in its own uncluttered workspace, ready for multi-provider expansion (`OneDrive`, `Dropbox`, `S3`).
- **In-App Automatic Update Detector & One-Click Self-Updater (`Start-BackgroundUpdateCheck` & `Invoke-AppSelfUpdate`):**
  - Asynchronously checks GitHub Releases (`AlphaAlgos/AlphaCloudSync/releases/latest`) after launch with `0 ms` startup impact.
  - When a newer version is available, displays a glowing **Top-Bar Update Pill (`BtnUpdateBanner`)** + Windows System Tray notification, plus a manual **Check for Updates (`BtnCheckUpdates`)** button in Settings.
  - One-click self-update downloads the latest release, verifies the Fail-Closed SHA-256 checksum, closes the old instance without interrupting mounted virtual drives, installs the update, and relaunches automatically.
- **Direct Account-to-Account Cloud Transfer (`Cloud-to-Cloud Transfer` — `Start-CloudToCloudBatch` & `Invoke-CloudToCloudTransferDialog`):**
  - Added **Cloud-to-Cloud Transfer (`⇄`)** in both **Drive & Storage** and **Settings -> Accounts & Connections** to transfer or copy files directly between any two connected Google Drive accounts (`--drive-server-side-across-configs=true`) with zero local hard drive usage.
  - Includes live remote cloud folder browsing (`Load Cloud Folders`), 3 transfer modes (**Copy**, **Sync with Safe Archive**, **Move**), **Preview Only**, and live file-by-file progress in the **Live Activity & Log** queue.
- **Configurable Delete Safety Limit (`MaxDeleteLimit`) in Settings (`Sync Safety & Performance`):**
  - Added a dedicated dropdown control (`CmbMaxDelete`) in **Settings -> Sync Safety & Performance** allowing users to choose the deletion protection threshold for **Exact Match (`Strict Mirror`)** mode: `No Limit (Unlimited)`, `Up to 200 files`, `Up to 500 files`, `Up to 1,000 files`, or `Up to 5,000 files`.
- **Human-Friendly Localized Sync Error Translator (`Resolve-FriendlySyncError`, 7 Languages x 388 Keys):**
  - Eliminated cryptic raw rclone exit code alerts (such as `"exited with code 7"` / `"Exit 7"`) across Windows toast notifications, folder status cells, and archive cleanup dialogs.
  - Translates rclone diagnostics into clear, actionable user messages and status badges in all 7 languages (`en`, `ar`, `de`, `es`, `fr`, `id`, `zh`) covering: Delete safety limit paused, Google Drive storage full, Google sign-in session expired, File open in another app / path unavailable, Temporary network interruption, and General transfer retry.
- **Seamless One-Line Shell Auto-Updater (`install.ps1` & `alphacloudsync-update`):**
  - Running `irm https://raw.githubusercontent.com/AlphaAlgos/AlphaCloudSync/main/install.ps1 | iex` (or typing `alphacloudsync-update` from any terminal) now verifies the new release via Fail-Closed SHA-256 first, gracefully closes any running `AlphaCloudSync` GUI/tray instance without interrupting mounted virtual drives, installs the new binary, and relaunches automatically.

### Fixed
- **Uncapped Safe Archive Mode (`Get-MaxDeleteFlagString`):**
  - Removed the `--max-delete 200` restriction from **Safe Archive** (`وضع الأرشفة الآمنة`) mode so refactoring, moving, or cleaning hundreds of files never aborts sync with rclone Exit Code 7 (since Safe Archive moves deleted/relocated files safely into `_CloudSync_Trash_Archive/<timestamp>` without deleting data).
- **Automatic Stale Preset Path Healing:**
  - Automatically refreshes stale default `JsonRulesPath` references in `settings.json` when custom rules are disabled.

## [1.0.0] - 2026-11-23
### Added
- **Lightweight Windows Cloud Storage Core (Google Drive First, Extensible Provider Architecture):** Built on an open-source `rclone` + `WinFsp` core (`~1.13 MB` self-contained portable executable, `0.0 MB` closed idle RAM) starting with Google Drive in v1.0 and architected for multi-provider expansion in v1.1+.
- **Hybrid Unified (`★ G:`) + Standalone Multi-Account Windows Drives (`D:`–`Z:`):**
  - Add unlimited Google accounts in **Settings -> Accounts & Connections** with optional display name (left empty by default — auto-generates unique remote IDs `gdrive`, `gdrive-2`, `gdrive-3`... via `Get-NextUniqueRemoteId` and automatically extracts your Google email username via `Format-EmailUsername`).
  - **Single Unified Drive (`★ G:`):** Combines pooled accounts into one Windows Explorer drive labeled **`AlphaCloudSync`** via `rclone mount :combine:`, auto-deduplicating duplicate folder labels (`alpha`, `alpha (2)`).
  - **Standalone Drives (`D:`–`Z:`):** Mount any individual account (double-click any row or click **Mount All Accounts**) with collision-free letter allocation (`Select-AvailableDriveLetters`) and concise 1-line Explorer volume labels (**`Drive - <Account>`**, `<= 21` chars so Explorer always keeps `"X TB free of Y TB"` visible on 1 line).
  - **Hybrid Per-Account Override:** Split any individual account out to its own standalone letter (`H:`, `I:`, etc.) while keeping other accounts inside `★ G:`.
  - **Per-Account Drive View (`MountScope`):** Choose `My Drive Only`, `My Computer Only`, or `My Drive + Computer` (`Both` side-by-side).
  - **Online Only (`--vfs-cache-mode writes`) vs Offline Copy (`--vfs-cache-mode full`):** Online Only stores zero permanent offline copies on SSD (minimal temporary write buffer flushed automatically); drives stay active in Explorer even after closing AlphaCloudSync (`31.3 MB` RAM / `0.00%` idle CPU).
  - **Sidebar Accounts Overview:** Live scrollable account cards showing connection dot, drive badge (`★ G:` / `H:`), quota bar, and active sync progress bar.
- **Zero-RAM Synced Folder Badges & Cloud Drive Icons (`.git/info/exclude` Safe):**
  - Stamps synced folders with `AlphaCloudSync-folder.ico` via native Windows `desktop.ini` + `SHChangeNotify` (`0.0 MB` extra RAM, zero Explorer DLL injection) and registers `HKCU\...\Explorer\DriveIcons` for mounted drives.
  - **Non-Destructive Guard:** Never overwrites any user-created `desktop.ini` missing the `; Managed by AlphaCloudSync` marker.
  - **Git & Cloud Safety:** Automatically adds `desktop.ini` to `.git/info/exclude` (never touches tracked `.gitignore`) and passes `--exclude "desktop.ini"` during syncs.
- **100% Unified Obsidian Dark Fluent Desktop Studio + Zero CMD Windows:**
  - Calm 2-Column Studio (`248px` sidebar + 4 focused views: **Backup Folders**, **Drive & Storage**, **Live Activity & Log**, and **Settings ⚙**), 38px `WindowChrome` with Aero Snap, symmetric Maximize, multi-DPI WorkArea clamping, and native Windows 11 Taskbar App Identity (`AppUserModelID` + `WM_SETICON` + `SHGetPropertyStoreForWindow`).
  - Custom-templated dark controls across every `ComboBox`, `CheckBox`, `TextBox`, `DatePicker`, `ContextMenu`, `ToolTip`, `ScrollBar`, `DataGrid`, `Show-AlphaMessageBox`, dark modals, and System Tray menu (`AlphaDarkTrayRenderer`).
  - Zero console flashes (`0` `cmd /c` and `0` `-WindowStyle Normal` calls verified by `T15`).
- **Branded Silent OAuth + Dark Waiting & Success Modals:**
  - Executes Google OAuth on `127.0.0.1` loopback with `CreateNoWindow = $true` and a custom Obsidian Dark branded browser confirmation page (`rclone authorize --template`, zero plain white default pages) while displaying a dark **"Waiting for Google Sign-In"** modal (with indeterminate progress bar & Cancel button), followed automatically by a dark **"Connected Successfully"** modal.
- **Silent Windows Explorer Auto-Refresh + Priority-Sorted Live Queue:**
  - Automatically broadcasts Windows shell drive events (`SHCNE_DRIVEADD` / `SHCNE_DRIVEREMOVED`) and silently refreshes open **This PC** Explorer windows via COM `Shell.Application` whenever a drive is mounted, unmounted, or switched.
  - Strict 3-tier priority Activity Queue keeps **Uploading** files pinned at the top, flashes **Completed / Archived** items right underneath for 3.5 seconds before auto-clearing cleanly (while full history stays in the live log below), and lists **Queued / Preview** pending items below with zero stuck `99%` rows.
- **Real-Time Auto-Sync (ON/OFF) + 12-Hour `AM / PM` Windows Task Scheduler (COM API):**
  - **Real-Time Auto-Sync (`OFF` by default):** Native .NET `AlphaFolderWatchHub` (`FileSystemWatcher`) monitors the active account's enabled folders while running (including in System Tray), immediately queues detected edits in the Activity Feed, ignores `.git`, `node_modules`, `.venv`, `__pycache__`, `.vs`, `.next`, `.expo`, `desktop.ini`, `Thumbs.db`, `~$*`, `*.tmp`, `*.part`, `*.crdownload`, waits **4 seconds** after edits settle, uploads changed files rapidly via targeted `--files-from`, and shows mode-aware System Tray completion notifications.
  - **Windows Task Scheduler (`12h AM / PM`, Locale-Independent COM `Schedule.Service`):** Schedule One-Time, Daily, Weekly, or Every Few Hours (`1h`–`12h`) backups that run silently on any Windows regional date format even when closed (`0.0 MB` RAM), writing status to `backup-health.json`.
- **Per-Account Isolated State, Sequential Engine & Safety Guards:**
  - Per-account isolated folder lists, Live File Activity feed, Console Log, progress counters, and Skip Rules (`presets/developer-default.json`, `creative-media.json`, `general-backup.json`, plus visual JSON editor & `.json` importer).
  - Sequential folder-by-folder engine with isolated per-job logs, weighted Rainbow Progress (`0% → 100%`), 3 Speed Modes (`Turbo`, `Balanced`, `Eco`), **Faster Mode** (personal Google Cloud OAuth key), **3 Delete Policies** (`Safe Archive`, `Copy Only`, `Exact Match`), filter-aware Empty-Source Guard, fail-closed invalid exclusion rules, `--max-delete 200`, and **Overwrite-Protected Safe Restore** (`Preview Only (No Files Changed)` + automatic backup to `%LOCALAPPDATA%\AlphaCloudSync\restore-backups\`).
- **Freely Draggable Dynamic Cloud Island + Storage & Trash Manager:**
  - Non-focus-stealing floating pill (`~250 × 32 px`) with 6-dot drag grip, auto-saved coordinates across monitors, 220ms hover-to-expand, right-click dark Quick-Snap menu, and Windows Taskbar icon progress glow.
  - Visual Quota Bar, **Check Space & Folder Sizes**, **Empty Drive Trash** (guarded by typing `EMPTY`), and **Clean Old Archive (`30d+`)**.
- **Modular Architecture + Extensible Cloud Provider Registry (`src/modules/`):**
  - Clean modular layout: thin 220-line entrypoint (`src/AlphaCloudSync.ps1`) + 13 focused modules (`Core.Helpers`, `Core.Config`, `Core.Rclone`, `Core.Shell`, `Providers/Provider.Registry`, `Providers/Provider.GoogleDrive`, `Engine.Mount`, `Engine.Headless`, `UI.Interop`, `UI.ThemeAndLayout`, `UI.ShellAndIsland`, `UI.Presenter`, `UI.SyncAndHandlers`) auto-discovered and embedded by `build/build-release.ps1`.
  - Ready for future cloud providers (`Provider.OneDrive.ps1`, `Provider.Dropbox.ps1`, `Provider.S3.ps1`) without changing Core, Mount, or UI engines.
- **Global Bandwidth Pause + Granular Windows Notifications + Folder Right-Click Menu + Live Upload Pulse:**
  - **System Tray Global Pause / Resume:** One click in the System Tray menu pauses all active syncing & live folder watching to free internet bandwidth and resumes cleanly across Sidebar, Cloud Island, and Auto-Watch.
  - **Pulsing Green Live Upload Indicator:** Smooth pulsing green indicator next to **Live Activity & Log** appears ONLY during active file uploads and hides completely when idle.
  - **Granular Notification Controls:** Toggle master notifications + 4 independent categories (Manual/Preview/Restore, Auto-Sync on real file changes only, Errors/Warnings, Drive mount/unmount alerts) — zero spam on `0`-file silent auto-sync checks.
  - **Zero-RAM Windows Explorer Folder Right-Click Menu (`HKCU`):** Right-click any Windows folder -> **AlphaCloudSync** (`Add Folder to Cloud Sync...` with multi-account picker, `Sync This Folder Now`, `Preview Changes Only`, `Remove Folder from Sync`), localized with RTL BiDi formatting, drive-root safe (`"%V\."`), atomic queued IPC, and toggleable cleanly in Settings.
  - **Mount PID Identity Guard:** Verifies `Win32_Process` executable + mount command line + remote/unified cache path + drive letter before terminating any mount PID (eliminates PID-reuse hazards).
- **Instant ~30ms 5-Stage Localized Splash Card, Foreground Activation & Sequential Account Hydration:**
  - Native C# rounded Obsidian Dark Splash Card (`AlphaSplashForm`) launches in `~30ms` displaying 5 live stacked progress stages localized across all 7 languages (including Arabic RTL) before fading out smoothly into the main window.
  - Forces the main window decisively to the foreground on startup above all open desktop windows (`AllowSetForegroundWindow` + `AttachThreadInput` + `SetForegroundWindow`).
  - Persisted non-secret display cache (`ui-account-cache.json`) + cached `rclone config dump` & `Win32_Process` snapshots + non-blocking sequential background hydration queue (`Start-SequentialAccountHydration`) refresh connected accounts strictly **one by one** (active account first) without freezing launch even with 10+ accounts.
- **100% 7-Language Localization (`345` Identical Keys + Arabic RTL/BiDi):**
  - Full translation across English, Arabic (native RTL & BiDi isolation), Spanish, French, German, Simplified Chinese, and Indonesian — zero developer jargon.
- **CLI, CI & Packaging (`install.ps1`, `build/build-release.ps1`, `.github/workflows/ci.yml`, `winget/`):**
  - Fail-Closed SHA-256 `install.ps1`, non-destructive `build/build-release.ps1` (auto-embedding all modular runtime resources + optional Authenticode signing), GitHub Actions Windows CI workflow, UTF-8 headless CLI (`Status`, `DryRun`, `Sync`, `Restore`, `Mount`, `Unmount`, `Auth`, `--minimized`, `-AutoStartSync`), and WinGet manifest (`winget/AlphaAlgorithms.AlphaCloudSync.yaml`).
- **Automated Verification (`25 / 25 PASS`) & Reproducible Benchmarks (`benchmarks/run-benchmarks.ps1`):**
  - `tests/run-tests.ps1` validates `T01`–`T25` with explicit `PASS`/`SKIP`/`FAIL` reporting, covering 345-key 7-language parity, filter-aware empty-source protection (`T16`), fail-closed rules/prefs/settings/mutex (`T17`–`T20`), mount PID identity guard (`T21`), fast auto-upload local filter & `--files-from` safety (`T22`), modular architecture + Provider Registry + Global Pause + Explorer Context Menu (`T23`), directory-rule filename safety + RTL `%V\.` menu quoting + atomic IPC queue + pulsing green upload dot (`T24`), and instant localized Splash Card + foreground enforcement + non-blocking sequential account hydration (`T25`).
