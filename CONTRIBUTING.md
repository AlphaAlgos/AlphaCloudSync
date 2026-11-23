# Contributing to AlphaCloudSync

Thank you for helping improve **AlphaCloudSync**! Contributions of all sizes are welcome.

## Easy Ways to Contribute
1. **Add a JSON Exclusion Preset (`presets/`):**
   - Copy `presets/developer-default.json` to `presets/<your-stack>.json` (e.g., `unity-gamedev.json`, `flutter-mobile.json`, `rust-cargo.json`).
   - Save as **Standard UTF-8 (without BOM)** and verify valid JSON syntax.
2. **Add or Improve a Language (`locales/`):**
   - Copy `locales/en.json` to `locales/<iso-code>.json` (maintaining exact parity across all **340** keys).
   - Set `"rtl": true` for right-to-left languages.
   - Register the language item in `CmbLanguage` inside `src/modules/UI.ThemeAndLayout.ps1` and `build/build-release.ps1`.
3. **Add a Cloud Provider Module (`src/modules/Providers/`):**
   - Create `src/modules/Providers/Provider.<YourProvider>.ps1` and call `Register-CloudProvider` (see `Provider.GoogleDrive.ps1` and `Provider.Registry.ps1`).
   - Both `src/AlphaCloudSync.ps1` and `build/build-release.ps1` automatically discover and embed all `src/modules/**/*.ps1` files.
4. **Engine, UI, or Packaging Enhancements:**
   - Test locally by running `.\build\build-release.ps1` and verifying `.\dist\AlphaCloudSync.exe -Action Status`.
   - Run the full **24-test** release gate before opening a PR: `powershell -NoProfile -ExecutionPolicy Bypass -File .\tests\run-tests.ps1`.

## Governance Model (Open Source with Maintainer Control)
- **License:** MIT — the full source code is public, free to inspect, use, fork, and submit pull requests against.
- **Maintainer Control:** Official merges to `main`, release tags, compiled binaries, and SHA-256 checksums are exclusively reviewed, approved, and published by **Alpha Algorithms Company** maintainers.
- **Pull Requests:** All PRs must pass the Windows CI workflow (`.github/workflows/ci.yml`), preserve Standard UTF-8 (no BOM), keep all 7 locale files synchronized, and pass maintainer code review before merging.

## Code Standards
- Encoding: **Standard UTF-8 (without BOM)** across all source, JSON, and Markdown files (`T02` enforced).
- Never commit local configs, tokens, `rclone.conf`, or personal paths (`T12` enforced).
- Keep `AlphaCloudSync.ps1` PowerShell 5.1 compatible (ASCII-safe script syntax so Windows PowerShell 5.1 parses UTF-8 no-BOM cleanly; store localized strings strictly in `locales/*.json`).
