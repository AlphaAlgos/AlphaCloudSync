<p align="center">
  <img src="assets/AlphaCloudSync-wordmark.png" alt="AlphaCloudSync — Respaldo. Sincronización. Restauración." width="560"/>
</p>

<h3 align="center">Un núcleo de control ligero, rápido y transparente para almacenamiento en la nube en Windows — comenzando con Google Drive.</h3>

<p align="center">
  Un estudio portátil y de código abierto para Windows diseñado como espacio de trabajo ligero en la nube (comenzando con <strong>Google Drive</strong> en v1.0, construido sobre un <strong>Registro Modular de Proveedores</strong> + <a href="https://rclone.org/">rclone</a> y <a href="https://winfsp.dev/">WinFsp</a> listo para futuros proveedores) — que ofrece copias de seguridad sin consumo ocioso, un <strong>Centro Híbrido de Unidades Unificada (<code>★ G:</code>) + Independientes en el Explorador de Windows</strong>, insignias de carpetas y menú contextual sin consumo de RAM, sincronización automática en tiempo real, pausa global de ancho de banda, restauración segura contra sobrescrituras, reglas de exclusión por cuenta, interfaz <strong>Obsidian Dark Fluent</strong> 100% oscura y una <strong>Isla Nube Dinámica</strong> arrastrable.<br/>
  Desarrollado por <a href="https://github.com/AlphaAlgos">Alpha Algorithms Company</a>.
</p>

<p align="center">
  <a href="LICENSE"><img src="https://img.shields.io/badge/License-MIT-38BDF8.svg" alt="Licencia MIT"/></a>
  <img src="https://img.shields.io/badge/Windows-10%20%2F%2011%20(x64)-10B981.svg" alt="Windows 10/11 x64"/>
  <img src="https://img.shields.io/badge/Portable%20EXE-~1.16%20MB-6366F1.svg" alt="EXE Portátil"/>
  <img src="https://img.shields.io/badge/Idiomas-7%20(345%20Claves%20%2B%20RTL)-F59E0B.svg" alt="7 Idiomas (345 Claves)"/>
  <img src="https://img.shields.io/badge/Pruebas%20Automáticas-25%2F25%20PASS-22C55E.svg" alt="25/25 Pruebas Superadas"/>
  <img src="https://img.shields.io/badge/Telemetría-Cero-4ADE80.svg" alt="Cero Telemetría"/>
</p>

<p align="center">
  <a href="README.md">English</a> · <a href="README.ar.md">العربية</a> · <strong>Español</strong> · <a href="README.fr.md">Français</a> · <a href="README.de.md">Deutsch</a> · <a href="README.zh.md">中文 (简体)</a> · <a href="README.id.md">Bahasa Indonesia</a>
</p>

<p align="center">
  <a href="docs/USER_GUIDE.md">Guía de Usuario</a> · <a href="BENCHMARKS.md">Benchmarks</a> · <a href="CHANGELOG.md">Cambios</a> · <a href="SECURITY.md">Seguridad</a> · <a href="CONTRIBUTING.md">Contribuir</a>
</p>

---

## ¿Por qué cambiar desde Google Drive para escritorio oficial?

Si usas Google Drive en Windows, probablemente te hayas topado con varios de estos problemas diarios:

| Problema cotidiano | Google Drive oficial para escritorio | AlphaCloudSync v1.0 |
| :--- | :--- | :--- |
| **¿Reinstalaste Windows?** | Crea **`My Computer (1)`** y vuelve a subir decenas de GB desde cero | **Cero duplicación** — reconecta directo a tu `My Drive` o etiqueta fija `My Computer` |
| **Consumo de RAM en segundo plano** | Procesos residentes siempre activos | **`0.0 MB` de RAM al cerrarse** · **`49.6 MB` de RAM** medidos con la unidad `G:` montada *(ver [`BENCHMARKS.md`](BENCHMARKS.md))* |
| **Subida de cachés y archivos basura** | Sube `node_modules`, `.venv`, `.gradle`, `*.tmp` desperdiciando espacio | **Reglas de exclusión por cuenta (`presets/`)** omiten basura de desarrollo/medios y muestran el espacio ahorrado |
| **Borrado local accidental** | La sincronización silenciosa puede borrar archivos en la nube | **3 políticas claras de borrado** (`Archivo seguro`, `Solo copiar`, `Coincidencia exacta`) + guardia de origen vacío + `--max-delete 200` |
| **Restaurar archivos al PC** | Riesgo de sobrescribir cambios locales recientes | **Restauración segura** — vista previa primero sin modificar archivos + respaldo automático local de sobrescrituras |
| **Múltiples cuentas de Google** | Opciones limitadas y acopladas | **Híbrido: Unidad Unificada (`★ G:`) + Independientes (`D:`–`Z:`)** — agrupa cuentas en `AlphaCloudSync` o separa cualquiera en su propia letra (`Drive - <Cuenta>`) |
| **Indicadores y menú de carpetas** | Pesadas extensiones DLL del Explorador | **Insignias de carpetas, iconos de unidad y menú contextual sin RAM** (`Agregar / Sincronizar / Vista previa / Quitar`) vía `desktop.ini` y `HKCU` |
| **Automatización y ancho de banda** | Impone sincronización continua en segundo plano | **Tú eliges:** **Auto-Sync rápido** (`--files-from`, `4s`) + **Pausa global en 1 clic** **O** **Programador COM de Windows** (`0.0 MB` al cerrarse) |
| **Instalador y huella** | Instalador pesado + actualizadores ocultos | **1 EXE portátil `~1.16 MB`** · Verificación Fail-Closed SHA-256 · Cero ventanas CMD · Cero telemetría |

