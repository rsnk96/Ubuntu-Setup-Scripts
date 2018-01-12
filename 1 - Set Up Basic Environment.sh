#!/bin/bash

set -e

sudo apt-get update -y
sudo apt-get dist-upgrade -y
sudo apt-get install ubuntu-restricted-extras -y

# My choice for terminal: Tilda+tmux
# Not guake because tilda is lighter on resources
# Not terminator because tmux sessions continue to run if you accidentally close the terminal emulator
sudo apt-get install git -y
sudo apt-get install tilda tmux -y
sudo apt-get install gimp meld -y
sudo apt-get install --assume-yes xclip # this is used for the copying tmux buffer to clipboard buffer
sudo apt-get install vim-gui-common
sudo apt-get install vim-runtime
cp config_files/.vimrc ~

# refer : [http://www.rushiagr.com/blog/2016/06/16/everything-you-need-to-know-about-tmux-copy-pasting-ubuntu/] for tmux buffers in ubuntu
cp config_files/.tmux.conf ~
cp config_files/.tmux.conf.local ~
mkdir -p ~/.config/tilda
cp config_files/config_0 ~/.config/tilda/


sh -c "$(wget https://gist.githubusercontent.com/rsnk96/87229bd910e01f2ee7c35f96d7cb2f6c/raw/f068812ebd711ed01ebc4c128c8624730ab0dc81/build-zsh.sh -O -)"
git clone --recursive https://github.com/Eriner/zim.git ${ZDOTDIR:-${HOME}}/.zim

cp config_files/zsh_config ~/.zim/templates/zimrc
ln -s ~/.zim/templates/zimrc ~/.zimrc
ln -s ~/.zim/templates/zlogin ~/.zlogin
ln -s ~/.zim/templates/zshrc ~/.zshrc

# If you prefer Prezto, then uncomment the next few lines. Zim is much faster though
# git clone --recursive https://github.com/sorin-ionescu/prezto.git "${ZDOTDIR:-$HOME}/.zprezto"

# ln -s ~/.zprezto/runcoms/zlogin ~/.zlogin
# ln -s ~/.zprezto/runcoms/zlogout ~/.zlogout
# ln -s ~/.zprezto/runcoms/zpreztorc ~/.zpreztorc
# ln -s ~/.zprezto/runcoms/zprofile ~/.zprofile
# ln -s ~/.zprezto/runcoms/zshenv ~/.zshenv
# ln -s ~/.zprezto/runcoms/zshrc ~/.zshrc


git clone https://github.com/axel-download-accelerator/axel.git
sudo apt-get install autopoint
cd axel
./autogen.sh
./configure
make
sudo make install
cd ../


# continuum_website=https://repo.continuum.io/archive/
# Stepwise filtering of the html at $continuum_website
# Get the topmost line that matches our requirements, extract the file name.
# latest_anaconda_steup=$(wget -q -O - $continuum_website index.html | grep "Anaconda3-" | grep "Linux" | grep "86_64" | head -n 1 | cut -d \" -f 2)
# axel -o ./anacondaInstallScript.sh "$continuum_website$latest_anaconda_steup"
# sudo mkdir /opt/anaconda3 && sudo chmod ugo+w /opt/anaconda3
# bash ./anacondaInstallScript.sh -f -b -p /opt/anaconda3

touch ~/.bash_aliases
echo "Adding aliases to ~/.bash_aliases"
{
    echo "alias maxvol=\"pactl set-sink-volume @DEFAULT_SINK@ 150%\""
    echo "alias download=\"wget --random-wait -r -p --no-parent -e robots=off -U mozilla\""
    echo "alias server=\"ifconfig | grep inet\\ addr && python3 -m http.server\""
    echo "weather() {curl wttr.in/\"\$1\";}"
    echo "alias gpom=\"git push origin master\""
    echo "alias update=\"sudo apt-get update && sudo apt-get upgrade -y\""
    echo "alias tmux=\"tmux -u\""
} >> ~/.bash_aliases

#echo "Adding anaconda to path variables"
#{
#    echo ""
#    echo "export OLDPATH=\$PATH"
#    echo "export PATH=/opt/anaconda3/bin:\$PATH"
#    echo "if [ -f ~/.bash_aliases ]; then"
#    echo "  source ~/.bash_aliases"
#    echo "fi"
#} >> ~/.zshrc

echo "The script has finished. The System will now reboot so that certain shell changes can take place"
echo "sudo reboot"
read -p "Press [Enter] to continue..." temp


command -v zsh | sudo tee -a /etc/shells
chsh -s /bin/zsh
sudo reboot
