# Versions
NOMAD_VERSION=1.2.3
CONSUL_VERSION=1.11.1
VAULT_VERSION=1.9.2
TERRAFORM_VERSION=1.1.2
GOLANG_VERSION=1.17.5

# Allow Flatpaks to access themes and icons
sudo flatpak override --filesystem=/usr/share/themes:ro
sudo flatpak override --filesystem=/usr/share/icons:ro

# Allow volume above 100%
gsettings set org.gnome.desktop.sound allow-volume-above-100-percent true

# Enable and configure UFW
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow from 192.168.1.0/24 to any port 22000 proto tcp comment "syncthing"
sudo ufw allow from 192.168.1.0/24 to any port 21027 proto udp comment "syncthing"
sudo ufw enable

# Install common software
sudo apt -y install git build-essential meson software-properties-common curl

# Install Vulkan drivers
sudo apt -y install mesa-vulkan-drivers

# Install Nnome system monitor and disk utility
sudo apt -y install gnome-system-monitor gnome-disk-utility

# Install and start syncthing
sudo apt -y install syncthing
sudo systemctl enable --now syncthing@${USER}.service

# Install Nomad
curl -sSL https://releases.hashicorp.com/nomad/${NOMAD_VERSION}/nomad_${NOMAD_VERSION}_linux_amd64.zip -o nomad.zip
unzip nomad.zip
sudo mv nomad /usr/local/bin
rm nomad.zip

# Install Consul
curl -sSL https://releases.hashicorp.com/consul/${CONSUL_VERSION}/consul_${CONSUL_VERSION}_linux_amd64.zip -o consul.zip
unzip consul.zip
sudo mv consul /usr/local/bin
rm consul.zip

# Install Vault
curl -sSL https://releases.hashicorp.com/vault/${VAULT_VERSION}/vault_${VAULT_VERSION}_linux_amd64.zip -o vault.zip
unzip vault.zip
sudo mv vault /usr/local/bin
rm vault.zip

# Install Terraform
curl -sSL https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip -o terraform.zip
unzip terraform.zip
sudo mv terraform /usr/local/bin
rm terraform.zip

# Install Golang
wget https://golang.org/dl/go${GOLANG_VERSION}.linux-amd64.tar.gz
sudo rm -rf /usr/local/go
sudo tar -C /usr/local -xzf go${GOLANG_VERSION}.linux-amd64.tar.gz
grep -qxF 'export PATH=$PATH:/usr/local/go/bin' ~/.bashrc.d/exports || echo 'export PATH=$PATH:/usr/local/go/bin' >> ~/.bashrc.d/exports
rm go${GOLANG_VERSION}.linux-amd64.tar.gz

# Install hey
wget https://hey-release.s3.us-east-2.amazonaws.com/hey_linux_amd64
sudo mv hey_linux_amd64 /usr/local/bin/hey
chmod +x /usr/local/bin/hey

# Enable Flathub and Flathub Beta repos
sudo flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
sudo flatpak remote-add --if-not-exists flathub-beta https://flathub.org/beta-repo/flathub-beta.flatpakrepo
flatpak update --appstream

# Install Firefox Flatpak
flatpak install -y flathub org.mozilla.firefox
flatpak install -y flathub org.freedesktop.Platform.ffmpeg-full/x86_64/21.08

# Open Firefox in headless mode and then close it to create profile folder
timeout 5 flatpak run org.mozilla.firefox --headless