---

## Matriz completa de funciones (`src/AlphaCloudSync.ps1` y `src/modules/`)

### 1. Centro híbrido de unidades: Unificada (`★ G:`) + Independientes (`D:` – `Z:`)
Conecta cuentas ilimitadas de Google Drive (`1`, `2`, `5`, `10+`...) desde **Configuración → Cuentas y conexiones** y explóralas nativamente en el Explorador de Windows:
- **Dos modos o ambos a la vez (Modo Híbrido):**
  - **Unidad Unificada (`★ G:`):** Agrupa las cuentas elegidas en una sola unidad titulada **`AlphaCloudSync`** (`rclone mount :combine:`), mostrando cada cuenta como una carpeta con deduplicación automática (`alice.dev`, `alice.dev (2)`).
  - **Unidades Independientes (`D:` – `Z:`):** Monta cualquier cuenta individualmente o pulsa **Montar todas las cuentas** con asignación automática sin conflictos (`G:`, `H:`, `I:`...) y etiquetas de 1 línea (**`Drive - <Cuenta>`**, `<= 21` caracteres).
  - **Control híbrido por cuenta:** Incluso en modo Unificado puedes separar una cuenta específica en su propia letra (`H:`, `I:`) mientras el resto permanece en `★ G:`.
- **Vista por cuenta (`MountScope`):** Elige **`Solo Mi unidad`**, **`Solo Mi equipo`** o **`Mi unidad + Equipo`**.
- **Solo en línea (`0 GB` permanentes en SSD) vs Copia sin conexión:** Solo en línea (`--vfs-cache-mode writes`) transmite bajo demanda sin duplicar en tu SSD; Copia sin conexión (`--vfs-cache-mode full`) guarda caché local de hasta `50G` / `720h`.
- **Persistentes al cerrar y actualización silenciosa del Explorador:** Las unidades siguen activas incluso al cerrar AlphaCloudSync (`0.00%` CPU en reposo), refrescando **Este equipo** silenciosamente y protegidas por el **Guardia de identidad PID** (`T21`).

### 2. Insignias de carpetas, iconos de unidad y menú contextual sin RAM
- **Iconos nativos sin inyección DLL:** Marca carpetas sincronizadas con `AlphaCloudSync-folder.ico` mediante `desktop.ini` + `SHChangeNotify` y registra `HKCU\...\Explorer\DriveIcons` para unidades montadas.
- **Menú contextual en carpetas de Windows (`HKCU`):** Haz clic derecho en cualquier carpeta → **AlphaCloudSync** → **`Agregar carpeta a la sincronización...`** (con selector de cuenta y destino), **`Sincronizar esta carpeta ahora`**, **`Solo vista previa`** o **`Quitar de la sincronización`** — traducido en los 7 idiomas, seguro con raíces de unidad (`"%V\."`) y cola IPC atómica.
- **Protección `.git/info/exclude` y no destructiva:** Agrega `desktop.ini` a `.git/info/exclude` (sin tocar `.gitignore`), jamás sobrescribe un `desktop.ini` propio del usuario y excluye `desktop.ini` de Google Drive.

### 3. Interfaz Obsidian Dark Fluent 100%, inicio instantáneo y cero ventanas CMD
- **Inicio instantáneo en primer plano, tarjeta Splash de 5 etapas (~30ms) e hidratación secuencial:** Muestra una tarjeta oscura redondeada con 5 etapas en vivo en tu idioma al instante, trae la ventana principal siempre al frente sobre las aplicaciones abiertas (`AllowSetForegroundWindow` + `AttachThreadInput`) y actualiza cada cuenta conectada **de forma asíncrona una por una** (primero la cuenta activa) para abrir al instante incluso con 10 o 50 cuentas.
- **Indicador verde pulsante de subida:** Aparece junto a **Actividad y registro en vivo** únicamente durante subidas activas y desaparece completamente en reposo.
- **Cero ventanas CMD:** Todas las llamadas a `rclone` se ejecutan ocultas (`0` llamadas `cmd /c`, verificado en `T15`).

