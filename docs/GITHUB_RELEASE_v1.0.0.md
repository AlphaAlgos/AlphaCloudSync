# AlphaCloudSync v1.0.0 — Official Release

<p align="center">
  <img src="https://raw.githubusercontent.com/AlphaAlgos/AlphaCloudSync/main/assets/AlphaCloudSync-wordmark.png" alt="AlphaCloudSync v1.0.0 — Backup. Sync. Restore." width="560"/>
</p>

> **A Lightweight, Fast & Transparent Cloud Storage Control Core for Windows — Starting with Google Drive.**  
> A self-contained portable Windows studio (`~1.16 MB` executable over `rclone` + `WinFsp`) delivering zero-bloat folder backups, a **Hybrid Unified (`★ G:`) + Standalone Multi-Account Explorer Drive Hub**, Zero-RAM Synced Folder Badges, optional **Real-Time Auto-Sync**, overwrite-protected **Safe Restore**, per-account **Skip Rules**, a **100% Obsidian Dark Fluent UI** with zero CMD flashes, and a freely draggable **Dynamic Cloud Island**.

---

## Quick Install (Windows 10 / 11 x64)

### 1-Line Fail-Closed PowerShell Install (Recommended)
```powershell
irm https://raw.githubusercontent.com/AlphaAlgos/AlphaCloudSync/main/install.ps1 | iex
```
Downloads `AlphaCloudSync.exe` and `SHA256SUMS.txt` into `%LOCALAPPDATA%\AlphaCloudSync\app\`, **enforces Fail-Closed SHA-256 verification** (immediately aborts & deletes the downloaded file if `SHA256SUMS.txt` is missing, malformed, or mismatched), creates Desktop & Start Menu shortcuts, and adds `AlphaCloudSync` to your user `PATH`.

### Manual Portable Download
1. Download **`AlphaCloudSync.exe`** and **`SHA256SUMS.txt`** from the release assets below.
2. Verify integrity in PowerShell against `SHA256SUMS.txt`:
   ```powershell
   Get-FileHash .\AlphaCloudSync.exe -Algorithm SHA256
   ```
3. Double-click `AlphaCloudSync.exe` — if `rclone` is not installed yet, click **Yes** on the first-launch prompt to install it automatically with official `SHA256SUMS` verification.

---

## What's New in v1.0.0

### 1. Hybrid Unified (`★ G:`) + Standalone Multi-Account Windows Drives (`D:` – `Z:`)
- **Single Unified Drive (`★ G:`):** Combine chosen Google accounts into one Windows Explorer drive labeled **`AlphaCloudSync`** (`rclone mount :combine:`), with each account appearing as an auto-deduplicated folder inside (`alice.dev`, `alice.dev (2)`).
- **Standalone Drives (`D:` – `Z:`):** Mount any account individually (double-click any row) or click **Mount All Accounts** for automatic collision-free drive letters (`G:`, `H:`, `I:`...) with concise 1-line Explorer labels (**`Drive - <Account>`**, `<= 21` chars so Explorer always keeps `"X TB free of Y TB"` visible).
- **Hybrid Per-Account Control:** Split any account onto its own dedicated letter (`H:`, `I:`, etc.) while keeping the remaining pool inside `★ G:`.
- **Per-Account Drive View (`MountScope`):** Choose `My Drive Only`, `My Computer Only`, or `My Drive + Computer` (`Both`).
- **Online Only (`0 GB` SSD) vs Offline Copy:** Online Only (`--vfs-cache-mode writes`) keeps no permanent offline mirrors on your SSD (only a minimal temporary write buffer flushed automatically). Drives stay mounted in Explorer even after closing AlphaCloudSync (`49.6 MB` RAM / `0.00%` idle CPU), with silent Explorer auto-refresh and Mount PID Identity Guard (`T21`).
- **Sidebar Accounts Overview:** Live scrollable cards for every account showing status dot, drive badge (`★ G:` / `H:`), quota bar, and live sync progress.

### 2. Zero-RAM Synced Folder Badges, Drive Icons & Explorer Right-Click Menu
- Marks synced local folders with `AlphaCloudSync-folder.ico` via native Windows `desktop.ini` + `SHChangeNotify` (`0.0 MB` extra RAM, zero Explorer DLL injection) and sets `HKCU\...\Explorer\DriveIcons` on mounted drives.
- **Zero-RAM Windows Explorer Folder Right-Click Menu (`HKCU`):** Right-click any folder -> **AlphaCloudSync** (`Add Folder to Cloud Sync...` with multi-account picker, `Sync This Folder Now`, `Preview Changes Only`, `Remove Folder from Sync`), localized across all 7 languages with RTL BiDi formatting, drive-root safe (`"%V\."`), and atomic queued IPC.
- **`.git/info/exclude` Safety:** Automatically appends `desktop.ini` to parent `.git/info/exclude` (including Git worktrees) without touching tracked `.gitignore`.
- **Non-Destructive & Cloud Safe:** Refuses to overwrite existing user-created `desktop.ini` files and excludes `desktop.ini` from Drive uploads (`--exclude "desktop.ini"`).

### 3. 100% Unified Obsidian Dark Fluent UI + Branded Silent OAuth + Zero CMD Windows
- Every `ComboBox`, `CheckBox`, `TextBox`, `DatePicker`, `ContextMenu`, `ToolTip`, `ScrollBar`, `DataGrid`, `Show-AlphaMessageBox`, modal dialog, and System Tray menu (`AlphaDarkTrayRenderer`) is custom-templated Obsidian Dark (`#080D17` / `#0F1829`), with a **pulsing green Live Activity upload dot** that appears ONLY while actively uploading.
- **Zero CMD Flashes:** `0` `cmd /c` and `0` `-WindowStyle Normal` calls (`T15` verified).
- **Branded Silent OAuth:** Leave the optional display name box blank to auto-generate unique remote IDs (`gdrive`, `gdrive-2`, ...) and auto-extract your Google email username; sign-in serves a branded Obsidian Dark HTML confirmation page (`rclone authorize --template`) behind dark **"Waiting for Google Sign-In"** and **"Connected Successfully"** modals.
- **Windows 11 Taskbar Identity & 38px `WindowChrome`:** Native `AppUserModelID` + `WM_SETICON` + `SHGetPropertyStoreForWindow`, Aero Snap, symmetric Maximize, and single-instance restore.

