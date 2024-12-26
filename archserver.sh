#==============================================================================
# SECTION 1: System Preparation
#==============================================================================

## Configure drive
sudo mkdir /mnt/sda1
sudo mkfs.btrfs -f /dev/sda1 # Don't forget to backup your data!
sudo mount /dev/sda1 /mnt/sda1
sudo sh -c 'echo "/dev/sda1 /mnt/sda1 btrfs defaults 0 2" >> /etc/fstab'
sudo systemctl daemon-reload

## Configure RAID
# sudo mkdir /mnt/raid
# sudo mkfs.btrfs -f -d raid1 -m raid1 /dev/sda /dev/sdb # Add more devices if you want
# sudo mount /dev/sda /mnt/raid
# sudo sh -c 'echo "/dev/sda /mnt/raid btrfs defaults 0 2" >> /etc/fstab'
# sudo systemctl daemon-reload

## Configure pacman
sudo sed -i 's/#Color/Color/' /etc/pacman.conf
sudo sed -i 's/#VerbosePkgLists/VerbosePkgLists/' /etc/pacman.conf
sudo sed -i 's/#ParallelDownloads/ParallelDownloads/' /etc/pacman.conf

#==============================================================================
# SECTION 2: Package Installation and Configuration
#==============================================================================

## Install necessary applilcations
sudo pacman -Syyu --noconfirm cronie dhcpcd docker docker-compose firewalld openssh rsync # Install networkmanager to manage Wi-Fi connections

## Install recommended applications
sudo pacman -S --noconfirm bash-completion btop fastfetch nano powertop xorg-xset

## Configure dhcpcd
sudo systemctl enable dhcpcd.service # Enable networkmanager if installed

## Configure fastfetch
fastfetch --gen-config
echo "fastfetch" >> ~/.bashrc
echo "alias clearfetch='clear && fastfetch'" >> ~/.bashrc
source ~/.bashrc

#==============================================================================
# SECTION 3: SSH Configuration
#==============================================================================

## Set port for SSH
blocked_ports=("80" "81" "90" "403" "443" "1900" "2283" "5800" "7359" "7575" "7878" "8080" "8096" "8920" "9443")
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
# SECTION 4: Immich preparation
#==============================================================================

## Set password for immich database
mkdir ~/Server/immich
read -s -p "Enter your Immich database password: " DB_PASSWORD

## Create environment file
cat > ~/Server/immich/.env << EOF ## Change every /home/enrique* to your user's home directory
# You can find documentation for all the supported env variables at https://immich.app/docs/install/environment-variables

# The location where your uploaded files are stored
UPLOAD_LOCATION=/home/enrique/Server/immich/library
# The location where your database files are stored
DB_DATA_LOCATION=/home/enrique/Server/immich/postgres

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
curl -L -o ~/Server/immich/hwaccel.transcoding.yml https://github.com/immich-app/immich/releases/latest/download/hwaccel.transcoding.yml
curl -L -o ~/Server/immich/hwaccel.ml.yml https://github.com/immich-app/immich/releases/latest/download/hwaccel.ml.yml

#==============================================================================
# SECTION 5: Docker configuration
#==============================================================================

## Start Docker
sudo systemctl enable docker.service
sudo systemctl start docker.service

## Set Duck DNS domain and token
read -p "Enter your Duck DNS domain: " duck_domain
read -p "Enter your Duck DNS token: " duck_token

## Create docker-compose file
cat > ~/Server/immich/docker-compose.yml << 'EOF'
services:
  duckdns:
    image: lscr.io/linuxserver/duckdns:latest
    container_name: duckdns
    network_mode: host #optional
    environment:
      - PUID=1000 #optional
      - PGID=1000 #optional
      - TZ=Etc/UTC #optional
      - SUBDOMAINS=${duck_domain}
      - TOKEN=${duck_token}
      - UPDATE_IP=ipv4 # Optional
      - LOG_FILE=false # Optional
    volumes:
      - /path/to/duckdns/config:/config # Optional
    restart: unless-stopped
---
services:
  homarr:
    image: ghcr.io/ajnart/homarr:latest
    container_name: homarr
    environment:
      - PUID=1000
      - PGID=1000
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock # Optional, only if you want docker integration
      - /home/enrique/Server/homarr/configs:/app/data/configs
      - /home/enrique/Server/homarr/icons:/app/public/icons
      - /home/enrique/Server/homarr/data:/data
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
      - /home/enrique/Server/immich/model-cache:/cache
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
      - /home/enrique/Server/jellyfin/library:/config
      - /mnt/sda1/Filme:/data/movies # Change directory if you are using RAID
      - /mnt/sda1/Musik:/data/music # Change directory if you are using RAID
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
      - /home/enrique/Server/makemkv/docker/appdata/makemkv:/config:rw
      - /home/enrique/Server/makemkv:/storage:ro
      - /mnt/sda1:/output:rw # Change directory if you are using RAID
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
      - /home/enrique/Server/nextcloud/config:/config
      - /home/enrique/Server/nextcloud/data:/data
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
      - /home/enrique/Server/nginx-proxy-manager/data:/data
      - /home/enrique/Server/nginx-proxy-manager/letsencrypt:/etc/letsencrypt
    ports:
      - 90:90 # Changed it to avoid conflict with Vaultwarden
      - 81:81
      - 403:403 # Changed it to avoid conflict with Nextcloud
    restart: unless-stopped
---
services:
  portainer:
    image: portainer/portainer-ce:latest
    container_name: portainer
    environment:
      - PUID=1000
      - PGID=1000
    volumes:
        - /home/enrique/Server/portainer/data:/data
        - /var/run/docker.sock:/var/run/docker.sock
    ports:
      - 9443:9443
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
      - /home/enrique/Server/radarr/data:/config
      - /mnt/sda1/Filme:/movies
      - /mnt/sda1:/downloads
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
      - /home/enrique/Server/sabnzbd/config:/config
      - /mnt/sda1:/downloads
      - /mnt/sda1/sabnzbd/incomplete:/incomplete-downloads
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
      - /home/enrique/Server/vaultwarden/vw-data:/data
    ports:
      - 80:80
    restart: unless-stopped
---
services:
  watchtower:
    image: containrrr/watchtower
    container_name: watchtower
    environment:
      - PUID=1000
      - PGID=1000
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
    restart: unless-stopped
EOF

## Run docker-compose file
sudo docker compose -f ~/Server/immich/docker-compose.yml up -d

#==============================================================================
# SECTION 6: Backup creation
#==============================================================================

## Setup backup
sudo chown -R $(whoami) /mnt/sda1 # Change directory if you are using RAID
echo "rsync -avh --delete ~/Server /mnt/sda1/" > ~/Server/server_backup.sh # Change directory if you are using RAID
chmod +x ~/Server/server_backup.sh
(crontab -l 2>/dev/null; echo "0 3 * * * ~/Server/server_backup.sh") | crontab -
sudo chown -R $(whoami) ~/Server
~/Server/server_backup.sh

#==============================================================================
# SECTION 7: Cleanup
#==============================================================================

## Remove unnecessary files
sudo pacman -Qdtq | awk '{print $1}' | xargs -r sudo pacman -Rns --noconfirm
sudo pacman -Scc --noconfirm
sudo rm -rf ~/.cache/go-build
sudo rm -rf ~/.config/go

## Update system
sudo pacman -Syyu --noconfirm
sudo powertop --calibrate
sudo powertop --auto-tune

## Remember SSH port
echo -e "Your SSH port is: $random_port"