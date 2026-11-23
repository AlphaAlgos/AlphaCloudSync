<p align="center">
  <img src="assets/AlphaCloudSync-wordmark.png" alt="AlphaCloudSync — Sauvegarde. Synchronisation. Restauration." width="560"/>
</p>

<h3 align="center">Un noyau de contrôle léger, rapide et transparent pour le stockage cloud sur Windows — en commençant par Google Drive.</h3>

<p align="center">
  Un studio Windows portable et open source conçu comme espace de travail cloud léger (démarrant avec <strong>Google Drive</strong> en v1.0, basé sur un <strong>Registre Modulaire de Fournisseurs</strong> + <a href="https://rclone.org/">rclone</a> et <a href="https://winfsp.dev/">WinFsp</a> prêt pour les futurs fournisseurs) — offrant des sauvegardes sans surcharge, un <strong>Hub Hybride de Lecteurs Unifié (<code>★ G:</code>) + Autonomes dans l'Explorateur Windows</strong>, des badges de dossiers et un menu contextuel à zéro RAM, la synchronisation automatique en temps réel, une pause globale de bande passante, une restauration sécurisée anti-écrasement, des règles d'exclusion par compte, une interface <strong>Obsidian Dark Fluent</strong> 100% sombre et un <strong>Îlot Cloud Dynamique</strong> déplaçable.<br/>
  Développé par <a href="https://github.com/AlphaAlgos">Alpha Algorithms Company</a>.
</p>

<p align="center">
  <a href="LICENSE"><img src="https://img.shields.io/badge/License-MIT-38BDF8.svg" alt="Licence MIT"/></a>
  <img src="https://img.shields.io/badge/Windows-10%20%2F%2011%20(x64)-10B981.svg" alt="Windows 10/11 x64"/>
  <img src="https://img.shields.io/badge/Portable%20EXE-~1.16%20MB-6366F1.svg" alt="EXE Portable"/>
  <img src="https://img.shields.io/badge/Langues-7%20(345%20Clés%20%2B%20RTL)-F59E0B.svg" alt="7 Langues (345 Clés)"/>
  <img src="https://img.shields.io/badge/Tests%20Automatisés-25%2F25%20PASS-22C55E.svg" alt="25/25 Tests Réussis"/>
  <img src="https://img.shields.io/badge/Télémétrie-Zéro-4ADE80.svg" alt="Zéro Télémétrie"/>
</p>

<p align="center">
  <a href="README.md">English</a> · <a href="README.ar.md">العربية</a> · <a href="README.es.md">Español</a> · <strong>Français</strong> · <a href="README.de.md">Deutsch</a> · <a href="README.zh.md">中文 (简体)</a> · <a href="README.id.md">Bahasa Indonesia</a>
</p>

<p align="center">
  <a href="docs/USER_GUIDE.md">Guide Utilisateur</a> · <a href="BENCHMARKS.md">Benchmarks</a> · <a href="CHANGELOG.md">Historique</a> · <a href="SECURITY.md">Sécurité</a> · <a href="CONTRIBUTING.md">Contribuer</a>
</p>

---

## Pourquoi quitter le client officiel Google Drive pour ordinateur ?

| Problème quotidien | Google Drive officiel | AlphaCloudSync v1.0 |
| :--- | :--- | :--- |
| **Windows réinstallé ?** | Crée **`My Computer (1)`** et renvoie des dizaines de Go depuis zéro | **Zéro doublon** — reconnexion directe à `My Drive` ou au libellé fixe `My Computer` |
| **RAM en arrière-plan** | Processus résidents toujours actifs | **`0.0 Mo` de RAM une fois fermé** · **`49.6 Mo` de RAM** mesurés avec le lecteur `G:` monté *(voir [`BENCHMARKS.md`](BENCHMARKS.md))* |
| **Envoi de caches et fichiers inutiles** | Envoie `node_modules`, `.venv`, `.gradle`, `*.tmp` | **Règles d'exclusion par compte (`presets/`)** ignorent automatiquement les caches et affichent les Go économisés |
| **Suppression locale accidentelle** | Risque de suppression silencieuse sur le cloud | **3 politiques claires** (`Archive sécurisée`, `Copie seule`, `Miroir exact`) + garde source vide + `--max-delete 200` |
| **Restaurer sur le PC** | Risque d'écraser des fichiers locaux plus récents | **Restauration sécurisée** — aperçu sans modification d'abord + sauvegarde locale automatique avant remplacement |
| **Plusieurs comptes Google** | Gestion multi-compte limitée | **Hybride : Lecteur Unifié (`★ G:`) + Lecteurs Autonomes (`D:`–`Z:`)** — regroupe dans `AlphaCloudSync` ou attribue une lettre dédiée (`Drive - <Compte>`) |
| **Badges et menu Explorateur** | Extensions DLL lourdes | **Badges de dossiers, icônes de lecteurs et menu clic droit à zéro RAM** via `desktop.ini` et `HKCU` |
| **Automatisation et débit** | Impose une synchronisation permanente | **Au choix :** **Auto-Sync rapide** (`--files-from`, `4s`) + **Pause globale en 1 clic** **OU** **Planificateur Windows COM** (`0.0 Mo` fermé) |
| **Empreinte et transparence** | Installeur lourd + mises à jour silencieuses | **1 EXE portable `~1.16 Mo`** · SHA-256 Fail-Closed · Zéro fenêtre CMD · Zéro télémétrie |

