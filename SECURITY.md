# Security & Data Protection Policy

## Built-In Security Controls in AlphaCloudSync v1.0.0
1. **Zero Telemetry:** No analytics, tracking endpoints, or remote crash reporting exist anywhere in the codebase.
2. **Fail-Closed SHA-256 Verified Downloads:**
   - `install.ps1` downloads to a temporary staging file and **fails closed**: if `SHA256SUMS.txt` is missing, malformed, lacks a valid 64-character SHA-256 entry for `AlphaCloudSync.exe`, or does not match the binary hash, installation aborts immediately and deletes the downloaded file.
   - Portable `rclone` fallback downloads are verified against official GitHub release `SHA256SUMS` before extraction.
3. **Non-Destructive Build, Process & Shell Safety:**
   - `build/build-release.ps1` never force-kills running user processes; it refuses cleanly if `AlphaCloudSync` is running or the output binary is locked.
   - **Mount Process Identity Guard (`T21`):** Before terminating any tracked virtual-drive PID, `Test-IsExpectedMountProcess` verifies `Win32_Process` image name (`rclone.exe`), `mount` subcommand, exact remote/unified cache path (`vfs-cache\unified-all`), and drive letter — preventing accidental termination of unrelated processes after OS PID reuse.
   - **Fail-Closed Runtime Extraction Lock (`T19`):** `AlphaCloudSyncLauncher.cs` acquires `Local\AlphaCloudSync_ExtractLock` before extracting embedded runtime files and aborts cleanly on timeout instead of racing concurrently.
   - **Atomic Queued Context-Menu IPC (`T24`):** Windows Explorer right-click actions (`"%V\."`) pass normalized paths through atomic `.tmp` → `.json` queue files with full JSON control-character escaping and a UI reentrancy guard.
   - **Non-Destructive Folder Badges:** `Set-SyncedFolderBadge` refuses to overwrite any existing `desktop.ini` not tagged with `; Managed by AlphaCloudSync`, automatically adds `desktop.ini` to `.git/info/exclude` (including Git worktrees, never modifies tracked `.gitignore`), and passes `--exclude "desktop.ini"` during cloud syncs.
   - **Zero CMD Shell Invocation:** Process orchestration uses `CreateNoWindow = $true` / `-WindowStyle Hidden` with zero `cmd /c` calls (`T15`).
4. **Command-Injection Prevention:** JSON exclusion patterns are validated (rejecting newlines, quotes, and leading switch hyphens) and written to a sanitized `--exclude-from` filter file rather than concatenated into raw shell strings. Targeted fast auto-uploads filter locally via `Test-RelPathExcludedByRules` (strictly matching `dir/**` only on directory segments, `T22`/`T24`) and fall back to full sync when complex rclone patterns or comment-prefixed filenames appear.
5. **Data-Loss Guards:**
   - **Filter-Aware Empty-Source Guard:** Uses `rclone lsf --recursive --files-only` with the exact active exclusion flags before any sync. If no included files remain, or enumeration fails, the job is blocked and remote data is left untouched. Missing, malformed, or deleted custom exclusion rules, corrupt account-preference data, and corrupt global settings also block sync instead of silently disabling filters or switching to a different bundled preset.
   - **Delete Cap:** Applies `--max-delete 200` on destructive sync runs.
   - **Overwrite-Protected Safe Restore:** Automatically copies any local file about to be overwritten during Restore into `%LOCALAPPDATA%\AlphaCloudSync\restore-backups\`.
   - **Drive Trash Confirmation:** Emptying Google Drive Trash requires explicit confirmation by typing `EMPTY`.
6. **Authenticode & SmartScreen Transparency:**
   - Community open-source releases of `AlphaCloudSync.exe` are currently **unsigned** (no commercial EV code-signing certificate yet), which may trigger Windows SmartScreen on first launch.
   - Users can independently verify binary integrity via `SHA256SUMS.txt` or build locally from source via `.\build\build-release.ps1`.
   - Maintainers with a code-signing certificate can sign release builds via `.\build\build-release.ps1 -SignCertThumbprint <THUMBPRINT>` (or setting `ALPHACLOUDSYNC_CERT_THUMBPRINT`), which invokes `signtool.exe` with SHA-256 and RFC 3161 timestamping.
7. **Local Credentials & Loopback OAuth Only:**
   - Google OAuth runs via `rclone`'s local `127.0.0.1` loopback redirect directly between your browser, `rclone`, and Google (served with a local Obsidian Dark HTML confirmation template).
   - OAuth refresh tokens remain strictly inside your local `rclone.conf` under `%APPDATA%\rclone\` and are never transmitted to any third-party server.
   - Optional **Real-Time Auto-Sync** uses a local-only `.NET FileSystemWatcher` (`AlphaFolderWatchHub`) in-process without installing background Windows services.

## Automated Security Verification
Run `powershell -NoProfile -ExecutionPolicy Bypass -File .\tests\run-tests.ps1` to execute all **24** automated checks (`T01`–`T24`) covering Fail-Closed SHA-256 rejection, filter-aware empty-source protection, fail-closed exclusion-rule/account-preference/global-settings handling, runtime extraction mutex safety, mount PID identity & reuse protection, fast `--files-from` local exclusion safety, atomic IPC queue & drive-root quoting, non-destructive build guard, Safe Archive/Restore overwrite protection, `.git/info/exclude` badge safety, zero CMD invocations, and zero privacy leaks.

## Reporting a Vulnerability
Please open a private security advisory on GitHub (`AlphaAlgos/AlphaCloudSync/security/advisories/new`) rather than posting sensitive details in public issues.
