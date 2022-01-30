# Versions
GOLANG_VERSION=1.17.6
MITOGEN_VERSION=0.3.2

# Create folders
mkdir -p ${HOME}/src

# Avoid GRUB menu timeout
echo 'GRUB_RECORDFAIL_TIMEOUT=$GRUB_TIMEOUT' | sudo tee -a /etc/default/grub > /dev/null
sudo update-grub

# Install common software
sudo apt -y install git build-essential meson valac software-properties-common curl git

# Install current theme as Flatpak
sudo apt -y install ostree appstream-util
git clone https://github.com/refi64/stylepak.git
cd stylepak
chmod +x stylepak
./stylepak install-system
cd ..
rm -rf stylepak

# Shortcuts
gsettings set org.gnome.settings-daemon.plugins.media-keys area-screenshot "['<Shift><Super>s']"
gsettings set org.gnome.settings-daemon.plugins.media-keys home "['<Super>e']"
gsettings set org.gnome.settings-daemon.plugins.media-keys terminal "['<Super>Return']"
gsettings set org.gnome.desktop.wm.keybindings close "['<Shift><Super>q']"
gsettings set org.pantheon.desktop.gala.keybindings cycle-workspaces-next "['<Shift><Super>Tab']"
gsettings set org.gnome.desktop.wm.keybindings show-desktop "['<Super>Tab']"

# Misc changes
gsettings set io.elementary.desktop.wingpanel.power show-percentage true
gsettings set io.elementary.desktop.agent-geoclue2 location-enabled false
gsettings set org.gnome.desktop.sound event-sounds false
gsettings set org.gnome.desktop.peripherals.touchpad disable-while-typing false
gsettings set org.pantheon.desktop.gala.behavior overlay-action "'io.elementary.wingpanel --toggle-indicator=app-launcher'"
gsettings set io.elementary.terminal.settings unsafe-paste-alert false

# Allow volume above 100%
gsettings set org.gnome.desktop.sound allow-volume-above-100-percent true

# Enable and configure UFW
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow from 192.168.1.0/24 to any port 22000 proto tcp comment "syncthing"
sudo ufw allow from 192.168.1.0/24 to any port 21027 proto udp comment "syncthing"
sudo ufw enable

# Install Gnome system monitor and disk utility
sudo apt -y install gnome-system-monitor gnome-disk-utility

# Install and start syncthing
sudo apt -y install syncthing
sudo systemctl enable --now syncthing@${USER}.service

# Install Hashi stack
curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add -
sudo apt-add-repository --yes "deb [arch=amd64] https://apt.releases.hashicorp.com focal main"
sudo apt update && sudo apt -y install consul nomad terraform vault

# Install Ansible
sudo add-apt-repository --yes --update ppa:ansible/ansible
sudo apt -y install ansible

# Install Mitogen
# wget https://networkgenomics.com/try/mitogen-${MITOGEN_VERSION}.tar.gz
# tar -xf mitogen-${MITOGEN_VERSION}.tar.gz -C ${HOME}/src
# rm mitogen-${MITOGEN_VERSION}.tar.gz

# Install Golang
wget https://golang.org/dl/go${GOLANG_VERSION}.linux-amd64.tar.gz
sudo rm -rf /usr/local/go
sudo tar -C /usr/local -xzf go${GOLANG_VERSION}.linux-amd64.tar.gz
grep -qxF 'export PATH=$PATH:/usr/local/go/bin' ${HOME}/.profile || echo 'export PATH=$PATH:/usr/local/go/bin' >> ${HOME}/.profile
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
sudo flatpak install -y flathub org.mozilla.firefox

# Open Firefox in headless mode and then close it to create profile folder
timeout 5 flatpak run org.mozilla.firefox --headless

