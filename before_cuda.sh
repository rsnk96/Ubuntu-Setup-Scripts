#!/bin/bash


set -e

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

# Speed up the process
# Env Var NUMJOBS overrides automatic detection
if [[ -n $NUMJOBS ]]; then
    MJOBS=$NUMJOBS
elif [[ -f /proc/cpuinfo ]]; then
    MJOBS=$(grep -c processor /proc/cpuinfo)
elif [[ "$OSTYPE" == "darwin"* ]]; then
	MJOBS=$(sysctl -n machdep.cpu.thread_count)
else
    MJOBS=4
fi

execute sudo apt-get update -y
if [[ ! -n $CIINSTALL ]]; then
    sudo apt-get dist-upgrade -y
    sudo apt-get install ubuntu-restricted-extras -y
fi
#sudo ubuntu-drivers autoinstall 

# My choice for terminal: Tilda+tmux
# Not guake because tilda is lighter on resources
# Not terminator because tmux sessions continue to run if you accidentally close the terminal emulator
execute sudo apt-get install git -y
rm -rf ~/.z*
execute sudo apt-get install tilda tmux -y
execute sudo apt-get install meld -y
execute sudo apt-get install xclip -y # this is used for the copying tmux buffer to clipboard buffer
execute sudo apt-get install vim-gui-common vim-runtime -y
cp ./config_files/.vimrc ~

# refer : [http://www.rushiagr.com/blog/2016/06/16/everything-you-need-to-know-about-tmux-copy-pasting-ubuntu/] for tmux buffers in ubuntu
cp ./config_files/.tmux.conf ~
cp ./config_files/.tmux.conf.local ~
mkdir -p ~/.config/tilda
cp ./config_files/config_0 ~/.config/tilda/

