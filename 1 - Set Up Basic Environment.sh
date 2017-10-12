#!/bin/bash

sudo apt-get update -y
sudo apt-get install ubuntu-restricted-extras -y

# My choice for terminal: Tilda+tmux
# Not guake because tilda is lighter on resources
# Not terminator because tmux sessions continue to run if you accidentally close the terminal emulator
sudo apt-get install tilda tmux -y
sudo apt-get install gimp meld -y

cp config_files/.tmux.conf ~

if [ ! -d "~/.config/tilda" ]; then
    mkdir ~/.config/tilda
fi

cp config_files/config_0 ~/.config/tilda/

sudo apt-get install git -y

sh -c "$(wget https://gist.githubusercontent.com/rsnk96/87229bd910e01f2ee7c35f96d7cb2f6c/raw/f068812ebd711ed01ebc4c128c8624730ab0dc81/build-zsh.sh -O -)"
git clone --recursive https://github.com/Eriner/zim.git ${ZDOTDIR:-${HOME}}/.zim

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

continuum_website=https://repo.continuum.io/archive/
# Stepwise filtering of the html at $continuum_website
# Get the topmost line that matches our requirements, extract the file name.
latest_anaconda_steup=$(wget -q -O - $continuum_website index.html | grep "Anaconda3-" | grep "Linux" | grep "86_64" | head -n 1 | cut -d \" -f 2)
wget -O ~/Downloads/anacondaInstallScript.sh "$continuum_website$latest_anaconda_steup"
sudo mkdir /opt/anaconda3 && sudo chmod ugo+w /opt/anaconda3
bash ~/Downloads/anacondaInstallScript.sh -f -b -p /opt/anaconda3

touch ~/.bash_aliases
echo "Adding aliases to ~/.bash_aliases"
{
    echo "alias jn=\"jupyter notebook\""
    echo "alias maxvol=\"pactl set-sink-volume @DEFAULT_SINK@ 150%\""
    echo "alias download=\"wget --random-wait -r -p --no-parent -e robots=off -U mozilla\""
    echo "alias server=\"ifconfig | grep inet\\ addr && python3 -m http.server\""
    echo "weather() {curl wttr.in/\"\$1\";}"
    echo "alias gpom=\"git push origin master\""
    echo "alias update=\"sudo apt-get update && sudo apt-get upgrade -y\""
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

echo "The script has finished. The System will now reboot so that certain shell changes can take place"
echo "sudo reboot"
read -p "Press [Enter] to continue..." temp

chsh -s /bin/zsh
sudo reboot
