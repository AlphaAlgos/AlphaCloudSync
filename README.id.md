<p align="center">
  <img src="assets/AlphaCloudSync-wordmark.png" alt="AlphaCloudSync — Cadangkan. Sinkronkan. Pulihkan." width="560"/>
</p>

<h3 align="center">Inti kontrol penyimpanan cloud yang ringan, cepat, dan transparan untuk Windows — dimulai dengan Google Drive.</h3>

<p align="center">
  Studio desktop Windows portabel &amp; sumber terbuka (dimulai dengan <strong>Google Drive</strong> pada v1.0, dibangun di atas <strong>Registri Penyedia Modular</strong> + <a href="https://rclone.org/">rclone</a> &amp; <a href="https://winfsp.dev/">WinFsp</a> siap untuk penyedia lain) — menghadirkan pencadangan tanpa beban, <strong>Hub Drive Hibrida Terpadu (<code>★ G:</code>) + Mandiri di Windows Explorer</strong>, lencana folder &amp; menu klik kanan tanpa RAM, Sinkronisasi Otomatis Real-Time, Jeda Global satu klik, Pemulihan Aman anti-timpa, aturan pengecualian per akun, antarmuka <strong>Obsidian Dark Fluent</strong> 100% gelap, serta <strong>Pulau Cloud Dinamis</strong> yang bebas digeser.<br/>
  Dikembangkan oleh <a href="https://github.com/AlphaAlgos">Alpha Algorithms Company</a>.
</p>

<p align="center">
  <a href="LICENSE"><img src="https://img.shields.io/badge/License-MIT-38BDF8.svg" alt="Lisensi MIT"/></a>
  <img src="https://img.shields.io/badge/Windows-10%20%2F%2011%20(x64)-10B981.svg" alt="Windows 10/11 x64"/>
  <img src="https://img.shields.io/badge/Portable%20EXE-~1.16%20MB-6366F1.svg" alt="EXE Portabel"/>
  <img src="https://img.shields.io/badge/Bahasa-7%20(345%20Kunci%20%2B%20RTL)-F59E0B.svg" alt="7 Bahasa (345 Kunci)"/>
  <img src="https://img.shields.io/badge/Tes%20Otomatis-25%2F25%20PASS-22C55E.svg" alt="25/25 Tes Lulus"/>
  <img src="https://img.shields.io/badge/Telemetri-Nol-4ADE80.svg" alt="Nol Telemetri"/>
</p>

<p align="center">
  <a href="README.md">English</a> · <a href="README.ar.md">العربية</a> · <a href="README.es.md">Español</a> · <a href="README.fr.md">Français</a> · <a href="README.de.md">Deutsch</a> · <a href="README.zh.md">中文 (简体)</a> · <strong>Bahasa Indonesia</strong>
</p>

<p align="center">
  <a href="docs/USER_GUIDE.md">Panduan Pengguna</a> · <a href="BENCHMARKS.md">Benchmark</a> · <a href="CHANGELOG.md">Log Perubahan</a> · <a href="SECURITY.md">Keamanan</a> · <a href="CONTRIBUTING.md">Kontribusi</a>
</p>

---

## Mengapa beralih dari Google Drive for Desktop resmi?

