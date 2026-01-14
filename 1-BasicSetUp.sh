#!/bin/bash

set -e

# Detect if running in CI environment (GitHub Actions, etc.)
is_ci() {
    [[ -n "$CI" ]] || [[ -n "$GITHUB_ACTIONS" ]] || [[ -n "$RUNNER_OS" ]] || [[ -n "$CIINSTALL" ]]
}

spatialPrint() {
    echo ""
    echo ""
    echo "$1"
	echo "================================"
}

# To note: the execute() function doesn't handle pipes well
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

execute sudo apt-get update -y
if [[ ! -n $CIINSTALL ]]; then
    sudo apt-get upgrade -y
    sudo apt-get install ubuntu-restricted-extras -y
fi

# Choice for terminal that will be adopted: tmux & zellij
execute sudo apt-get install unzip git byobu magic-wormhole openssh-server python3-pip htop curl expect neofetch ffmpeg software-properties-common git-delta -y
if ! is_ci; then
    execute sudo apt-get install xrdp -y
    execute sudo apt-get install xclip xsel -y # this is used for the copying tmux buffer to clipboard buffer
fi

#Completely uninstall ZSH and Zim along with all z-config files
spatialPrint "Removing existing Zsh and Zim installations"

# Reset shell to bash and uninstall zsh
if command -v zsh &> /dev/null || [[ "$SHELL" == *"zsh"* ]]; then
    sudo chsh -s /bin/bash "${USER}" 2>/dev/null || true
    sudo useradd -D -s /bin/bash 2>/dev/null || true
    sudo apt-get remove --purge zsh -y 2>/dev/null || true
    sudo apt-get autoremove -y 2>/dev/null || true
fi

# Remove all zsh/zim config files and directories
rm -rf ~/.z* ~/.zim ~/.cache/{zsh,zim}
sudo rm -rf /etc/zsh* /opt/.zsh*
sudo sed -i '/zsh/d' /etc/shells 2>/dev/null || true

spatialPrint "Setting up Zsh + Zim now"
execute sudo apt-get install zsh -y
sudo mkdir -p /opt/.zsh/ && sudo chmod ugo+w /opt/.zsh/
export ZIM_HOME=/opt/.zsh/zim
curl -fsSL https://raw.githubusercontent.com/zimfw/install/master/install.zsh | zsh
# Change default shell to zsh
command -v zsh | sudo tee -a /etc/shells
sudo chsh -s "$(command -v zsh)" "${USER}"
sudo useradd -D -s /bin/zsh

execute sudo apt-get install aria2 -y

# Create bash aliases
cp ./config_files/bash_aliases /opt/.zsh/bash_aliases >/dev/null  # Suppress error messages in case the file already exists
rm -f ~/.bash_aliases
ln -s /opt/.zsh/bash_aliases ~/.bash_aliases

{
    echo "if [ -f ~/.bash_aliases ]; then"
    echo "  source ~/.bash_aliases"
    echo "fi"

    echo "# Switching to 256-bit colour by default so that zsh-autosuggestion's suggestions are not suggested in white, but in grey instead"
    echo "export TERM=xterm-256color"
} >> ~/.zshrc

# Now create shortcuts
execute sudo apt-get install run-one xbindkeys wmctrl xdotool -y
cp ./config_files/xbindkeysrc ~/.xbindkeysrc

# Now download and install bat
execute sudo apt-get install bat -y

# Check if Anaconda's Miniconda is already installed
if [[ -n $(echo $PATH | grep 'conda') ]]; then
    echo "Anaconda is already installed, skipping installation"
    echo "To reinstall, delete the Anaconda install directory (/opt/anaconda3 if done by this script) and remove from PATH as well"
else
    spatialPrint "Installing the latest Anaconda Python in /opt/anaconda3"
    execute sudo rm -rf /opt/anaconda3
    latest_anaconda_setup="https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh"
    aria2c --file-allocation=none -c -x 10 -s 10 -o anacondaInstallScript.sh --dir ./extras ${latest_anaconda_setup}
    sudo mkdir -p /opt/anaconda3 && sudo chmod ugo+w /opt/anaconda3
    execute bash ./extras/anacondaInstallScript.sh -f -b -p /opt/anaconda3

    spatialPrint "Setting up your anaconda"
    execute /opt/anaconda3/bin/conda tos accept --override-channels --channel https://repo.anaconda.com/pkgs/main
    execute /opt/anaconda3/bin/conda tos accept --override-channels --channel https://repo.anaconda.com/pkgs/r
    execute /opt/anaconda3/bin/conda update conda -y
    execute /opt/anaconda3/bin/conda clean --all -y
    execute /opt/anaconda3/bin/conda install anaconda -y
    execute /opt/anaconda3/bin/conda install ipython -y

    execute /opt/anaconda3/bin/conda install libgcc -y
    execute /opt/anaconda3/bin/pip install numpy scipy matplotlib scikit-learn scikit-image jupyter notebook pandas h5py cython jupyterlab
    execute /opt/anaconda3/bin/pip install msgpack
    execute /opt/anaconda3/bin/conda install line_profiler -y
    sed -i.bak "/anaconda3/d" ~/.zshrc

    /opt/anaconda3/bin/conda info -a

    spatialPrint "Adding anaconda to path variables"
    {
        echo "# Anaconda Python. Change the \"conda activate base\" to whichever environment you would like to activate by default"
        echo ". /opt/anaconda3/etc/profile.d/conda.sh"
        echo "conda activate base"
    } >> ~/.zshrc