---

## Fonctionnalités clés (`src/AlphaCloudSync.ps1` & `src/modules/`)

### 1. Hub Hybride : Lecteur Unifié (`★ G:`) + Lecteurs Autonomes (`D:` – `Z:`)
Connectez un nombre illimité de comptes Google Drive dans **Paramètres → Comptes et connexions** :
- **Lecteur Unifié (`★ G:`):** Regroupe les comptes choisis dans un seul lecteur Explorateur nommé **`AlphaCloudSync`** (`rclone mount :combine:`), avec déduplication automatique des noms (`alice.dev`, `alice.dev (2)`).
- **Lecteurs Autonomes (`D:` – `Z:`):** Montez n'importe quel compte séparément ou tous les comptes sans conflit de lettres (`Drive - <Compte>`, `<= 21` caractères).
- **Mode Hybride & Vue par compte (`MountScope`):** Combinez `★ G:` et lettres individuelles, et choisissez **`Mon Drive uniquement`**, **`Mon ordinateur uniquement`** ou **`Les deux`**.
- **En ligne uniquement (`0 Go` permanent sur SSD) vs Copie hors ligne:** En ligne uniquement (`--vfs-cache-mode writes`) diffuse à la demande ; Copie hors ligne (`--vfs-cache-mode full`) met en cache jusqu'à `50 Go` / `720 h`.
- **Persistant après fermeture & Garde PID (`T21`):** Les lecteurs restent actifs après fermeture (`0.00%` CPU) avec actualisation silencieuse de **Ce PC**.

### 2. Badges de dossiers, icônes de lecteurs et menu clic droit (Zéro RAM)
- **Icônes natives (`desktop.ini` + `SHChangeNotify`)** sans injection DLL, protection automatique `.git/info/exclude` (sans toucher `.gitignore`), garde non destructive et exclusion automatique `--exclude "desktop.ini"`.
- **Menu clic droit sur les dossiers Windows (`HKCU`):** Clic droit → **AlphaCloudSync** → **`Ajouter à la synchronisation...`**, **`Synchroniser maintenant`**, **`Aperçu uniquement`** ou **`Retirer de la synchronisation`** — traduit en 7 langues, compatible racines de disques (`"%V\."`) et file IPC atomique.

### 3. Interface Obsidian Dark Fluent, démarrage instantané et zéro fenêtre CMD
- **Carte Splash sombre à 5 étapes (~30ms), premier plan garanti et chargement séquentiel :** Affiche 5 étapes en direct dans votre langue dès le clic, force l'affichage de la fenêtre principale au premier plan (`AllowSetForegroundWindow` + `AttachThreadInput`) et actualise les comptes **un par un en arrière-plan** (compte actif en premier) sans jamais figer l'interface, même avec 10 ou 50 comptes.
- **Indicateur vert pulsant :** Visible à côté d'**Activité et journal** uniquement pendant un envoi actif, masqué au repos.
- **Zéro fenêtre CMD** (`T15`) et **OAuth silencieux** avec page HTML sombre personnalisée (`rclone authorize --template`).

