## Some Arch apps don't work as expected by default. With these commands you can change that.

## Configure Vaultwarden Web
sudo sed -i 's/# WEB_VAULT_FOLDER=\/usr\/share\/webapps\/vaultwarden-web/WEB_VAULT_FOLDER=\/usr\/share\/webapps\/vaultwarden-web/' /etc/vaultwarden.env
sudo sed -i 's/WEB_VAULT_ENABLED=false/WEB_VAULT_ENABLED=true/' /etc/vaultwarden.env
