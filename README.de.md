<p align="center">
  <img src="assets/AlphaCloudSync-wordmark.png" alt="AlphaCloudSync — Sichern. Synchronisieren. Wiederherstellen." width="560"/>
</p>

<h3 align="center">Ein leichtgewichtiger, schneller und transparenter Cloud-Speicher-Kern für Windows — beginnend mit Google Drive.</h3>

<p align="center">
  Ein portables Open-Source-Windows-Studio (gestartet mit <strong>Google Drive</strong> in v1.0, aufgebaut auf einer modularen <strong>Provider-Registry</strong> + <a href="https://rclone.org/">rclone</a> &amp; <a href="https://winfsp.dev/">WinFsp</a> für künftige Anbieter) — mit schlanken Ordner-Backups, einem <strong>Hybriden Hub aus Vereintem (<code>★ G:</code>) &amp; Einzelnen Explorer-Laufwerken</strong>, Null-RAM-Ordnerabzeichen &amp; Kontextmenü, Echtzeit-Auto-Sync, globaler Bandbreiten-Pause, überschreibungsgeschützter Wiederherstellung, kontospezifischen Ausschlussregeln, 100% <strong>Obsidian Dark Fluent UI</strong> und frei verschiebbarer <strong>Dynamischer Cloud-Insel</strong>.<br/>
  Entwickelt von <a href="https://github.com/AlphaAlgos">Alpha Algorithms Company</a>.
</p>

<p align="center">
  <a href="LICENSE"><img src="https://img.shields.io/badge/License-MIT-38BDF8.svg" alt="MIT-Lizenz"/></a>
  <img src="https://img.shields.io/badge/Windows-10%20%2F%2011%20(x64)-10B981.svg" alt="Windows 10/11 x64"/>
  <img src="https://img.shields.io/badge/Portable%20EXE-~1.16%20MB-6366F1.svg" alt="Portable EXE"/>
  <img src="https://img.shields.io/badge/Sprachen-7%20(345%20Schlüssel%20%2B%20RTL)-F59E0B.svg" alt="7 Sprachen (345 Schlüssel)"/>
  <img src="https://img.shields.io/badge/Automatisierte%20Tests-25%2F25%20PASS-22C55E.svg" alt="25/25 Tests Bestanden"/>
  <img src="https://img.shields.io/badge/Telemetrie-Null-4ADE80.svg" alt="Null Telemetrie"/>
</p>

<p align="center">
  <a href="README.md">English</a> · <a href="README.ar.md">العربية</a> · <a href="README.es.md">Español</a> · <a href="README.fr.md">Français</a> · <strong>Deutsch</strong> · <a href="README.zh.md">中文 (简体)</a> · <a href="README.id.md">Bahasa Indonesia</a>
</p>

<p align="center">
  <a href="docs/USER_GUIDE.md">Benutzerhandbuch</a> · <a href="BENCHMARKS.md">Benchmarks</a> · <a href="CHANGELOG.md">Changelog</a> · <a href="SECURITY.md">Sicherheit</a> · <a href="CONTRIBUTING.md">Mitwirken</a>
</p>

---

## Warum von der offiziellen Google Drive Desktop-App wechseln?

