# Changelog

All notable changes to **AlphaCloudSync** are documented in this file.

## [1.0.0] - 2026-11-23
### Added
- **Lightweight Windows Cloud Storage Core (Google Drive First, Extensible Provider Architecture):** Built on an open-source `rclone` + `WinFsp` core (`~1.12 MB` self-contained portable executable, `0.0 MB` closed idle RAM) starting with Google Drive in v1.0 and architected for multi-provider expansion in v1.1+.
- **Hybrid Unified (`★ G:`) + Standalone Multi-Account Windows Drives (`D:`–`Z:`):**
  - Add unlimited Google accounts in **Settings -> Accounts & Connections** with optional display name (left empty by default — auto-generates unique remote IDs `gdrive`, `gdrive-2`, `gdrive-3`... via `Get-NextUniqueRemoteId` and automatically extracts your Google email username via `Format-EmailUsername`).
  - **Single Unified Drive (`★ G:`):** Combines pooled accounts into one Windows Explorer drive labeled **`Google Drive Unified`** via `rclone mount :combine:`, auto-deduplicating duplicate folder labels (`alpha`, `alpha (2)`).
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
  - Clean modular layout: thin 207-line entrypoint (`src/AlphaCloudSync.ps1`) + 13 focused modules (`Core.Helpers`, `Core.Config`, `Core.Rclone`, `Core.Shell`, `Providers/Provider.Registry`, `Providers/Provider.GoogleDrive`, `Engine.Mount`, `Engine.Headless`, `UI.Interop`, `UI.ThemeAndLayout`, `UI.ShellAndIsland`, `UI.Presenter`, `UI.SyncAndHandlers`) auto-discovered and embedded by `build/build-release.ps1`.
  - Ready for future cloud providers (`Provider.OneDrive.ps1`, `Provider.Dropbox.ps1`, `Provider.S3.ps1`) without changing Core, Mount, or UI engines.
- **Global Bandwidth Pause + Granular Windows Notifications + Folder Right-Click Menu:**
  - **System Tray Global Pause / Resume:** One click in the System Tray menu pauses all active syncing & live folder watching to free internet bandwidth and resumes cleanly.
  - **Granular Notification Controls:** Toggle master notifications + 4 independent categories (Manual/Preview/Restore, Auto-Sync on real file changes only, Errors/Warnings, Drive mount alerts) — zero spam on `0`-file silent auto-sync checks.
  - **Zero-RAM Windows Explorer Folder Right-Click Menu (`HKCU`):** Right-click any Windows folder -> **AlphaCloudSync** (`Add Folder to Cloud Sync...` with multi-account picker, `Sync This Folder Now`, `Preview Changes Only`, `Remove Folder from Sync`), toggleable cleanly in Settings.
  - **Mount PID Identity Guard:** Verifies `Win32_Process` executable + mount command line + remote + drive letter before terminating any mount PID (eliminates PID-reuse hazards).
- **100% 7-Language Localization (`336` Identical Keys + Arabic RTL/BiDi):**
  - Full translation across English, Arabic (native RTL & BiDi isolation), Spanish, French, German, Simplified Chinese, and Indonesian — zero developer jargon.
- **CLI, CI & Packaging (`install.ps1`, `build/build-release.ps1`, `.github/workflows/ci.yml`, `winget/`):**
  - Fail-Closed SHA-256 `install.ps1`, non-destructive `build/build-release.ps1` (auto-embedding all modular runtime resources + optional Authenticode signing), GitHub Actions Windows CI workflow, full headless CLI (`Status`, `DryRun`, `Sync`, `Restore`, `Mount`, `Unmount`, `Auth`, `--minimized`, `-AutoStartSync`), and WinGet manifest (`winget/AlphaAlgorithms.AlphaCloudSync.yaml`).
- **Automated Verification (`23 / 23 PASS`) & Reproducible Benchmarks (`benchmarks/run-benchmarks.ps1`):**
  - `tests/run-tests.ps1` validates `T01`–`T23` with explicit `PASS`/`SKIP`/`FAIL` reporting, covering 336-key 7-language parity, filter-aware empty-source protection (`T16`), fail-closed rules/prefs/settings/mutex (`T17`–`T20`), mount PID identity guard (`T21`), fast auto-upload local filter & `--files-from` safety (`T22`), and modular architecture + Provider Registry + Global Pause + Explorer Context Menu (`T23`).
