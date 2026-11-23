<p align="center">
  <img src="assets/AlphaCloudSync-wordmark.png" alt="AlphaCloudSync — Backup. Sync. Restore." width="560"/>
</p>

<h3 align="center">A Lightweight, Fast &amp; Transparent Cloud Storage Control Core for Windows — Starting with Google Drive.</h3>

<p align="center">
  An open-source portable Windows studio built as a lightweight cloud storage workspace (starting with <strong>Google Drive</strong> in v1.0, architected on a unified <a href="https://rclone.org/">rclone</a> &amp; <a href="https://winfsp.dev/">WinFsp</a> core for future providers) — giving you zero-bloat folder backups, a <strong>Hybrid Unified (<code>★ G:</code>) + Standalone Multi-Account Windows Explorer Drive Hub</strong>, Zero-RAM Synced Folder Badges, Real-Time Auto-Sync, overwrite-protected Safe Restore, per-account Skip Rules, a 100% Obsidian Dark Fluent UI, and a freely draggable <strong>Dynamic Cloud Island</strong>.<br/>
  Built by <a href="https://github.com/AlphaAlgos">Alpha Algorithms Company</a>.
</p>

<p align="center">
  <a href="LICENSE"><img src="https://img.shields.io/badge/License-MIT-38BDF8.svg" alt="MIT License"/></a>
  <img src="https://img.shields.io/badge/Windows-10%20%2F%2011%20(x64)-10B981.svg" alt="Windows 10/11 x64"/>
  <img src="https://img.shields.io/badge/Portable%20EXE-~1.12%20MB-6366F1.svg" alt="Portable EXE"/>
  <img src="https://img.shields.io/badge/Languages-7%20(336%20Keys%20%2B%20Arabic%20RTL)-F59E0B.svg" alt="7 Languages (336 Keys)"/>
  <img src="https://img.shields.io/badge/Automated%20Tests-20%2F20%20PASS-22C55E.svg" alt="20/20 Tests Pass"/>
  <img src="https://img.shields.io/badge/Telemetry-Zero-4ADE80.svg" alt="Zero Telemetry"/>
</p>

<p align="center">
  <strong>English</strong> · <a href="README.ar.md">العربية (Arabic)</a> · <a href="docs/USER_GUIDE.md">User Guide</a> · <a href="BENCHMARKS.md">Benchmarks</a> · <a href="CHANGELOG.md">Changelog</a> · <a href="SECURITY.md">Security</a> · <a href="CONTRIBUTING.md">Contributing</a>
</p>

---

## Why Switch from Official Google Drive for Desktop?

If you use Google Drive on Windows, you have likely run into at least one of these everyday frustrations:

| Everyday Pain Point | Official Google Drive for Desktop | AlphaCloudSync v1.0 |
| :--- | :--- | :--- |
| **Reinstalled Windows?** | Creates **`My Computer (1)`** and re-uploads tens of GB from scratch | **Zero duplication** — reconnects straight to your existing `My Drive` or fixed `My Computer` label |
| **Background RAM Usage** | Always-on resident background processes | **`0.0 MB` RAM when closed** · **`31.3 MB` RAM** measured with live `G:` Explorer drive mounted *(see [`BENCHMARKS.md`](BENCHMARKS.md))* |
| **Uploading Junk & Caches** | Uploads `node_modules`, `.venv`, `.gradle`, `*.tmp` and wastes quota | **Per-Account Skip Rules (`presets/`)** skip heavy dev/media/OS junk automatically & show exact gigabytes saved |
| **Accidental Local Delete** | Silent sync can wipe or bury cloud files | **3 Clear Delete Policies** (`Safe Archive`, `Copy Only`, `Exact Match`) + Empty-Source Guard + `--max-delete 200` |
| **Restoring Files Back to PC** | Risk of silently overwriting newer local edits | **Safe Restore** — preview changes first (`Preview Only (No Files Changed)`) + auto-backups overwritten local files |
| **Multiple Google Accounts** | Limited & entangled multi-account settings | **Hybrid Unified (`★ G:`) + Standalone Drives (`D:`–`Z:`)** — combine accounts into `Google Drive Unified` or split any account onto its own letter (`Drive - <Account>`) |
| **Folder Sync Indicators** | Heavy Explorer shell extensions | **Zero-RAM Synced Folder Badges & Drive Icons** via native `desktop.ini` + `.git/info/exclude` protection |
| **Automation Flexibility** | Forces always-running background sync | **Your Choice:** **Real-Time Auto-Sync** (`4s` debounce when running/in tray) **OR** silent **12h Task Scheduler** (`0.0 MB` RAM when closed) |
| **Installer & Footprint** | Heavy installer + silent auto-updaters | **1 portable `~1.12 MB` EXE** · Fail-Closed SHA-256 verified · Zero CMD windows · Zero telemetry |

