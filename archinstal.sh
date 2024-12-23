#==============================================================================
# SECTION 1: System Preparation
#==============================================================================

## Buffer sudo for the whole script
sudo -v
while true; do sudo -v; sleep 60; done &

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
sudo pacman -Syyu --noconfirm git
git clone https://aur.archlinux.org/yay.git
(cd yay && makepkg -si --noconfirm)
sudo rm -rf ~/yay

#==============================================================================
# SECTION 2: System Configuration
#==============================================================================

## Configure Graphical User Interface
yay -S --noconfirm gdm
gsettings set org.gnome.mutter experimental-features "['autoclose-xwayland' , 'kms-modifiers' , 'scale-monitor-framebuffer' , 'variable-refresh-rate' , 'xwayland-native-scaling']"
sudo systemctl enable gdm.service
sudo systemctl set-default graphical.target

## Configure Plymouth
yay -S --noconfirm plymouth
sudo sed -i 's/^HOOKS=(/HOOKS=(plymouth /' /etc/mkinitcpio.conf
sudo plymouth-set-default-theme -R bgrt
sudo sed -i 's/$/ quiet splash/' /boot/loader/entries/*.conf

## Configure network
yay -S --noconfirm network-manager-applet
sudo systemctl enable NetworkManager.service

## Configure Bluetooth
sudo sed -i 's/#AutoEnable=true/AutoEnable=false/' /etc/bluetooth/main.conf
sudo systemctl enable bluetooth.service

#==============================================================================
# SECTION 3: Package Installation
#==============================================================================

## Install GUI applications from official repository
sudo pacman -S --noconfirm audacity bleachbit dconf-editor evince fastfetch gnome-calculator gnome-control-center gnome-disk-utility gnome-software gnome-text-editor gnome-tweaks libreoffice-fresh nautilus pdfarranger picard soundconverter strawberry vlc

## Install terminal applications from official repository
sudo pacman -S --noconfirm adw-gtk-theme bash-completion firefox-ublock-origin ffmpegthumbnailer gnome-shell-extension-appindicator gvfs-mtp kdegraphics-thumbnailers power-profiles-daemon powertop ttf-liberation xdg-user-dirs xorg-xset

## Install GUI applications from AUR
yay -S --noconfirm blackbox-terminal extension-manager flatseal localsend-bin mission-center nuclear-player-bin vscodium-bin whatsapp-for-linux

## Install terminal applications from AUR
yay -S --noconfirm brother-hll2350dw dcraw-thumbnailer ffmpeg-audio-thumbnailer firefox-arkenfox-autoconfig firefox-extension-bitwarden gnome-shell-extension-bing-wallpaper gnome-shell-extension-blur-my-shell nautilus-open-any-terminal

## Install Flatpak applications
flatpak update
flatpak install -y adw-gtk3-dark winezgui

#==============================================================================
# SECTION 4: Package Configuration
#==============================================================================

## Hide unwanted desktop icons
echo "NoDisplay=true" | sudo tee ~/.local/share/applications/avahi-discover.desktop
echo "NoDisplay=true" | sudo tee ~/.local/share/applications/bssh.desktop bssh.desktop
echo "NoDisplay=true" | sudo tee ~/.local/share/applications/bvnc.desktop bvnc.desktop
echo "NoDisplay=true" | sudo tee ~/.local/share/applications/bvnc.desktop codium.desktop
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

## Configure printer
sudo systemctl enable cups.service
sudo lpadmin -p HLL2350DW -v lpd://192.168.178.67/BINARY_P1 -E
sudo lpoptions -d HLL2350DW # Manual configuaration still needed

## Configure fastfetch
fastfetch --gen-config
sudo sh -c 'echo "fastfetch" >> ~/.bashrc'
alias clearfast='clear && fastfetch'

## Configure other apps
gsettings set com.github.stunkymonkey.nautilus-open-any-terminal terminal blackbox
gsettings set org.gnome.desktop.privacy remember-recent-files false
gsettings set org.gnome.nautilus.preferences show-image-thumbnails 'always'

#==============================================================================
# SECTION 5: Cleanup
#==============================================================================

## Use powertop
sudo powertop --calibrate
sudo powertop --auto-tune
yay -Rnsu --noconfirm powertop xorg-xset

## Remove unnecessary files
sudo rm -rf ~/.rustup
sudo rm -rf /var/cache/powertop
yay -Yc --noconfirm
sudo pacman -Scc --noconfirm
yay -Syyu --noconfirm

## Stop sudo buffer
pkill -f "sudo -v"