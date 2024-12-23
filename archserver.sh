#==============================================================================
# SECTION 1: System Preparation
#==============================================================================

## Buffer sudo for the whole script
sudo -v
while true; do sudo -v; sleep 60; done &

## Configure drives
sudo sh -c 'echo "/dev/sda1   /mnt/sda1   ext4   defaults   0   2" >> /etc/fstab'
sudo systemctl daemon-reload

## Configure RAID
# sudo pacman -Syyu --noconfirm mdadm
# sudo wipefs --all /dev/sda
# sudo wipefs --all /dev/sdb # Add more if you have more drives
# sudo mdadm --create /dev/md0 --level=1 --raid-devices=2 /dev/sda /dev/sdb # Add more if you have more drives
# sudo mkfs.ext4 /dev/md0
# sudo sh -c 'echo "/dev/md0 /mnt/raid ext4 defaults 0 0" >> /etc/fstab'
# sudo mdadm --detail --scan >> /etc/mdadm.conf
# sudo mkinitcpio -P

## Configure pacman
sudo sed -i 's/#Color/Color/' /etc/pacman.conf
sudo sed -i 's/#VerbosePkgLists/VerbosePkgLists/' /etc/pacman.conf
sudo sed -i 's/#ParallelDownloads/ParallelDownloads/' /etc/pacman.conf

## Add repositories
sudo sh -c 'cat >> /etc/pacman.conf << EOF

[gnome-unstable]
Include = /etc/pacman.d/mirrorlist

[kde-unstable]
Include = /etc/pacman.d/mirrorlist
EOF'

## Install yay
sudo pacman -Syyu --noconfirm git # Only run pacman -S if you installed mdadm
git clone https://aur.archlinux.org/yay.git
(cd yay && makepkg -si --noconfirm)
sudo rm -rf ~/yay

#==============================================================================
# SECTION 2: Package Installation and Configuration
#==============================================================================

## Install necessary applilcations
yay -S --noconfirm cronie dhcpcd docker docker-compose firewalld openssh # Install networkmanager to manage Wi-Fi connections

## Install recommended applications
yay -S --noconfirm bash-completion fastfetch nano powertop xorg-xset

## Configure dhcpcd
sudo systemctl enable dhcpcd.service # Enable networkmanager if installed

## Configure fastfetch
fastfetch --gen-config
echo "fastfetch" >> ~/.bashrc
echo "alias clearfetch='clear && fastfetch'" >> ~/.bashrc
source ~/.bashrc

#==============================================================================
# SECTION 3: Duck DNS Configuration
#==============================================================================

## Set Duck DNS domain and token
read -p "Enter your Duck DNS domain: " duck_domain
read -p "Enter your Duck DNS token: " duck_token

## Configure Duck DNS
mkdir -p ~/server/duckdns
echo "echo url=\"https://www.duckdns.org/update?domains=${duck_domain}&token=${duck_token}&verbose=true\" | curl -k -o ~/server/duckdns/duck.log -K -" > ~/server/duckdns/duck.sh
chmod 700 ~/server/duckdns/duck.sh
echo "*/5 * * * * ~/server/duckdns/duck.sh >/dev/null 2>&1" | crontab -
sudo systemctl enable cronie.service
~/server/duckdns/duck.sh

#==============================================================================
# SECTION 4: SSH Configuration
#==============================================================================

## Set port for SSH
blocked_ports=("80" "81" "90" "403" "443" "1900" "2283" "5800" "6881" "7359" "7575" "7878" "8080" "8096" "8282" "8920" "9117")
while true; do
    random_port=$(shuf -i 1000-9999 -n 1)
    
    # Check if the generated port is in the blocked list
    if [[ ! " ${blocked_ports[@]} " =~ " ${random_port} " ]]; then
        break
    fi
done

## Edit SSH config
sudo sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin no/' /etc/ssh/sshd_config
sudo sed -i "s/#Port 22/Port ${random_port}/" /etc/ssh/sshd_config
sudo systemctl enable sshd.service

## Congure firewalld
sudo systemctl enable firewalld.service
sudo systemctl start firewalld.service
sudo firewall-cmd --zone=public --add-port=${random_port}/tcp --permanent
for port in "${blocked_ports[@]}"; do
    sudo firewall-cmd --zone=public --add-port=${port}/tcp --permanent
done
sudo firewall-cmd --reload

