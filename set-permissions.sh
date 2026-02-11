#!/bin/bash
set -e

ENV_FILE=".env"

if [ ! -f "$ENV_FILE" ]; then
    echo "File .env not found in $(pwd)"
    exit 1
fi

set -a
source "$ENV_FILE"
set +a

if [ -z "$MYSQL_DIR" ]; then
    echo "Please set MYSQL_DIR in .env"
    exit 1
fi

USER_NAME="$USER"

echo "Set ownership to user: $USER_NAME"
sudo chown -R $USER_NAME:$USER_NAME "$MYSQL_DIR"

echo "Set directory permissions: 755"
sudo find "$MYSQL_DIR" -type d -exec chmod 755 {} \;

echo "Set file permissions: 644"
sudo find "$MYSQL_DIR" -type f -exec chmod 644 {} \;

echo "Set permission .env: 600"
chmod 600 "$ENV_FILE"

echo "Permissions setup complete!."