### 4. OAuth silencioso con página oscura de marca
- Deja el nombre opcional vacío al añadir una cuenta para generar IDs únicos (`gdrive`, `gdrive-2`...) y extraer automáticamente tu usuario de correo.
- El flujo OAuth en `127.0.0.1` sirve una **página de confirmación HTML Obsidian Dark personalizada** (`rclone authorize --template`) junto a modales oscuros de espera y confirmación.

### 5. Auto-Sync en tiempo real, Pausa global, Notificaciones y Programador COM
- **Auto-Sync rápido con `--files-from` (`OFF` por defecto):** Vigila las carpetas activas con `AlphaFolderWatchHub`, ignora rutas ruidosas (`.git`, `node_modules`, `.venv`, `*.tmp`...), espera `4s` y sube los archivos modificados en ~2 segundos.
- **Pausa global en 1 clic desde la bandeja del sistema:** Pausa sincronizaciones activas y vigilancia para liberar todo el ancho de banda y reanuda cuando quieras.
- **Notificaciones granulares:** Interruptor maestro + 4 categorías independientes (Manual/Vista previa/Restaurar, Auto-Sync solo con cambios reales, Errores y Unidades virtuales).
- **Programador de tareas COM (`12h AM / PM`):** Programa respaldos únicos, diarios, semanales o por horas (`1h`–`12h`) con `0.0 MB` de RAM cuando está cerrado.

### 6. Cola de actividad priorizada, Reglas de exclusión y Restauración segura
- **Cola ordenada automáticamente:** **Subiendo** fijado arriba → **Subido / Archivado** visible 3.5s y se limpia automáticamente (historial completo en el registro inferior) → **En cola / Sinc. eliminación / Renombrado** abajo en orden FIFO.
- **3 políticas de borrado + Guardias de seguridad:** `Archivo seguro`, `Solo copiar` y `Coincidencia exacta`, con guardia de origen vacío consciente de filtros (`rclone lsf`), reglas fail-closed y `--max-delete 200`.
- **Restauración segura:** Vista previa primero y copia automática local en `%LOCALAPPDATA%\AlphaCloudSync\restore-backups\` antes de sobrescribir archivos locales distintos.
- **Isla Nube Dinámica + 7 idiomas (`345` claves idénticas):** Cápsula flotante arrastrable (`~250 × 32 px`) con menú rápido de anclaje + soporte completo en **English · العربية (RTL) · Español · Français · Deutsch · 中文 (简体) · Bahasa Indonesia**.

---

## Arquitectura modular (`src/modules/`)

Entrada ligera de 216 líneas (`src/AlphaCloudSync.ps1`) + 13 módulos (`Core.*`, `Providers/Provider.Registry`, `Providers/Provider.GoogleDrive`, `Engine.Mount`, `Engine.Headless`, `UI.*`) autodescubiertos e incrustados en un único EXE portátil — listos para añadir módulos de **OneDrive**, **Dropbox**, **S3 / Cloudflare R2** y **Nextcloud** en `v1.1+`.

---

## Rendimiento real medido (reproducible en tu PC)

Medido con [`benchmarks/run-benchmarks.ps1`](benchmarks/run-benchmarks.ps1) en **Intel Core i5-7Y57 (1.20 GHz) / 7.9 GB RAM / Windows 11 Pro** — JSON bruto en [`benchmarks/latest-results.json`](benchmarks/latest-results.json):

| Escenario | Resultado medido | RAM pico | CPU en reposo |
| :--- | :---: | :---: | :---: |
| **Ejecutable portátil (`AlphaCloudSync.exe`)** | **`~1.16 MB`** (`1,191.5 KB`, 27 recursos integrados) | — | — |
| **Cerrado / Modo programado inactivo** | 0 procesos en segundo plano | **`0.0 MB`** | **`0.00%`** |
| **Unidad virtual persistente (`G:` Solo en línea)** | Activa en el Explorador con la app cerrada | **`49.6 MB`** | **`0.00%`** |
| **Escaneo sin filtros (`2,800` archivos / `39.06 MB`)** | **`7.440 s`** | **`50.2 MB`** | Bajo |
| **Escaneo filtrado (`node_modules`/`.venv` omitidos)** | **`3.509 s`** (**`2,400` archivos basura / `37.5 MB` = 96.0% omitido — 2.1x más rápido**) | **`49.5 MB`** | Bajo |
| **Sincronización con Archivo seguro (`400` archivos)** | **`4.113 s`** | **`54.4 MB`** | Bajo |
| **Restauración segura (`--backup-dir`)** | **`0.838 s`** | **`49.2 MB`** | Bajo |
| **CLI sin interfaz (`AlphaCloudSync.exe -Action Status`)** | **`ExitCode: 0`** (`9.853 s`) | Bajo | — |

---

## Empieza en 30 segundos (Windows 10 / 11 x64)

### Opción 1 — Instalación en 1 línea con PowerShell (Verificación SHA-256 Fail-Closed)
```powershell
irm https://raw.githubusercontent.com/AlphaAlgos/AlphaCloudSync/main/install.ps1 | iex
```

### Opción 2 — EXE portátil
1. Descarga **`AlphaCloudSync.exe`** y **`SHA256SUMS.txt`** desde [GitHub Releases](https://github.com/AlphaAlgos/AlphaCloudSync/releases).
2. Verifica la integridad: `Get-FileHash .\AlphaCloudSync.exe -Algorithm SHA256`.
3. Haz doble clic en **`AlphaCloudSync.exe`**.

### Opción 3 — Compilar desde el código fuente (2 segundos)
```powershell
git clone https://github.com/AlphaAlgos/AlphaCloudSync.git
cd AlphaCloudSync
.\build\build-release.ps1
```

### Opción 4 — Manifiesto WinGet
Incluido en [`winget/AlphaAlgorithms.AlphaCloudSync.yaml`](winget/AlphaAlgorithms.AlphaCloudSync.yaml) (`winget install AlphaAlgorithms.AlphaCloudSync` tras publicación).

---

## Verifica todo tú mismo (`25 / 25` Pruebas automáticas)

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\tests\run-tests.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\benchmarks\run-benchmarks.ps1
```

