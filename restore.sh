#!/usr/bin/env bash
# Restauration depuis les fichiers créés par backup.sh : bases PostgreSQL (Axelor, SaaS) et GED Axelor.
#
# Usage :
#   ./restore.sh list                               liste les sauvegardes disponibles
#   ./restore.sh <horodatage> verify                teste les dumps dans une base temporaire (sans arrêt de service)
#   ./restore.sh <horodatage> axelor|saas|ged|all   RESTAURE (arrête le service, confirmation demandée)
# Exemple : ./restore.sh 2026-11-11_020001 all
# Pour la GED, le script utilise sudo (propriétaire uid 1000 des fichiers).
set -euo pipefail

DIR="$(cd "$(dirname "$0")" && pwd)"
[ -f "$DIR/docker-compose.yml" ] || DIR="$(dirname "$DIR")"
cd "$DIR"

BACKUP_DIR="${BACKUP_DIR:-/mnt/data/backups}"
DATA_DIR="${DATA_DIR:-/mnt/data}"
NOW="$(date +%F_%H%M%S)"
SUDO=""; [ "$(id -u)" -ne 0 ] && SUDO="sudo"
umask 077

die() { echo "ERREUR : $*" >&2; exit 1; }

usage() { sed -n '2,10p' "$0" | sed 's/^# \{0,1\}//'; exit 0; }

list_backups() {
  echo "Sauvegardes disponibles dans $BACKUP_DIR (les plus récentes d'abord) :"
  ls -1 "$BACKUP_DIR" 2>/dev/null | sed -n 's/^axelor-db_\(.*\)\.dump$/\1/p' | sort -r | head -30
}

# Le dump est relu par le pg_restore du conteneur qui le restaurera
check_dump() { # service fichier
  [ -s "$2" ] || die "fichier absent ou vide : $2"
  docker compose exec -T "$1" pg_restore --list < "$2" >/dev/null || die "dump illisible : $2"
}

safety_dump() { # service libellé
  local out="$BACKUP_DIR/pre-restore_${2}_$NOW.dump"
  docker compose exec -T "$1" sh -c 'pg_dump -U "$POSTGRES_USER" -d "$POSTGRES_DB" -Fc' > "$out"
  echo "  copie de sécurité de l'état actuel : $out"
}

restore_db() { # service fichier
  docker compose exec -T "$1" sh -c 'psql -v ON_ERROR_STOP=1 -U "$POSTGRES_USER" -d postgres \
    -c "DROP DATABASE IF EXISTS \"$POSTGRES_DB\" WITH (FORCE)" \
    -c "CREATE DATABASE \"$POSTGRES_DB\" OWNER \"$POSTGRES_USER\" TEMPLATE template0"'
  docker compose exec -T "$1" sh -c 'pg_restore -U "$POSTGRES_USER" -d "$POSTGRES_DB" --no-owner --single-transaction --exit-on-error' < "$2"
}

verify_db() { # service fichier
  echo "  - vérification de $2 dans une base temporaire (restore_verify)"
  docker compose exec -T "$1" sh -c 'psql -v ON_ERROR_STOP=1 -U "$POSTGRES_USER" -d postgres \
    -c "DROP DATABASE IF EXISTS restore_verify WITH (FORCE)" -c "CREATE DATABASE restore_verify TEMPLATE template0"'
  docker compose exec -T "$1" sh -c 'pg_restore -U "$POSTGRES_USER" -d restore_verify --no-owner --exit-on-error' < "$2" \
    || { docker compose exec -T "$1" sh -c 'psql -U "$POSTGRES_USER" -d postgres -c "DROP DATABASE IF EXISTS restore_verify WITH (FORCE)"'; die "restauration de test échouée pour $2"; }
  docker compose exec -T "$1" sh -c 'psql -At -U "$POSTGRES_USER" -d restore_verify' <<'SQL'
select 'tables : ' || count(*) from information_schema.tables where table_schema = 'public';
SQL
  docker compose exec -T "$1" sh -c 'psql -U "$POSTGRES_USER" -d postgres -c "DROP DATABASE IF EXISTS restore_verify WITH (FORCE)"' >/dev/null
  echo "    OK"
}

