#!/usr/bin/env bash
set -euo pipefail
umask 077

COMPOSE_DIR=/mnt/data/n2f
BACKUP_DIR=/mnt/data/backups
RETENTION_DAYS=7
STAMP=$(date +%F_%H%M)

DB_USER=$(grep '^DB_USER=' "$COMPOSE_DIR/.env" | cut -d= -f2-)
DB_NAME=$(grep '^DB_NAME=' "$COMPOSE_DIR/.env" | cut -d= -f2-)

mkdir -p "$BACKUP_DIR"
echo "[$(date '+%F %T')] Début de la sauvegarde"

# 1. Base de données (format custom, compressé, restaurable avec pg_restore)
DB_FILE="$BACKUP_DIR/db_${DB_NAME}_${STAMP}.dump"
docker exec n2f-db pg_dump -U "$DB_USER" -d "$DB_NAME" -Fc > "$DB_FILE.tmp"

# Vérification : le dump doit être lisible
docker exec -i n2f-db pg_restore -l < "$DB_FILE.tmp" > /dev/null
mv "$DB_FILE.tmp" "$DB_FILE"

# 2. Fichiers Axelor (pièces jointes, etc.)
FILES_FILE="$BACKUP_DIR/files_${STAMP}.tar.gz"
tar czf "$FILES_FILE.tmp" -C /mnt/data axelor-data
mv "$FILES_FILE.tmp" "$FILES_FILE"

# 3. Rotation
find "$BACKUP_DIR" -type f \( -name 'db_*.dump' -o -name 'files_*.tar.gz' \) -mtime +"$RETENTION_DAYS" -delete

echo "[$(date '+%F %T')] OK : $(basename "$DB_FILE") ($(du -h "$DB_FILE" | cut -f1)), $(basename "$FILES_FILE") ($(du -h "$FILES_FILE" | cut -f1))"