### 4. Fast Real-Time Auto-Sync, Global Bandwidth Pause, Granular Notifications & COM Scheduler
- **Fast Targeted Real-Time Auto-Sync (`OFF` by default):** Native .NET `AlphaFolderWatchHub` (`FileSystemWatcher`) monitors the active account's enabled folders while running (including in System Tray), ignores noisy paths, waits **4 seconds** after edits settle, filters locally against Skip Rules, and uploads changed files rapidly via targeted `--files-from`.
- **1-Click System Tray Global Pause / Resume:** Pause all syncing & live watching instantly to free internet bandwidth and resume cleanly anytime.
- **Granular Windows Notifications:** Master toggle + 4 independent categories (Manual/Preview/Restore, Auto-Sync on real changes only — zero `0`-file spam, Errors/Warnings, Drive mount/unmount alerts).
- **12-Hour `AM / PM` Auto-Backup Scheduler (COM `Schedule.Service`):** Locale-independent One-Time, Daily, Weekly, or Every Few Hours (`1h`–`12h`) scheduling (`0.0 MB` RAM when closed), with `backup-health.json` logging.

### 5. Priority-Sorted Activity Queue, Skip Rules, Safe Restore, Cloud Island & Modular Core
- Isolated per-account folder lists, **Priority-Sorted Live Activity Queue** (Uploading pinned top -> Completed/Archived 3.5s auto-dismiss -> Queued/Delete Sync/Rename Sync FIFO bottom with auto-visible top ceiling), **Activity Log**, counters, and **Skip Rules** (`Developer`, `Creative & Media`, `General Backup`, visual JSON editor, `.json` importer).
- **3 Delete Policies + Safety Guards:** `Safe Archive` (`_CloudSync_Trash_Archive/<timestamp>/`), `Copy Only`, `Exact Match`, filter-aware Empty-Source Guard (enumerates included files using rclone's active filters), fail-closed invalid rules, and `--max-delete 200`.
- **Overwrite-Protected Safe Restore:** Dark review screen with **Preview Only (No Files Changed)** first, plus automatic local backups into `%LOCALAPPDATA%\AlphaCloudSync\restore-backups\` before replacing differing local files.
- **Freely Draggable Dynamic Cloud Island + Quick-Snap:** Translucent non-focus-stealing pill (`~250 × 32 px`) with 6-dot grip, auto-saved multi-monitor coordinates, 220ms hover-to-expand, right-click dark Quick-Snap menu, and Windows Taskbar progress glow.
- **7 Built-In Languages (`345` Identical Keys, Zero Jargon):** English · العربية (Full RTL & BiDi) · Español · Français · Deutsch · 中文 (简体) · Bahasa Indonesia.
- **Instant ~30ms 5-Stage Splash Card, Foreground Launch & Sequential Account Hydration:** Native Obsidian Dark rounded Splash Card displays live stacked startup stages in your language, forces the studio cleanly into the desktop foreground, and refreshes connected accounts asynchronously one by one (active account first) for instant startup even with 10+ accounts.
- **Modular Architecture + Provider Registry (`src/modules/`):** Clean 13-module layout (`Core`, `Providers/Provider.GoogleDrive`, `Engine.Mount`, `Engine.Headless`, `UI`), ready for OneDrive/Dropbox/S3/Nextcloud modules in `v1.1+`.
- **3 Speed Modes + Faster Mode:** `Turbo`, `Balanced`, `Eco` (2 MB/s cap), plus optional personal Google Cloud Desktop Client ID for up to 5x faster uploads.

---

## Reproducible Benchmarks & Automated Verification

- **Automated Test Suite (`tests/run-tests.ps1`):** **`25 / 25 PASS`** (`T01`–`T25` with explicit `PASS`/`SKIP`/`FAIL` reporting & Windows CI covering 345-key 7-language parity, Fail-Closed SHA-256, non-destructive build guard, real `rclone` Safe Archive/Copy-Only/Mirror/Restore/Exclusions, filter-aware empty-source data-loss prevention `T16`, fail-closed rules/prefs/mutex/settings `T17`–`T20`, mount PID identity guard `T21`, fast `--files-from` auto-upload filter `T22`, modular architecture + Provider Registry + Global Pause + Explorer Context Menu `T23`, directory-rule safety + RTL `%V\.` menu + atomic IPC + pulsing green upload dot `T24`, instant Splash Card + foreground enforcement + sequential multi-account hydration `T25`, simultaneous dual-mount `T13`, 1-line labels & `:combine:` Unified mount `T14`, and Folder Badges + `.git/info/exclude` + Zero CMD `T15`).
- **Measured Performance (`benchmarks/run-benchmarks.ps1` on Intel Core i5-7Y57 / 7.9 GB RAM / Windows 11 Pro):**
  - Portable Executable: **`~1.16 MB`** (`1,191.5 KB`, 27 embedded modular resources)
  - Closed / Scheduled Idle: **`0.0 MB` RAM / `0.00%` CPU**
  - Persistent Explorer Drive (`G:` Online Only Idle): **`49.6 MB` RAM / `0.00%` CPU**
  - Filtered Repo Scan (`node_modules`/`.venv` skipped): **`3.509 sec`** vs **`7.440 sec`** raw (**2.1x faster**, **96.0% of repo size** skipped)
  - Filtered Safe-Archive Sync (`400` clean files): **`4.113 sec`** (`54.4 MB` peak RAM)
  - Overwrite-Protected Safe Restore: **`0.838 sec`** (`49.2 MB` peak RAM)
  - Headless CLI (`AlphaCloudSync.exe -Action Status`): **`ExitCode: 0`** (`9.853 sec`)

---

## Transparency, Privacy & SmartScreen Note

- **Zero Telemetry:** No analytics, no tracking, no third-party servers. OAuth runs directly between your browser, `rclone`, and Google (`127.0.0.1` loopback; refresh token stored locally in `%APPDATA%\rclone\rclone.conf`).
- **Windows SmartScreen:** Open-source community releases are currently **unsigned** (no commercial EV certificate yet), so SmartScreen may prompt on first launch. Verify `SHA256SUMS.txt` or build locally via `.\build\build-release.ps1` (27 auto-embedded runtime & modular resources).

---

## Documentation Links (All 7 Languages)
- **English:** [`README.md`](https://github.com/AlphaAlgos/AlphaCloudSync/blob/main/README.md) · **User Guide:** [`docs/USER_GUIDE.md`](https://github.com/AlphaAlgos/AlphaCloudSync/blob/main/docs/USER_GUIDE.md)
- **العربية (Arabic):** [`README.ar.md`](https://github.com/AlphaAlgos/AlphaCloudSync/blob/main/README.ar.md) · **دليل الاستخدام:** [`docs/USER_GUIDE.ar.md`](https://github.com/AlphaAlgos/AlphaCloudSync/blob/main/docs/USER_GUIDE.ar.md)
- **Español (Spanish):** [`README.es.md`](https://github.com/AlphaAlgos/AlphaCloudSync/blob/main/README.es.md)
- **Français (French):** [`README.fr.md`](https://github.com/AlphaAlgos/AlphaCloudSync/blob/main/README.fr.md)
- **Deutsch (German):** [`README.de.md`](https://github.com/AlphaAlgos/AlphaCloudSync/blob/main/README.de.md)
- **中文 (简体 / Simplified Chinese):** [`README.zh.md`](https://github.com/AlphaAlgos/AlphaCloudSync/blob/main/README.zh.md)
- **Bahasa Indonesia (Indonesian):** [`README.id.md`](https://github.com/AlphaAlgos/AlphaCloudSync/blob/main/README.id.md)
- **Benchmarks & Security:** [`BENCHMARKS.md`](https://github.com/AlphaAlgos/AlphaCloudSync/blob/main/BENCHMARKS.md) · [`SECURITY.md`](https://github.com/AlphaAlgos/AlphaCloudSync/blob/main/SECURITY.md)
