#Axelor std v8.4.8:
https://github.com/axelor/axelor-docker.git

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
sudo systemctl stop docker
sudo nano /etc/docker/daemon.json
{
  "data-root": "/mnt/data/docker"
}
sudo systemctl start docker
docker info | grep "Docker Root Dir"

rm -f ~/.docker/cli-plugins/docker-buildx
sudo rm -f /usr/local/lib/docker/cli-plugins/docker-buildx
sudo apt install --reinstall -y docker-buildx
docker buildx version


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
docker compose up -d
docker compose logs db

------------------------------------------------------
Utilisez-la dans votre Helm values.yaml : 
image:
  repository: n2f
  tag: v1.0.0
  pullPolicy: IfNotPresent
------------------------------------------------------