# Import Firefox user settings
tee -a ${HOME}/.var/app/org.mozilla.firefox/.mozilla/firefox/*-release/user.js << EOF
user_pref("toolkit.legacyUserProfileCustomizations.stylesheets", true);
user_pref("media.ffmpeg.vaapi.enabled", true);
user_pref("media.rdd-ffmpeg.enabled", true);
EOF

# Install Elementary OS Firefox theme
wget https://raw.githubusercontent.com/Zonnev/elementaryos-firefox-theme/elementaryos-firefox-theme/install.sh
sed -i 's#${HOME}/.mozilla/firefox#${HOME}/.var/app/org.mozilla.firefox/.mozilla/firefox#g' install.sh
chmod +x install.sh
./install.sh
rm install.sh

# Set Firefox Flatpak as default browser
xdg-settings set default-web-browser org.mozilla.firefox.desktop

# Install Authenticator
flatpak install -y flathub com.belmoussaoui.Authenticator
sudo flatpak override --nodevice=all com.belmoussaoui.Authenticator
sudo flatpak override --unshare=network com.belmoussaoui.Authenticator

# Install Flatpaks
flatpak install -y appcenter com.github.bluesabre.darkbar
flatpak install -y flathub org.gtk.Gtk3theme.Adwaita-dark
flatpak install -y flathub org.gnome.PasswordSafe
flatpak install -y flathub com.spotify.Client
flatpak install -y flathub org.gimp.GIMP
flatpak install -y flathub org.blender.Blender
# flatpak install -y flathub org.videolan.VLC
flatpak install -y flathub org.chromium.Chromium
flatpak install -y flathub com.github.tchx84.Flatseal
flatpak install -y flathub-beta com.google.Chrome
flatpak install -y flathub com.usebottles.bottles
flatpak install -y flathub org.libreoffice.LibreOffice

# Install Steam and allow Steam Link on local network
# flatpak install flathub com.valvesoftware.Steam
# sudo flatpak override --filesystem=/media/${USER}/data/games/steam com.valvesoftware.Steam
# sudo ufw allow from 192.168.1.0/24 to any port 27036:27037 proto tcp comment "steam link"
# sudo ufw allow from 192.168.1.0/24 to any port 27031:27036 proto udp comment "steam link"

# Install Lutris
# flatpak install flathub-beta net.lutris.Lutris//beta
# flatpak install flathub org.gnome.Platform.Compat.i386 org.freedesktop.Platform.GL32.default org.freedesktop.Platform.GL.default
# sudo flatpak override --filesystem=/media/${USER}/data/games/lutris net.lutris.Lutris

# Chrome - Enable GPU acceleration
mkdir -p ~/.var/app/com.google.Chrome/config
tee -a ~/.var/app/com.google.Chrome/config/chrome-flags.conf << EOF
--ignore-gpu-blacklist
--enable-gpu-rasterization
--enable-zero-copy
--enable-features=VaapiVideoDecoder
--use-vulkan
EOF

# Chromium - Enable GPU acceleration
mkdir -p ~/.var/app/org.chromium.Chromium/config
tee -a ~/.var/app/org.chromium.Chromium/config/chromium-flags.conf << EOF
--ignore-gpu-blacklist
--enable-gpu-rasterization
--enable-zero-copy
--enable-features=VaapiVideoDecoder
--use-vulkan
EOF

# Install VSCode
wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > packages.microsoft.gpg
sudo install -o root -g root -m 644 packages.microsoft.gpg /etc/apt/trusted.gpg.d/
sudo sh -c 'echo "deb [arch=amd64,arm64,armhf signed-by=/etc/apt/trusted.gpg.d/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" > /etc/apt/sources.list.d/vscode.list'
rm -f packages.microsoft.gpg
sudo apt -y install apt-transport-https
sudo apt update
sudo apt -y install code

# VSCode - Import user settings
mkdir -p ${HOME}/.config/Code/User
tee -a ${HOME}/.config/Code/User/settings.json << EOF
{
    "telemetry.telemetryLevel": "off",
    "window.menuBarVisibility": "toggle",
    "workbench.startupEditor": "none",
    "editor.fontFamily": "'Noto Sans Mono', 'Droid Sans Mono', 'monospace', monospace, 'Droid Sans Fallback'",
    "workbench.enableExperiments": false,
    "workbench.settings.enableNaturalLanguageSearch": false,
    "workbench.iconTheme": "material-icon-theme"
}
EOF

# VSCode - install extensions
code --install-extension PKief.material-icon-theme
code --install-extension golang.Go
code --install-extension HashiCorp.terraform

# Install Docker
sudo apt -y install docker.io

# Fix Docker and UFW
# https://github.com/chaifeng/ufw-docker
sudo tee -a /etc/ufw/after.rules << EOF
# BEGIN UFW AND DOCKER
*filter
:ufw-user-forward - [0:0]
:ufw-docker-logging-deny - [0:0]
:DOCKER-USER - [0:0]
-A DOCKER-USER -j ufw-user-forward

-A DOCKER-USER -j RETURN -s 10.0.0.0/8
-A DOCKER-USER -j RETURN -s 172.16.0.0/12
-A DOCKER-USER -j RETURN -s 192.168.0.0/16

-A DOCKER-USER -p udp -m udp --sport 53 --dport 1024:65535 -j RETURN

-A DOCKER-USER -j ufw-docker-logging-deny -p tcp -m tcp --tcp-flags FIN,SYN,RST,ACK SYN -d 192.168.0.0/16
-A DOCKER-USER -j ufw-docker-logging-deny -p tcp -m tcp --tcp-flags FIN,SYN,RST,ACK SYN -d 10.0.0.0/8
-A DOCKER-USER -j ufw-docker-logging-deny -p tcp -m tcp --tcp-flags FIN,SYN,RST,ACK SYN -d 172.16.0.0/12
-A DOCKER-USER -j ufw-docker-logging-deny -p udp -m udp --dport 0:32767 -d 192.168.0.0/16
-A DOCKER-USER -j ufw-docker-logging-deny -p udp -m udp --dport 0:32767 -d 10.0.0.0/8
-A DOCKER-USER -j ufw-docker-logging-deny -p udp -m udp --dport 0:32767 -d 172.16.0.0/12

-A DOCKER-USER -j RETURN

-A ufw-docker-logging-deny -m limit --limit 3/min --limit-burst 10 -j LOG --log-prefix "[UFW DOCKER BLOCK] "
-A ufw-docker-logging-deny -j DROP

COMMIT
# END UFW AND DOCKER
EOF
sudo ufw reload

# Install Wingpanel Ayatana-Compatibility Indicator
# https://github.com/Lafydev/wingpanel-indicator-ayatana
sudo apt -y install libglib2.0-dev libgranite-dev libindicator3-dev libwingpanel-dev indicator-application
wget https://github.com/Lafydev/wingpanel-indicator-ayatana/blob/master/com.github.lafydev.wingpanel-indicator-ayatana_2.0.8_odin.deb
sudo dpkg -i ./com.github.lafydev.wingpanel*.deb
rm com.github.lafydev.wingpanel-indicator-ayatana_2.0.8_odin.deb
mkdir -p ~/.config/autostart
cp /etc/xdg/autostart/indicator-application.desktop ~/.config/autostart/
sed -i 's/^OnlyShowIn.*/OnlyShowIn=Unity;GNOME;Pantheon;/' ~/.config/autostart/indicator-application.desktop

# Wingpanel legacy icons support
git clone https://github.com/msmaldi/wingpanel-indicator-na-tray.git
cd wingpanel-indicator-na-tray
meson builddir --prefix=/usr
ninja -C builddir
sudo ninja -C builddir install
cd .. && rm -rf wingpanel-indicator-na-tray

# Git configs
git config --global init.defaultBranch main