### 4. Auto-Sync rapide, Pause globale, Notifications et Planificateur COM
- **Auto-Sync ciblé (`--files-from`, désactivé par défaut) :** Surveille les dossiers activés (`4s` de stabilisation), ignore `.git`/`node_modules`/`*.tmp` et envoie les fichiers modifiés en ~2 secondes.
- **Pause globale en 1 clic (zone de notification) :** Libérez instantanément toute votre bande passante et reprenez à tout moment.
- **Notifications granulaires :** Interrupteur principal + 4 catégories indépendantes (Manuel/Aperçu/Restauration, Auto-Sync uniquement lors de vrais changements, Erreurs, Lecteurs).
- **Planificateur Windows COM (`12h AM / PM`) :** Unique, quotidien, hebdomadaire ou toutes les `1h`–`12h` avec `0.0 Mo` de RAM une fois fermé.

### 5. File prioritaire, Règles d'exclusion, Restauration sécurisée & 7 langues (`345` clés)
- **File prioritaire :** **Envoi** épinglé en haut → **Envoyé / Archivé** masqué automatiquement après 3,5s → **En attente / Suppression / Renommage** en bas (FIFO).
- **3 politiques de suppression + Garde source vide filtrée (`rclone lsf`) + `--max-delete 200`** + **Restauration sécurisée** avec aperçu préalable et sauvegarde automatique dans `restore-backups\`.
- **Îlot Cloud Dynamique (`~250 × 32 px`)** déplaçable librement + **7 langues intégrées (`345` clés) :** English · العربية (RTL) · Español · Français · Deutsch · 中文 (简体) · Bahasa Indonesia.

---

## Performances mesurées ([`benchmarks/latest-results.json`](benchmarks/latest-results.json))

Mesuré via [`benchmarks/run-benchmarks.ps1`](benchmarks/run-benchmarks.ps1) sur **Intel Core i5-7Y57 (1.20 GHz) / 7.9 Go RAM / Windows 11 Pro** :

| Scénario | Résultat mesuré | RAM max | CPU au repos |
| :--- | :---: | :---: | :---: |
| **Exécutable portable (`AlphaCloudSync.exe`)** | **`~1.16 Mo`** (`1,191.5 Ko`, 27 ressources intégrées) | — | — |
| **Fermé / Mode planifié** | 0 processus en arrière-plan | **`0.0 Mo`** | **`0.00%`** |
| **Lecteur Explorateur persistant (`G:` En ligne)** | Actif même application fermée | **`49.6 Mo`** | **`0.00%`** |
| **Analyse brute (`2 800` fichiers / `39.06 Mo`)** | **`7.440 s`** | **`50.2 Mo`** | Faible |
| **Analyse filtrée (`node_modules`/`.venv` ignorés)** | **`3.509 s`** (**`2 400` fichiers / `37.5 Mo` = 96.0% ignorés — 2.1x plus rapide**) | **`49.5 Mo`** | Faible |
| **Sync Archive sécurisée (`400` fichiers)** | **`4.113 s`** | **`54.4 Mo`** | Faible |
| **Restauration sécurisée (`--backup-dir`)** | **`0.838 s`** | **`49.2 Mo`** | Faible |
| **CLI (`AlphaCloudSync.exe -Action Status`)** | **`ExitCode: 0`** (`9.853 s`) | Faible | — |

---

## Démarrer en 30 secondes (Windows 10 / 11 x64)

```powershell
# Option 1 : Installation PowerShell en 1 ligne (Vérification SHA-256 Fail-Closed)
irm https://raw.githubusercontent.com/AlphaAlgos/AlphaCloudSync/main/install.ps1 | iex

# Option 2 : Télécharger AlphaCloudSync.exe + SHA256SUMS.txt depuis GitHub Releases
# Option 3 : Compiler localement en 2 secondes
git clone https://github.com/AlphaAlgos/AlphaCloudSync.git
cd AlphaCloudSync
.\build\build-release.ps1

# Exécuter les 25 tests automatisés (T01-T25)
powershell -NoProfile -ExecutionPolicy Bypass -File .\tests\run-tests.ps1
```

## Confidentialité, sécurité & licence
- **Zéro télémétrie :** Aucune donnée envoyée à un tiers ; OAuth local `127.0.0.1` conservé dans `%APPDATA%\rclone\rclone.conf`.
- **SmartScreen :** Les builds communautaires ne disposent pas encore de certificat EV commercial ; vérifiez `SHA256SUMS.txt` ou compilez depuis les sources. Voir [`SECURITY.md`](SECURITY.md).
- **Licence :** [MIT License](LICENSE) — projet indépendant développé par **Alpha Algorithms Company**, non affilié à Google LLC.
