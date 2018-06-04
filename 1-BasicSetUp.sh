#!/bin/bash

set -e

sudo apt-get update -y
sudo apt-get dist-upgrade -y
sudo apt-get install ubuntu-restricted-extras -y
#sudo ubuntu-drivers autoinstall 

# My choice for terminal: Tilda+tmux
# Not guake because tilda is lighter on resources
# Not terminator because tmux sessions continue to run if you accidentally close the terminal emulator
sudo apt-get install git -y
rm -rf ~/.z*
sudo apt-get install tilda tmux -y
sudo apt-get install gimp meld -y
sudo apt-get install xclip -y # this is used for the copying tmux buffer to clipboard buffer
sudo apt-get install vim-gui-common vim-runtime -y
cp ./config_files/.vimrc ~

# refer : [http://www.rushiagr.com/blog/2016/06/16/everything-you-need-to-know-about-tmux-copy-pasting-ubuntu/] for tmux buffers in ubuntu
cp ./config_files/.tmux.conf ~
cp ./config_files/.tmux.conf.local ~
mkdir -p ~/.config/tilda
cp ./config_files/config_0 ~/.config/tilda/

# Set up zsh + zim
sh -c "$(wget https://gist.githubusercontent.com/rsnk96/87229bd910e01f2ee7c35f96d7cb2f6c/raw/f068812ebd711ed01ebc4c128c8624730ab0dc81/build-zsh.sh -O -)"
git clone --recursive https://github.com/Eriner/zim.git ${ZDOTDIR:-${HOME}}/.zim
ln -s ~/.zim/templates/zimrc ~/.zimrc
ln -s ~/.zim/templates/zlogin ~/.zlogin
ln -s ~/.zim/templates/zshrc ~/.zshrc

# Install axel, a download accelerator
if ! test -d "axel"; then
    git clone https://github.com/axel-download-accelerator/axel.git
else
    (
        cd axel || exit
        git pull
    )
fi
sudo apt-get install autopoint openssl libssl-dev -y
cd axel
./autogen.sh
./configure
make
sudo make install
cd ../


continuum_website=https://repo.continuum.io/archive/
# Stepwise filtering of the html at $continuum_website
# Get the topmost line that matches our requirements, extract the file name.
latest_anaconda_steup=$(wget -q -O - $continuum_website index.html | grep "Anaconda3-" | grep "Linux" | grep "86_64" | head -n 1 | cut -d \" -f 2)
axel -o ./anacondaInstallScript.sh "$continuum_website$latest_anaconda_steup"
sudo mkdir /opt/anaconda3 && sudo chmod ugo+w /opt/anaconda3
bash ./anacondaInstallScript.sh -f -b -p /opt/anaconda3

touch ~/.bash_aliases
echo "Adding aliases to ~/.bash_aliases"
{
    echo "alias jn=\"jupyter notebook\""
    echo "alias jl=\"jupyter lab\""
    echo "alias maxvol=\"pactl set-sink-volume @DEFAULT_SINK@ 150%\""
    echo "alias download=\"wget --random-wait -r -p --no-parent -e robots=off -U mozilla\""
    echo "alias server=\"ifconfig | grep inet\\ addr && python3 -m http.server\""
    echo "weather() {curl wttr.in/\"\$1\";}"
    echo "alias gpom=\"git push origin master\""
    echo "alias update=\"sudo apt-get update && sudo apt-get dist-upgrade && sudo apt-get autoremove -y\""
    echo "alias tmux=\"tmux -u new-session \\; \\
            neww \\; \\
              send-keys 'htop' C-m \\; \\
              split-window -h \\; \\
              send-keys 'nvidia-smi -l 1' C-m \\; \\
              rename-window 'performance' \\; \\
            select-window -l\""

} >> ~/.bash_aliases

echo "Adding anaconda to path variables"
{
    echo ""
    echo "export OLDPATH=\$PATH"
    echo "export PATH=/opt/anaconda3/bin:\$PATH"

    echo "if [ -f ~/.bash_aliases ]; then"
    echo "  source ~/.bash_aliases"
    echo "fi"
} >> ~/.zshrc

# Change default shell to zsh
command -v zsh | sudo tee -a /etc/shells
sudo chsh -s "$(command -v zsh)" "${USER}"

echo "The script has finished. The System will now reboot so that certain shell changes can take place"
echo "sudo reboot"
read -p "Press [Enter] to continue..." temp

sudo reboot
