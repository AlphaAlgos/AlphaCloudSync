# AlphaCloudSync — Reproducible Performance & Resource Benchmarks

Every metric below was measured on real Windows 11 Pro x64 hardware (**Intel Core i5-7Y57 @ 1.20 GHz · 7.9 GB RAM · rclone v1.76.0**) using the reproducible benchmark harness included in this repository ([`benchmarks/run-benchmarks.ps1`](benchmarks/run-benchmarks.ps1)) with raw JSON output saved in [`benchmarks/latest-results.json`](benchmarks/latest-results.json).

## Reproduce on Your Own Machine

```powershell
# Run the full automated release-gate test suite (15 tests incl. simultaneous dual-mount, unified combine mount, and badges)
powershell -NoProfile -ExecutionPolicy Bypass -File .\tests\run-tests.ps1

# Run the reproducible benchmark harness (generates benchmarks/latest-results.json)
powershell -NoProfile -ExecutionPolicy Bypass -File .\benchmarks\run-benchmarks.ps1
```

## Measured Results (`AlphaCloudSync v1.0.0`)

| Benchmark Scenario | Measured Result | Peak RAM | Idle CPU | Verification |
| :--- | :---: | :---: | :---: | :--- |
| **Portable Binary (`dist/AlphaCloudSync.exe`)** | **`~1.12 MB`** (`1,144 KB`, 27 embedded modular resources in `build-release.ps1`) | — | — | Verify against `SHA256SUMS.txt` |
| **Closed / Scheduled Idle Mode** | **0 background processes** | **`0.0 MB`** | **`0.00%`** | Runs only at scheduled time via Windows Task Scheduler |
| **Persistent Explorer Drive (`G:` Online Only Idle)** | Live in Windows Explorer while GUI closed | **`31.3 MB`** | **`0.00%`** | Measured live `rclone mount` WorkingSet while idle |
| **Raw Unfiltered Repo Scan (`2,800` files / `39.06 MB`)** | **`5.181 sec`** | **`52.1 MB`** | Low | Baseline unindexed directory traversal |
| **Filtered Repo Scan (`node_modules`/`.venv` skipped)** | **`0.680 sec`** (**`2,400` junk files / `37.5 MB` skipped**) | **`51.4 MB`** | Low | **7.6x faster**; **`96.0%` of repo size** (`85.7%` of files) eliminated |
| **Filtered Safe-Archive Sync (`400` clean files)** | **`4.834 sec`** | **`56.3 MB`** | Low | Real `rclone sync --backup-dir --exclude-from` |
| **Overwrite-Protected Safe Restore (`--backup-dir`)** | **`0.790 sec`** | **`52.8 MB`** | Low | Preserves overwritten local files in `restore-backups/` |
| **Headless CLI (`AlphaCloudSync.exe -Action Status`)** | **`ExitCode: 0`** (`14.147 sec`) | Low | — | Verified runtime auto-extraction & clean exit code |

## Methodology Notes

- **Peak RAM:** Measured via `Process.PeakWorkingSet64` / `WorkingSet64` polling every 30ms during each isolated run.
- **Zero Impact on User Data:** The benchmark harness runs entirely inside an isolated `%TEMP%\acs_bench_<PID>` sandbox and removes all temporary files upon completion.
- **Fair Measurement Scope:** Only `AlphaCloudSync` is directly benchmarked in this harness (`benchmarks/latest-results.json`). We deliberately avoid publishing unverified head-to-head multipliers against third-party closed-source desktop clients. `AlphaCloudSync` consumes **0.0 MB RAM** when closed, **31.3 MB RAM** while keeping a live Explorer virtual drive mounted, **0.0 MB extra RAM** for native `desktop.ini` Synced Folder Badges, and enforces Skip Rules before touching Google Drive.
