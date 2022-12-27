#!/usr/bin/env bash
# cheap and nasty presaltbox prep
# https://github.com/maximuskowalski/getw/blob/main/scripts/maxstall.sh
# https://raw.githubusercontent.com/maximuskowalski/getw/main/scripts/maxstall.sh
#
# not tested yet
# wget -q https://raw.githubusercontent.com/maximuskowalski/getw/main/scripts/maxstall.sh -O maxstall.sh && bash ./maxstall.sh

PACKAGE_LIST=(
  bwm-ng
  curl
  git
  htop
  iftop
  neofetch
  sysstat
  unattended-upgrades
  zip
)

###############################################
#  max installer,  not meant for general use  #
###############################################

#____________________
#
#
#

echo "#######################"
echo "#   adding ssh keys   #"
echo "#######################"

# No root - no good
[ "$(id -u)" != "0" ] && {
    usage "ERROR: You must be root to run this script.\\nPlease login as root and execute the script again."
    exit 1
}


echo "# add my ssh key"
mkdir -p .ssh && chmod 700 .ssh && touch .ssh/authorized_keys
echo ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGRBrjTGEVSsSofVMbTMA+BMPSSogb0Wzx15iIbH/ERQ max@home >> ~/.ssh/authorized_keys
chmod 600 .ssh/authorized_keys

# basics

echo "#######################"
echo "# Installing Packages #"
echo "#######################"

sudo apt update

# iterate through package and installs them
for package_name in "${PACKAGE_LIST[@]}"; do
  if ! sudo apt list --installed | grep -q "^\<$package_name\>"; then
    echo "Installing $package_name..."
    sleep .5
    sudo apt install "$package_name" -y
    echo "$package_name has been installed"
  else
    echo "$package_name already installed"
  fi
done

# requires interactive ( I think )

dpkg-reconfigure --priority=low unattended-upgrades

echo "#######################"
echo "# Cleanup and Updates #"
echo "#######################"

sudo apt upgrade -y
sudo apt autoremove -y

echo "#######################"
echo "#   Config Settings   #"
echo "#######################"

echo "#  edit ssh config #"

# TODO consider using a file instead of editing default file
# /etc/ssh/sshd_config.d/maxos_sshd.conf

echo "DebianBanner no
DisableForwarding yes
# PermitRootLogin no
IgnoreRhosts yes
PasswordAuthentication no
UseDNS no" | tee /etc/ssh/sshd_config.d/maxos_sshd.conf

echo "#     UseDNS no    #"
# sed -i 's/#UseDNS.*/UseDNS no/' /etc/ssh/sshd_config

echo "# PasswordAuthentication OFF #"
# sed -i 's/#PasswordAuthentication.*/PasswordAuthentication no/' /etc/ssh/sshd_config

echo "#   IgnoreRhosts   #"
# sed -i 's/#IgnoreRhosts.*/IgnoreRhosts yes/' /etc/ssh/sshd_config

service ssh restart

echo "#  firewall  #"

ufw default deny incoming
ufw allow ssh
ufw allow OpenSSH

ufw --force enable

# answer with yes
# yes | ufw enable

echo "#  fail to ban  #"
echo "#  leaving out for now  #"

# [ssh]

# enabled  = true
# banaction = iptables-multiport
# port     = ssh
# filter   = sshd
# logpath  = /var/log/auth.log
# maxretry = 5
# findtime = 43200
# bantime = 86400"

# sudo systemctl restart fail2ban

echo "#  set timezone to Au  #"

timedatectl set-timezone Australia/Sydney && timedatectl set-ntp true
systemctl restart systemd-timesyncd

echo "#  add service accounts  #"
[[ -f /opt/sa.zip ]] && cd /opt && unzip sa.zip

echo "#######################"
echo "#    Saltbox Deps     #"
echo "#######################"

curl -sL https://install.saltbox.dev | sudo -H bash && cd /srv/git/saltbox ||


# add a user



echo "# home logs log rotater"

echo "/home/max/logs/*.log {
    daily
    copytruncate
    create 660 max max
    dateext
    extension log
    rotate 5
    delaycompress
    missingok
    notifempty
    su max max
}" | tee /etc/logrotate.d/homelogs

echo "# updater"

echo "#!/usr/bin/env bash
# Update system
sudo -s -- <<EOF
apt-get update
apt-get upgrade -y
apt-get dist-upgrade -y
apt-get autoremove -y
apt-get autoclean -y
EOF
" | tee /usr/local/bin/update.sh

chmod 775 /usr/local/bin/update.sh

echo "#    FIN     #"
#
