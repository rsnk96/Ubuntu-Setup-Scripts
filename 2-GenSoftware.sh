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

# Get the OS major version number (major e.g. 20, 18)
get_os_version () {
    if [[ $(. /etc/os-release;echo $ID) == "ubuntu" ]]; then    # If an official ubuntu flavour
        echo $(. /etc/os-release;echo $VERSION_ID | grep -o -E '[0-9][0-9]' | head -n 1)
    else                                                        # If an unofficial ubuntu flavour, like Zorin/Pop/...
        ubuntu_codename=$(. /etc/os-release;echo $UBUNTU_CODENAME)
        if [[ ${ubuntu_codename} == "focal" ]]; then
            echo "20.04"
        elif [[ ${ubuntu_codename} == "xenial" ]]; then
            echo "18.04"
        fi
    fi
}

OS_VERSION=$(get_os_version)
OS_MAJOR_VERSION=$(echo ${OS_VERSION} | grep -o -E '[0-9][0-9]' | head -1)

if [[ $XDG_CURRENT_DESKTOP = *"Unity"* ]]; then	# To be removed once Unity is phased out
    execute sudo apt-get install unity-tweak-tool -y
elif [[ $XDG_CURRENT_DESKTOP = *"GNOME"* ]]; then
    execute sudo apt-get install gnome-tweak-tool -y
    execute sudo apt-get install gnome-shell-extensions -y
elif [[ $XDG_CURRENT_DESKTOP = *"MATE"* ]]; then
    execute sudo apt-get install mate-tweak -y
fi
execute sudo apt-get install arc-theme -y
execute sudo apt-get install curl -y

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
    wget -qO - https://packagecloud.io/AtomEditor/atom/gpgkey | sudo apt-key add -
    sudo sh -c 'echo "deb [arch=amd64] https://packagecloud.io/AtomEditor/atom/any/ any main" > /etc/apt/sources.list.d/atom.list'
    execute sudo apt-get update
    execute sudo apt-get install atom
elif [ "$tempvar" = "s" ]; then
    wget -q -O - https://download.sublimetext.com/sublimehq-pub.gpg | sudo apt-key add -
    echo "deb https://download.sublimetext.com/ apt/stable/" | sudo tee /etc/apt/sources.list.d/sublime-text.list
    execute sudo apt-get install apt-transport-https -y
    execute sudo apt-get update
    execute sudo apt-get install sublime-text -y
elif [ "$tempvar" = "q" ];then
    echo "Skipping this step"
fi

### General Software from now on ###

# Enable partner repositories if disabled
sudo sed -i.bak "/^# deb .*partner/ s/^# //" /etc/apt/sources.list
execute sudo apt-get update

# TLP manager
execute sudo add-apt-repository ppa:linrunner/tlp -y
execute sudo apt-get update
execute sudo apt-get install tlp tlp-rdw -y
sudo tlp start

# Multiload and other sensor applets
execute sudo apt-get install lm-sensors hddtemp -y
execute sudo apt-get install psensor xsensors -y

# Flameshot, a tool for screenshot with annotation. Linked to Super+Shift+S (Windows shortcut) as per keybindings
execute sudo apt-get install flameshot -y

# Make tilda start on login
mkdir -p ~/.config/autostart
cp ./config_files/tilda.desktop ~/.config/autostart

execute sudo apt-get install htop cpufrequtils indicator-cpufreq gparted expect -y
sudo sed -i 's/^GOVERNOR=.*/GOVERNOR=”powersave”/' /etc/init.d/cpufrequtils

# Boot repair
execute sudo add-apt-repository ppa:yannubuntu/boot-repair -y
execute sudo apt-get update
execute sudo apt-get install -y boot-repair

# Installation of Docker Community Edition
if ! which docker > /dev/null; then
    echo "Installing docker"
    execute wget get.docker.com -O dockerInstall.sh
    execute chmod +x dockerInstall.sh
    execute ./dockerInstall.sh
    execute rm dockerInstall.sh
    # Adds user to the `docker` group so that docker commands can be run without sudo
    execute sudo usermod -aG docker ${USER}
fi

# Docker-Compose
if ! which docker-compose > /dev/null; then
    execute sudo curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    execute sudo chmod +x /usr/local/bin/docker-compose
fi

# nvidia-docker installation
# Only install if Nvidia GPU is present with drivers installed
if which nvidia-smi > /dev/null; then
    echo "Installing nvidia-docker"
    # If you have nvidia-docker 1.0 installed: we need to remove it and all existing GPU containers
    distribution=$(echo ubuntu${OS_VERSION})
    curl -s -L https://nvidia.github.io/nvidia-docker/gpgkey | sudo apt-key add -
    curl -s -L https://nvidia.github.io/nvidia-docker/$distribution/nvidia-docker.list | sudo tee /etc/apt/sources.list.d/nvidia-docker.list

    execute sudo apt-get update
    execute sudo apt-get install -y nvidia-container-toolkit nvidia-docker2
    execute sudo systemctl restart docker
else
    echo "Skipping nvidia-docker2 installation. Requires Nvidia GPU with drivers installed"
fi


# Grub customization
execute sudo apt-get install grub-customizer -y

# Screen Recorder
execute sudo add-apt-repository ppa:sylvain-pineau/kazam -y
execute sudo apt-get update
execute sudo apt-get install kazam -y

# Bitwarden
sudo snap install bitwarden

# VLC
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
#if [[ ! -n $(lsb_release -d | grep 18) ]]; then
#    execute sudo add-apt-repository ppa:webupd8team/tor-browser -y
#    execute sudo apt-get update -y
#    execute sudo apt-get install tor-browser -y
#else
#    execute sudo apt-get install tor torbrowser-launcher -y
#fi

# # # Install I2P
# # execute sudo apt-add-repository ppa:i2p-maintainers/i2p -y
# # execute sudo apt-get update -y
# # execute sudo apt-get install i2p -y

if [[ ! -n $CIINSTALL ]]; then
    su - ${USER}  # For user being added to docker group to take effect
fi

echo "Script finished"