---

## Complete Feature Matrix (Verified in `src/AlphaCloudSync.ps1`)

### 1. Hybrid Unified (`★ G:`) + Standalone Multi-Account Windows Drives (`D:` – `Z:`)
Add unlimited Google Drive accounts (`1`, `2`, `5`, `10+`...) in **Settings -> Accounts & Connections** and browse them natively in Windows Explorer:
- **Two Flexible Layouts — Or Both Together (Hybrid):**
  - **Single Unified Drive (`★ G:`):** Combines chosen accounts into one Windows Explorer drive labeled **`Google Drive Unified`** (powered by `rclone mount :combine:`), with each account appearing as its own folder inside (auto-deduplicated if two accounts share a name, e.g., `alice.dev`, `alice.dev (2)`).
  - **Standalone Drives (`D:` – `Z:`):** Mount any account individually (double-click its row in **Drive & Storage**, or pick a letter in the sidebar) or click **Mount All Accounts** for automatic collision-free drive letters (`G:`, `H:`, `I:`...). Standalone drives display concise 1-line Explorer labels (**`Drive - <Account>`**, `<= 21` chars) so Windows Explorer always shows `"X TB free of Y TB"` on one clean line.
  - **Hybrid Per-Account Control:** Even in Unified layout, you can assign any specific account to its own standalone letter (`H:`, `I:`, etc.) while keeping the rest inside `★ G:`!
