## Configure pacman
sudo sed -i 's/#Color/Color/' /etc/pacman.conf
sudo sed -i 's/#VerbosePkgLists/VerbosePkgLists/' /etc/pacman.conf
sudo sed -i 's/#ParallelDownloads/ParallelDownloads/' /etc/pacman.conf

## Add repositories
sudo sh -c 'echo "" >> /etc/pacman.conf'
sudo sh -c 'echo "[gnome-unstable]" >> /etc/pacman.conf'
sudo sh -c 'echo "Include = /etc/pacman.d/mirrorlist" >> /etc/pacman.conf'
sudo sh -c 'echo "" >> /etc/pacman.conf'
sudo sh -c 'echo "[kde-unstable]" >> /etc/pacman.conf'
sudo sh -c 'echo "Include = /etc/pacman.d/mirrorlist" >> /etc/pacman.conf'

## Install yay
sudo pacman -Syyu
sudo pacman -S git
git clone https://aur.archlinux.org/yay.git
( cd yay && makepkg -si )
sudo rm -rf ~/yay

## Install applications
yay -S cronie dhcpcd docker docker-compose firewalld openssh powertop
yay -S bash-completion fastfetch

## Configure system apps
sudo systemctl enable dhcpcd.service
fastfetch --gen-config
sh -c 'echo "fastfetch" >> ~/.bashrc'
alias clearfast='clear && fastfetch'

## Set Duck DNS domain and token
read -p "Enter your Duck DNS domain: " duck_domain
read -p "Enter your Duck DNS token: " duck_token

## Configure Duck DNS
mkdir ~/duckdns
echo "echo url=\"https://www.duckdns.org/update?domains=${duck_domain}&token=${duck_token}&ip=&verbose=true\" | curl -k -o ~/duckdns/duck.log -K -" > ~/duckdns/duck.sh
chmod 700 ~/duckdns/duck.sh
echo "*/5 * * * * ~/duckdns/duck.sh >/dev/null 2>&1" | crontab -
sudo systemctl enable cronie.service

## Configure SSH
blocked_ports=("80" "81" "90" "403" "443" "1900" "2283" "5800" "6881" "7359" "7575" "7878" "8080" "8096" "8282" "8920" "9117")
while true; do
    random_port=$(shuf -i 1000-9999 -n 1)
    
    # Check if the generated port is in the blocked list
    if [[ ! " ${blocked_ports[@]} " =~ " ${random_port} " ]]; then
        break
    fi
done
sudo sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin no/' /etc/ssh/sshd_config
sudo sed -i "s/#Port 22/Port ${random_port}/" /etc/ssh/sshd_config
echo "Using random SSH port: ${random_port}"
sudo systemctl enable sshd.service
sudo systemctl enable firewalld.service
sudo systemctl start firewalld.service
sudo firewall-cmd --zone=public --add-port=${random_port}/tcp --permanent
sudo firewall-cmd --reload

## Configure Docker
sudo systemctl enable docker.service
sudo systemctl start docker.service
mkdir ~/docker-compose
read -s -p "Enter your Immich database password: " DB_PASSWORD
echo "# You can find documentation for all the supported env variables at https://immich.app/docs/install/environment-variables

# The location where your uploaded files are stored
UPLOAD_LOCATION=~/docker-compose/immich-app/library
# The location where your database files are stored
DB_DATA_LOCATION=~/docker-compose/immich-app/postgres

# To set a timezone, uncomment the next line and change Etc/UTC to a TZ identifier from this list: https://en.wikipedia.org/wiki/List_of_tz_database_time_zones#List
# TZ=Etc/UTC

# The Immich version to use. You can pin this to a specific version like "v1.71.0"
IMMICH_VERSION=release

# Connection secret for postgres. You should change it to a random password
# Please use only the characters `A-Za-z0-9`, without special characters or spaces
DB_PASSWORD=${DB_PASSWORD}

# The values below this line do not need to be changed
###################################################################################
DB_USERNAME=postgres
DB_DATABASE_NAME=immich" > ~/docker-compose/.env
curl -L -o ~/docker-compose/hwaccel.transcoding.yml https://github.com/immich-app/immich/releases/latest/download/hwaccel.transcoding.yml
curl -L -o ~/docker-compose/hwaccel.ml.yml https://github.com/immich-app/immich/releases/latest/download/hwaccel.ml.yml
echo "## This installation script sets up various services for a home server using Docker Compose (Homarr, Immich, Nextcloud, Vaultwarden, Jellyfin, Jackett, Radarr, Sabnzbd and Nginx Proxy Manager)
## I took a combination of linuxserver.io and official Docker containers. Then edited the 'restart' settings for all to have the same policy and sorted all sections to "harmonize" the file.
## Ensure that this file is placed in the same folder as the .env and other .yml files for Immich to work correctly.

services:
  homarr:
    image: ghcr.io/ajnart/homarr:latest
    container_name: homarr
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock # Optional, only if you want docker integration
      - ~/docker-compose/homarr/configs:/app/data/configs
      - ~/docker-compose/homarr/icons:/app/public/icons
      - ~/docker-compose/homarr/data:/data
    ports:
      - '7575:7575'
    restart: unless-stopped
---
services:      
  immich-server:
    image: ghcr.io/immich-app/immich-server:${IMMICH_VERSION:-release}  
    container_name: immich_server
    volumes:
      - ${UPLOAD_LOCATION}:/usr/src/app/upload
      - /etc/localtime:/etc/localtime:ro
    ports:
      - '2283:2283' 
    restart: unless-stopped 
    extends:
      file: hwaccel.transcoding.yml
      service: quicksync
    env_file:
      - .env
    depends_on:
      - redis
      - database
