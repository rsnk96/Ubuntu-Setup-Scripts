#!/bin/bash


execute () {
	echo "$ $*"
	OUTPUT=$($@ 2>&1)
	if [ $? -ne 0 ]; then
        echo "$OUTPUT"
        echo ""
        echo "Failed to Execute $*" >&2
        exit 1
    fi
}

execute sudo apt-get install libboost-all-dev curl -y

execute sudo add-apt-repository ppa:noobslab/themes -y
execute sudo apt-get update
execute sudo apt-get install arc-theme -y

# Install code editor of your choice
if [[ ! -n $CIINSTALL ]]; then
    read -p "Download and Install VS Code / Atom / Sublime. Press q to skip this. Default: Skip Editor installation [v/a/s/q]: " tempvar
fi
tempvar=${tempvar:-q}

if [ "$tempvar" = "v" ]; then
    curl https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > microsoft.gpg
    sudo install -o root -g root -m 644 microsoft.gpg /etc/apt/trusted.gpg.d/
    sudo sh -c 'echo "deb [arch=amd64] https://packages.microsoft.com/repos/vscode stable main" > /etc/apt/sources.list.d/vscode.list'
    execute sudo apt-get install apt-transport-https -y
    execute sudo apt-get update
    execute sudo apt-get install code -y # or code-insiders
    execute rm microsoft.gpg
elif [ "$tempvar" = "a" ]; then
    execute sudo add-apt-repository ppa:webupd8team/atom
    execute sudo apt-get update; execute sudo apt-get install atom -y
elif [ "$tempvar" = "s" ]; then
    execute sudo add-apt-repository ppa:webupd8team/sublime-text-3
    execute sudo apt-get update
    execute sudo apt-get install sublime-text-installer -y
elif [ "$tempvar" = "q" ];then
    echo "Skipping this step"
fi

# Recommended libraries for Nvidia CUDA
execute sudo apt-get install freeglut3 freeglut3-dev libxi-dev libxmu-dev -y


# General Software from now on

# Enable partner repositories if disabled
sudo sed -i.bak "/^# deb .*partner/ s/^# //" /etc/apt/sources.list
execute sudo apt-get update

if which nautilus > /dev/null; then
    execute sudo apt-get install nautilus-dropbox -y
elif which caja > /dev/null; then
    execute sudo apt-get install caja-dropbox -y
fi

# TLP manager 
execute sudo add-apt-repository ppa:linrunner/tlp -y
execute sudo apt-get update
execute sudo apt-get install tlp tlp-rdw -y
sudo tlp start

# Multiload and other sensor applets
execute sudo apt-get install lm-sensors hddtemp
execute sudo apt-get install psensor xsensors
execute sudo apt-get update

execute sudo apt-get install redshift redshift-gtk shutter -y

mkdir -p ~/.config/autostart 
cp ./config_files/tilda.desktop ~/.config/autostart
cp ./config_files/redshift-gtk.desktop ~/.config/autostart

execute sudo apt-get install htop gparted expect -y

# Boot repair
execute sudo add-apt-repository ppa:yannubuntu/boot-repair -y
execute sudo apt-get update
execute sudo apt-get install -y boot-repair

# Installation of Docker Community Edition
execute wget get.docker.com -O dockerInstall.sh
execute chmod +x dockerInstall.sh
execute ./dockerInstall.sh
execute rm dockerInstall.sh
# Adds user to the `docker` group so that docker commands can be run without sudo
execute sudo usermod -aG docker ${USER}

# Grub customization
execute sudo add-apt-repository ppa:danielrichter2007/grub-customizer -y
execute sudo apt-get update
execute sudo apt-get install grub-customizer -y

# Keepass 2
execute sudo apt-add-repository ppa:jtaylor/keepass -y
execute sudo apt-get update -y
execute sudo apt-get install xdotool keepass2 -y

execute sudo apt-get install vlc -y
execute mkdir -p ~/.cache/vlc   # For VLSub to work flawlessly

execute sudo apt-get install vmg -y # Virtual magnifying glass, enabled by shortcut Super+<NumPadPlus>

# Browsers
wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | sudo apt-key add - 
sudo sh -c 'echo "deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main" >> /etc/apt/sources.list.d/google-chrome.list'
execute sudo apt-get update  -y
execute sudo apt-get install google-chrome-stable -y
#execute sudo apt-get install chromium-browser -y
execute sudo apt-get install firefox -y

# Install tor
if [[ ! -n $(lsb_release -d | grep 18) ]]; then
    execute sudo add-apt-repository ppa:webupd8team/tor-browser -y
    execute sudo apt-get update -y
    execute sudo apt-get install tor-browser -y
else
    execute sudo apt-get install tor torbrowser-launcher -y
fi

# # # Install I2P
# # execute sudo apt-add-repository ppa:i2p-maintainers/i2p -y
# # execute sudo apt-get update -y
# # execute sudo apt-get install i2p -y

if [[ ! -n $CIINSTALL ]]; then
    # Adobe flashplugin doesn't install on travis for some reason
    execute sudo apt-get install adobe-flashplugin -y

    # Skype - travis doesn't allow dpkg -i for some reason
    # echo "deb [arch=amd64] https://repo.skype.com/deb stable main" | sudo tee /etc/apt/sources.list.d/skype-stable.list
    # execute wget https://repo.skype.com/data/SKYPE-GPG-KEY 
    # execute sudo apt-key add SKYPE-GPG-KEY
    # execute sudo apt install apt-transport-https
    # execute sudo apt update
    # execute sudo apt install skypeforlinux
    # execute rm SKYPE-GPG-KEY

    # Station, an electron app to manage commonly used websites
    execute sudo aria2c --file-allocation=none -c -x 10 -s 10 -d /opt/ -o station.AppImage "https://dl.getstation.com/download/linux_64?filetype=AppImage"
    sudo chmod +x /opt/station.AppImage

    su - ${USER}  # For user being added to docker group to take effect
fi

echo "Script finished"
