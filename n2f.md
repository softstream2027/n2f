#Axelor std v8.4.8:
https://github.com/axelor/axelor-docker.git
https://github.com/axelor/open-suite-webapp/tree/v8.4.8

ssh-keygen -f "/home/audaxis/.ssh/known_hosts" -R "83.228.244.59"
ssh -i ~/.ssh/mekkaoui.pem ubuntu@83.228.244.59
cd /mnt/data
df -h
sudo rm -r *
sudo chown -R ubuntu:ubuntu /mnt/data

# n2f
git clone https://github.com/softstream2027/n2f.git
cd n2f/
ls -la
nano .env   
nano .env.saas

git config --global user.name "softstream2027"
git config --global user.email "softstream2027@gmail.com"
ssh -T git@github.com
ssh-keygen -t ed25519 -C "softstream2027@gmail.com"
cat ~/.ssh/id_ed25519.pub
https://github.com/settings/keys
Ajoutez la clé publique (~/.ssh/id_ed25519.pub) sur GitHub : Settings > SSH and GPG keys > New SSH key.
git remote set-url origin git@github.com:softstream2027/n2f.git
ssh -T git@github.com

sudo apt update
sudo apt install docker.io -y
sudo usermod -aG docker $USER
newgrp docker
sudo docker system prune -a --volumes -f

sudo mkdir -p /mnt/data/docker
sudo rsync -aHAX --info=progress2 /var/lib/docker/ /mnt/data/docker/
sudo systemctl stop docker
sudo mkdir -p /etc/docker

echo '{ "data-root": "/mnt/data/docker" }' | sudo tee /etc/docker/daemon.json
sudo nano /etc/docker/daemon.json

{
  "data-root": "/mnt/data/docker"
}

df -h /
sudo systemctl start docker
docker info | grep -E "Docker Root Dir|Storage Driver"
docker ps -a
docker images
docker info | grep "Docker Root Dir"
sudo rm -rf /var/lib/docker
df -h /

rm -f ~/.docker/cli-plugins/docker-buildx
sudo rm -f /usr/local/lib/docker/cli-plugins/docker-buildx
sudo apt install --reinstall -y docker-buildx
docker buildx version

------------------------------------------------------
installer que dasn /mnt/data
sudo systemctl stop docker docker.socket containerd
sudo mkdir -p /mnt/data/containerd
sudo rsync -aHAX --info=progress2 /var/lib/containerd/ /mnt/data/containerd/
sudo mkdir -p /etc/containerd
echo 'root = "/mnt/data/containerd"' | sudo tee /etc/containerd/config.toml
sudo systemctl start containerd docker
sudo ctr version >/dev/null 2>&1; sudo containerd config dump | grep -E '^root|^state'
docker images
docker ps -a
sudo du -sh /var/lib/containerd /mnt/data/containerd
sudo rm -rf /var/lib/containerd
df -h /
------------------------------------------------------

cd /mnt/data/n2f

Fichier .env (dans /mnt/data/n2f/)

cd /mnt/data/n2f

chmod 600 .env
echo ".env" >> .gitignore
--------------------------------
.env.saas (toutes les autres variables du SaaS) :
 

sed -i "s|A_GENERER|$(openssl rand -hex 32)|" .env.saas
chmod 600 .env .env.saas
printf ".env\n.env.saas\n" >> .gitignore

# Build  v9.2.0 version
docker build \
  --build-arg ADDITIONAL_MODULES="" \
  -t n2f:1.1.0 .

  /*
# Build v8.4.8 version
#docker build   --build-arg AOS_VERSION=v8.4.8   -t axelor/aos-ce:v8.4.8 .
#docker build --build-arg AOS_VERSION=v8.4.8 -t n2f:v1.0.0 .
ou bien
docker build --no-cache \
  --build-arg AOS_VERSION=v8.4.8 \
  -t n2f:v1.0.0 .
  # docker buildx build --no-cache --build-arg AOS_VERSION=v8.4.8 -t n2f:v1.0.0 --load .
*/