# Import Firefox user settings
cd ${HOME}/.var/app/org.mozilla.firefox/.mozilla/firefox/*-release
tee -a user.js << EOF
user_pref("toolkit.legacyUserProfileCustomizations.stylesheets", true);
user_pref("media.ffmpeg.vaapi.enabled", true);
user_pref("media.rdd-ffmpeg.enabled", true);
EOF
cd

# Install Elementary OS Firefox theme
wget https://raw.githubusercontent.com/Zonnev/elementaryos-firefox-theme/elementaryos-firefox-theme/install.sh
sed -i 's#${HOME}/.mozilla/firefox#${HOME}/.var/app/org.mozilla.firefox/.mozilla/firefox#g' install.sh
chmod +x install.sh
./install.sh
rm install.sh

# Set Firefox Flatpak as default browser
xdg-settings set default-web-browser org.mozilla.firefox.desktop

# Install Flatpaks
sudo flatpak install -y appcenter com.github.bluesabre.darkbar
sudo flatpak install -y appcenter io.github.jhaygood86.mauborgne
sudo flatpak install -y appcenter com.github.muriloventuroso.easyssh
sudo flatpak install -y appcenter com.github.alecaddd.sequeler
sudo flatpak install -y appcenter com.github.philip_scott.notes-up
sudo flatpak install -y appcenter com.github.manexim.insomnia
sudo flatpak install -y appcenter com.github.treagod.spectator
sudo flatpak install -y flathub com.usebottles.bottles
sudo flatpak install -y flathub org.gnome.PasswordSafe
sudo flatpak install -y flathub com.spotify.Client
sudo flatpak install -y flathub org.gimp.GIMP
sudo flatpak install -y flathub org.blender.Blender
sudo flatpak install -y flathub org.chromium.Chromium
sudo flatpak install -y flathub com.github.tchx84.Flatseal
sudo flatpak install -y flathub-beta com.google.Chrome
sudo flatpak install -y flathub org.libreoffice.LibreOffice

# Install Steam and allow Steam Link on local network
# sudo flatpak install -y flathub com.valvesoftware.Steam
# sudo flatpak install -y flathub com.valvesoftware.Steam.CompatibilityTool.Proton
# sudo flatpak install -y flathub com.valvesoftware.Steam.CompatibilityTool.Proton-GE
# sudo flatpak install -y flathub com.valvesoftware.Steam.CompatibilityTool.Proton-Exp
# sudo flatpak override --filesystem=/media/${USER}/data/games/steam com.valvesoftware.Steam
# sudo ufw allow from 192.168.1.0/24 to any port 27036:27037 proto tcp comment "steam link"
# sudo ufw allow from 192.168.1.0/24 to any port 27031:27036 proto udp comment "steam link"

# Install Lutris
# sudo flatpak install flathub-beta net.lutris.Lutris//beta
# sudo flatpak install flathub org.gnome.Platform.Compat.i386 org.freedesktop.Platform.GL32.default org.freedesktop.Platform.GL.default
# sudo flatpak override --filesystem=/media/${USER}/data/games/lutris net.lutris.Lutris

# Chrome - Enable GPU acceleration
mkdir -p ~/.var/app/com.google.Chrome/config
tee -a ~/.var/app/com.google.Chrome/config/chrome-flags.conf << EOF
--ignore-gpu-blacklist
--enable-gpu-rasterization
--enable-zero-copy
--enable-features=VaapiVideoDecoder
EOF

# Chromium - Enable GPU acceleration
mkdir -p ~/.var/app/org.chromium.Chromium/config
tee -a ~/.var/app/org.chromium.Chromium/config/chromium-flags.conf << EOF
--ignore-gpu-blacklist
--enable-gpu-rasterization
--enable-zero-copy
--enable-features=VaapiVideoDecoder
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
    "editor.fontFamily": "'Noto Sans Mono', 'Droid Sans Mono', 'monospace', 'Droid Sans Fallback'",
    "workbench.enableExperiments": false,
    "workbench.settings.enableNaturalLanguageSearch": false,
    "workbench.iconTheme": "material-icon-theme",
    "editor.fontWeight": "500"
}
EOF

# VSCode - install extensions
code --install-extension PKief.material-icon-theme
code --install-extension golang.Go
code --install-extension HashiCorp.terraform
code --install-extension redhat.ansible

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
wget https://github.com/Lafydev/wingpanel-indicator-ayatana/raw/master/com.github.lafydev.wingpanel-indicator-ayatana_2.0.8_odin.deb
sudo dpkg -i ./com.github.lafydev.wingpanel*.deb
rm com.github.lafydev.wingpanel-indicator-ayatana_2.0.8_odin.deb
mkdir -p ~/.config/autostart
cp /etc/xdg/autostart/indicator-application.desktop ~/.config/autostart/
sed -i 's/^OnlyShowIn.*/OnlyShowIn=Unity;GNOME;Pantheon;/' ~/.config/autostart/indicator-application.desktop

# Git configs
git config --global init.defaultBranch main
