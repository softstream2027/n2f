# n2f
git clone https://github.com/softstream2027/n2f.git
cd n2f/


#Axelor std v8.4.8:
https://github.com/axelor/axelor-docker.git


sudo apt update
sudo apt install docker.io -y
sudo usermod -aG docker $USER
newgrp docker


# Build v8.4.8 version
docker build \
  --build-arg AOS_VERSION=v8.4.8 \
  -t axelor/aos-ce:v8.4.8 .
