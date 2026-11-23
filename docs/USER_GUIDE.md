# AlphaCloudSync — Complete User Guide (`v1.0.0`)

Welcome! This guide walks you step-by-step through every screen, setting, safety guard, and workflow in **AlphaCloudSync v1.0.0**, using plain everyday language backed strictly by the actual Windows studio implementation.

---

## Table of Contents
1. [First Launch & Silent Google Sign-In](#1-first-launch--silent-google-sign-in)
2. [Navigating the 100% Obsidian Dark Fluent Studio](#2-navigating-the-100-obsidian-dark-fluent-studio)
3. [Adding Folders (Zero `My Computer (1)` Duplication)](#3-adding-folders-zero-my-computer-1-duplication)
4. [Delete Policies & Data-Loss Safety Guards](#4-delete-policies--data-loss-safety-guards)
5. [Per-Account Skip Rules & Filter Savings](#5-per-account-skip-rules--filter-savings)
6. [Hybrid Unified (`★ G:`) and Standalone Drives & Storage Manager](#6-hybrid-unified--g-and-standalone-drives--storage-manager)
7. [Zero-RAM Folder Badges, Drive Icons & Explorer Right-Click Menu](#7-zero-ram-folder-badges-drive-icons--explorer-right-click-menu)
8. [Automation, Global Bandwidth Pause & Windows Notifications](#8-automation-global-bandwidth-pause--windows-notifications)
9. [Freely Draggable Dynamic Cloud Island + Quick-Snap](#9-freely-draggable-dynamic-cloud-island--quick-snap)
10. [Overwrite-Protected Safe Restore](#10-overwrite-protected-safe-restore)
11. [Upload Speed Modes & Faster Mode (Personal Google Cloud Key)](#11-upload-speed-modes--faster-mode-personal-google-cloud-key)
12. [CLI & Headless Automation](#12-cli--headless-automation)
13. [Troubleshooting & FAQ](#13-troubleshooting--faq)

---

## 1. First Launch & Silent Google Sign-In

1. Run **`AlphaCloudSync.exe`** (or launch it from the Start Menu / Desktop shortcut if installed via `install.ps1`).
2. **First-Time Engine Setup:** If `rclone` is not installed on your PC yet, a dark prompt asks to install it automatically. Click **Yes** — AlphaCloudSync installs `rclone` (via WinGet or official GitHub `SHA256SUMS`-verified download) into `%LOCALAPPDATA%\AlphaCloudSync\bin\rclone.exe`.
3. **Choose Language:** Open **Settings (⚙)** in the sidebar → **General & Interface** → **Interface Language** to pick any of the **7 built-in languages** (`English`, `العربية` with full RTL/BiDi, `Español`, `Français`, `Deutsch`, `中文 (简体)`, `Bahasa Indonesia`).
4. **Silent OAuth Sign-In (Zero CMD Windows):**
   - Open **Settings (⚙) → Accounts & Connections** and click **Sign In with Google** (or **`+ Add Account`**).
   - When adding another account, a dark modal asks for an **optional display name (empty by default)**:
     - **Leave it empty (Recommended):** AlphaCloudSync automatically assigns a unique internal profile ID (`gdrive`, `gdrive-2`, `gdrive-3`...) and automatically displays your Google email username (e.g., `alice.dev` from `alice.dev@gmail.com`).
     - **Or type a friendly label** (e.g., `work-drive`) to name it immediately.
   - Click **Continue to Google Sign-In**. AlphaCloudSync opens your default browser for Google OAuth on `127.0.0.1` loopback while showing a **dark "Waiting for Google Sign-In" modal** (with a Cancel button and zero console/CMD windows).
   - Once you approve access in your browser, the wait modal closes automatically and displays the dark **"Connected Successfully"** dialog. Your account turns green in the sidebar and shows your live Google Drive quota.

---

## 2. Navigating the 100% Obsidian Dark Fluent Studio

AlphaCloudSync uses a calm 2-column desktop studio with custom-templated dark controls (`ComboBox`, `CheckBox`, `TextBox`, `DatePicker`, `ContextMenu`, `ToolTip`, `ScrollBar`, `DataGrid`, and dark System Tray menu):

- **38px Custom `WindowChrome` Title Bar:** Drag anywhere to move, double-click to Maximize/Restore with symmetric borders, resize smoothly from any edge or corner, snap via Windows Aero Snap, or click **Hide to Tray** (`↓`) to tuck the app into the System Tray (`Left-click` or `Double-click` the tray icon, or re-launch the EXE, to pop it right back up).
- **248px Dark Sidebar:**
  - **Active Account Switcher:** Switch between connected Google accounts (`CmbAccountProfile`).
  - **4 Focused Views:**
    1. **Backup Folders** (Home view)
    2. **Drive & Storage** (Quota, Trash/Archive manager, Hybrid Multi-Account Drives Hub)
    3. **Live Activity & Log** (Real-time per-file upload table + draggable splitter + live console log)
    4. **Settings (⚙)** (4 organized cards: *Accounts & Connections*, *General & Interface*, *Schedule & Skip Rules*, *Sync Safety & Performance*)
  - **Accounts Overview (`ListSidebarAccounts`):** Scrollable live cards for every connected account showing status dot, drive badge (**`★ G:`** in gold for Unified members, **`H:`** in cyan for Standalone drives), quota bar, and live sync progress bar when syncing. Click any card to switch to that account.
  - **Quick Explorer Drive Widget:** Pick a drive letter (or `★ G:` Unified), mode (`Online Only`, `Offline Copy`, or `Show in Unified Drive`), and Drive View (`My Drive Only`, `My Computer Only`, `My Drive + Computer`), then toggle **Show Drive / Hide Drive**.
  - **Mini Storage Bar:** Shows the active account's `Used / Total (%)`.
- **Docked Bottom Sync Bar:** Always visible at the bottom across all views with **START BACKUP OF CHECKED FOLDERS**, **Preview Changes Only (No Files Changed)**, **Safe Restore from Drive**, the **Rainbow Spectrum Progress Bar (`0% → 100%`)**, file counters, transfer speed (`MB/s`), and `ETA`.

> **Per-Account Isolation:** Switching accounts cleanly isolates each account's folder list (`%APPDATA%\AlphaCloudSync\profiles\folders-<remote>.json`), **Live File Activity** feed, **Activity Log** console, progress counters, and **Skip Rules**.

---

## 3. Adding Folders (Zero `My Computer (1)` Duplication)

1. In **Backup Folders**, click **`+ Add Folder`** or **drag and drop** folders directly from Windows Explorer into the table (e.g., `C:\Users\YourName\Projects\MyApp`).
2. Choose where on Google Drive the folder should live:
   - **`My Drive` (Recommended):** syncs to `My Drive/<FolderName>`.
   - **`My Computer`:** syncs inside your fixed **PC Folder Name** (editable in **Settings → Sync Safety & Performance**; defaults to `My Computer`). Even if you reinstall Windows or switch PCs, pointing AlphaCloudSync to the same name **never** creates `My Computer (1)`.
3. **Per-Folder Controls:**
   - Check/uncheck **`Include`** (`✓`) to control which folders run during batch backups.
   - Change any row's **`Drive Path`** inline via its dropdown (`My Drive/<Folder>` vs `My Computer/<Folder>`).
   - **Double-click** any row to open the local folder in Windows Explorer.
   - **Right-click** any row for instant actions: **Back Up This Folder Now**, **Preview Changes Only**, **Safe Restore This Folder**, **Switch Location**, **Open Local Folder**, or **Remove from Backup List**.

---

## 4. Delete Policies & Data-Loss Safety Guards

Configure **When Deleted** in **Settings (⚙) → Sync Safety & Performance** (the active policy chip always displays in the bottom-right of **Backup Folders**):

| Delete Policy | Underlying Behavior | Best For |
| :--- | :--- | :--- |
| **Safe Archive (Recommended)** | `rclone sync` with `--backup-dir "<remote>:_CloudSync_Trash_Archive/<timestamp>/<path>"` | Daily backups — deleted local files are safely archived with timestamps instead of vanishing |
| **Copy Only (Never Delete)** | `rclone copy` (strictly additive) | Cold archives — new/edited files upload; nothing is ever deleted on Drive |
| **Exact Match (Mirror PC)** | `rclone sync --drive-use-trash=true` | Exact 1:1 mirror — deleted items move to Google Drive Trash |

**Built-in Safety Guards:**
- **Empty-Source Guard:** Refuses destructive sync if a local folder is missing (e.g., unplugged external SSD) or contains `0` real files.
- **Mass-Delete Cap (`--max-delete 200`):** Prevents accidental mass cloud deletions in a single sync pass.
- **Sequential Folder Processing:** Syncs checked folders strictly one at a time with isolated per-job logs so runs never collide.

---

## 5. Per-Account Skip Rules & Filter Savings

Skip Rules are stored **per account** in `account-prefs.json` and configured in **Settings (⚙) → Schedule & Skip Rules**:

1. Ensure **`Skip Rules`** is checked.
2. Choose a built-in profile from `presets/`:
   - **Developer (`presets/developer-default.json`):** skips `node_modules`, `.venv`, `venv`, `.expo`, `.next`, `.nuxt`, `.turbo`, `__pycache__`, `.pytest_cache`, `.wrangler/state`, `.wrangler/tmp`, `.gradle`, `android/build`, `android/.gradle`, `android/app/build`, `ios/Pods`, `dist`, `build`, `out`, `target`, `bin/Debug`, `obj`, `*.pyc`, `*.pyo`, `*.bak_*`, `*.tmp`, `*.temp`, `Thumbs.db`, `.DS_Store`, `desktop.ini` — while preserving your source code, configs, `.env` files, and databases.
   - **Creative & Media (`presets/creative-media.json`):** skips Adobe Premiere auto-saves/previews, `Media Cache Files`, `Peak Files`, `CacheClip`, `ProxyMedia`, `Render Cache`, `*.pek`, `*.cfa`, `*.tmp`, `*.bak`.
   - **General Backup (`presets/general-backup.json`):** skips only OS system clutter (`$RECYCLE.BIN`, `System Volume Information`, `__MACOSX`, `~$*`, `*.tmp`, `*.temp`, `Thumbs.db`, `.DS_Store`, `desktop.ini`).
   - **Custom Rules File:** click **Import Rules...** to load any `.json` rules file, or **Edit Rules** to edit the JSON inside AlphaCloudSync's dark code editor (with automatic JSON syntax validation on save).
3. Open **Drive & Storage** and click **Check Space & Folder Sizes** to measure exact clean sizes, cloud sizes, and see the green **`Saved by Filters: X MB (Y files)`** pill inside Settings.

---

## 6. Hybrid Unified (`★ G:`) and Standalone Drives & Storage Manager

Open **Drive & Storage** in the sidebar to manage both cloud space and Windows Explorer drives:

### A. Understanding Drive Layouts (Separate, Unified, or Hybrid)
Use **Windows Drive Layout** (available in both **Drive & Storage** and **Settings → General & Interface**) or customize individual rows in the **Multi-Account Windows Drives** table:

1. **Separate Drive per Account (`G:`, `H:`, `I:`...):**
   - Each account mounts as its own Windows Explorer drive letter (`D:`–`Z:`) with a clean 1-line Explorer volume label **`Drive - <Account>`** (`<= 21` chars so Windows Explorer never hides `"X TB free of Y TB"`).
   - Click **Mount All Accounts** to assign collision-free drive letters to every added account automatically, or **double-click** any single row to mount/open just that account.
2. **Single Unified Drive (`★ G:` — Combined Explorer Pool):**
   - Combines pooled accounts into one Explorer drive (default `★ G:`) labeled **`AlphaCloudSync`** via `rclone mount :combine:`.
   - Inside `G:\`, each account appears as its own folder (`alice.dev`, `work-drive`, etc. — automatically deduplicated like `alpha`, `alpha (2)` if two accounts have the same display name).
   - Note: Each Google account still keeps its own separate storage quota on Google's servers.
3. **Hybrid Mode (Unified + Standalone Simultaneously):**
   - Even when **Single Unified Drive** is selected, open the **Drive Letter** dropdown on any account row in **Multi-Account Windows Drives** (or in the sidebar Quick Drive card) and choose a dedicated letter (`H:`, `I:`...) to split that account out onto its own standalone drive while keeping all other accounts inside **`★ G:`**!
   - Clicking **Mount Unified Drive (All Accounts)** mounts the Unified pool on `★ G:` *and* mounts any accounts explicitly assigned as standalone onto their chosen letters.

### B. Per-Account Drive View & Cache Mode
- **Drive View (`MountScope`):** Choose per account in the **Drive View** column (or sidebar):
  - `My Drive Only`
  - `My Computer Only`
  - `My Drive + Computer` (mounts both folders side-by-side inside that drive)
- **Mount Mode:**
  - **Online Only (`0 GB`):** streams on demand (`--vfs-cache-mode writes`, minimal temporary write buffer in `%LOCALAPPDATA%\AlphaCloudSync\vfs-cache\` flushed automatically). No permanent offline SSD copies.
  - **Offline Copy (Local Storage):** local VFS cache (`--vfs-cache-mode full`, up to `50G` / `720h`) for offline access.
- **Persistent After Closing & Silent Explorer Auto-Refresh:** Mounted Explorer drives stay alive even if you exit AlphaCloudSync completely (`31.3 MB` RAM / `0.00%` idle CPU measured on a live `G:` drive). Mounting or unmounting refreshes open **This PC** windows silently via Windows Shell COM.
- **Double-click** any mounted row (even inside Unified Drive!) to jump straight to that account's folder in Windows Explorer, or click **Rename Account** to customize its label.

### C. Google Drive Quota & Trash Manager
- **Check Space & Folder Sizes:** Refreshes `Total`, `Used (%)`, `Free`, `Drive Trash`, and scans all folder sizes.
- **Clean Old Archive (`30d+`):** Counts files older than 30 days inside `_CloudSync_Trash_Archive`, shows the exact file count & size, and asks confirmation before removing them.
- **Empty Drive Trash:** Protected by a dark confirmation modal requiring you to type **`EMPTY`** in all caps before permanently emptying Google Drive Trash.
- **Open Drive in Browser:** Launches `https://drive.google.com/drive/my-drive`.

---

## 7. Zero-RAM Folder Badges, Drive Icons & Explorer Right-Click Menu

Enabled by default in **Settings (⚙) → General & Interface**:

- **Synced Folder Badges & Drive Icons (0.0 MB RAM):** Stamps synced local folders with a hidden/system `desktop.ini` pointing to `AlphaCloudSync-folder.ico` and registers `HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\DriveIcons\<Letter>\DefaultIcon` for mounted cloud drives, then refreshes Explorer via `SHChangeNotify`. No Explorer shell-extension DLL is injected into memory.
- **Windows Explorer Folder Right-Click Menu (`HKCU`):** Right-click any folder on your PC → **AlphaCloudSync** to **`Add Folder to Cloud Sync...`** (opens a dark modal letting you choose the exact Google account & destination), **`Sync This Folder Now`**, **`Preview Changes Only`**, or **`Remove Folder from Sync`**. Automatically updates to match your chosen UI language (all 7 languages, with proper Arabic RTL alignment) and can be toggled ON/OFF cleanly in Settings.
- **`.git/info/exclude` Protection:** Automatically walks up parent directories (including Git worktrees) to locate `.git` and appends `desktop.ini` to `.git/info/exclude` locally — keeping `git status` clean without modifying tracked `.gitignore` files.
- **Non-Destructive Guard:** If a folder already contains a `desktop.ini` not created by AlphaCloudSync (missing `; Managed by AlphaCloudSync`), AlphaCloudSync leaves your custom icon untouched.
- **Never Uploaded to Drive:** Automatically passes `--exclude "desktop.ini"` during syncs. Toggling the checkbox OFF removes all AlphaCloudSync-managed badges and drive icons cleanly.

---

## 8. Automation, Global Bandwidth Pause & Windows Notifications

You can choose either automation method—or stay 100% manual (`0.0 MB` closed RAM) — inside **Settings (⚙) → Schedule & Skip Rules**:

| Feature | Real-Time Auto-Sync (`ON/OFF`) | Windows Task Scheduler (`12h AM/PM` COM) |
| :--- | :--- | :--- |
| **Requires App Running?** | **Yes** — runs while AlphaCloudSync is open or hidden in System Tray | **No** — runs silently even when AlphaCloudSync is **completely closed (`0.0 MB` RAM)** |
| **Trigger** | Instant local file/folder create, edit, delete, or rename in active account's checked folders (fast targeted `--files-from` upload for edited files!) | Fixed schedule: **One-Time**, **Daily**, **Weekly** (selected days), or **Every Few Hours** (`1h`–`12h`) via locale-independent COM `Schedule.Service` |
| **Debounce & Ignores** | Waits **4 seconds** after changes settle; ignores `.git`, `node_modules`, `.venv`, `__pycache__`, `.vs`, `.next`, `.expo`, `desktop.ini`, `Thumbs.db`, `~$*`, `*.tmp`, `*.part`, `*.crdownload` | Runs full headless batch (`AlphaCloudSync.exe -Action Sync -RemoteName <remote>`) |
| **Notifications & Activity** | Priority-sorted Live Activity Queue + pulsing green live indicator while uploading + optional Auto-Sync toast (fires ONLY when real files changed) | Writes exit code and summary to `%APPDATA%\AlphaCloudSync\backup-health.json` + `%LOCALAPPDATA%\AlphaCloudSync\logs\` |

- **1-Click Global Bandwidth Pause (System Tray):** Right-click the AlphaCloudSync icon in the System Tray → **Pause All Syncing (Save Bandwidth)** to pause active syncs and live watching whenever you need maximum internet speed, then click **Resume Syncing** when ready.
- **Granular Notification Controls (`Settings → General & Interface`):** Control master Windows notifications plus 4 independent categories: **Manual Sync / Preview / Restore**, **Real-Time Auto-Sync** (real changes only), **Sync Errors & Warnings**, and **Virtual Drive Mount / Unmount Events**.
- **Tip:** Enable **Start with Windows (Quiet)** in **Settings → General & Interface** if you use **Real-Time Auto-Sync** so AlphaCloudSync starts silently in your System Tray (`--minimized`) at Windows login.

---

## 9. Freely Draggable Dynamic Cloud Island + Quick-Snap

1. Enable **Show Dynamic Cloud Island** in **Settings (⚙) → General & Interface** (or toggle from the System Tray right-click menu).
2. A slim translucent floating pill (`~250 × 32 px`) appears without ever stealing keyboard focus from your editor, browser, or game.
3. **Drag Anywhere:** Grab the **6-dot drag grip** (or anywhere on the pill background) to move it across single or multi-monitor setups; coordinates save automatically.
4. **Smart `220ms` Hover-to-Expand:** Rest your cursor over the pill for `220ms` to expand folder progress (`Folder 1/2`), full Rainbow Progress Bar, speed, `ETA`, and **Pause / Resume / Open / Hide** buttons.
5. **Right-Click Quick-Snap Menu:** Right-click the Island to snap instantly to **Top Center**, **Top Left**, **Top Right**, **Bottom Left**, **Bottom Right**, **Open Main Window**, or **Hide Island**.

---

## 10. Overwrite-Protected Safe Restore

1. Click **Safe Restore from Drive** on the bottom bar (or right-click a specific folder row → **Safe Restore This Folder from Drive**).
2. Review the source Google Drive paths and local destinations in the dark Safe Restore modal.
3. Click **Preview Only (No Files Changed)** first to inspect every file that would download or overwrite in **Live Activity & Log** without modifying anything on disk.
4. Click **Start Safe Restore Now** when ready. Any existing local file that differs from Drive is **automatically copied first** into `%LOCALAPPDATA%\AlphaCloudSync\restore-backups\<FolderName>\<Timestamp>\` before being replaced. (Real-Time Auto-Sync watchers are automatically paused during restore so downloaded files don't trigger a redundant upload loop.)

---

## 11. Upload Speed Modes & Faster Mode (Personal Google Cloud Key)

### Upload Speed Presets (`Settings → Sync Safety & Performance`)
- **Fast (Turbo):** `--transfers 12 --checkers 24 --drive-chunk-size 128M --drive-upload-cutoff 64M --tpslimit 10 --tpslimit-burst 20 --fast-list`
- **Balanced:** `--transfers 6 --checkers 12 --drive-chunk-size 64M --drive-upload-cutoff 32M --tpslimit 8 --fast-list`
- **Gentle (Low Bandwidth / Eco):** `--transfers 2 --checkers 4 --bwlimit 2M --drive-chunk-size 32M --fast-list`

### Faster Mode (Optional Personal Google Cloud Key)
By default, `rclone` uses a shared public OAuth client ID that Google rate-limits across all users globally. To boost upload throughput up to **5x** using your own free quota:
1. Create a free project in [Google Cloud Console](https://console.cloud.google.com/), enable the **Google Drive API**, configure the OAuth Consent Screen (External, add your own Google email under Test Users), and create an **OAuth Client ID** with application type **Desktop app**.
2. In AlphaCloudSync **Settings (⚙) → Accounts & Connections**, click **Faster Mode (Personal Key)**, paste your **Client ID** (`*.apps.googleusercontent.com`) and **Client Secret**, and click **Save & Reconnect**.
3. Complete the browser OAuth flow once — the button updates to **`Faster Mode: Active`**.

---

## 12. CLI & Headless Automation

```powershell
# Inspect configuration, authentication, mounts, schedule, and skip rules
AlphaCloudSync.exe -Action Status

# Preview changes without modifying local or cloud files
AlphaCloudSync.exe -Action DryRun

# Run headless backup for a specific account or single named folder
AlphaCloudSync.exe -Action Sync -RemoteName gdrive
AlphaCloudSync.exe -Action Sync -FolderName "MyProject"

# Headless overwrite-protected restore for a folder
AlphaCloudSync.exe -Action Restore -FolderName "MyProject"

# Mount / Unmount a standalone Explorer drive via CLI
AlphaCloudSync.exe -Action Mount -RemoteName gdrive -DriveLetter G:
AlphaCloudSync.exe -Action Unmount -RemoteName gdrive -DriveLetter G:

# Launch Google OAuth flow for a remote
AlphaCloudSync.exe -Action Auth -RemoteName gdrive

# Start GUI minimized in System Tray, or auto-start sync on launch
AlphaCloudSync.exe --minimized
AlphaCloudSync.exe -AutoStartSync
```

---

## 13. Troubleshooting & FAQ

- **Windows Defender SmartScreen says *"Windows protected your PC"*:**
  Open-source community builds are currently unsigned (no paid EV certificate yet). Verify `SHA256SUMS.txt` with `Get-FileHash .\AlphaCloudSync.exe -Algorithm SHA256`, then click **More info → Run anyway**, or compile locally via `.\build\build-release.ps1`.
- **Browser shows *"127.0.0.1 refused to connect"* or sign-in hangs:**
  Ensure you didn't close the dark **"Waiting for Google Sign-In"** modal before approving in your browser, and check that no firewall/VPN blocks local `127.0.0.1` loopback redirects. Click **Cancel** in the wait modal and try **Sign In with Google** again.
- **Virtual drive fails to mount (`WinFsp` prompt):**
  Mounting Explorer drives requires the open-source **WinFsp** driver (`C:\Program Files (x86)\WinFsp`). Accept the automatic `winget install WinFsp.WinFsp` prompt or install WinFsp manually from [winfsp.dev](https://winfsp.dev/).
- **Folder badge icon did not update immediately in Windows Explorer:**
  Windows Explorer caches folder icons briefly. Press `F5` in Explorer or toggle **Show AlphaCloudSync icon on synced folders & drives** OFF and back ON in **Settings → General & Interface**. Note that folders with an existing custom `desktop.ini` are intentionally left untouched.
- **Sync skipped a folder with `[GUARD] Refused to sync empty folder`:**
  This is the **Empty-Source Guard** protecting your Google Drive backup when a folder is empty or on a disconnected drive. Add at least one file or check the drive connection before syncing.
- **Slow speeds or `403 rateLimitExceeded` errors in Activity Log:**
  Switch **Upload Speed** from `Turbo` to `Balanced` or configure your own free **Faster Mode (Personal Key)** in **Settings → Accounts & Connections**.
