#!/usr/bin/env bash
# Einmaliges Setup: baut die Container, installiert Laravel (falls noch nicht vorhanden)
# und richtet die MariaDB-Verbindung ein. Aufruf in Git Bash:  bash setup.sh
set -euo pipefail

cd "$(dirname "$0")"

# Git Bash wandelt sonst Pfade wie /var/www/html in Windows-Pfade um
export MSYS_NO_PATHCONV=1

info() { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
fail() { printf '\033[1;31mFehler:\033[0m %s\n' "$*" >&2; exit 1; }

command -v docker >/dev/null 2>&1 || fail "Docker wurde nicht gefunden. Bitte Docker Desktop installieren."
docker info >/dev/null 2>&1 || fail "Docker Desktop läuft nicht. Bitte starten und erneut versuchen."

# 1) .env für Docker Compose anlegen
if [ ! -f .env ]; then
  cp .env.example .env
  info ".env aus .env.example erstellt"
fi

# .env einlesen (CRLF-Zeilenenden werden entfernt)
set -a
# shellcheck disable=SC1090
source <(tr -d '\r' < .env)
set +a

WEB_PORT="${WEB_PORT:-8080}"
PMA_PORT="${PMA_PORT:-8081}"
DB_DATABASE="${DB_DATABASE:-laravel}"
DB_USERNAME="${DB_USERNAME:-laravel}"
DB_PASSWORD="${DB_PASSWORD:-secret}"

# 2) Images bauen
info "Baue Docker-Images (beim ersten Mal dauert das einige Minuten) ..."
docker compose build

# 3) Laravel installieren, falls ./src noch leer ist
mkdir -p src
if [ ! -f src/artisan ]; then
  info "Installiere Laravel nach ./src ..."
  docker compose run --rm --no-deps -T app \
    composer create-project laravel/laravel . --prefer-dist --no-interaction
else
  info "Laravel ist bereits in ./src vorhanden, überspringe Installation"
fi

# Abhängigkeiten nachholen, z. B. nach einer abgebrochenen Installation
# oder bei einem frischen Clone mit eigener App in ./src
if [ ! -f src/vendor/autoload.php ]; then
  info "Installiere Composer-Abhängigkeiten ..."
  docker compose run --rm --no-deps -T app \
    composer install --prefer-dist --no-interaction
fi

# 4) Laravel-.env auf MariaDB umstellen
set_env() {
  local key="$1" value="$2" file="src/.env" escaped
  escaped=$(printf '%s' "$value" | sed -e 's/[&|\\]/\\&/g')
  if grep -Eq "^#?[[:space:]]*${key}=" "$file"; then
    sed -i.bak -E "s|^#?[[:space:]]*${key}=.*|${key}=${escaped}|" "$file" && rm -f "${file}.bak"
  else
    printf '%s=%s\n' "$key" "$value" >> "$file"
  fi
}

[ -f src/.env ] || cp src/.env.example src/.env

info "Konfiguriere Datenbankverbindung in src/.env ..."
set_env APP_URL        "http://localhost:${WEB_PORT}"
set_env DB_CONNECTION  "mariadb"
set_env DB_HOST        "db"
set_env DB_PORT        "3306"
set_env DB_DATABASE    "$DB_DATABASE"
set_env DB_USERNAME    "$DB_USERNAME"
set_env DB_PASSWORD    "$DB_PASSWORD"

# 5) Alle Container starten und warten, bis die Datenbank bereit ist
info "Starte Container ..."
docker compose up -d --wait

# 6) App-Key, Schreibrechte und Migrationen
if ! grep -Eq '^APP_KEY=.+' src/.env; then
  docker compose exec -T app php artisan key:generate --force
fi

docker compose exec -T app chmod -R a+rwX storage bootstrap/cache || true

info "Führe Datenbank-Migrationen aus ..."
docker compose exec -T app php artisan migrate --force

echo
info "Fertig! Das Projekt läuft:"
echo "    Laravel:     http://localhost:${WEB_PORT}"
echo "    phpMyAdmin:  http://localhost:${PMA_PORT}   (Benutzer: ${DB_USERNAME} / Passwort: ${DB_PASSWORD})"
echo
echo "    Nützlich:    bin/shell    bin/artisan    bin/composer"
