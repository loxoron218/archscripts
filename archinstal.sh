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
sudo pacman -S git
git clone https://aur.archlinux.org/yay.git
( cd yay && makepkg -si )
sudo rm -rf ~/yay

## Install and configure DE
sudo pacman -S gdm network-manager-applet plymouth
gsettings set org.gnome.mutter experimental-features "['autoclose-xwayland' , 'kms-modifiers' , 'scale-monitor-framebuffer' , 'variable-refresh-rate' , 'xwayland-native-scaling']"
sudo sed -i 's/#AutoEnable=true/AutoEnable=false/' /etc/bluetooth/main.conf
sudo systemctl enable bluetooth.service
sudo systemctl enable gdm.service
sudo systemctl set-default graphical.target
sudo systemctl enable NetworkManager.service
sudo sed -i 's/^HOOKS=(/HOOKS=(plymouth /' /etc/mkinitcpio.conf
sudo plymouth-set-default-theme -R bgrt
sudo sed -i 's/$/ quiet splash/' /boot/loader/entries/*.conf

## Install other applications
sudo pacman -S audacity bleachbit dconf-editor evince fastfetch gnome-calculator gnome-control-center gnome-disk-utility gnome-software gnome-text-editor gnome-tweaks libreoffice-fresh nautilus pdfarranger picard soundconverter strawberry vlc
sudo pacman -S adw-gtk-theme bash-completion firefox-ublock-origin ffmpegthumbnailer gnome-shell-extension-appindicator gvfs-mtp kdegraphics-thumbnailers power-profiles-daemon powertop ttf-liberation xdg-user-dirs
yay -S blackbox-terminal czkawka-gui-bin extension-manager flatseal localsend-bin makemkv mission-center nuclear-player-bin whatsapp-for-linux
yay -S brother-hll2350dw dcraw-thumbnailer ffmpeg-audio-thumbnailer firefox-arkenfox-autoconfig gnome-shell-extension-bing-wallpaper gnome-shell-extension-blur-my-shell nautilus-open-any-terminal
flatpak update
flatpak install -y adw-gtk3-dark winezgui

## Hide unwanted desktop icons
echo "NoDisplay=true" | sudo tee ~/.local/share/applications/avahi-discover.desktop
echo "NoDisplay=true" | sudo tee ~/.local/share/applications/bssh.desktop bssh.desktop
echo "NoDisplay=true" | sudo tee ~/.local/share/applications/bvnc.desktop bvnc.desktop
echo "NoDisplay=true" | sudo tee ~/.local/share/applications/cups.desktop cups.desktop
echo "NoDisplay=true" | sudo tee ~/.local/share/applications/libreoffice-base.desktop libreoffice-base.desktop
echo "NoDisplay=true" | sudo tee ~/.local/share/applications/libreoffice-calc.desktop libreoffice-calc.desktop
echo "NoDisplay=true" | sudo tee ~/.local/share/applications/libreoffice-draw.desktop libreoffice-draw.desktop
echo "NoDisplay=true" | sudo tee ~/.local/share/applications/libreoffice-impress.desktop libreoffice-impress.desktop
echo "NoDisplay=true" | sudo tee ~/.local/share/applications/libreoffice-math.desktop libreoffice-math.desktop
echo "NoDisplay=true" | sudo tee ~/.local/share/applications/libreoffice-writer.desktop libreoffice-writer.desktop
echo "NoDisplay=true" | sudo tee ~/.local/share/applications/nm-connection-editor.desktop nm-connection-editor.desktop
echo "NoDisplay=true" | sudo tee ~/.local/share/applications/org.gnome.Extensions.desktop org.gnome.Extensions.desktop
echo "NoDisplay=true" | sudo tee ~/.local/share/applications/qv4l2.desktop qv4l2.desktop
echo "NoDisplay=true" | sudo tee ~/.local/share/applications/qvidcap.desktop qvidcap.desktop

## Configure system apps
fastfetch --gen-config
sudo sh -c 'echo "fastfetch" >> ~/.bashrc'
alias clearfast='clear && fastfetch'
gsettings set com.github.stunkymonkey.nautilus-open-any-terminal terminal blackbox
gsettings set org.gnome.desktop.privacy remember-recent-files false
gsettings set org.gnome.nautilus.preferences show-image-thumbnails 'always'
sudo systemctl enable cups.service
sudo lpadmin -p HLL2350DW -v lpd://192.168.178.67/BINARY_P1 -E
sudo lpoptions -d HLL2350DW

## Update
yay -Rnsu git powertop
sudo rm -rf ~/.rustup
sudo rm -rf /var/cache/powertop
yay -Yc
sudo pacman -Scc
yay -Syyu
sudo powertop --auto-tune
