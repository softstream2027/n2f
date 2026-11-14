sudo apt update
sudo apt install -y ansible-core


cd /mnt/data 
sudo chown -R ubuntu:ubuntu /mnt/data
git clone https://github.com/softstream2027/n2f.git
cd n2f/
ls -la
cp .env.example   .env   
cp .env.saas.example .env.saas

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

 
sudo systemctl start docker
docker info | grep -E "Docker Root Dir|Storage Driver"
docker ps -a
docker images
docker info | grep "Docker Root Dir"
sudo rm -rf /var/lib/docker
 

rm -f ~/.docker/cli-plugins/docker-buildx
sudo rm -f /usr/local/lib/docker/cli-plugins/docker-buildx
sudo apt install --reinstall -y docker-buildx
docker buildx version
 
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
 
cd /mnt/data/n2f
 
chmod 600 .env
echo ".env" >> .gitignore
sed -i "s|A_GENERER|$(openssl rand -hex 32)|" .env.saas
chmod 600 .env .env.saas
printf ".env\n.env.saas\n" >> .gitignore

docker build \
  --build-arg ADDITIONAL_MODULES="" \
  -t n2f:1.1.0 .
 

docker images
sudo mkdir -p /mnt/data/axelor-data /mnt/data/postgres-data
sudo chown -R 1000:1000 /mnt/data/axelor-data
sudo apt install -y docker-compose-v2
docker compose down
sudo rm -rf /mnt/data/postgres-data/*
sudo chown -R 999:999 /mnt/data/postgres-data

docker compose up -d
 

3. Planifier chaque nuit à 2h
crontab -e
0 2 * * * /mnt/data/n2f/backup.sh >> /mnt/data/backups/backup.log 2>&1
  
    
 docker compose exec -T db psql -U sbsoft2026 -d sbsoft2026 -v ON_ERROR_STOP=1 < delete_all.sql
  

 
 