| Alltägliches Problem | Offizielles Google Drive | AlphaCloudSync v1.0 |
| :--- | :--- | :--- |
| **Windows neu installiert?** | Erzeugt **`My Computer (1)`** und lädt dutzende GB neu hoch | **Keine Duplikate** — verbindet direkt mit `My Drive` oder festem `My Computer`-Namen |
| **RAM im Hintergrund** | Dauerhaft laufende Hintergrundprozesse | **`0.0 MB` RAM im geschlossenen Zustand** · **`49.6 MB` RAM** mit aktivem `G:`-Laufwerk *(siehe [`BENCHMARKS.md`](BENCHMARKS.md))* |
| **Upload von Caches & Datenmüll** | Lädt `node_modules`, `.venv`, `.gradle`, `*.tmp` hoch | **Kontospezifische Ausschlussregeln (`presets/`)** überspringen Build-/Medien-Müll und zeigen gesparte GB |
| **Versehentliches lokales Löschen** | Stiller Sync kann Cloud-Dateien löschen | **3 klare Löschrichtlinien** (`Sicheres Archiv`, `Nur kopieren`, `Exakter Spiegel`) + Leerquellen-Schutz + `--max-delete 200` |
| **Wiederherstellung auf den PC** | Gefahr des stillen Überschreibens neuer lokaler Dateien | **Sichere Wiederherstellung** — erst Vorschau ohne Änderungen + automatische lokale Sicherung in `restore-backups\` |
| **Mehrere Google-Konten** | Eingeschränkte Multi-Konto-Verwaltung | **Hybrid: Vereintes Laufwerk (`★ G:`) + Einzellaufwerke (`D:`–`Z:`)** — kombiniert in `AlphaCloudSync` oder eigener Laufwerksbuchstabe (`Drive - <Konto>`) |
| **Ordner-Icons & Kontextmenü** | Schwere Explorer-DLL-Erweiterungen | **Null-RAM Ordnerabzeichen, Laufwerks-Icons & Rechtsklickmenü** via `desktop.ini` & `HKCU` |
| **Automatisierung & Bandbreite** | Erzwingt dauerhaften Hintergrund-Sync | **Freie Wahl:** **Schneller Auto-Sync** (`--files-from`, `4s`) + **1-Klick-Globale Pause** **ODER** **Windows COM-Aufgabenplanung** (`0.0 MB` RAM) |
| **Fußabdruck & Transparenz** | Schwerer Installer + stille Updater | **1 portable `~1.16 MB` EXE** · Fail-Closed SHA-256 · Keine CMD-Fenster · Null Telemetrie |

---

## Funktionsübersicht (`src/AlphaCloudSync.ps1` & `src/modules/`)

### 1. Hybrider Laufwerks-Hub: Vereint (`★ G:`) + Einzellaufwerke (`D:` – `Z:`)
- **Vereintes Laufwerk (`★ G:`):** Bündelt ausgewählte Konten unter dem Explorer-Namen **`AlphaCloudSync`** (`rclone mount :combine:`) mit automatischer Namens-Deduplizierung (`alice.dev`, `alice.dev (2)`).
- **Einzellaufwerke (`D:` – `Z:`) & Hybridmodus:** Kollisionsfreie Laufwerksbuchstaben mit einzeiliger Bezeichnung (**`Drive - <Konto>`**, `<= 21` Zeichen) — kombinierbar mit `★ G:`.
- **Ansicht pro Konto (`MountScope`) & Cache-Modi:** **`Nur Meine Ablage`**, **`Nur Mein PC`** oder **`Beides`**; **Nur online (`0 GB` dauerhaft auf SSD)** vs **Offline-Kopie** (`50G` / `720h`). Bleibt nach dem Beenden gemountet (`0.00%` Idle-CPU), inklusive stillem Explorer-Refresh und **PID-Identitätsschutz (`T21`)**.

### 2. Null-RAM Ordnerabzeichen, Laufwerks-Icons & Explorer-Kontextmenü
- Native Windows-Icons via `desktop.ini` + `SHChangeNotify`, automatischer `.git/info/exclude`-Schutz (ohne `.gitignore` zu verändern), nicht-destruktive Prüfung und automatischer Ausschluss von `desktop.ini`.
- **Explorer-Rechtsklickmenü (`HKCU`):** Rechtsklick auf jeden Ordner → **AlphaCloudSync** → **`Ordner hinzufügen...`**, **`Jetzt synchronisieren`**, **`Nur Vorschau`** oder **`Entfernen`** — in allen 7 Sprachen, laufwerkswurzel-sicher (`"%V\."`) mit atomarer IPC-Warteschlange.

### 3. Obsidian Dark Fluent UI, Sofortstart & Null CMD-Fenster
- **~30ms 5-Stufen-Splash-Karte, Vordergrund-Erzwingung & sequentielle Konto-Hydration:** Zeigt beim Klick sofort eine abgerundete dunkle Splash-Karte mit 5 Live-Schritten in deiner Sprache, bringt das Hauptfenster zuverlässig vor alle offenen Programme (`AllowSetForegroundWindow` + `AttachThreadInput`) und aktualisiert verbundene Konten **asynchron nacheinander** (aktives Konto zuerst) — flüssig auch bei 10–50 Konten.
- **Grün pulsierender Upload-Punkt** neben **Live-Aktivität** (nur bei aktivem Upload sichtbar), **0 CMD-Fenster (`T15`)** und dunkle OAuth-Bestätigungsseite (`rclone authorize --template`).

### 4. Auto-Sync, Globale Pause, Benachrichtigungen & COM-Zeitplaner
- **Schneller Auto-Sync (`--files-from`, standardmäßig AUS)** mit `4s`-Debounce, **1-Klick-Globale Pause im System Tray**, **4 granulare Benachrichtigungskategorien** (kein 0-Dateien-Spam) sowie **lokalunabhängiger Windows-COM-Zeitplaner (`12h AM / PM`)**.

### 5. Priorisierte Aktivitätsliste, Ausschlussregeln, Sichere Wiederherstellung & 7 Sprachen (`345` Schlüssel)
- **Priorisierte Liste:** **Wird hochgeladen** oben → **Abgeschlossen** 3,5s sichtbar dann automatisch ausgeblendet → **Warteschlange / Lösch-Sync / Umbenennung** unten (FIFO).
- **Filterbewusster Leerquellen-Schutz (`rclone lsf`)**, Fail-Closed JSON-Regeln, `--max-delete 200`, **Sichere Wiederherstellung** mit Vorschau & Backup, **Dynamische Cloud-Insel** (`~250 × 32 px`) und **7 Sprachen (`345` Schlüssel)**.

---

## Gemessene Leistung ([`benchmarks/latest-results.json`](benchmarks/latest-results.json))

Gemessen mit [`benchmarks/run-benchmarks.ps1`](benchmarks/run-benchmarks.ps1) auf **Intel Core i5-7Y57 (1.20 GHz) / 7.9 GB RAM / Windows 11 Pro**:

| Szenario | Messergebnis | Spitzen-RAM | Idle-CPU |
| :--- | :---: | :---: | :---: |
| **Portable EXE (`AlphaCloudSync.exe`)** | **`~1.16 MB`** (`1,191.5 KB`, 27 eingebettete Ressourcen) | — | — |
| **Geschlossen / Geplanter Leerlauf** | 0 Hintergrundprozesse | **`0.0 MB`** | **`0.00%`** |
| **Persistentes Laufwerk (`G:` Nur online)** | Aktiv bei geschlossener App | **`49.6 MB`** | **`0.00%`** |
| **Ungefilterter Scan (`2,800` Dateien / `39.06 MB`)** | **`7.440 s`** | **`50.2 MB`** | Niedrig |
| **Gefilterter Scan (`node_modules`/`.venv` übersprungen)** | **`3.509 s`** (**`2,400` Dateien / `37.5 MB` = 96.0% gespart — 2.1x schneller**) | **`49.5 MB`** | Niedrig |
| **Safe-Archive-Sync (`400` Dateien)** | **`4.113 s`** | **`54.4 MB`** | Niedrig |
| **Sichere Wiederherstellung (`--backup-dir`)** | **`0.838 s`** | **`49.2 MB`** | Niedrig |
| **Headless CLI (`AlphaCloudSync.exe -Action Status`)** | **`ExitCode: 0`** (`9.853 s`) | Niedrig | — |

---

## In 30 Sekunden starten (Windows 10 / 11 x64)

```powershell
# Option 1: 1-Zeilen-Installation per PowerShell (Fail-Closed SHA-256 geprüft)
irm https://raw.githubusercontent.com/AlphaAlgos/AlphaCloudSync/main/install.ps1 | iex

# Option 2: AlphaCloudSync.exe + SHA256SUMS.txt aus GitHub Releases herunterladen
# Option 3: Lokal in 2 Sekunden aus dem Quellcode bauen
git clone https://github.com/AlphaAlgos/AlphaCloudSync.git
cd AlphaCloudSync
.\build\build-release.ps1

# Alle 25 automatisierten Tests ausführen (T01-T25)
powershell -NoProfile -ExecutionPolicy Bypass -File .\tests\run-tests.ps1
```

## Datenschutz, Sicherheit & Lizenz
- **Null Telemetrie:** Keine Analysen oder Fremdserver; lokales OAuth (`127.0.0.1`) in `%APPDATA%\rclone\rclone.conf`.
- **Windows SmartScreen:** Community-Builds sind derzeit unsigniert; prüfe `SHA256SUMS.txt` oder kompiliere selbst. Details in [`SECURITY.md`](SECURITY.md).
- **Lizenz:** [MIT License](LICENSE) — unabhängiges Open-Source-Projekt von **Alpha Algorithms Company**, nicht verbunden mit Google LLC.