- **Per-Account Drive View (`MountScope`):** Choose what each account exposes in Explorer: **`My Drive Only`**, **`My Computer Only`**, or **`My Drive + Computer`** (`Both` side-by-side).
- **Online Only (`0 GB` Permanent SSD) vs Offline Copy:**
  - **Online Only (`--vfs-cache-mode writes`):** browse and open cloud files on demand without storing permanent local mirrors on your SSD (uses only a minimal temporary write buffer in `%LOCALAPPDATA%\AlphaCloudSync\vfs-cache\` flushed automatically).
  - **Offline Copy (`--vfs-cache-mode full`):** caches up to `50G` / `720h` locally for fast offline access.
- **Persistent After Closing:** Virtual drives stay mounted in Windows Explorer even after closing AlphaCloudSync completely (`31.3 MB` RAM / `0.00%` idle CPU measured on a live `G:` drive).
- **Sidebar Accounts Overview:** Scrollable live cards for every connected account showing connection dot, drive badge (`★ G:` in gold for Unified members, `H:` in cyan for Standalone), live storage quota bar, and live sync progress when active.

### 2. Zero-RAM Synced Folder Badges & Cloud Drive Icons (`.git/info/exclude` Safe)
See at a glance which local folders and Windows drives belong to AlphaCloudSync — with **0.0 MB extra RAM**:
- **Native Shell Icons (No Explorer DLL Injection):** Uses standard Windows `desktop.ini` + `SHChangeNotify` to stamp synced local folders with the green-checkmark AlphaCloudSync folder icon (`assets/AlphaCloudSync-folder.ico`) and registers `HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\DriveIcons` so mounted cloud drives display the AlphaCloudSync drive icon.
- **`.git/info/exclude` Safety:** Automatically detects parent `.git` repositories and appends `desktop.ini` to `.git/info/exclude` locally so Git status stays clean without modifying your repo's tracked `.gitignore`.
- **Non-Destructive Guard & Cloud Exclusion:** Never overwrites an existing user-authored `desktop.ini` (checks for `; Managed by AlphaCloudSync`), automatically passes `--exclude "desktop.ini"` during syncs so badge files never upload to Google Drive, and cleans everything up cleanly if you remove a folder or toggle badges OFF in **Settings -> General & Interface**.

### 3. 100% Unified Obsidian Dark Fluent UI & Zero CMD Windows
A calm, cohesive Windows 11 desktop studio with zero jarring white popups or terminal flashes:
- **Calm 2-Column Studio Architecture:** Sleek `248px` dark sidebar (Active Account switcher, 4 navigation tabs: **Backup Folders**, **Live Activity & Log**, **Drive & Storage**, and **Settings ⚙**, scrollable **Accounts Overview**, Quick Drive widget, and mini quota bar) paired with a docked bottom action & **Rainbow Spectrum Progress Bar**.
- **100% Custom-Templated Dark Controls:** Every `ComboBox`, `CheckBox`, `TextBox`, `DatePicker`, `ContextMenu`, `ToolTip`, `ScrollBar`, `DataGrid`, `Show-AlphaMessageBox`, modal dialog, and even the System Tray menu (`AlphaDarkTrayRenderer`) uses native Obsidian Dark styling (`#080D17` / `#0F1829`).
- **Zero CMD Windows:** Every `rclone`, `schtasks`, and helper invocation runs with `CreateNoWindow = $true` / `-WindowStyle Hidden` (`0` `cmd /c` and `0` `-WindowStyle Normal` calls verified by automated test `T15`).
- **Windows 11 Taskbar Identity & WindowChrome:** Custom 38px `WindowChrome` with edge/corner resizing, Aero Snap, symmetric Maximize framing, multi-DPI WorkArea clamping across 6+ monitor profiles, single-instance restore (re-launching or left-clicking the tray icon restores the hidden window), and native `AppUserModelID` + `WM_SETICON` + `SHGetPropertyStoreForWindow` Taskbar/Alt+Tab icon binding.

### 4. Silent OAuth + Dark Waiting & Success Modals
- Clicking **Sign In with Google** or **`+ Add Account`** opens a dark modal with an **optional display name box (empty by default)** — leave it blank to automatically generate unique remote IDs (`gdrive`, `gdrive-2`, `gdrive-3`...) and automatically display your Google email username (e.g., `alice.dev`).
- While you complete Google OAuth in your browser (`127.0.0.1` loopback), AlphaCloudSync displays a **dark "Waiting for Google Sign-In" modal** (with indeterminate progress bar and Cancel button) with zero CMD windows, then transitions automatically into a dark **"Connected Successfully"** confirmation dialog.

### 5. Real-Time Auto-Sync (ON/OFF) vs Windows Task Scheduler (`12h AM/PM`)
Choose the exact automation style that fits your machine:
- **Real-Time Auto-Sync (`OFF` by default for 0% background overhead):** Toggle ON in **Settings -> Schedule & Skip Rules** to watch the active account's enabled backup folders using the native .NET `AlphaFolderWatchHub` (`FileSystemWatcher`) while AlphaCloudSync is running (including minimized in the System Tray).
  - Automatically ignores noisy paths (`.git`, `node_modules`, `__pycache__`, `.venv`, `.vs`, `.next`, `.expo`, `desktop.ini`, `Thumbs.db`, `~$*`, `*.tmp`, `*.part`, `*.crdownload`).
  - Waits **4 seconds** after edits settle (`4s` debounce) before syncing automatically with your Delete Policy & Skip Rules, then shows a System Tray completion popup.
- **12-Hour `AM / PM` Auto-Backup Scheduler:** Prefer **`0.0 MB` RAM** when not actively syncing? Schedule **One-Time**, **Daily**, **Weekly** (chosen days), or **Every Few Hours** (`1h`, `2h`, `4h`, `6h`, `12h`) via native Windows Task Scheduler (`schtasks.exe`). AlphaCloudSync exits completely until the scheduled time and logs execution status to `backup-health.json`.

### 6. Per-Account Isolated Activity, Logs, Skip Rules & Safe Sync Engine
- **Per-Account Isolation:** Switching accounts cleanly isolates each account's folder list (`profiles/folders-<remote>.json`), **Live File Activity** feed, **Activity Log** console, progress counters, and **Skip Rules** (`account-prefs.json`).
- **Sequential Folder-by-Folder Engine:** Processes checked folders strictly one at a time with unique per-job logs, weighted overall Rainbow Progress (`0% → 100%`), speed (`MB/s`), `ETA`, and crisp **12-hour `AM / PM`** timestamps. Pause or close anytime and resume only what remains.
- **3 Delete Policies + Safety Guards:**
  - **Safe Archive (Recommended):** deleted local files move safely to `_CloudSync_Trash_Archive/<timestamp>/` on Drive.
  - **Copy Only (Never Delete):** strictly additive — never deletes cloud files.
  - **Exact Match (Mirror PC):** mirrors your PC cleanly and sends removed files to Google Drive Trash.
  - Protected by **Empty-Source Guard** (refuses destructive sync if a local folder is missing or empty) and **Mass-Delete Cap** (`--max-delete 200`).
- **Overwrite-Protected Safe Restore:** Opens a dark review modal with **Preview Only (No Files Changed)** first, and automatically backs up any differing local file into `%LOCALAPPDATA%\AlphaCloudSync\restore-backups\` before replacing it.
- **Speed Modes & Faster Mode:** Switch between **Fast (Turbo)**, **Balanced**, and **Gentle (`Eco` — 2 MB/s cap)**, or add your own free Google Cloud Desktop Client ID in **Faster Mode** to lift shared public OAuth rate limits.

### 7. Freely Draggable Dynamic Cloud Island, Storage Manager & 7 Languages (`336` Keys)
- **Dynamic Cloud Island:** Slim translucent floating pill (`~250 × 32 px`, never steals keyboard focus) with a 6-dot drag grip, persistent coordinates across monitors, smart `220ms` hover-to-expand, 1-click Pause/Resume, and a right-click dark **Quick-Snap Menu** (**Top Center**, **Top Left**, **Top Right**, **Bottom Left**, **Bottom Right**, **Open Main Window**, **Hide Island**). Native Taskbar icon progress glow works even when the Island is hidden.
- **Google Drive Storage & Trash Manager:** Inspect Total / Used / Free / Trash space, run **Check Space & Folder Sizes** (showing exact space & file count saved by Skip Rules), **Empty Drive Trash** (guarded by typing `EMPTY`), **Clean Old Archive (`30d+`)**, or **Open Drive in Browser**.
- **7 Built-In Languages (`336` Identical Keys, Zero Jargon):**
  **English · العربية (Full RTL & BiDi) · Español · Français · Deutsch · 中文 (简体) · Bahasa Indonesia**

---

## Real Measured Performance (Reproducible on Your PC)

Measured via [`benchmarks/run-benchmarks.ps1`](benchmarks/run-benchmarks.ps1) on a modest **Intel Core i5-7Y57 (1.20 GHz) / 7.9 GB RAM Windows 11 Pro laptop** — raw output saved in [`benchmarks/latest-results.json`](benchmarks/latest-results.json). *(Note: only AlphaCloudSync is directly benchmarked below; we avoid unverified head-to-head multipliers against closed-source sync apps.)*

| Scenario | Measured Result | Peak RAM | Idle CPU |
| :--- | :---: | :---: | :---: |
| **Portable Executable (`AlphaCloudSync.exe`)** | **`~1.12 MB`** (self-contained, 27 embedded resources) | — | — |
| **Closed / Scheduled Idle Mode** | 0 background processes | **`0.0 MB`** | **`0.00%`** |
| **Live Persistent Explorer Drive (`G:` Online Only Idle)** | Active in Explorer while app closed | **`31.3 MB`** | **`0.00%`** |
| **Raw Unfiltered Repo Scan (`2,800` files / `39.06 MB`)** | **`5.181 sec`** | **`52.1 MB`** | Low |
| **Filtered Repo Scan (`node_modules`/`.venv` skipped)** | **`0.680 sec`** (**`2,400` junk files / `37.5 MB` = 96.0% of repo size**, 85.7% of files skipped — **7.6x faster**) | **`51.4 MB`** | Low |
| **Filtered Safe-Archive Sync (`400` clean files)** | **`4.834 sec`** | **`56.3 MB`** | Low |
| **Overwrite-Protected Safe Restore (`--backup-dir`)** | **`0.790 sec`** | **`52.8 MB`** | Low |
| **Headless CLI (`AlphaCloudSync.exe -Action Status`)** | **`ExitCode: 0`** | Low | — |

See full methodology in [`BENCHMARKS.md`](BENCHMARKS.md).

---

## Get Started in 30 Seconds (Windows 10 / 11 x64)

### Option 1 — One-Line PowerShell Install (Fail-Closed SHA-256 Verified)
```powershell
irm https://raw.githubusercontent.com/AlphaAlgos/AlphaCloudSync/main/install.ps1 | iex
```
Downloads the latest release to `%LOCALAPPDATA%\AlphaCloudSync\app\`, **enforces Fail-Closed SHA-256 verification** (immediately aborts & deletes the download if `SHA256SUMS.txt` is missing, malformed, or mismatched), creates Desktop & Start Menu shortcuts, and adds `AlphaCloudSync` to your user `PATH`.

### Option 2 — Portable `.exe`
1. Download **`AlphaCloudSync.exe`** and **`SHA256SUMS.txt`** from [GitHub Releases](https://github.com/AlphaAlgos/AlphaCloudSync/releases).
2. Verify the hash against `SHA256SUMS.txt`:
   ```powershell
   Get-FileHash .\AlphaCloudSync.exe -Algorithm SHA256
   ```
3. Double-click **`AlphaCloudSync.exe`** — if `rclone` is not installed yet, click **Yes** in the first-run setup to install it automatically (verified with official `SHA256SUMS`).

### Option 3 — Build Locally from Source (2 Seconds)
```powershell
git clone https://github.com/AlphaAlgos/AlphaCloudSync.git
cd AlphaCloudSync
.\build\build-release.ps1
# Output: .\dist\AlphaCloudSync.exe (27 embedded resources) + .\dist\SHA256SUMS.txt
```

### Option 4 — WinGet Package Manifest
A WinGet singleton manifest is included at [`winget/AlphaAlgorithms.AlphaCloudSync.yaml`](winget/AlphaAlgorithms.AlphaCloudSync.yaml) (`PackageIdentifier: AlphaAlgorithms.AlphaCloudSync`). Once published to the official WinGet community repository, you can install via:
```powershell
winget install AlphaAlgorithms.AlphaCloudSync
```

---

## Verify Everything Yourself (`23 / 23` Automated Tests & Benchmarks)

```powershell
# Run all 23 automated release-gate, SHA-256 fail-closed, filter-aware data-loss guard, mount PID guard, modular provider, 336-key i18n, real rclone & WinFsp tests
powershell -NoProfile -ExecutionPolicy Bypass -File .\tests\run-tests.ps1

# Run the reproducible performance & RAM benchmark harness
powershell -NoProfile -ExecutionPolicy Bypass -File .\benchmarks\run-benchmarks.ps1
```

> **Verification Scope & Modular v1.1+ Roadmap:** Today's **`23/23`** automated suite (`T01`–`T23`, with explicit `PASS` / `SKIP` / `FAIL` reporting & Windows GitHub Actions CI) validates PowerShell AST across all 18 scripts, Standard UTF-8 No-BOM, 7-language × **336-key** parity, 5/5 brand assets, Fail-Closed SHA-256 rejection, non-destructive build guard, 12h/overall-%/6-screen WorkArea unit tests, real `rclone` Safe Archive / Copy-Only / Strict Mirror / Safe Restore / Skip Rules, privacy guard, simultaneous dual-drive Explorer mounting (`T13`), 1-line volume labels & `:combine:` Unified mounting (`T14`), Synced Folder Badges + `.git/info/exclude` + zero CMD flashes (`T15`), filter-aware empty-source protection (`T16`), fail-closed rules/prefs/mutex/settings (`T17`–`T20`), mount PID identity guard (`T21`), fast `--files-from` auto-upload filter (`T22`), and modular architecture + extensible Cloud Provider Registry + Global Tray Pause + Explorer Right-Click Context Menu (`T23`). Because `src/modules/Providers/` is already modular, **v1.1+ milestones** will plug in `OneDrive`, `Dropbox`, `S3 / Cloudflare R2`, and `Nextcloud` provider modules cleanly.

---

## CLI & Task Scheduler Automation

```powershell
AlphaCloudSync.exe -Action Status
AlphaCloudSync.exe -Action DryRun
AlphaCloudSync.exe -Action Sync -RemoteName gdrive
AlphaCloudSync.exe -Action Sync -FolderName "MyProject"
AlphaCloudSync.exe -Action Restore -FolderName "MyProject"
AlphaCloudSync.exe -Action Mount -RemoteName gdrive -DriveLetter G:
AlphaCloudSync.exe -Action Unmount -RemoteName gdrive -DriveLetter G:
AlphaCloudSync.exe -Action Auth -RemoteName gdrive
AlphaCloudSync.exe --minimized
AlphaCloudSync.exe -AutoStartSync
```

Need a complete walkthrough of every view and setting? Read the **[Complete User Guide (`docs/USER_GUIDE.md`)](docs/USER_GUIDE.md)**.

---

## Honest Limitations & Security Model

We believe open-source tools earn trust through complete transparency:

1. **Google OAuth Loopback (`127.0.0.1`):** Sign-in uses `rclone`'s local `127.0.0.1` OAuth loopback flow directly between your browser, `rclone`, and Google (your refresh token stays strictly local in `%APPDATA%\rclone\rclone.conf`). If you use the default shared `rclone` OAuth client rather than your own **Faster Mode** Google Cloud Desktop Client ID, Google may apply shared rate limits or display a standard third-party/unverified app notice during consent.
2. **Windows SmartScreen on Unsigned Open-Source Builds:** Community releases of `AlphaCloudSync.exe` are currently **unsigned** (no commercial EV code-signing certificate yet), so Windows Defender SmartScreen may show *"Windows protected your PC"* on first launch. Click **More info → Run anyway** after verifying `SHA256SUMS.txt`, or compile locally with `.\build\build-release.ps1` (which also supports optional Authenticode signing via `-SignCertThumbprint`). See [`SECURITY.md`](SECURITY.md).
3. **Real-Time Auto-Sync vs Task Scheduler:** **Real-Time Auto-Sync** (`FileSystemWatcher` with 4s debounce) monitors the active account's enabled folders only while AlphaCloudSync is running (including minimized in the System Tray). If you close AlphaCloudSync completely for `0.0 MB` RAM, use the **Windows Task Scheduler** option instead so backups still run on schedule.
4. **Unified Drive Quota Semantics:** Mounting multiple Google accounts inside **Single Unified Drive (`★ G:`)** combines their folders cleanly into one Explorer drive (`Google Drive Unified`) via `rclone :combine:`, while each Google account retains its own separate Google Drive storage quota on Google's servers.
5. **Cloud Storage Scope in v1.0:** Version 1.0 focuses specifically on **Google Drive**; additional providers (OneDrive, Dropbox, S3/R2, Nextcloud) are planned for v1.1+.

---

## Frequently Asked Questions

<details>
<summary><strong>If I pause or close the app mid-upload, does it start over from zero?</strong></summary>

No! When you resume, `rclone` compares file sizes, timestamps, and Google Drive MD5 checksums. Already-uploaded files are skipped immediately, and only remaining or modified files are uploaded.
</details>

<details>
<summary><strong>What is the difference between Unified Drive (★ G:) and Standalone Drives?</strong></summary>

**Unified Drive (`★ G:`)** groups selected accounts into a single Windows Explorer drive labeled `Google Drive Unified` with each account as a subfolder (`alice.dev`, `work-drive`, etc.). **Standalone Drives** give each account its own dedicated Explorer partition (`G:`, `H:`, `I:`...) labeled `Drive - <Account>`. You can even mix both (**Hybrid Mode**) by keeping some accounts in `★ G:` while giving another account its own dedicated drive letter.
</details>

<details>
<summary><strong>Do Synced Folder Badges touch my Git repositories or upload desktop.ini?</strong></summary>

No. AlphaCloudSync automatically adds `desktop.ini` to `.git/info/exclude` (local Git ignore — never edits tracked `.gitignore`), refuses to overwrite any pre-existing custom `desktop.ini` you created yourself, and automatically passes `--exclude "desktop.ini"` so badge files are never uploaded to Google Drive.
</details>

<details>
<summary><strong>Will my mounted Windows drives stop working if I close AlphaCloudSync?</strong></summary>

No. Mounted Explorer drives stay active even after exiting AlphaCloudSync completely, using ~31.3 MB RAM and 0.00% idle CPU. Reopen AlphaCloudSync anytime and it reconnects seamlessly.
</details>

<details>
<summary><strong>Does AlphaCloudSync collect telemetry or see my Google password?</strong></summary>

Never. AlphaCloudSync has **zero telemetry** and zero third-party servers. Google OAuth runs directly between your browser, `rclone`, and Google — your refresh token stays strictly local in `%APPDATA%\rclone\rclone.conf`.
</details>

---

## Support & Sponsorship (Optional)

AlphaCloudSync is **100% free and MIT-licensed open-source software** with no paywalls or locked features. If AlphaCloudSync saves you time or SSD space and you would like to help cover future **EV Code-Signing Certificates** (to eliminate Windows SmartScreen prompts) and multi-cloud testing, you can star the repository or sponsor **Alpha Algorithms Company** once GitHub Sponsors is enabled on [`AlphaAlgos`](https://github.com/AlphaAlgos) *(optional sponsorship link placeholder — coming soon via GitHub Sponsors)*.

---

## Privacy, Trademark & License
- **Zero Telemetry:** No analytics, no tracking, no crash uploads. Everything stays 100% on your PC.
- **Independent Open-Source Project:** Built by **Alpha Algorithms Company** to work with Google Drive via Rclone & WinFsp. Not affiliated with or endorsed by Google LLC. Google Drive is a trademark of Google LLC.
- **License:** [MIT License](LICENSE).