---
services:
  immich-machine-learning:
    image: ghcr.io/immich-app/immich-machine-learning:${IMMICH_VERSION:-release}-openvino
    container_name: immich_machine_learning
    volumes:
      - model-cache:/cache
    restart: unless-stopped
    extends:
      file: hwaccel.ml.yml
      service: openvino
    env_file:
      - .env
---
services:
  redis:
    image: docker.io/redis:6.2-alpine@sha256:eaba718fecd1196d88533de7ba49bf903ad33664a92debb24660a922ecd9cac8
    container_name: immich_redis
    restart: unless-stopped
---
services:
  database:
    image: docker.io/tensorchord/pgvecto-rs:pg14-v0.2.0@sha256:90724186f0a3517cf6914295b5ab410db9ce23190a2d9d0b9dd6463e3fa298f0
    container_name: immich_postgres
    environment:
      POSTGRES_PASSWORD: ${DB_PASSWORD}
      POSTGRES_USER: ${DB_USERNAME}
      POSTGRES_DB: ${DB_DATABASE_NAME}
      POSTGRES_INITDB_ARGS: '--data-checksums'
    volumes:
      - ${DB_DATA_LOCATION}:/var/lib/postgresql/data
    restart: unless-stopped
    command: >-
      postgres
      -c shared_preload_libraries=vectors.so
      -c 'search_path="$$user", public, vectors'
      -c logging_collector=on
      -c max_wal_size=2GB
      -c shared_buffers=512MB
      -c wal_compression=on
volumes:
  model-cache:
---
services:
  jackett:
    image: lscr.io/linuxserver/jackett:latest
    container_name: jackett
    environment:
      - PUID=1000
      - PGID=1000
      - TZ=Etc/UTC
      - AUTO_UPDATE=true
      - RUN_OPTS=
    volumes:
      - ~/docker-compose/jackett/data:/config
      - ~/docker-compose/blackhole:/downloads
    ports:
      - 9117:9117
    restart: unless-stopped
---
services:
  jellyfin:
    image: lscr.io/linuxserver/jellyfin:nightly
    container_name: jellyfin
    environment:
      - PUID=1000
      - PGID=1000
      - TZ=Etc/UTC
      - JELLYFIN_PublishedServerUrl=http://192.168.0.5
    volumes:
      - ~/docker-compose/jellyfin/library:/config
      - ~/docker-compose/tvseries:/data/tvshows
      - ~/docker-compose/movies:/data/movies
    ports:
      - 8096:8096
      - 8920:8920
      - 7359:7359/udp
      - 1900:1900/udp
    restart: unless-stopped
---
services:
  makemkv:
    image: jlesage/makemkv
    volumes:
      - "~/docker-compose/docker/appdata/makemkv:/config:rw"
      - "~/docker-compose:/storage:ro"
      - "~/docker-compose:/output:rw"
    ports:
      - "5800:5800"
    devices:
      - "/dev/sr0:/dev/sr0"
      - "/dev/sg2:/dev/sg2"
    restart: unless-stopped
---
services:
  nextcloud:
    image: lscr.io/linuxserver/nextcloud:develop
    container_name: nextcloud
    environment:
      - PUID=1000
      - PGID=1000
      - TZ=Etc/UTC
    volumes:
      - ~/docker-compose/nextcloud/config:/config
      - ~/docker-compose/data:/data
    ports:
      - 443:443
    restart: unless-stopped
---
services:
  app:
    image: 'docker.io/jc21/nginx-proxy-manager:latest'
    volumes:
      - data:/data
      - ~/docker-compose/letsencrypt:/etc/letsencrypt
    ports:
      - '90:90' # Changed it to avoid conflict with Vaultwarden
      - '81:81'
      - '403:403' # Changed it to avoid conflict with Nextcloud
    restart: unless-stopped
---
services:
  qbittorrent:
    image: lscr.io/linuxserver/qbittorrent:latest
    container_name: qbittorrent
    environment:
      - PUID=1000
      - PGID=1000
      - TZ=Etc/UTC
      - WEBUI_PORT=8282 # Changed it to avoid conflict with SABnzbd
      - TORRENTING_PORT=6881
    volumes:
      - ~/docker-compose/qbittorrent/appdata:/config
      - ~/docker-compose/downloads:/downloads #optional
    ports:
      - 8282:8282 # Changed it to avoid conflict with SABnzbd
      - 6881:6881
      - 6881:6881/udp
    restart: unless-stopped
---
services:
  radarr:
    image: lscr.io/linuxserver/radarr:nightly
    container_name: radarr
    environment:
      - PUID=1000
      - PGID=1000
      - TZ=Etc/UTC
    volumes:
      - ~/docker-compose/radarr/data:/config
      - ~/docker-compose/movies:/movies
      - ~/docker-compose/download-client-downloads:/downloads
    ports:
      - 7878:7878
    restart: unless-stopped
---
services:
  sabnzbd:
    image: lscr.io/linuxserver/sabnzbd:nightly
    container_name: sabnzbd
    environment:
      - PUID=1000
      - PGID=1000
      - TZ=Etc/UTC
    volumes:
      - ~/docker-compose/sabnzbd/config:/config
      - ~/docker-compose/downloads:/downloads
      - ~/docker-compose/incomplete/downloads:/incomplete-downloads
    ports:
      - 8080:8080
    restart: unless-stopped
---
services:
  vaultwarden:
    image: vaultwarden/server:testing
    container_name: vaultwarden
    volumes:
      - ~/docker-compose/vw-data:/data
    ports:
      - 80:80
    restart: unless-stopped" > ~/docker-compose/docker-compose.yml
sudo docker compose -f ~/docker-compose/docker-compose.yml up -d

## Update
yay -Rnsu git
yay -Yc
sudo pacman -Scc
yay -Syyu
sudo powertop --auto-tune