## Automatización por CLI

```powershell
AlphaCloudSync.exe -Action Status
AlphaCloudSync.exe -Action DryRun
AlphaCloudSync.exe -Action Sync -RemoteName gdrive
AlphaCloudSync.exe -Action Sync -FolderName "MyProject"
AlphaCloudSync.exe -Action Restore -FolderName "MyProject"
AlphaCloudSync.exe -Action Mount -RemoteName gdrive -DriveLetter G:
AlphaCloudSync.exe -Action Unmount -RemoteName gdrive -DriveLetter G:
AlphaCloudSync.exe --minimized
```

---

## Limitaciones honestas y modelo de seguridad

1. **OAuth local (`127.0.0.1`):** Las credenciales permanecen estrictamente locales en `%APPDATA%\rclone\rclone.conf`. Usar tu propio Client ID gratuito en **Modo más rápido** elimina los límites compartidos de Google.
2. **Windows SmartScreen:** Las compilaciones comunitarias actuales no están firmadas con certificado EV comercial; verifica `SHA256SUMS.txt` y pulsa **Más información → Ejecutar de todas formas**, o compila localmente con `.\build\build-release.ps1`.
3. **Auto-Sync vs Programador:** Auto-Sync vigila mientras la app corre (o en la bandeja). Para `0.0 MB` de RAM con la app cerrada, usa el **Programador de tareas de Windows**.
4. **Cuota de la Unidad Unificada:** `AlphaCloudSync` (`★ G:`) combina carpetas en una sola unidad del Explorador, mientras cada cuenta mantiene su propia cuota independiente en Google Drive.
5. **Alcance v1.0:** v1.0 ofrece soporte completo para **Google Drive**; OneDrive, Dropbox, S3/R2 y Nextcloud llegarán en `v1.1+`.

---

## Preguntas frecuentes

<details>
<summary><strong>Si pauso o cierro la aplicación a mitad de una subida, ¿empieza desde cero?</strong></summary>

No. Al reanudar, `rclone` compara tamaños, fechas y sumas MD5, omitiendo al instante los archivos ya subidos.
</details>

<details>
<summary><strong>¿Las insignias de carpetas modifican mi repositorio Git o suben desktop.ini?</strong></summary>

No. Se añade `desktop.ini` a `.git/info/exclude` (sin tocar `.gitignore`), nunca sobrescribe un `desktop.ini` del usuario y excluye `desktop.ini` al sincronizar.
</details>

<details>
<summary><strong>¿Recopila AlphaCloudSync telemetría o accede a mi contraseña de Google?</strong></summary>

Nunca. Cero telemetría y cero servidores de terceros. Todo ocurre localmente entre tu navegador, `rclone` y Google.
</details>

---

## Privacidad, marcas y licencia
- **Cero telemetría:** Sin analíticas ni rastreo.
- **Proyecto independiente de código abierto:** Desarrollado por **Alpha Algorithms Company** sobre Rclone y WinFsp. No afiliado ni respaldado por Google LLC.
- **Licencia:** [MIT License](LICENSE).