| Kendala sehari-hari | Google Drive for Desktop resmi | AlphaCloudSync v1.0 |
| :--- | :--- | :--- |
| **Instal ulang Windows?** | Membuat **`My Computer (1)`** dan mengunggah ulang puluhan GB dari awal | **Nol duplikasi** — langsung terhubung ke `My Drive` atau nama `My Computer` tetap |
| **Pemakaian RAM latar belakang** | Proses selalu aktif di latar belakang | **`0.0 MB` RAM saat ditutup** · **`49.6 MB` RAM** terukur dengan drive `G:` terpasang *(lihat [`BENCHMARKS.md`](BENCHMARKS.md))* |
| **Mengunggah cache & file sampah** | Mengunggah `node_modules`, `.venv`, `.gradle`, `*.tmp` | **Aturan Pengecualian per akun (`presets/`)** melewati file sampah otomatis & menampilkan GB yang dihemat |
| **Penghapusan lokal tidak sengaja** | Sinkronisasi senyap bisa menghapus file di cloud | **3 Kebijakan Hapus jelas** (`Arsip Aman`, `Salin Saja`, `Cermin Tepat`) + penjaga sumber kosong + `--max-delete 200` |
| **Memulihkan file ke PC** | Risiko menimpa suntingan lokal terbaru | **Pemulihan Aman** — pratinjau dulu tanpa mengubah file + cadangan otomatis lokal di `restore-backups\` |
| **Banyak akun Google** | Pengaturan multi-akun terbatas | **Hibrida: Drive Terpadu (`★ G:`) + Drive Mandiri (`D:`–`Z:`)** — gabungkan di `AlphaCloudSync` atau pisahkan ke huruf drive sendiri (`Drive - <Akun>`) |
| **Lencana & menu Explorer** | Ekstensi DLL Explorer yang berat | **Lencana folder, ikon drive & menu klik kanan tanpa RAM** lewat `desktop.ini` & `HKCU` |
| **Otomatisasi & bandwidth** | Memaksa sinkronisasi latar belakang permanen | **Pilihan Anda:** **Auto-Sync cepat** (`--files-from`, `4d`) + **Jeda Global 1 klik** **ATAU** **Penjadwal Windows COM** (`0.0 MB` saat ditutup) |
| **Ukuran & transparansi** | Pemasang berat + pembaru tersembunyi | **1 EXE portabel `~1.16 MB`** · Verifikasi SHA-256 Fail-Closed · Nol jendela CMD · Nol telemetri |

---

## Fitur Lengkap (`src/AlphaCloudSync.ps1` & `src/modules/`)

### 1. Hub Drive Hibrida: Terpadu (`★ G:`) + Mandiri (`D:` – `Z:`)
- **Drive Terpadu (`★ G:`):** Menggabungkan akun pilihan ke satu drive Windows Explorer berlabel **`AlphaCloudSync`** (`rclone mount :combine:`), dengan deduplikasi nama otomatis (`alice.dev`, `alice.dev (2)`).
- **Drive Mandiri (`D:` – `Z:`) & Mode Hibrida:** Huruf drive bebas bentrok dengan label 1 baris (**`Drive - <Akun>`**, `<= 21` karakter) — dapat digabungkan dengan `★ G:`.
- **Tampilan per Akun (`MountScope`) & Mode Cache:** Pilih **`Hanya Drive Saya`**, **`Hanya Komputer`**, atau **`Keduanya`**; **Hanya Online (`0 GB` SSD permanen)** vs **Salinan Offline** (`50G` / `720j`). Tetap terpasang meski aplikasi ditutup (`0.00%` CPU) dengan penyegaran Explorer senyap & **Penjaga Identitas PID (`T21`)**.

### 2. Lencana Folder, Ikon Drive & Menu Klik Kanan Tanpa RAM
- Ikon Windows asli via `desktop.ini` + `SHChangeNotify`, perlindungan otomatis `.git/info/exclude` (tanpa mengubah `.gitignore`), penjaga non-destruktif, dan pengecualian otomatis `desktop.ini` dari Google Drive.
- **Menu Klik Kanan Folder Windows (`HKCU`):** Klik kanan folder mana pun → **AlphaCloudSync** → **`Tambahkan ke Sinkronisasi...`** (dengan pemilih akun & tujuan), **`Sinkronkan Sekarang`**, **`Pratinjau Saja`**, atau **`Hapus`** — diterjemahkan ke 7 bahasa, aman untuk root drive (`"%V\."`) dengan antrean IPC atomik.

### 3. UI Obsidian Dark Fluent 100%, Mulai Instan & Nol Jendela CMD
- **Kartu Splash 5 Tahap (~30ms), Tampil di Depan & Hidrasi Akun Berurutan:** Kartu gelap membulat muncul seketika menampilkan 5 tahap aktif dalam bahasa pilihan Anda, memaksa jendela utama tampil paling depan di atas aplikasi terbuka (`AllowSetForegroundWindow` + `AttachThreadInput`), lalu menyegarkan akun **satu per satu secara asinkron** (akun aktif terlebih dahulu) sehingga tetap cepat meski memiliki 10–50 akun.
- **Titik hijau berdenyut** di sebelah **Aktivitas Langsung** hanya saat mengunggah aktif, **0 jendela CMD (`T15`)**, dan halaman konfirmasi OAuth gelap khusus (`rclone authorize --template`).

### 4. Auto-Sync Cepat, Jeda Global, Notifikasi & Penjadwal COM
- **Auto-Sync tertarget (`--files-from`, nonaktif secara default)** dengan jeda stabilisasi `4d`, **Jeda Global 1 klik di System Tray**, **4 kategori notifikasi independen** (nol spam saat `0` file berubah), serta **Penjadwal Tugas Windows COM (`12j AM / PM`)**.

### 5. Antrean Prioritas, Aturan Pengecualian, Pemulihan Aman & 7 Bahasa (`345` Kunci)
- **Antrean terurut otomatis:** **Mengunggah** di atas → **Selesai / Diarsipkan** tampil 3,5 detik lalu hilang otomatis → **Antrean / Sinkron Hapus / Ganti Nama** di bawah (FIFO).
- **Penjaga Sumber Kosong sadar filter (`rclone lsf`)**, aturan JSON Fail-Closed, `--max-delete 200`, **Pemulihan Aman**, **Pulau Cloud Dinamis (`~250 × 32 px`)**, dan **7 bahasa bawaan (`345` kunci identik)**.

---

## Performa Terukur ([`benchmarks/latest-results.json`](benchmarks/latest-results.json))

Diukur dengan [`benchmarks/run-benchmarks.ps1`](benchmarks/run-benchmarks.ps1) pada **Intel Core i5-7Y57 (1.20 GHz) / 7.9 GB RAM / Windows 11 Pro**:

| Skenario | Hasil Terukur | RAM Puncak | CPU Siaga |
| :--- | :---: | :---: | :---: |
| **Executable Portabel (`AlphaCloudSync.exe`)** | **`~1.16 MB`** (`1,191.5 KB`, 27 sumber daya tertanam) | — | — |
| **Ditutup / Mode Terjadwal** | 0 proses latar belakang | **`0.0 MB`** | **`0.00%`** |
| **Drive Explorer Persisten (`G:` Online)** | Aktif meski aplikasi ditutup | **`49.6 MB`** | **`0.00%`** |
| **Pemindaian Mentah (`2.800` file / `39.06 MB`)** | **`7.440 dtk`** | **`50.2 MB`** | Rendah |
| **Pemindaian Terfilter (`node_modules`/`.venv` dilewati)** | **`3.509 dtk`** (**`2.400` file sampah / `37.5 MB` = 96.0% dilewati — 2.1x lebih cepat**) | **`49.5 MB`** | Rendah |
| **Sinkronisasi Arsip Aman (`400` file)** | **`4.113 dtk`** | **`54.4 MB`** | Rendah |
| **Pemulihan Aman (`--backup-dir`)** | **`0.838 dtk`** | **`49.2 MB`** | Rendah |
| **CLI (`AlphaCloudSync.exe -Action Status`)** | **`ExitCode: 0`** (`9.853 dtk`) | Rendah | — |

---

## Mulai dalam 30 Detik (Windows 10 / 11 x64)

```powershell
# Opsi 1: Instalasi 1 baris PowerShell (Verifikasi SHA-256 Fail-Closed)
irm https://raw.githubusercontent.com/AlphaAlgos/AlphaCloudSync/main/install.ps1 | iex

# Opsi 2: Unduh AlphaCloudSync.exe + SHA256SUMS.txt dari GitHub Releases
# Opsi 3: Bangun lokal dalam 2 detik dari kode sumber
git clone https://github.com/AlphaAlgos/AlphaCloudSync.git
cd AlphaCloudSync
.\build\build-release.ps1

# Jalankan seluruh 25 tes otomatis (T01-T25)
powershell -NoProfile -ExecutionPolicy Bypass -File .\tests\run-tests.ps1
```

## Privasi, Keamanan & Lisensi
- **Nol Telemetri:** Tanpa analitik atau server pihak ketiga; token OAuth disimpan lokal di `%APPDATA%\rclone\rclone.conf`.
- **Windows SmartScreen:** Build komunitas saat ini belum ditandatangani sertifikat EV komersial; verifikasi `SHA256SUMS.txt` atau bangun dari kode sumber. Lihat [`SECURITY.md`](SECURITY.md).
- **Lisensi:** [MIT License](LICENSE) — proyek open-source independen oleh **Alpha Algorithms Company**, tidak berafiliasi dengan Google LLC.
