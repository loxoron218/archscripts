# archscripts
Collection of scripts to configure my Linux system. Arch BTW.

## On a fresh installation, use this to mount your USB and run the selected script
`mkdir ~/USB`

`sudo mount /dev/sda1 ~/USB`

`/home/enrique/USB/archserver.sh`

## After ending, run this to unmount your USB and clean leftovers
`sudo umount /dev/sda1`

`sudo rm -rf /home/enrique/USB`

## Ressources
1.  Homarr Installtion Guide: https://homarr.dev/docs/getting-started/installation/
2.  Immich Docker Compose Installation Guide: https://immich.app/docs/install/docker-compose/
3.  Immich Docker Example .env file: https://github.com/immich-app/immich/blob/main/docker/example.env
4.  LinuxServer.io Docker Image for Jackett: https://docs.linuxserver.io/images/docker-radarr/
5.  LinuxServer.io Docker Image for Jellyfin: https://docs.linuxserver.io/images/docker-jellyfin/
6.  MakeMKV Docker Github Repository: https://github.com/jlesage/docker-makemkv
7.  LinuxServer.io Docker Image for Nextcloud: https://docs.linuxserver.io/images/docker-nextcloud/
8.  Nginx Proxy Manager GitHub Repository: https://github.com/NginxProxyManager/nginx-proxy-manager
9.  LinuxServer.io Docker Image for Radarr: https://docs.linuxserver.io/images/docker-radarr/
10.  LinuxServer.io Docker Image for SABnzbd: https://docs.linuxserver.io/images/docker-sabnzbd/
11.  Vaultwarden GitHub Repository: https://github.com/dani-garcia/vaultwarden
