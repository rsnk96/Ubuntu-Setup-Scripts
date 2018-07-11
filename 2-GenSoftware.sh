#!/bin/bash

sudo apt-get install libboost-all-dev -y
sudo apt-get install clang-format -y

# Install code editor of your choice
echo
echo
if [[ ! -n $CIINSTALL ]]; then
    read -p "Download and Install VS Code / Atom / Sublime. Press q to skip this. Default is VS Code [v/a/s/q]: " tempvar
fi
tempvar=${tempvar:-v}

if [ "$tempvar" = "v" ]; then
    curl https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > microsoft.gpg
    sudo mv microsoft.gpg /etc/apt/trusted.gpg.d/microsoft.gpg
    sudo sh -c 'echo "deb [arch=amd64] http://packages.microsoft.com/repos/vscode stable main" > /etc/apt/sources.list.d/vscode.list'
    sudo apt-get update
    sudo apt-get install code # or code-insiders
    echo
    echo
    echo
    echo "If you are using VS Code, note that you have to remove the line which modifies \$TMPDIR in your .zprofile."
elif [ "$tempvar" = "a" ]; then
    sudo add-apt-repository ppa:webupd8team/atom
    sudo apt update; sudo apt install atom
elif [ "$tempvar" = "s" ]; then
    sudo add-apt-repository ppa:webupd8team/sublime-text-3
    sudo apt-get update
    sudo apt-get install sublime-text-installer
elif [ "$tempvar" = "q" ];then
    echo "Skipping this step"
fi

# Recommended libraries for Nvidia CUDA
sudo apt-get install libglu1-mesa libxi-dev libxmu-dev libglu1-mesa-dev libx11-dev -y


# General Software from now on

if which nautilus > /dev/null; then
    sudo apt-get install nautilus-dropbox -y
elif which caja > /dev/null; then
    sudo apt-get install caja-dropbox -y
fi

# TLP manager 
sudo add-apt-repository ppa:linrunner/tlp -y
sudo apt-get update
sudo apt-get install tlp tlp-rdw -y
sudo tlp start

# Multiload and other sensor applets
sudo apt-get install lm-sensors
sudo apt-add-repository ppa:sneetsher/copies -y
sudo apt update 
sudo apt install indicator-sensors indicator-multiload -y
sudo apt-add-repository -r ppa:sneetsher/copies -y
sudo apt update

sudo apt-get install redshift redshift-gtk shutter -y

mkdir -p ~/.config/autostart 
cp ./config_files/indicator-multiload.desktop ~/.config/autostart
cp ./config_files/indicator-sensors.desktop ~/.config/autostart
cp ./config_files/tilda.desktop ~/.config/autostart
cp ./config_files/redshift-gtk.desktop ~/.config/autostart

sudo apt-get install htop gparted task expect -y

# Boot repair
sudo add-apt-repository ppa:yannubuntu/boot-repair -y
sudo apt-get update
sudo apt-get install -y boot-repair

# Installation of Docker Community Edition
wget get.docker.com -O dockerInstall.sh
chmod +x dockerInstall.sh
./dockerInstall.sh
rm dockerInstall.sh
# Adds user to the `docker` group so that docker commands can be run without sudo
sudo usermod -aG docker ${USER}

# Grub customization
sudo add-apt-repository ppa:danielrichter2007/grub-customizer -y
sudo apt-get update
sudo apt-get install grub-customizer -y

# Keepass 2
sudo apt-add-repository ppa:jtaylor/keepass -y
sudo apt-get update -y
sudo apt-get install xdotool keepass2 -y

# Skype
wget https://go.skype.com/skypeforlinux-64.deb
sudo dpkg -i skypeforlinux-64.deb
rm skypeforlinux-64.deb

sudo apt-get install vlc -y

# Browsers
wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | sudo apt-key add - 
sudo sh -c 'echo "deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main" >> /etc/apt/sources.list.d/google-chrome.list'
sudo apt-get update  -y
sudo apt-get install google-chrome-stable -y
#sudo apt-get install chromium-browser -y
sudo apt-get install adobe-flashplugin -y
sudo apt-get install firefox -y
# Install tor
sudo add-apt-repository ppa:webupd8team/tor-browser -y
sudo apt-get update -y
sudo apt-get install tor-browser -y
# Install I2P
sudo apt-add-repository ppa:i2p-maintainers/i2p -y
sudo apt-get update -y
sudo apt-get install i2p -y

# Franz
wget https://github.com/meetfranz/franz/releases/download/v5.0.0-beta.18/franz_5.0.0-beta.18_amd64.deb
sudo dpkg -i *.deb
sudo apt-get install -f
rm -rf *.deb

echo "Script finished"
if [[ ! -n $CIINSTALL ]]; then
    su - ${USER}  # For docker
fi