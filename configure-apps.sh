## Some Arch apps don't work as expected by default. With these commands you can change that.

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
