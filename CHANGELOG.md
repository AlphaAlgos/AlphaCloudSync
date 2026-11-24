# Changelog

All notable changes to **AlphaCloudSync** are documented in this file.

## [1.2.0] - 2026-11-24
### Added
- **All-Stages Visible Startup Splash Screen (`AlphaSplashForm`):**
  - All 5 startup stages are visible from the instant the launcher opens, providing users with a clear roadmap of the initialization sequence.
  - Features 3 distinct visual states: **Completed** (emerald ring with crisp checkmark `✓`), **Active In-Progress** (glowing pulsing cyan wave & bold text), and **Pending** (subtle muted dark ring with dimmed slate text indicating queued status).
  - Added early stage-2 dispatch in PowerShell runtime (`Set-SplashStage "2"`) for smooth, real-time stage transitions.
- **Stacked Accounts List with Active Default Highlighting (`ListSettingsAccounts`):**
  - Redesigned the Accounts & Connections tab to display all connected accounts in a clean vertical stack.
  - The active default account features an exclusive glowing cyan border (`#38BDF8`), deep navy background (`#112240`), and `[✓ Default Account]` badge.
  - Non-default accounts feature a one-click `[Set as Default]` button to switch active accounts seamlessly, alongside web folder opening and disconnect options.
- **Bulletproof Modal Dialog Close Architecture (`New-AlphaModalWindow` & `Show-AlphaMessageBox`):**
  - Resolved non-client hit-test collision in RTL layouts by setting `WindowChrome CaptionHeight="0"`, ensuring 100% WPF client area hit-testing for close buttons.
  - Added redundant `Click` and `PreviewMouseLeftButtonUp` handlers, smart title-bar drag-move exclusion, and `Escape` key dismissal across all modal dialogs.
- **Full 7-Language Parity (395 Keys Across All Locales):**
  - Localized account card badges and controls across Arabic, English, German, Spanish, French, Indonesian, and Chinese.

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
