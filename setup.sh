# Versions
GOLANG_VERSION=1.17.8
NOMAD_VERSION=1.2.5
CONSUL_VERSION=1.11.2
VAULT_VERSION=1.9.3
TERRAFORM_VERSION=1.1.4
PACKER_VERSION=1.8.0

# Create folders
mkdir -p \
${HOME}/.bashrc.d/ \
${HOME}/.local/bin \
${HOME}/src

# User specific environment
if ! [[ "\$PATH" =~ "\$HOME/.local/bin:\$HOME/bin:" ]]
then
    PATH="\$HOME/.local/bin:\$HOME/bin:\$PATH"
fi
export PATH

# User specific aliases and functions
if [ -d ~/.bashrc.d ]; then
        for rc in ~/.bashrc.d/*; do
                if [ -f "\$rc" ]; then
                        . "\$rc"
                fi
        done
fi

unset rc
EOF

# Avoid GRUB menu timeout
echo 'GRUB_RECORDFAIL_TIMEOUT=$GRUB_TIMEOUT' | sudo tee -a /etc/default/grub > /dev/null
sudo update-grub

# Install common software
sudo apt -y install git curl jq ffmpeg vainfo build-essential meson valac software-properties-common 

# Install current theme as Flatpak
sudo apt -y install ostree appstream-util
git clone https://github.com/refi64/stylepak.git
cd stylepak
chmod +x stylepak
./stylepak install-system
cd ..
rm -rf stylepak

# Allow Flatpaks to access themes and icons
sudo flatpak override --filesystem=xdg-data/themes:ro
sudo flatpak override --filesystem=xdg-data/icons:ro
sudo flatpak override --filesystem=xdg-config/gtk-3.0:ro
sudo flatpak override --filesystem=xdg-config/gtk-4.0:ro

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
curl -sSL https://releases.hashicorp.com/nomad/${NOMAD_VERSION}/nomad_${NOMAD_VERSION}_linux_amd64.zip -o hashistack-nomad.zip
curl -sSL https://releases.hashicorp.com/consul/${CONSUL_VERSION}/consul_${CONSUL_VERSION}_linux_amd64.zip -o hashistack-consul.zip
curl -sSL https://releases.hashicorp.com/vault/${VAULT_VERSION}/vault_${VAULT_VERSION}_linux_amd64.zip -o hashistack-vault.zip
curl -sSL https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip -o hashistack-terraform.zip
curl -sSL https://releases.hashicorp.com/packer/${PACKER_VERSION}/packer_${PACKER_VERSION}_linux_amd64.zip -o hashistack-packer.zip
unzip 'hashistack-*.zip' -d  ${HOME}/.local/bin
rm hashistack-*.zip

# Install Ansible
sudo add-apt-repository -y --update ppa:ansible/ansible
sudo apt -y install ansible-core

# Install Golang
wget https://golang.org/dl/go${GOLANG_VERSION}.linux-amd64.tar.gz
rm -rf ${HOME}/.local/go
tar -C ${HOME}/.local -xzf go${GOLANG_VERSION}.linux-amd64.tar.gz
grep -qxF 'export PATH=$PATH:${HOME}/.local/go/bin' ${HOME}/.bashrc.d/exports || echo 'export PATH=$PATH:${HOME}/.local/go/bin' >> ${HOME}/.bashrc.d/exports
rm go${GOLANG_VERSION}.linux-amd64.tar.gz

# Install hey
curl -sSL https://hey-release.s3.us-east-2.amazonaws.com/hey_linux_amd64 -o ${HOME}/.local/bin/hey
chmod +x ${HOME}/.local/bin/hey

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
EOF
cd

# Install Elementary OS Firefox theme
bash <(wget --quiet --output-document - "https://raw.githubusercontent.com/Zonnev/elementaryos-firefox-theme/elementaryos-firefox-theme/install.sh")

# Install Flatpaks
sudo flatpak install -y appcenter com.github.bluesabre.darkbar
sudo flatpak install -y appcenter io.github.jhaygood86.mauborgne
sudo flatpak install -y appcenter com.github.muriloventuroso.easyssh
sudo flatpak install -y appcenter com.github.alecaddd.sequeler
sudo flatpak install -y appcenter com.github.philip_scott.notes-up
sudo flatpak install -y appcenter com.github.manexim.insomnia
sudo flatpak install -y appcenter com.github.treagod.spectator
sudo flatpak install -y flathub com.usebottles.bottles
sudo flatpak install -y flathub org.gnome.World.Secrets
sudo flatpak install -y flathub com.spotify.Client
sudo flatpak install -y flathub org.chromium.Chromium
sudo flatpak install -y flathub com.github.tchx84.Flatseal
sudo flatpak install -y flathub-beta com.google.Chrome
sudo flatpak install -y flathub org.libreoffice.LibreOffice

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
    "editor.fontWeight": "500",
    "redhat.telemetry.enabled": false,
    "files.associations": {
        "*.j2": "terraform",
        "*.hcl": "terraform",
        "*.bu": "yaml",
        "*.ign": "json"
    },
    "extensions.ignoreRecommendations": true
}
EOF

# VSCode - install extensions
code --install-extension PKief.material-icon-theme
code --install-extension golang.Go
code --install-extension HashiCorp.terraform
code --install-extension redhat.ansible
code --install-extension dbaeumer.vscode-eslint
code --install-extension editorconfig.editorconfig
code --install-extension octref.vetur

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
