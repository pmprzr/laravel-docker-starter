# Laravel Docker Starter

Ein Docker-Setup, mit dem du in wenigen Minuten eine lauffähige Laravel-Entwicklungsumgebung bekommst:

| Dienst       | Technik                  | Adresse                  |
|--------------|--------------------------|--------------------------|
| Webserver    | Nginx                    | http://localhost:8080    |
| Anwendung    | PHP 8.4 (FPM) + Composer | -                        |
| Datenbank    | MariaDB 11.4             | `localhost:3306`         |
| DB-Verwaltung| phpMyAdmin               | http://localhost:8081    |
| Framework    | Laravel (aktuelle Version)| in `./src`              |

## Voraussetzungen

- [Docker Desktop](https://www.docker.com/products/docker-desktop/) (läuft und ist gestartet)
- Git (unter Windows inklusive Git Bash)

## Schnellstart

```bash
git clone https://github.com/<dein-name>/laravel-docker-starter.git
cd laravel-docker-starter
bash setup.sh
```

Das Skript erledigt alles Nötige:

1. legt die `.env` aus `.env.example` an
2. baut die Docker-Images
3. installiert Laravel nach `./src` (nur wenn dort noch keins liegt)
4. trägt die MariaDB-Zugangsdaten in `src/.env` ein
5. startet alle Container und führt die Migrationen aus

Danach erreichst du Laravel unter <http://localhost:8080> und phpMyAdmin unter <http://localhost:8081>
(Benutzer `laravel`, Passwort `secret`, sofern du die Standardwerte nicht geändert hast).

## Alltag

```bash
docker compose up -d          # Container starten
docker compose down           # Container stoppen (Datenbank bleibt erhalten)
docker compose down -v        # Stoppen und Datenbank-Volume löschen

bin/artisan migrate           # php artisan im Container
bin/composer require <paket>  # composer im Container
bin/shell                     # interaktive Shell (z. B. für php artisan tinker)
```

## Konfiguration

Ports und Datenbank-Zugangsdaten stehen in der `.env` im Projektordner. Sind Ports bereits belegt,
ändere dort `WEB_PORT`, `PMA_PORT` oder `DB_PORT` und starte mit `docker compose up -d` neu.

Wenn du Zugangsdaten **nach** dem ersten Start änderst, musst du das Datenbank-Volume neu anlegen
(`docker compose down -v`), denn MariaDB liest die Werte nur bei der Erstinitialisierung.

## Projektstruktur

```
.
├── docker/
│   ├── nginx/default.conf   # Nginx-Konfiguration für Laravel
│   └── php/                 # Dockerfile und php.ini für PHP-FPM
├── bin/                     # Hilfsskripte (artisan, composer, shell)
├── src/                     # Laravel-Anwendung (wird vom Setup angelegt)
├── docker-compose.yml
├── .env.example
└── setup.sh
```

## Hinweise für Windows / Git Bash

- **Interaktive Shell:** In Git Bash scheitert `docker compose exec app bash` oft mit
  „the input device is not a TTY“. `bin/shell` nutzt dafür automatisch `winpty`.
- **Pfade:** Git Bash wandelt Pfade wie `/var/www/html` in Windows-Pfade um. Die Skripte in `bin/` setzen deshalb
  `MSYS_NO_PATHCONV=1`; bei eigenen Docker-Befehlen musst du das ggf. selbst davorsetzen.
- **Zeilenenden:** `.gitattributes` erzwingt LF für Shell-Skripte. Mit CRLF bricht Bash mit `\r: command not found` ab.
- **Geschwindigkeit:** Docker Desktop sollte das WSL-2-Backend nutzen. Noch schneller wird Laravel,
  wenn das Projekt direkt im WSL-Dateisystem liegt (z. B. `\\wsl$\Ubuntu\home\...`) statt unter `C:\`.

## Fehlerbehebung

- **Composer bricht mit „exceeded the timeout of 300 seconds“ ab:** Das passiert, wenn das Projekt auf einem
  langsamen Windows-Laufwerk liegt (besonders in OneDrive-Ordnern wie `Dokumente` oder `Desktop`, oder mit aktivem
  Virenscanner). Das Timeout ist im Image abgeschaltet; `bash setup.sh` einfach erneut starten, es macht dort weiter,
  wo es aufgehört hat. Dauerhaft deutlich schneller: das Projekt in einen Ordner außerhalb von OneDrive legen oder
  ins WSL-Dateisystem verschieben.
- **„tempnam(): file created in the system's temporary directory“ oder „Permission denied“ in `storage/`:**
  Der PHP-Prozess darf dort nicht schreiben. Im Dev-Setup läuft PHP-FPM deshalb als root
  (`docker/php/fpm-dev.conf` und `php-fpm -R` in der `docker-compose.yml`). Nach dem Update der Dateien reicht
  `docker compose up -d`. Für Produktion ist das **nicht** geeignet; dort gehört FPM auf `www-data`.
- **Setup von vorn beginnen:** `docker compose down -v`, danach den Ordner `src/` leeren und `bash setup.sh` ausführen.

## Eigene Anwendung committen

Der Ordner `src/` ist bewusst **nicht** in der `.gitignore`. So kannst du deine Laravel-App im selben Repository
versionieren (Laravel bringt eine eigene `.gitignore` für `vendor/`, `.env` usw. mit). Möchtest du das Repo nur als
reine Docker-Vorlage nutzen, trage `src/` in die `.gitignore` ein.

## Auf GitHub veröffentlichen

```bash
git init -b main
git add .
git update-index --chmod=+x setup.sh bin/artisan bin/composer bin/shell
git commit -m "Initial commit"
git remote add origin https://github.com/<dein-name>/laravel-docker-starter.git
git push -u origin main
```

Der `update-index`-Schritt sorgt dafür, dass die Skripte auch unter Linux und macOS ausführbar sind.
Aktivierst du in den Repository-Einstellungen **Template repository**, können andere über „Use this template“
direkt ein eigenes Projekt daraus erzeugen.
