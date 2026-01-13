#!/bin/bash

set -e

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

# Get the OS LTS version (24.04 or 26.04)
get_os_lts_version () {
    if [[ $(. /etc/os-release;echo $ID) == "ubuntu" ]]; then
        version_id=$(. /etc/os-release;echo $VERSION_ID)
        # Only support LTS releases: 24.04 and 26.04
        if [[ ${version_id} == "24.04" || ${version_id} == "26.04" ]]; then
            echo ${version_id}
        else
            echo "Unsupported Ubuntu version: ${version_id}. This script supports Ubuntu 24.04 and 26.04 LTS only." >&2
            exit 1
        fi
    else
        # For unofficial ubuntu flavours, check codename
        ubuntu_codename=$(. /etc/os-release;echo $UBUNTU_CODENAME)
        version_id=$(. /etc/os-release;echo $VERSION_ID)
        if [[ ${ubuntu_codename} == "noble" ]] || [[ ${version_id} == "24.04" ]]; then
            echo "24.04"
        elif [[ ${version_id} == "26.04" ]]; then
            echo "26.04"
        else
            echo "Unsupported Ubuntu version: ${version_id} (codename: ${ubuntu_codename}). This script supports Ubuntu 24.04 and 26.04 LTS only." >&2
            exit 1
        fi
    fi
}

OS_VERSION=$(get_os_lts_version)

if [[ $XDG_CURRENT_DESKTOP = *"GNOME"* ]]; then
    execute sudo apt install gnome-tweaks gnome-shell-extensions -y
elif [[ $XDG_CURRENT_DESKTOP = *"MATE"* ]]; then
    execute sudo apt install mate-tweak -y
fi

# Install VS Code and Cursor IDEs
# Check and install VS Code
if [ -x "$(command -v code)" ]; then
    echo "VS Code already installed, skipping it"
else
    echo "Installing VS Code..."
    curl -fsSL https://packages.microsoft.com/keys/microsoft.asc | sudo gpg --dearmor -o /usr/share/keyrings/microsoft.gpg
    echo "deb [arch=amd64 signed-by=/usr/share/keyrings/microsoft.gpg] https://packages.microsoft.com/repos/vscode stable main" | sudo tee /etc/apt/sources.list.d/vscode.list > /dev/null
    execute sudo apt update
    execute sudo apt install code -y
fi

# Check and install Cursor
if [ -x "$(command -v cursor)" ]; then
    echo "Cursor already installed, skipping it"
else
    echo "Installing Cursor..."
    # Use official install script (handles both .deb and AppImage)
    curl -fsSL https://cursor.sh/linux/install.sh | sudo bash
fi

### General Software from now on ###

# Enable partner repositories if disabled
sudo sed -i.bak "/^# deb .*partner/ s/^# //" /etc/apt/sources.list
execute sudo apt update

# Install Brave browser
sudo curl -fsSLo /usr/share/keyrings/brave-browser-archive-keyring.gpg https://brave-browser-apt-release.s3.brave.com/brave-browser-archive-keyring.gpg
sudo curl -fsSLo /etc/apt/sources.list.d/brave-browser-release.sources https://brave-browser-apt-release.s3.brave.com/brave-browser.sources
execute sudo apt update
execute sudo apt install brave-browser -y


# System monitoring tools
execute sudo apt install lm-sensors psensor -y

# Flameshot - screenshot tool with annotation
execute sudo apt install flameshot -y

# Disk management
execute sudo apt install gparted -y

# Grub customization and image editor
# Add PPA for grub-customizer (not available in default repos)
execute sudo add-apt-repository ppa:danielrichter2007/grub-customizer -y
execute sudo apt update
execute sudo apt install grub-customizer gimp -y

# Screen recorder
execute sudo apt install kazam -y

# Password manager
sudo snap install bitwarden

# Media player
execute sudo apt install vlc -y
mkdir -p ~/.cache/vlc

# Google Chrome browser
curl -fsSL https://dl.google.com/linux/linux_signing_key.pub | sudo gpg --dearmor -o /usr/share/keyrings/google-chrome.gpg
echo "deb [arch=amd64 signed-by=/usr/share/keyrings/google-chrome.gpg] http://dl.google.com/linux/chrome/deb/ stable main" | sudo tee /etc/apt/sources.list.d/google-chrome.list > /dev/null
execute sudo apt update
execute sudo apt install google-chrome-stable -y

# Remote desktop client
sudo snap install remmina

### AWS CLI
if [ -x "$(command -v aws)" ]; then
    echo "AWS CLI already installed, skipping it"
else
    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
    unzip -q awscliv2.zip
    sudo ./aws/install
    rm -rf ./aws awscliv2.zip
fi

if [[ ! -n $CIINSTALL ]]; then
    echo ""
    echo "Note: If you were added to the docker group, please log out and log back in for changes to take effect."
fi

echo "Script finished"
