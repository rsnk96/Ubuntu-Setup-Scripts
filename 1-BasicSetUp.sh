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
execute sudo apt-get install tilda tmux -y
execute sudo apt-get install gimp -y
execute sudo apt-get install xclip -y # this is used for the copying tmux buffer to clipboard buffer
execute sudo apt-get install vim-gui-common vim-runtime -y
cp ./config_files/vimrc ~/.vimrc
execute sudo snap install micro --classic
mkdir -p ~/.config/micro/
cp ./config_files/micro_bindings.json ~/.config/micro/bindings.json

# refer : [http://www.rushiagr.com/blog/2016/06/16/everything-you-need-to-know-about-tmux-copy-pasting-ubuntu/] for tmux buffers in ubuntu
cp ./config_files/tmux.conf ~/.tmux.conf
cp ./config_files/tmux.conf.local ~/.tmux.conf.local
mkdir -p ~/.config/tilda
cp ./config_files/config_0 ~/.config/tilda/

#Checks if ZSH is partially or completely Installed to Remove the folders and reinstall it
rm -rf ~/.z*
zsh_folder=/opt/.zsh/
if [[ -d $zsh_folder ]];then
	sudo rm -r /opt/.zsh/*
fi

spatialPrint "Setting up Zsh + Zim now"
sudo apt install zsh
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
    echo "alias server=\"ifconfig | grep inet && python3 -m http.server\""
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
cp ./config_files/xbindkeysrc ~/.xbindkeysrc

# Now download and install bat
spatialPrint "Installing bat, a handy replacement for cat"
latest_bat_setup=$(wget -q -O - https://github.com/sharkdp/bat/releases/ index.html | grep "deb" | head -n 1 | cut -d \" -f 2)
aria2c --file-allocation=none -c -x 10 -s 10 --dir /tmp -o bat.deb https://github.com${latest_bat_setup}
execute sudo dpkg -i /tmp/bat.deb
execute sudo apt-get install -f

spatialPrint "Installing the latest Anaconda Python in /opt/anaconda3"
continuum_website=https://repo.continuum.io/archive/
# Stepwise filtering of the html at $continuum_website
# Get the topmost line that matches our requirements, extract the file name.
latest_anaconda_setup=$(wget -q -O - $continuum_website index.html | grep "Anaconda3-" | grep "Linux" | grep "86_64" | head -n 1 | cut -d \" -f 2)
aria2c --file-allocation=none -c -x 10 -s 10 -o anacondaInstallScript.sh ${continuum_website}${latest_anaconda_setup}
sudo mkdir -p /opt/anaconda3 && sudo chmod ugo+w /opt/anaconda3
execute bash ./anacondaInstallScript.sh -f -b -p /opt/anaconda3

spatialPrint "Setting up your anaconda"
execute /opt/anaconda3/bin/conda update conda -y
execute /opt/anaconda3/bin/conda clean --all -y
execute /opt/anaconda3/bin/conda install ipython -y

execute /opt/anaconda3/bin/conda install libgcc -y
execute /opt/anaconda3/bin/pip install numpy scipy matplotlib scikit-learn scikit-image jupyter notebook pandas h5py cython
execute /opt/anaconda3/bin/pip install msgpack
execute /opt/anaconda3/bin/conda install line_profiler -y
sed -i.bak "/anaconda3/d" ~/.zshrc

execute /opt/anaconda3/bin/pip install autopep8 scdl youtube-dl jupyterlab
echo "alias ydl=\"youtube-dl -f 140 --add-metadata --metadata-from-title \\\"%(artist)s - %(title)s\\\" -o \\\"%(title)s.%(ext)s\\\"\"" >> ~/.bash_aliases

execute /opt/anaconda3/bin/conda info --envs

spatialPrint "Adding anaconda to path variables"
{
    echo "# Anaconda Python. Change the \"conda activate base\" to whichever environment you would like to activate by default"
    echo ". /opt/anaconda3/etc/profile.d/conda.sh"
    echo "conda activate base"

    echo "if [ -f ~/.bash_aliases ]; then"
    echo "  source ~/.bash_aliases"
    echo "fi"

    echo "# Switching to 256-bit colour by default so that zsh-autosuggestion's suggestions are not suggested in white, but in grey instead"
    echo "export TERM=xterm-256color"

    echo "# Setting the default text editor to micro, a terminal text editor with shortcuts similar to what you'd encounter in an IDE"
    echo "export VISUAL=micro"
} >> ~/.zshrc

# echo "*************************** NOTE *******************************"
# echo "If you ever mess up your anaconda installation somehow, do"
# echo "\$ conda remove anaconda matplotlib mkl mkl-service nomkl openblas"
# echo "\$ conda clean --all"
# echo "Do this for each environment as well as your root. Then reinstall all except nomkl"

## If you want to install the bleeding edge Nvidia drivers, uncomment the next set of lines
# sudo add-apt-repository ppa:graphics-drivers/ppa -y
# execute sudo apt-get update
# sudo ubuntu-drivers autoinstall
# echo "The PC will restart now. Check if your display is working, as your display driver would have been updated. Hit [Enter]"
# echo "Also, when installing CUDA next, ********don't******* install display drivers."
# echo "In case your drivers don't work, purge gdm3 and use lightdm (sudo apt-get purge lightdm && sudo dpkg-reconfigure gdm3)"
# read temp


spatialPrint "The script has finished."
if [[ ! -n $CIINSTALL ]]; then
    # echo "The terminal instance will now close so that the shell changes can take place"
    # read -p "Press [Enter] to continue..." temp
    # kill -9 $PPID
    su - $USER
fi
