#!/usr/bin/env bash
# Sauvegarde : bases PostgreSQL (format custom) + GED Axelor, avec rétention.
# Usage : ./scripts/backup.sh   (à planifier en cron, ex. 02:00 chaque nuit)
set -euo pipefail
#cd "$(dirname "$0")/.."

BACKUP_DIR="${BACKUP_DIR:-/mnt/data/backups}"
RETENTION_DAYS="${RETENTION_DAYS:-14}"
TS="$(date +%F_%H%M%S)"
mkdir -p "$BACKUP_DIR"
umask 077

# Les identifiants sont lus dans l'environnement des conteneurs (pas de .env sourcé)
docker compose exec -T db sh -c 'pg_dump -U "$POSTGRES_USER" -d "$POSTGRES_DB" -Fc' \
  > "$BACKUP_DIR/axelor-db_$TS.dump"
docker compose exec -T saas-db sh -c 'pg_dump -U "$POSTGRES_USER" -d "$POSTGRES_DB" -Fc' \
  > "$BACKUP_DIR/saas-db_$TS.dump"
tar -C /mnt/data -czf "$BACKUP_DIR/axelor-data_$TS.tgz" axelor-data

# Contrôle d'intégrité des dumps
for f in "$BACKUP_DIR"/axelor-db_"$TS".dump "$BACKUP_DIR"/saas-db_"$TS".dump; do
  docker compose exec -T db pg_restore --list < "$f" >/dev/null
done

find "$BACKUP_DIR" -type f -mtime +"$RETENTION_DAYS" -delete
echo "Sauvegarde terminée : $BACKUP_DIR ($TS)"