fi # Anaconda Installation end

# echo "*************************** NOTE *******************************"
# echo "If you ever mess up your anaconda installation somehow, do"
# echo "\$ conda remove anaconda matplotlib mkl mkl-service nomkl openblas"
# echo "\$ conda clean --all"
# echo "Do this for each environment as well as your root. Then reinstall all except nomkl"

# For utilities such as lspci
execute sudo apt-get install pciutils

## Detect if an Nvidia card is attached, and install the graphics drivers automatically if not already installed
if [[ -n $(lspci | grep -i nvidia) && ! $(command -v nvidia-smi) ]]; then
    spatialPrint "Installing Display drivers and any other auto-detected drivers for your hardware"
    execute sudo apt-get update
    execute sudo ubuntu-drivers autoinstall
    execute /opt/anaconda3/bin/conda install -c conda-forge nvitop -y
fi

### Docker and Docker-Compose
if [ -x "$(command -v docker)" ]; then
    echo "Docker already installed, skipping it \n\n"
else
    sudo apt-get update
    sudo apt-get install ca-certificates curl gnupg -y
    sudo install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    sudo chmod a+r /etc/apt/keyrings/docker.gpg
    echo "deb [arch="$(dpkg --print-architecture)" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu "$(. /etc/os-release && echo "$VERSION_CODENAME")" stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    sudo apt-get update
    sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y
    sudo usermod -aG docker $USER
fi

### Nvidia-Container Toolkit
if [ -x "$(docker info | grep nvidia)" ]; then
    echo "Nvidia container runtime seems to already be installed, skipping!"
else
    if [ ! -f /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg ]; then
        curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg
    else
        echo "Nvidia Container Toolkit Keyring already present – not overwriting."
    fi
    curl -s -L https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list | \
    sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | \
    sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list \
    && \
    sudo apt-get update
    sudo apt-get install -y nvidia-container-toolkit
    sudo nvidia-ctk runtime configure --runtime=docker
    sudo systemctl restart docker
fi


## Install zellij
wget https://github.com/zellij-org/zellij/releases/download/v0.43.1/zellij-x86_64-unknown-linux-musl.tar.gz
tar -xvf zellij-x86_64-unknown-linux-musl.tar.gz
chmod +x zellij
sudo mv zellij /usr/local/bin/
rm -rf ./zellij*

## Install Neovim with all essential lazyvim plugins

curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt install -y build-essential "lua5.1" luarocks ripgrep fd-find fzf nodejs
mkdir -p ~/.local/bin
ln -s $(which fdfind) ~/.local/bin/fd
rm -rf ~/.local/share/nvim/
rm -rf ~/.config/nvim/

## Install nerd fonts
sudo mkdir -p /usr/local/share/fonts
wget -O /tmp/VictorMono.zip \
  https://github.com/ryanoasis/nerd-fonts/releases/latest/download/VictorMono.zip
sudo unzip /tmp/VictorMono.zip -d /usr/local/share/fonts/VictorMono
sudo fc-cache -fv

sudo add-apt-repository ppa:neovim-ppa/unstable -y
sudo apt update
sudo apt install -y neovim
git clone https://github.com/LazyVim/starter ~/.config/nvim
rm -rf ~/.config/nvim/.git


# Force GDM to use Xorg (X11) instead of Wayland (skip in CI - no display manager)
if ! is_ci; then
    if [[ -f /etc/gdm3/custom.conf ]]; then
        sudo sed -i 's/^#WaylandEnable=true/WaylandEnable=false/' /etc/gdm3/custom.conf
        # If the line does not exist in that form, ensure it is present:
        # Also check if gdm3 is the default display manager
        if ! grep -q '^WaylandEnable=' /etc/gdm3/custom.conf && [[ $(dpkg-query -W -f='${Status}' gdm3 2>/dev/null | grep -c "ok installed") -eq 1 ]]; then
          echo 'WaylandEnable=false' | sudo tee -a /etc/gdm3/custom.conf
        fi
    fi
    spatialPrint "The script has finished. Please Reboot, you will be switching to X11"
else
    spatialPrint "The script has finished."
fi
