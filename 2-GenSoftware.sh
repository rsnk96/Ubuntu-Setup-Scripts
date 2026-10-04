#!/bin/bash

set -e

# Detect if running in CI environment (GitHub Actions, etc.)
is_ci() {
  [[ -n "$CI" ]] || [[ -n "$GITHUB_ACTIONS" ]] || [[ -n "$RUNNER_OS" ]] || [[ -n "$CIINSTALL" ]]
}

execute() {
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
get_os_lts_version() {
  if [[ $(
    . /etc/os-release
    echo $ID
  ) == "ubuntu" ]]; then
    version_id=$(
      . /etc/os-release
      echo $VERSION_ID
    )
    # Only support LTS releases: 24.04 and 26.04
    if [[ ${version_id} == "24.04" || ${version_id} == "26.04" ]]; then
      echo ${version_id}
    else
      echo "Unsupported Ubuntu version: ${version_id}. This script supports Ubuntu 24.04 and 26.04 LTS only." >&2
      exit 1
    fi
  else
    # For unofficial ubuntu flavours, check codename
    ubuntu_codename=$(
      . /etc/os-release
      echo $UBUNTU_CODENAME
    )
    version_id=$(
      . /etc/os-release
      echo $VERSION_ID
    )
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

# Skip desktop environment tweaks in CI (no GUI)
if ! is_ci; then
  if [[ $XDG_CURRENT_DESKTOP = *"GNOME"* ]]; then
    execute sudo apt install gnome-tweaks gnome-shell-extensions -y
  elif [[ $XDG_CURRENT_DESKTOP = *"MATE"* ]]; then
    execute sudo apt install mate-tweak -y
  fi
fi

# Install VS Code and Cursor IDEs
# Check and install VS Code
if [ -x "$(command -v code)" ]; then
  echo "VS Code already installed, skipping it"
else
  echo "Installing VS Code..."
  curl -fsSL https://packages.microsoft.com/keys/microsoft.asc | sudo gpg --dearmor -o /usr/share/keyrings/microsoft.gpg
  echo "deb [arch=amd64 signed-by=/usr/share/keyrings/microsoft.gpg] https://packages.microsoft.com/repos/vscode stable main" | sudo tee /etc/apt/sources.list.d/vscode.list >/dev/null
  execute sudo apt update
  execute sudo apt install code -y
fi

# Check and install Cursor
if [ -x "$(command -v cursor)" ]; then
  echo "Cursor already installed, skipping it"
else
  echo "Installing Cursor..."
  # Add Cursor's GPG key
  curl -fsSL https://downloads.cursor.com/keys/anysphere.asc | gpg --dearmor | sudo tee /etc/apt/keyrings/cursor.gpg >/dev/null

  # Add the Cursor repository
  echo "deb [arch=amd64,arm64 signed-by=/etc/apt/keyrings/cursor.gpg] https://downloads.cursor.com/aptrepo stable main" | sudo tee /etc/apt/sources.list.d/cursor.list >/dev/null

  # Update and install
  sudo apt update
  sudo apt install cursor
fi

### General Software from now on ###

### CI-Compatible Tools (work in both CI and desktop environments) ###

# Google Chrome browser (can run headless in CI)
if [ -x "$(command -v google-chrome-stable)" ]; then
  echo "Google Chrome already installed, skipping it"
else
  echo "Installing Google Chrome..."
  curl -fsSL https://dl.google.com/linux/linux_signing_key.pub | sudo gpg --dearmor -o /usr/share/keyrings/google-chrome.gpg
  echo "deb [arch=amd64 signed-by=/usr/share/keyrings/google-chrome.gpg] http://dl.google.com/linux/chrome/deb/ stable main" | sudo tee /etc/apt/sources.list.d/google-chrome.list >/dev/null
  execute sudo apt update
  execute sudo apt install google-chrome-stable -y
fi

### GUI-Only Tools (skip in CI environments) ###
if ! is_ci; then
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

  # Media player and VPN, as snaps
  sudo snap install vlc
  sudo snap install surfshark

  # Stremio from Flathub
  execute sudo apt install flatpak -y
  sudo flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
  sudo flatpak install -y flathub com.stremio.Stremio

  # Remote desktop client
  sudo snap install remmina
fi

### GitHub and GitLab CLIs
if [ -x "$(command -v gh)" ]; then
  echo "GitHub CLI already installed, skipping it"
else
  execute sudo apt-get install gh -y
fi

if [ -x "$(command -v glab)" ]; then
  echo "GitLab CLI already installed, skipping it"
else
  # Ubuntu's glab package lags the release used day to day. Take the latest .deb.
  glab_deb_url="$(
    curl -fsSL "https://gitlab.com/api/v4/projects/gitlab-org%2Fcli/releases/permalink/latest" |
      python3 -c 'import json,sys; rel=json.load(sys.stdin); print(next(a["direct_asset_url"] for a in rel["assets"]["links"] if a["name"].endswith("_linux_amd64.deb")))'
  )"
  curl -fsSL "$glab_deb_url" -o /tmp/glab.deb
  sudo dpkg -i /tmp/glab.deb
  rm -f /tmp/glab.deb
fi

### AWS CLI and Session Manager plugin
if [ -x "$(command -v aws)" ]; then
  echo "AWS CLI already installed, skipping it"
else
  curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
  unzip -q awscliv2.zip
  sudo ./aws/install
  rm -rf ./aws awscliv2.zip
fi

if [ -x "$(command -v session-manager-plugin)" ]; then
  echo "AWS Session Manager plugin already installed, skipping it"
else
  curl -fsSL "https://s3.amazonaws.com/session-manager-downloads/plugin/latest/ubuntu_64bit/session-manager-plugin.deb" -o /tmp/session-manager-plugin.deb
  sudo dpkg -i /tmp/session-manager-plugin.deb
  rm -f /tmp/session-manager-plugin.deb
fi

### dltop, herdr, and the xhisper fork
if [ -x "$(command -v dltop)" ]; then
  echo "dltop already installed, skipping it"
else
  execute sudo apt-get install pipx -y
  pipx install dltop
  pipx ensurepath
fi

if [ -x "$(command -v herdr)" ]; then
  echo "herdr already installed, skipping it"
else
  curl -fsSL https://herdr.dev/install.sh | sh
fi

if [ -x "$(command -v xhisper)" ]; then
  echo "xhisper already installed, skipping it"
else
  execute sudo apt-get install -y build-essential pipewire pipewire-utils jq ffmpeg wl-clipboard python3-gi gir1.2-gtk-3.0 bc
  xhisper_src="$(mktemp -d)"
  # This branch is the fork actually in use. abszar/main does not carry the conda and X11 fixes.
  git clone --depth 1 --branch fix/conda-env-and-clipboard-detection https://github.com/rsnk96/xhisper-ubuntu-linux.git "$xhisper_src"
  make -C "$xhisper_src"
  sudo make -C "$xhisper_src" install
  rm -rf "$xhisper_src"
  sudo usermod -aG input "$USER"
  echo 'KERNEL=="uinput", GROUP="input", MODE="0660"' | sudo tee /etc/udev/rules.d/99-uinput.rules >/dev/null
  sudo udevadm control --reload-rules || true
  if [[ -e /dev/uinput ]]; then
    sudo udevadm trigger /dev/uinput || true
  fi
fi

if [[ ! -n $CIINSTALL ]]; then
  echo ""
  echo "Note: If you were added to the docker or input group, please log out and log back in for changes to take effect."
fi

echo "Script finished"
