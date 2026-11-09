#Axelor std v8.4.8:
https://github.com/axelor/axelor-docker.git
https://github.com/axelor/open-suite-webapp/tree/v8.4.8

ssh-keygen -f "/home/audaxis/.ssh/known_hosts" -R "83.228.244.59"
ssh -i ~/.ssh/mekkaoui.pem ubuntu@83.228.244.59
cd /mnt/data
df -h
sudo chown -R ubuntu:ubuntu /mnt/data

# n2f
git clone https://github.com/softstream2027/n2f.git
cd n2f/

git config --global user.name "softstream2027"
git config --global user.email "softstream2027@gmail.com"
ssh -T git@github.com
ssh-keygen -t ed25519 -C "softstream2027@gmail.com"
cat ~/.ssh/id_ed25519.pub
Ajoutez la clé publique (~/.ssh/id_ed25519.pub) sur GitHub : Settings > SSH and GPG keys > New SSH key.
git remote set-url origin git@github.com:softstream2027/n2f.git
ssh -T git@github.com

sudo apt update
sudo apt install docker.io -y
sudo usermod -aG docker $USER
newgrp docker


sudo docker system prune -a --volumes -f
df -h /
sudo mkdir -p /mnt/data/docker

sudo rsync -aHAX --info=progress2 /var/lib/docker/ /mnt/data/docker/
sudo systemctl stop docker
sudo mkdir -p /etc/docker
echo '{ "data-root": "/mnt/data/docker" }' | sudo tee /etc/docker/daemon.json
sudo nano /etc/docker/daemon.json
{
  "data-root": "/mnt/data/docker"
}
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

# Build v8.4.8 version
#docker build   --build-arg AOS_VERSION=v8.4.8   -t axelor/aos-ce:v8.4.8 .
docker build --build-arg AOS_VERSION=v8.4.8 -t n2f:v1.0.0 .
ou bien
docker build --no-cache \
  --build-arg AOS_VERSION=v8.4.8 \
  -t n2f:v1.0.0 .

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
------------------------------------------------------
Utilisez-la dans votre Helm values.yaml : 
image:
  repository: n2f
  tag: v1.0.0
  pullPolicy: IfNotPresent
