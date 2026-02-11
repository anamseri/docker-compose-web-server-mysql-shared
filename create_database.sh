#!/usr/bin/env bash
set -Eeuo pipefail

error() {
  echo "❌ $1" >&2
  exit 1
}

info() {
  echo "▶ $1"
}

warn() {
  echo "⚠ $1"
}

APP_NAME=""
CUSTOM_ENV=""
MODE="create"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --app)
      APP_NAME="$2"
      shift 2
      ;;
    --env)
      CUSTOM_ENV="$2"
      shift 2
      ;;
    --drop)
      MODE="drop"
      shift
      ;;
    -h|--help)
      echo "Usage:"
      echo "  Create        : $0 --app {DIR_NAME}"
      echo "  - Example     : $0 --app laravelapp1"
      echo "  Custom        : $0 --env {APP_DIR}/.env"
      echo "  - Example     : $0 --env /srv/anamseri/laravelapp1/.env"
      echo "  Drop          : $0 --app {DIR_NAME} --drop"
      echo "  - Example     : $0 --app laravelapp1 --drop"
      warn "  Perform a backup before drop the database. Drop action cannot be undone."
      exit 0
      ;;
    *)
      info "  use: $0 -h | --help"
      error " Unknown argument: $1"
      ;;
  esac
done

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MYSQL_ENV="${SCRIPT_DIR}/.env"

[[ -f "$MYSQL_ENV" ]] || error "MySQL env not found: $MYSQL_ENV"

set -o allexport
source <(sed 's/\r$//' "$MYSQL_ENV")
set +o allexport

if [[ -z "${PROJECT_DIR:-}" ]]; then
  PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
  info "PROJECT_DIR auto-detected: $PROJECT_DIR"
fi

if [[ -n "$CUSTOM_ENV" ]]; then
  APP_ENV="$CUSTOM_ENV"
else
  [[ -n "$APP_NAME" ]] || error "--app is required"
  APP_ENV="${PROJECT_DIR}/${APP_NAME}/.env"
fi

[[ -f "$APP_ENV" ]] || error "App env not found: $APP_ENV"
info "Using app env: $APP_ENV"

set -o allexport
source <(sed 's/\r$//' "$APP_ENV")
set +o allexport

REQUIRED_VARS=(
  DB_DATABASE
  DB_USERNAME
  DB_PASSWORD
  MYSQL_ROOT_PASSWORD
  DB_CONTAINER_NAME
  DB_IMAGE
)

for VAR in "${REQUIRED_VARS[@]}"; do
  [[ -n "${!VAR:-}" ]] || error "Missing env variable: $VAR"
done

docker ps --format '{{.Names}}' | grep -qx "$DB_CONTAINER_NAME" \
  || error "DB container not running: $DB_CONTAINER_NAME"

if [[ "$MODE" == "drop" ]]; then
  warn "Perform a backup before drop the database. This action cannot be undone."
  warn "Preparing to DROP database & user: $DB_DATABASE"

  info "Checking if database exists..."

  DB_EXISTS=$(
    docker run --rm \
      --network laravel_netshared \
      "$DB_IMAGE" \
      mariadb -h "$DB_CONTAINER_NAME" \
        -uroot -p"${MYSQL_ROOT_PASSWORD}" \
        -N -s \
        -e "SELECT SCHEMA_NAME FROM INFORMATION_SCHEMA.SCHEMATA WHERE SCHEMA_NAME='${DB_DATABASE}';" \
      2>/dev/null
  )

  if [[ -z "$DB_EXISTS" ]]; then
    warn "Database '$DB_DATABASE' does NOT exist."
    warn "Drop aborted.."
    exit 0
  fi

  info "Database exists. Proceeding with drop..."

  warn "WARNING: YOU ARE ABOUT TO DROP DATABASE"
  echo "  Database : $DB_DATABASE"
  echo "  User     : $DB_USERNAME"
  echo

  read -rp "Type database name to confirm drop: " CONFIRM

  if [[ "$CONFIRM" != "$DB_DATABASE" ]]; then
    error "Confirmation failed. Drop aborted.."
    exit 1
  fi

  info "Dropping database & user..."

  docker run --rm -i \
    --network laravel_netshared \
    "$DB_IMAGE" \
    mariadb -h "$DB_CONTAINER_NAME" \
      -uroot -p"${MYSQL_ROOT_PASSWORD}" <<SQL
DROP DATABASE IF EXISTS \`${DB_DATABASE}\`;
DROP USER IF EXISTS '${DB_USERNAME}'@'%';
FLUSH PRIVILEGES;
SQL

  info "Drop database & user completed!."
  exit 0
fi

info "Creating database: $DB_DATABASE"
info "Creating user: $DB_USERNAME"

docker run --rm -i \
  --network laravel_netshared \
  "${DB_IMAGE}" \
  mariadb -h "$DB_CONTAINER_NAME" \
    -uroot -p"${MYSQL_ROOT_PASSWORD}" <<SQL
CREATE DATABASE IF NOT EXISTS \`${DB_DATABASE}\`
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

CREATE USER IF NOT EXISTS '${DB_USERNAME}'@'%'
  IDENTIFIED BY '${DB_PASSWORD}';

GRANT ALL PRIVILEGES ON \`${DB_DATABASE}\`.* TO '${DB_USERNAME}'@'%';
FLUSH PRIVILEGES;
SQL

info "Database & User created successfully."