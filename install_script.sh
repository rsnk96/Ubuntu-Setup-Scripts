#!/bin/bash


set -e

spatialPrint() {
    echo ""
    echo ""
    echo "$1"
	echo "================================"
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

sudo apt-get update -y
sudo apt-get dist-upgrade -y
sudo apt-get install ubuntu-restricted-extras -y

# My choice for terminal: Tilda+tmux
# Not guake because tilda is lighter on resources
# Not terminator because tmux sessions continue to run if you accidentally close the terminal emulator
sudo apt-get install git wget curl -y
sudo apt-get install tilda tmux -y
sudo apt-get install gimp -y
sudo apt-get install xclip -y # this is used for the copying tmux buffer to clipboard buffer
sudo apt-get install vim-gui-common vim-runtime -y
cp ./config_files/.vimrc ~
sudo snap install micro --classic
mkdir -p ~/.config/micro/
cp ./config_files/micro_bindings.json ~/.config/micro/bindings.json

# refer : [http://www.rushiagr.com/blog/2016/06/16/everything-you-need-to-know-about-tmux-copy-pasting-ubuntu/] for tmux buffers in ubuntu
cp ./config_files/.tmux.conf ~
cp ./config_files/.tmux.conf.local ~
mkdir -p ~/.config/tilda
cp ./config_files/config_0 ~/.config/tilda/

#Checks if ZSH is partially or completely Installed to Remove the folders and reinstall it
rm -rf ~/.z*
zsh_folder=/opt/.zsh/
if [[ -d $zsh_folder ]];then
	sudo rm -r /opt/.zsh/*
fi

spatialPrint "Setting up Zsh + Zim now"
sudo apt install zsh -y
sudo mkdir -p /opt/.zsh/ && sudo chmod ugo+w /opt/.zsh/
export ZIM_HOME=/opt/.zsh/zim
curl -fsSL https://raw.githubusercontent.com/zimfw/install/master/install.zsh | zsh
# Change default shell to zsh
command -v zsh | sudo tee -a /etc/shells
sudo chsh -s "$(command -v zsh)" "${USER}"

sudo apt-get install aria2 -y

# Create bash aliases
cp ./config_files/bash_aliases /opt/.zsh/bash_aliases
ln -s /opt/.zsh/bash_aliases ~/.bash_aliases

{
    echo "if [ -f ~/.bash_aliases ]; then"
    echo "  source ~/.bash_aliases"
    echo "fi"

    echo "# Switching to 256-bit colour by default so that zsh-autosuggestion's suggestions are not suggested in white, but in grey instead"
    echo "export TERM=xterm-256color"

    echo "# Setting the default text editor to micro, a terminal text editor with shortcuts similar to what you'd encounter in an IDE"
    echo "export VISUAL=micro"
} >> ~/.zshrc

# Now create shortcuts
sudo apt-get install run-one xbindkeys xbindkeys-config wmctrl xdotool -y
cp ./config_files/.xbindkeysrc ~/

# Now download and install bat
mkdir -p extras
spatialPrint "Installing bat, a handy replacement for cat"
latest_bat_setup=$(curl --silent "https://api.github.com/repos/sharkdp/bat/releases/latest" | grep "deb" | grep "browser_download_url" | head -n 1 | cut -d \" -f 4)
aria2c --file-allocation=none -c -x 10 -s 10 --dir extras -o bat.deb $latest_bat_setup
sudo dpkg -i ./extras/bat.deb
sudo apt-get install -f

# Check if Anaconda is already installed
if [[ -n $(echo $PATH | grep 'conda') ]]; then
    echo "Anaconda is already installed, skipping installation"
    echo "To reinstall, delete the Anaconda install directory and remove from PATH as well"
else

    spatialPrint "Installing the latest Anaconda Python in /opt/anaconda3"
    continuum_website=https://repo.continuum.io/archive/
    # Stepwise filtering of the html at $continuum_website
    # Get the topmost line that matches our requirements, extract the file name.
    latest_anaconda_setup=$(wget -q -O - $continuum_website index.html | grep "Anaconda3-" | grep "Linux" | grep "86_64" | head -n 1 | cut -d \" -f 2)
    aria2c --file-allocation=none -c -x 10 -s 10 -o anacondaInstallScript.sh --dir ./extras ${continuum_website}${latest_anaconda_setup}
    sudo mkdir -p /opt/anaconda3 && sudo chmod ugo+w /opt/anaconda3
    bash ./extras/anacondaInstallScript.sh -f -b -p /opt/anaconda3

    spatialPrint "Setting up your anaconda"
    /opt/anaconda3/bin/conda update conda -y
    /opt/anaconda3/bin/conda clean --all -y
    /opt/anaconda3/bin/conda install ipython -y

    /opt/anaconda3/bin/conda install libgcc -y
    /opt/anaconda3/bin/pip install numpy scipy matplotlib scikit-learn scikit-image jupyter notebook pandas h5py cython jupyterlab
    /opt/anaconda3/bin/pip install msgpack
    /opt/anaconda3/bin/conda install line_profiler -y
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

## Detect if an Nvidia card is attached, and install the graphics drivers automatically
if [[ -n $(lspci | grep -i nvidia) ]]; then
    spatialPrint "Installing Display drivers and any other auto-detected drivers for your hardware"
    sudo add-apt-repository ppa:graphics-drivers/ppa -y
    sudo apt-get update
    sudo ubuntu-drivers autoinstall
fi

############################################
## Below is content from 2-GenSoftware
############################################

sudo apt-get install libboost-all-dev curl -y

curl https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > microsoft.gpg
sudo install -o root -g root -m 644 microsoft.gpg /etc/apt/trusted.gpg.d/
sudo sh -c 'echo "deb [arch=amd64] https://packages.microsoft.com/repos/vscode stable main" > /etc/apt/sources.list.d/vscode.list'
sudo apt-get install apt-transport-https -y
sudo apt-get update
sudo apt-get install code -y # or code-insiders
rm microsoft.gpg

# Recommended libraries for Nvidia CUDA
sudo apt-get install freeglut3 freeglut3-dev libxi-dev libxmu-dev -y


# Enable partner repositories if disabled
sudo sed -i.bak "/^# deb .*partner/ s/^# //" /etc/apt/sources.list
sudo apt-get update

# TLP manager 
sudo add-apt-repository ppa:linrunner/tlp -y
sudo apt-get update
sudo apt-get install tlp tlp-rdw -y
sudo tlp start

# Multiload and other sensor applets
sudo apt-get install lm-sensors hddtemp -y
sudo apt-get install psensor xsensors -y
sudo apt-get update

sudo apt-get install shutter -y

mkdir -p ~/.config/autostart
cp ./config_files/tilda.desktop ~/.config/autostart
cp ./config_files/redshift-gtk.desktop ~/.config/autostart

# REMVOE THE THIRD LINE for production desktops because it will boot the PC into power saving mode
sudo apt-get install htop indicator-cpufreq gparted expect -y
cpufreq-info
sudo sed -i 's/^GOVERNOR=.*/GOVERNOR=”powersave”/' /etc/init.d/cpufrequtils

# Boot repair
sudo add-apt-repository ppa:yannubuntu/boot-repair -y
sudo apt-get update
sudo apt-get install -y boot-repair

# Installation of Docker Community Edition
if ! which docker > /dev/null; then
    echo "Installing docker"
    wget get.docker.com -O dockerInstall.sh
    chmod +x dockerInstall.sh
    ./dockerInstall.sh
    rm dockerInstall.sh
    # Adds user to the `docker` group so that docker commands can be run without sudo
    sudo usermod -aG docker ${USER}
fi

# nvidia-docker installation
# Only install if Nvidia GPU is present with drivers installed
if which nvidia-smi > /dev/null; then
    echo "Installing nvidia-docker"
    # If you have nvidia-docker 1.0 installed: we need to remove it and all existing GPU containers
    distribution=$(. /etc/os-release;echo $ID$VERSION_ID)
    curl -s -L https://nvidia.github.io/nvidia-docker/gpgkey | sudo apt-key add -
    curl -s -L https://nvidia.github.io/nvidia-docker/$distribution/nvidia-docker.list | sudo tee /etc/apt/sources.list.d/nvidia-docker.list

    sudo apt-get update
    sudo apt-get install -y nvidia-container-toolkit
    sudo systemctl restart docker
else
    echo "Skipping nvidia-docker2 installation. Requires Nvidia GPU with drivers installed"
fi


# Grub customization
sudo add-apt-repository ppa:danielrichter2007/grub-customizer -y
sudo apt-get update
sudo apt-get install grub-customizer -y

# Screen Recorder
sudo add-apt-repository ppa:sylvain-pineau/kazam -y
sudo apt-get update
sudo apt-get install kazam -y

sudo snap install bitwarden
sudo snap install p3x-onenote

sudo apt-get install vlc -y
mkdir -p ~/.cache/vlc   # For VLSub to work flawlessly

if [[ $(cat /etc/os-release | grep "VERSION_ID" | grep -o -E '[1-9][1-9]') -ge 18 ]]; then
    sudo apt-get install vmg -y # Virtual magnifying glass, enabled by shortcut Super+<NumPadPlus>
fi

# Browsers
wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | sudo apt-key add - 
sudo sh -c 'echo "deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main" >> /etc/apt/sources.list.d/google-chrome.list'
sudo apt-get update  -y
sudo apt-get install google-chrome-stable -y
sudo apt-get install firefox -y

sudo apt-get install adobe-flashplugin -y

############################################
## Below is content from 3-ML-Basic
############################################
#!/bin/bash

if [[ -n $(echo $SHELL | grep "zsh") ]] ; then
    SHELLRC=~/.zshrc
elif [[ -n $(echo $SHELL | grep "bash") ]] ; then
    SHELLRC=~/.bashrc
elif [[ -n $(echo $SHELL | grep "ksh") ]] ; then
    SHELLRC=~/.kshrc
else
    echo "Unidentified shell $SHELL"
    exit # Ain't nothing I can do to help you buddy :P
fi

# Executes first command passed &
# echo's it to the file passed as second argument 
run_and_echo () {
    eval $1
    echo "$1" >> $2
}


if [[ (-n $(lspci | grep -i nvidia)) && (! ( -d "/usr/local/cuda" ) ) ]]; then
    echo "Installing the latest cuda"
    cuda_instr_block=$(wget -q -O - 'https://developer.nvidia.com/cuda-downloads' | grep wget | head -n 1)
    cuda_download_command=$(echo ${cuda_instr_block} | sed 's#\(.*\)"cudaBash">.*#\1#' | sed 's#.*"cudaBash">\([^<]*\).*#\1#' )
    cuda_install_command=$(echo ${cuda_instr_block} | sed 's#.*"cudaBash">\([^<]*\).*#\1#' | sed 's#&nbsp;# ./extras/#' ) # Get everything after the last `"cudaBash"` block till the next `<` character, replace the &nbsp; with a download path
    if [[ $(command -v aria2c) ]]; then
        cuda_download_command=$(echo ${cuda_download_command} | sed 's#wget#aria2c --file-allocation=none -c -x 10 -s 10 --dir extras#' )
    else
        cuda_download_command=$(${cuda_download_command} -P ./extras)
    fi

    $cuda_download_command
    $cuda_install_command --silent --toolkit --run-nvidia-xconfig
fi


if [[ (! -n $(echo $PATH | grep 'cuda')) && ( -d "/usr/local/cuda" ) ]]; then
    echo "Adding Cuda location to PATH"
    run_and_echo "# Cuda" $SHELLRC
    run_and_echo "export PATH=/usr/local/cuda/bin:\$PATH" $SHELLRC
    run_and_echo "export LD_LIBRARY_PATH=/usr/local/cuda/lib64:/usr/local/cuda/extras/CUPTI/lib64:\$LD_LIBRARY_PATH" $SHELLRC
    run_and_echo "export CUDA_HOME=/usr/local/cuda" $SHELLRC
fi

if which nvidia-smi > /dev/null; then 
    echo "Installing nvtop"
    sudo apt-get install cmake libncurses5-dev git -y
    if [[ ! -d "nvtop" ]]; then
        git clone --quiet https://github.com/Syllo/nvtop.git
    else
    (
        cd nvtop || exit
        git pull origin master
    )
    fi
    mkdir -p nvtop/build
    cd nvtop/build
    cmake -DCMAKE_BUILD_TYPE=Optimized -DNVML_RETRIEVE_HEADER_ONLINE=True ..
    make
    sudo make install
    cd ../../
fi

if [[ $(command -v conda) || (-n $CIINSTALL) ]]; then
    PIP="pip install"
else
    sudo apt-get install python3 python3-dev -y
    if [[ ! -n $CIINSTALL ]]; then sudo apt-get install python3-pip -y; fi
    PIP="sudo pip3 install"
fi

sudo apt-get install libhdf5-dev exiftool ffmpeg -y

# Install opencv from pip only if it isn't already installed. Need to use `pkgutil` because opencv built from source does not appear in `pip list`
if [[ ! $(python3 -c "import pkgutil; print([p[1] for p in pkgutil.iter_modules()])" | grep cv2) ]]; then
    $PIP opencv-contrib-python --upgrade
fi

$PIP --upgrade numpy pandas tabulate python-dateutil
$PIP --upgrade keras

if [[ -n $(command -v nvidia-smi) ]]; then

    # If Anaconda is present, use conda
    if [[ -n $(command -v conda) ]]; then
        conda install tensorflow-gpu -y
        conda install pytorch torchvision -c pytorch -y
    else
        # Else use pip
        $PIP --upgrade tensorflow
        $PIP --upgrade torch torchvision
    fi

else
    # If Anaconda is present, use conda
    if [[ -n $(command -v conda) ]]; then
        conda install tensorflow -y
        conda install pytorch torchvision cpuonly -c pytorch -y
    else
        $PIP --upgrade tensorflow
        $PIP --upgrade torch==1.4.0+cpu torchvision==0.5.0+cpu -f https://download.pytorch.org/whl/torch_stable.html
    fi
fi

echo ""
echo "This script has finished"