docker images
sudo mkdir -p /mnt/data/axelor-data /mnt/data/postgres-data
sudo chown -R 1000:1000 /mnt/data/axelor-data
sudo apt install -y docker-compose-v2
docker compose down
sudo rm -rf /mnt/data/postgres-data/*
sudo chown -R 999:999 /mnt/data/postgres-data

docker compose up -d

docker compose logs -f app
docker compose logs db
docker compose logs -f

activer email smtp dasn axelor : Compte par défaut Compte par défaut ssl smtp.gmail.com
importer les roles dans gestion des appllications

https://taysirflow.duckdns.org/#/ds/admin.root.templating.template/edit/3
Dans le champ "Valeur Expr." de cette fenêtre, remplacez tout le texte par ceci :
eval: com.axelor.utils.helpers.StringHelper.escapeHtml(transientPassword)
eval: com.axelor.utils.helpers.StringHelper.escapeHtml(__repo__(User).find(id).transientPassword)

ajouter le role Expense User et role mobile base et mobile hr    a la group HRM
et perm.mobile.MetaFile.r en Cochez la case Modification (Write).
//et Timesheet Read:
//ajpter la permission perm.base.Product.rwcde au role Expense User
//aussi perm.auth.my,perm.base.company.r


------------pas avec nginix on a utiliser caddy:2-------------------

-------------------
1. Créer les deux domaines sur duckdns.org

Votre compte est à 1/5, il reste de la place. Dans la case « sub domain » puis « add domain », créez :

saas-taysirflow
api-taysirflow
---------------
sudo ln -s /etc/nginx/sites-available/saas /etc/nginx/sites-enabled/saas
sudo nginx -t && sudo systemctl reload nginx
sudo certbot --nginx -d saas-taysirflow.duckdns.org -d api-taysirflow.duckdns.org --redirect
--------------------------------------------------------------------------
4. Ouvrir les ports chez Infomaniak

Dans le pare-feu du panneau Infomaniak, autorisez TCP 80 et 443 en entrée. Sans cela, Let’s Encrypt ne peut pas valider le domaine. Si ufw est actif : sudo ufw allow 80,443/tcp.
5. Obtenir le certificat HTTPS
sudo certbot --nginx -d taysirflow.duckdns.org --redirect
softstream2027@gmail.com
6. Vérifier Depuis votre PC :
curl -I https://taysirflow.duckdns.org

2. Vérifier le renouvellement automatique du certificat
sudo certbot renew --dry-run
systemctl list-timers | grep certbot
3. Sécuriser Axelor

Changez le mot de passe admin (et ceux des comptes par défaut) dès maintenant.
Si des liens ou redirections partent en http://, réglez application.base.url=https://taysirflow.duckdns.org.

4. Sécurité générale

Régénérez le token DuckDNS, visible sur votre capture d’écran.
Limitez SSH (port 22) à votre IP dans le pare-feu Infomaniak si possible.
Gardez ouverts uniquement 22, 80 et 443.


2. Vérifier le renouvellement automatique du certificat
sudo certbot renew --dry-run
systemctl list-timers | grep certbot

5. Robustesse après redémarrage

Vérifiez que /mnt/data est monté automatiquement (/etc/fstab), car Docker et containerd y sont maintenant.
Vérifiez que les services démarrent au boot : 
systemctl is-enabled docker containerd nginx
Vos conteneurs doivent avoir restart: unless-stopped dans le compose.
6. Sauvegardes de la base
docker exec n2f-db pg_dump -U <user> <db> | gzip > /mnt/data/backup-$(date +%F).sql.gz
Vous pouvez la planifier avec crontab -e, par exemple chaque nuit à 2h. Pensez aussi à copier ces sauvegardes hors du serveur.

cd /mnt/data/n2f
mkdir -p /mnt/data/backups
cat > backup.sh <<'EOF'
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
EOF
chmod 700 backup.sh
2. Tester une fois à la main
./backup.sh
ls -lh /mnt/data/backups
3. Planifier chaque nuit à 2h
crontab -e
0 2 * * * /mnt/data/n2f/backup.sh >> /mnt/data/backups/backup.log 2>&1
--------------------------------------
Restauration
cd /mnt/data/n2f
docker compose stop app
docker exec -i n2f-db pg_restore -U sbsoft2026 -d sbsoft2026 --clean --if-exists --no-owner < /mnt/data/backups/db_sbsoft2026_2026-11-09_0938.dump
docker compose start app
Pour les fichiers :
sudo tar xzf /mnt/data/backups/files_2026-11-09_0938.tar.gz -C /mnt/data

1. Corriger les variables dans GitLab
https://gitlab.com/k8s-axelor/softstream-saas/-/settings/ci_cd#js-cicd-variables-settings
NEXT_PUBLIC_API_URL=https://api-taysirflow.duckdns.org et non pas https://softstream.taysirflow.duckdns.org
et alors modifier le url webhooks dans stripe:
1. Corriger l’URL dans Stripe Cliquez sur Modifier la destination et remplacez l’URL par :
https://api-taysirflow.duckdns.org/api/webhooks/stripe
------------------------------------------------------

Utilisez-la dans votre Helm values.yaml : 
image:
  repository: n2f
  tag: v1.0.0
  pullPolicy: IfNotPresent


------------pas avec nginix on a utiliser caddy:2-------------------
https nginix :
2. Installer Nginx et Certbot
sudo apt install -y nginx certbot python3-certbot-nginx

sudo nano /etc/nginx/sites-available/n2f
server {
    listen 80;
    server_name taysirflow.duckdns.org;

    client_max_body_size 100m;

    location / {
        proxy_pass http://127.0.0.1:8080;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        # Timeout long pour Axelor (qui peut mettre du temps à générer des rapports)
        proxy_read_timeout 300s;
        proxy_connect_timeout 300s;
        proxy_send_timeout 300s;
    }
}
sudo nano /etc/nginx/sites-available/saas
# --- FRONTEND NEXT.JS ---
server {
    listen 80;
    server_name saas-taysirflow.duckdns.org;

    location / {
        proxy_pass http://127.0.0.1:3000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        # 👇 CRUCIAL POUR NEXT.JS (WebSockets / Hot Reload)
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
    }
}

# --- BACKEND NESTJS (API) ---
server {
    listen 80;
    server_name api-taysirflow.duckdns.org;

    client_max_body_size 20m;

    location / {
        proxy_pass http://127.0.0.1:4000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        # 👇 CRUCIAL POUR NESTJS (WebSockets)
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
    }
}
# Activer les sites
sudo ln -s /etc/nginx/sites-available/n2f /etc/nginx/sites-enabled/
sudo ln -s /etc/nginx/sites-available/saas /etc/nginx/sites-enabled/

# Supprimer le site par défaut (pour éviter les conflits)
sudo rm -f /etc/nginx/sites-enabled/default

# Tester la syntaxe
sudo nginx -t

# Recharger Nginx
sudo systemctl reload nginx

# Certificat pour Axelor
sudo certbot --nginx -d taysirflow.duckdns.org --redirect

softstream2027@gmail.com

# Certificat pour le SaaS (Front + API d'un coup)
sudo certbot --nginx -d saas-taysirflow.duckdns.org -d api-taysirflow.duckdns.org --redirect

/*
ou bien:
-------------------------en cas de souci-----------------------------
docker buildx build --build-arg AOS_VERSION=v8.4.8 -t n2f:v1.0.0 --load .
docker compose up -d --force-recreate app
docker exec n2f-app /home/axelor/tomcat/bin/version.sh | head -3
------------------------------------------------------

3. Créer la configuration du site
sudo tee /etc/nginx/sites-available/n2f >/dev/null <<'EOF'
server {
    listen 80;
    server_name taysirflow.duckdns.org;

    client_max_body_size 100m;

    location / {
        proxy_pass http://127.0.0.1:8080;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_read_timeout 300s;
    }
}
EOF

sudo ln -s /etc/nginx/sites-available/n2f /etc/nginx/sites-enabled/n2f
sudo rm -f /etc/nginx/sites-enabled/default
sudo nginx -t && sudo systemctl reload nginx
---------------------------------------------------------------------------
sudo tee /etc/nginx/sites-available/saas >/dev/null <<'EOF'
server {
    listen 80;
    server_name saas-taysirflow.duckdns.org;
    location / {
        proxy_pass http://127.0.0.1:3000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
server {
    listen 80;
    server_name api-taysirflow.duckdns.org;
    client_max_body_size 20m;
    location / {
        proxy_pass http://127.0.0.1:4000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
EOF
------
*/





------------a zero----------------------------
./restore.sh list  
Sauvegardes disponibles dans /mnt/data/backups (les plus récentes d'abord) : 2026-11-10_230000 = base avec data demo std all
 ./restore.sh 2026-11-10_230000 all
 ----------------------------------------------
 docker compose exec -T db psql -U sbsoft2026 -d sbsoft2026 -v ON_ERROR_STOP=1 < delete_all.sql
# 1. Arrêter le conteneur de la base SaaS
docker compose stop saas-db
# 2. Vider le dossier de données (ATTENTION : cela supprime tout)
sudo rm -rf /mnt/data/saas-postgres-data/*
# 3. Redémarrer le conteneur (il va recréer une base vierge)
docker compose up -d saas-db
docker compose exec backend npx prisma migrate reset --force
docker compose exec backend npx prisma db push
docker compose restart backend


docker compose pull frontend
docker compose up -d --force-recreate frontend

docker compose pull backend
docker compose up -d --force-recreate backend

docker compose logs --tail=100 backend
docker compose logs -f app