restore_ged() { # fichier
  local aside="$DATA_DIR/axelor-data.pre-restore_$NOW"
  [ -d "$DATA_DIR/axelor-data" ] && $SUDO mv "$DATA_DIR/axelor-data" "$aside" && echo "  ancienne GED conservée : $aside"
  $SUDO tar -C "$DATA_DIR" -xzf "$1"
  $SUDO chown -R 1000:1000 "$DATA_DIR/axelor-data"
}

CMD="${1:-}"; TARGET="${2:-}"
case "$CMD" in
  ""|-h|--help) usage ;;
  list) list_backups; exit 0 ;;
esac

TS="$CMD"
[[ "$TS" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}_[0-9]{6}$ ]] || die "horodatage invalide ($TS). Voir : $0 list"
AX="$BACKUP_DIR/axelor-db_$TS.dump"
SA="$BACKUP_DIR/saas-db_$TS.dump"
GE="$BACKUP_DIR/axelor-data_$TS.tgz"

case "$TARGET" in
  verify)
    check_dump db "$AX"; check_dump saas-db "$SA"; tar -tzf "$GE" >/dev/null || die "archive GED illisible"
    echo "Vérification des sauvegardes $TS :"
    verify_db db "$AX"; verify_db saas-db "$SA"
    echo "GED : archive lisible"
    echo "Toutes les vérifications sont OK."
    exit 0 ;;
  axelor) DO_AX=1; DO_SA=0; DO_GE=0 ;;
  saas)   DO_AX=0; DO_SA=1; DO_GE=0 ;;
  ged)    DO_AX=0; DO_SA=0; DO_GE=1 ;;
  all)    DO_AX=1; DO_SA=1; DO_GE=1 ;;
  *) die "cible manquante ou inconnue : verify | axelor | saas | ged | all" ;;
esac

# Contrôles AVANT tout arrêt de service
[ "$DO_AX" = 1 ] && check_dump db "$AX"
[ "$DO_SA" = 1 ] && check_dump saas-db "$SA"
[ "$DO_GE" = 1 ] && { [ -s "$GE" ] && tar -tzf "$GE" >/dev/null || die "archive GED absente ou illisible : $GE"; }

echo "Restauration de la sauvegarde $TS :"
[ "$DO_AX" = 1 ] && echo "  - base Axelor : REMPLACÉE par $AX"
[ "$DO_SA" = 1 ] && echo "  - base SaaS   : REMPLACÉE par $SA"
[ "$DO_GE" = 1 ] && echo "  - GED Axelor  : REMPLACÉE par $GE"
echo "Le service sera interrompu. Les données actuelles seront d'abord copiées (copie de sécurité)."
read -r -p "Tapez RESTAURER pour continuer : " ANSWER
[ "$ANSWER" = "RESTAURER" ] || die "annulé"

trap 'echo "ÉCHEC de la restauration. Copies de sécurité : $BACKUP_DIR/pre-restore_*_$NOW.dump" >&2' ERR

echo "Copies de sécurité :"
[ "$DO_AX" = 1 ] && safety_dump db axelor
[ "$DO_SA" = 1 ] && safety_dump saas-db saas

echo "Arrêt des services..."
if [ "$DO_AX" = 1 ] || [ "$DO_GE" = 1 ]; then docker compose stop app; fi
if [ "$DO_SA" = 1 ]; then docker compose stop backend frontend; fi

[ "$DO_AX" = 1 ] && { echo "Restauration de la base Axelor..."; restore_db db "$AX"; }
[ "$DO_SA" = 1 ] && { echo "Restauration de la base SaaS...";  restore_db saas-db "$SA"; }
[ "$DO_GE" = 1 ] && { echo "Restauration de la GED...";        restore_ged "$GE"; }

echo "Redémarrage..."
docker compose up -d app backend frontend
echo "Attente de l'application (jusqu'à 30 min)..."
for _ in $(seq 1 180); do
  [ "$(docker inspect -f '{{.State.Health.Status}}' n2f-app 2>/dev/null)" = "healthy" ] && { echo "Application prête."; break; }
  sleep 10
done
trap - ERR
echo "Restauration terminée. Vérifiez : connexion à l'ERP, une note de frais, une pièce jointe."
