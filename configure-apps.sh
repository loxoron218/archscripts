## Some Arch apps don't work as expected by default. With these commands you can change that.

## Configure Duck DNS with Cronie
read -p "Enter your Duck DNS domain: " duck_domain
read -p "Enter your Duck DNS token: " duck_token
echo
mkdir -p ~/duckdns
sudo chown -R $(whoami) ~/duckdns
echo "echo url=\"https://www.duckdns.org/update?domains=${duck_domain}&token=${duck_token}&verbose=true\" | curl -k -o ~/duckdns/duck.log -K -" > ~/duckdns/duck.sh
chmod 700 ~/duckdns/duck.sh
echo "*/5 * * * * ~/duckdns/duck.sh >/dev/null 2>&1" | crontab -
sudo systemctl enable cronie.service
~/duckdns/duck.sh

## Setup Server Backup
sudo mkdir /mnt/sda1/server # Change directory if you are using RAID
echo "rsync -avh --delete --exclude='~/server/immich/postgres' ~/ /mnt/sda1/server" > ~/server/server_backup.sh
chmod 700 ~/server/server_backup.sh
sudo chown -R $(whoami) /mnt/sda1 # Change directory if you are using RAID
sudo chown -R $(whoami) ~/
(crontab -l 2>/dev/null; echo "0 3 * * * ~/server/server_backup.sh") | crontab -
~/server/server_backup.sh

## Configure Vaultwarden Web
sudo sed -i 's/# WEB_VAULT_FOLDER=\/usr\/share\/webapps\/vaultwarden-web/WEB_VAULT_FOLDER=\/usr\/share\/webapps\/vaultwarden-web/' /etc/vaultwarden.env
sudo sed -i 's/WEB_VAULT_ENABLED=false/WEB_VAULT_ENABLED=true/' /etc/vaultwarden.env

## Create desktop icon for Jackett
sudo curl -o /usr/share/pixmaps/jacket_medium.svg https://raw.githubusercontent.com/Jackett/Jackett/95384a92ee9d86301743b10d33dd72d3846372da/src/Jackett.Common/Content/jacket_medium.png
sudo sh -c 'echo "[Desktop Entry]" >> ~/.local/share/applications/Jackett.desktop'
sudo sh -c 'echo "Name=Jackett" >> ~/.local/share/applications/Jackett.desktop'
sudo sh -c 'echo "Exec=sh -c \"/usr/lib/jackett/jackett & sleep 10 && xdg-open http://localhost:9117\"" >> ~/.local/share/applications/Jackett.desktop'
sudo sh -c 'echo "Terminal=False" >> ~/.local/share/applications/Jackett.desktop'
sudo sh -c 'echo "Type=Application" >> ~/.local/share/applications/Jackett.desktop'
sudo sh -c 'echo "Icon=/usr/share/pixmaps/jacket_medium.svg" >> ~/.local/share/applications/Jackett.desktop'

## Create desktop icon for Radarr
sudo curl -o /usr/share/pixmaps/Radarr.svg https://raw.githubusercontent.com/Radarr/Radarr/refs/heads/develop/Logo/Radarr.svg
sudo sh -c 'echo "[Desktop Entry]" >> ~/.local/share/applications/Radarr.desktop'
sudo sh -c 'echo "Name=Radarr" >> ~/.local/share/applications/Radarr.desktop'
sudo sh -c 'echo "Exec=/usr/lib/radarr/bin/Radarr -browser" >> ~/.local/share/applications/Radarr.desktop'
sudo sh -c 'echo "Terminal=False" >> ~/.local/share/applications/Radarr.desktop'
sudo sh -c 'echo "Type=Application" >> ~/.local/share/applications/Radarr.desktop'
sudo sh -c 'echo "Icon=/usr/share/pixmaps/Radarr.svg" >> ~/.local/share/applications/Radarr.desktop'

## Create desktop icon for SABnzbd
sudo curl -o /usr/share/pixmaps/logo-arrow.svg https://raw.githubusercontent.com/sabnzbd/sabnzbd/refs/heads/develop/icons/logo-arrow.svg
sudo cp /usr/lib/sabnzbd/linux/sabnzbd.desktop ~/.local/share/applications/
sudo sed -i 's|^Exec=.*|Exec=/usr/lib/sabnzbd/SABnzbd.py --browser 1|' ~/.local/share/applications/sabnzbd.desktop
sudo sed -i 's|^Icon=.*|Icon=/usr/share/pixmaps/logo-arrow.svg|' ~/.local/share/applications/sabnzbd.desktop

## Select best mirrors after Archinstall
sudo pacman -Syyu
sudo pacman -S reflector
sudo reflector -c DE -l 10 -p https --save /etc/pacman.d/mirrorlist
sudo pacman -Rnsu reflector
