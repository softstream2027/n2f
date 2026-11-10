# Déploiement n2f (Axelor Open Suite 9) — runbook

Basé sur le guide d'installation Axelor AOS 9 / AOP 8.2 :
Java 21 · Tomcat 10.1 · PostgreSQL ≥ 16 (extension `unaccent`) · Caddy (TLS) devant Tomcat.

## Contenu
| Fichier | Rôle |
|---|---|
| `Dockerfile` | Build multi-étapes, Tomcat 10.1.55 derrière proxy (scheme https), `/health`, non-root |
| `docker-compose.yml` | Caddy, Axelor, PostgreSQL, SaaS (backend, frontend, base, Redis), réseaux isolés |
| `Caddyfile` | TLS 1.2/1.3 automatique, en-têtes de sécurité, upload 20 Mo, timeouts 1800 s |
| `initdb/01-unaccent.sh` | Active `unaccent` à la première initialisation de la base |
| `scripts/backup.sh` | Dumps PostgreSQL + GED, contrôle d'intégrité, rétention |
| `.env.example` | Variables à renseigner |

À placer à côté : `docker-entrypoint.sh`, `post-startup.d/`, `.env.saas`.

## Serveur (référence Axelor : Ubuntu Server 24.04 LTS)
Dimensionnement indicatif avec base colocalisée : ~10 utilisateurs 2 vCPU / 8 Gio ·
~30 : 4 vCPU / 16 Gio · ~60 : 8 vCPU / 32 Gio. `JAVA_XMX` + PostgreSQL + SaaS doivent
rester sous la RAM de l'hôte.

```bash
sudo ufw allow OpenSSH && sudo ufw allow 80/tcp && sudo ufw allow 443/tcp && sudo ufw allow 443/udp
sudo ufw enable
sudo mkdir -p /mnt/data/{axelor-data,postgres-data,saas-postgres-data,redis-data,backups}
sudo chown -R 1000:1000 /mnt/data/axelor-data
```
Docker contourne `ufw` pour les ports publiés : seul Caddy publie des ports ici, ne
publiez rien d'autre.

## Mise en service
```bash
cp .env.example .env && chmod 600 .env     # renseigner mots de passe et domaines
docker compose config -q                    # validation
docker build -t n2f:v1.0.0 .                # voir l'en-tête du Dockerfile pour les --build-arg
docker compose up -d
docker compose ps
docker compose exec app curl -fs http://localhost:8080/health   # {"status":"UP"}
curl -fs https://$AXELOR_DOMAIN/health
```
Le premier démarrage peut durer longtemps (migrations de schéma, chargement des apps) :
attendez `healthy` avant d'ouvrir l'accès aux utilisateurs.

Base déjà initialisée (le script `initdb` ne rejoue pas) :
```bash
docker compose exec db psql -U "$DB_USER" -d "$DB_NAME" -c "CREATE EXTENSION IF NOT EXISTS unaccent;"
```

## Paramètres Axelor à vérifier
Le guide Axelor conserve la configuration hors du WAR (`AXELOR_CONFIG`). Votre
`docker-entrypoint.sh` doit produire l'équivalent de :
```properties
db.default.ddl        = update
data.upload.max-size  = 20
data.upload.dir       = /data/attachments
data.export.dir       = /data/exports
template.search-dir   = /data/templates
reports.design-dir    = /data/reports
application.mode      = prod
application.base-url  = https://erp.example.com
session.timeout       = 60
session.cookie.secure = true
```
Aucun mot de passe dans ce fichier : les accès base passent par les variables `PG*`.

## Sauvegarde et restauration
```bash
./scripts/backup.sh                          # cron : 0 2 * * * /chemin/deploy/scripts/backup.sh
# Restauration (base Axelor) :
docker compose stop app
docker compose exec -T db pg_restore -U "$DB_USER" -d "$DB_NAME" --clean --if-exists < axelor-db_YYYY-MM-DD_HHMMSS.dump
docker compose start app
```
Copiez les sauvegardes hors du serveur et testez une restauration régulièrement.

## Mise à jour
1. Sauvegarde (`backup.sh`).
2. Nouvelle image : `docker build --build-arg AOS_VERSION=v9.x.y ... -t n2f:v1.x.y .`
3. Changer le tag dans `docker-compose.yml`, puis `docker compose up -d app`.
4. Suivre `docker compose logs -f app` jusqu'à `healthy`.
Pour passer d'AOS 8 à 9 : migration planifiée (Java 8→21, Tomcat 9→10.1, chiffrement CBC→GCM).

## Conformité AGPLv3
Le code d'Axelor modifié et exposé en réseau doit être proposé aux utilisateurs : passez
`--build-arg SOURCE_URL=<dépôt public>` au build (label OCI `source`) et ajoutez un lien
« Source » visible dans l'application. Gardez dans ce dépôt public les modules de la
solution, jamais `.env`, `.env.saas` ni les secrets.