#Checks if ZSH is partially or completely Installed to Remove the folders and reinstall it
zsh_folder=/opt/.zsh/
if [[ -d $zsh_folder ]];then
	sudo rm -r /opt/.zsh/*
fi

spatialPrint "Setting up Zsh + Zim now"
sudo apt install zsh -y
sudo mkdir -p /opt/.zsh/ && sudo chmod ugo+w /opt/.zsh/
git clone --recursive --quiet https://github.com/Eriner/zim.git /opt/.zsh/zim
ln -s /opt/.zsh/zim/ ~/.zim
ln -s /opt/.zsh/zim/templates/zimrc ~/.zimrc
ln -s /opt/.zsh/zim/templates/zlogin ~/.zlogin
ln -s /opt/.zsh/zim/templates/zshrc ~/.zshrc
git clone https://github.com/zsh-users/zsh-autosuggestions /opt/.zsh/zsh-autosuggestions
echo "source /opt/.zsh/zsh-autosuggestions/zsh-autosuggestions.zsh" >> ~/.zshrc
# Change default shell to zsh
command -v zsh | sudo tee -a /etc/shells
sudo chsh -s "$(command -v zsh)" "${USER}"

execute sudo apt-get install aria2 -y

touch /opt/.zsh/bash_aliases
ln -s /opt/.zsh/bash_aliases ~/.bash_aliases
spatialPrint "Adding aliases to ~/.bash_aliases"
{
    echo "alias jn=\"jupyter notebook\""
    echo "alias jl=\"jupyter lab\""
    echo "alias maxvol=\"pactl set-sink-volume @DEFAULT_SINK@ 150%\""
    echo "alias download=\"wget --random-wait -r -p --no-parent -e robots=off -U mozilla\""
    echo "alias server=\"ifconfig | grep inet\\ addr && python3 -m http.server\""
    echo "alias gpom=\"git push origin master\""
    echo "alias update=\"sudo apt update && sudo apt full-upgrade -y && sudo apt autoremove -y\""
    echo "alias aria=\"aria2c --file-allocation=none -c -x 10 -s 10\""
    echo "alias tsux=\"tmux -u new-session \\; \\
            neww \\; \\
              send-keys 'htop' C-m \\; \\
              split-window -h \\; \\
              send-keys 'nvtop' C-m \\; \\
              split-window -v \\; \\
              send-keys 'watch sensors' C-m \\; \\
              rename-window 'performance' \\; \\
            select-window -l\""

} >> ~/.bash_aliases

# Now create shortcuts
execute sudo apt-get install run-one xbindkeys xbindkeys-config wmctrl xdotool -y
cp ./config_files/.xbindkeysrc ~/

spatialPrint "Installing the latest Anaconda Python in /opt/anaconda3"
continuum_website=https://repo.continuum.io/archive/
# Stepwise filtering of the html at $continuum_website
# Get the topmost line that matches our requirements, extract the file name.
latest_anaconda_steup=$(wget -q -O - $continuum_website index.html | grep "Anaconda3-" | grep "Linux" | grep "86_64" | head -n 1 | cut -d \" -f 2)
aria2c --file-allocation=none -c -x 10 -s 10 -o anacondaInstallScript.sh ${continuum_website}${latest_anaconda_steup}
sudo mkdir -p /opt/anaconda3 && sudo chmod ugo+w /opt/anaconda3
execute bash ./anacondaInstallScript.sh -f -b -p /opt/anaconda3

spatialPrint "Setting up your anaconda"
execute /opt/anaconda3/bin/conda update conda -y
execute /opt/anaconda3/bin/conda clean --all -y
execute /opt/anaconda3/bin/conda install ipython -y

execute /opt/anaconda3/bin/conda install libgcc -y
execute /opt/anaconda3/bin/pip install numpy scipy matplotlib scikit-learn scikit-image jupyter jupyterlab notebook pandas h5py cython
execute /opt/anaconda3/bin/pip install msgpack
execute /opt/anaconda3/bin/conda install line_profiler -y
sed -i.bak "/anaconda3/d" ~/.zshrc


spatialPrint "Adding anaconda to path variables"
{
    echo "# Anaconda Python. Change the \"conda activate base\" to whichever environment you would like to activate by default"
    echo ". /opt/anaconda3/etc/profile.d/conda.sh"
    echo "conda activate base"

    echo "if [ -f ~/.bash_aliases ]; then"
    echo "  source ~/.bash_aliases"
    echo "fi"
} >> ~/.zshrc

sudo add-apt-repository ppa:graphics-drivers/ppa -y
execute sudo apt-get update
sudo ubuntu-drivers autoinstall

# spatialPrint "The script has finished."
# if [[ ! -n $CIINSTALL ]]; then
#     # echo "The terminal instance will now close so that the shell changes can take place"
#     # read -p "Press [Enter] to continue..." temp
#     # kill -9 $PPID
#     su - $USER
# fi


execute sudo apt-get install libboost-all-dev curl -y

curl https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > microsoft.gpg
sudo install -o root -g root -m 644 microsoft.gpg /etc/apt/trusted.gpg.d/
sudo sh -c 'echo "deb [arch=amd64] https://packages.microsoft.com/repos/vscode stable main" > /etc/apt/sources.list.d/vscode.list'
execute sudo apt-get install apt-transport-https -y
execute sudo apt-get update
execute sudo apt-get install code -y # or code-insiders
execute rm microsoft.gpg

# Recommended libraries for Nvidia CUDA
execute sudo apt-get install freeglut3 freeglut3-dev libxi-dev libxmu-dev -y


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
execute sudo apt-get update

execute sudo apt-get install shutter -y

mkdir -p ~/.config/autostart
cp ./config_files/tilda.desktop ~/.config/autostart
cp ./config_files/redshift-gtk.desktop ~/.config/autostart

execute sudo apt-get install htop gparted expect -y

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

# nvidia-docker installation
# Only install if Nvidia GPU is present with drivers installed
if which nvidia-smi > /dev/null; then
    echo "Installing nvidia-docker"
    # If you have nvidia-docker 1.0 installed: we need to remove it and all existing GPU containers
    distribution=$(. /etc/os-release;echo $ID$VERSION_ID)
    curl -s -L https://nvidia.github.io/nvidia-docker/gpgkey | sudo apt-key add -
    curl -s -L https://nvidia.github.io/nvidia-docker/$distribution/nvidia-docker.list | sudo tee /etc/apt/sources.list.d/nvidia-docker.list

    execute sudo apt-get update
    execute sudo apt-get install -y nvidia-container-toolkit
    execute sudo systemctl restart docker
else
    echo "Skipping nvidia-docker2 installation. Requires Nvidia GPU with drivers installed"
fi


# Grub customization
execute sudo add-apt-repository ppa:danielrichter2007/grub-customizer -y
execute sudo apt-get update
execute sudo apt-get install grub-customizer -y

# Screen Recorder
execute sudo apt-get update
execute sudo apt-get install kazam -y

execute sudo apt-get install vlc -y
execute mkdir -p ~/.cache/vlc   # For VLSub to work flawlessly

if [[ $(cat /etc/os-release | grep "VERSION_ID" | grep -o -E '[1-9][1-9]') -ge 18 ]]; then
    execute sudo apt-get install vmg -y # Virtual magnifying glass, enabled by shortcut Super+<NumPadPlus>
fi

# Browsers
wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | sudo apt-key add - 
sudo sh -c 'echo "deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main" >> /etc/apt/sources.list.d/google-chrome.list'
execute sudo apt-get update  -y
execute sudo apt-get install google-chrome-stable -y
execute sudo apt-get install firefox -y

if [[ ! -n $CIINSTALL ]]; then
    execute sudo apt-get install adobe-flashplugin -y
    su - ${USER}  # For user being added to docker group to take effect
fi

echo "Script finished"