#==============================================================================
# SECTION 5: Immich preparation
#==============================================================================

## Set password for immich database
mkdir ~/server/immich
read -s -p "Enter your Immich database password: " DB_PASSWORD

## Create environment file
cat > ~/server/immich/.env << EOF
# You can find documentation for all the supported env variables at https://immich.app/docs/install/environment-variables

# The location where your uploaded files are stored
UPLOAD_LOCATION=~/server/immich/library
# The location where your database files are stored
DB_DATA_LOCATION=~/server/immich/postgres

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
DB_DATABASE_NAME=immich
EOF

## Download hardware acceleration files
curl -L -o ~/server/immich/hwaccel.transcoding.yml https://github.com/immich-app/immich/releases/latest/download/hwaccel.transcoding.yml
curl -L -o ~/server/immich/hwaccel.ml.yml https://github.com/immich-app/immich/releases/latest/download/hwaccel.ml.yml

#==============================================================================
# SECTION 6: Docker configuration
#==============================================================================

## Start Docker
sudo systemctl enable docker.service
sudo systemctl start docker.service

## Create docker-compose file
cat > ~/server/immich/docker-compose.yml << 'EOF' 
services:
  homarr:
    image: ghcr.io/ajnart/homarr:latest
    container_name: homarr
    environment:
      - PUID=1000
      - PGID=1000
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock # Optional, only if you want docker integration
      - ~/server/homarr/configs:/app/data/configs
      - ~/server/homarr/icons:/app/public/icons
      - ~/server/homarr/data:/data
    ports:
      - 7575:7575
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
      - 2283:2283 
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
      - ~/server/jackett/data:/config
      - ~/server/jackett/blackhole:/downloads
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
      - ~/server/jellyfin/library:/config
      - ~/server/jellyfin/tvseries:/data/tvshows
      - ~/server/jellyfin/movies:/data/movies
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
    container_name: makemkv
    environment:
      - PUID=1000
      - PGID=1000
    volumes:
      - ~/server/makemkv/docker/appdata/makemkv:/config:rw
      - ~/server/makemkv:/storage:ro
      - ~/server/makemkv:/output:rw
    ports:
      - 5800:5800
  # devices: # Uncomment if you have optical drives
      # - /dev/sr0:/dev/sr0 # Uncomment if you have optical drives
      # - /dev/sg2:/dev/sg2 # Uncomment if you have optical drives
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
      - ~/server/nextcloud/config:/config
      - ~/server/nextcloud/data:/data
    ports:
      - 443:443
    restart: unless-stopped
---
services:
  nginx-proxy-manager:
    image: docker.io/jc21/nginx-proxy-manager:latest
    container_name: nginx-proxy-manager
    environment:
      - PUID=1000
      - PGID=1000
    volumes:
      - ~/server/nginx-proxy-manager/data:/data
      - ~/server/nginx-proxy-manager/letsencrypt:/etc/letsencrypt
    ports:
      - 90:90 # Changed it to avoid conflict with Vaultwarden
      - 81:81
      - 403:403 # Changed it to avoid conflict with Nextcloud
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
      - ~/server/qbittorrent/appdata:/config
      - ~/server/qbittorrent/downloads:/downloads
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
      - ~/server/radarr/data:/config
      - ~/server/radarr/movies:/movies
      - ~/server/radarr/download-client-downloads:/downloads
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
      - ~/server/sabnzbd/config:/config
      - ~/server/sabnzbd/downloads:/downloads
      - ~/server/sabnzbd/incomplete/downloads:/incomplete-downloads
    ports:
      - 8080:8080
    restart: unless-stopped
---
services:
  vaultwarden:
    image: vaultwarden/server:testing
    container_name: vaultwarden
    environment:
      - PUID=1000
      - PGID=1000
    volumes:
      - ~/server/vaultwarden/vw-data:/data
    ports:
      - 80:80
    restart: unless-stopped
EOF

## Run docker-compose file
sudo docker compose -f ~/server/immich/docker-compose.yml up -d

#==============================================================================
# SECTION 7: Cleanup
#==============================================================================

## Remove unnecessary files
yay -Yc --noconfirm
sudo pacman -Scc --noconfirm

## Update system
yay -Syyu --noconfirm
sudo powertop --calibrate
sudo powertop --auto-tune

## Stop sudo buffer
pkill -f "sudo -v"

## Remember SSH port
echo -e "Your SSH port is: $random_port"