#!/bin/bash

sudo apt-get update -y
sudo apt-get install ubuntu-restricted-extras -y

# My choice for terminal: Tilda+tmux
# Not guake because tilda is lighter on resources
# Not terminator because tmux sessions continue to run if you accidentally close the terminal emulator
sudo apt-get install tilda -y
sudo apt-get install tmux -y

cp config_files/.tmux.conf ~

if [ ! -d "~/.config/tilda" ]; then
    mkdir ~/.config/tilda
fi

cp config_files/config_0 ~/.config/tilda/

sudo apt-get install zsh -y
sudo apt-get install git -y

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

CONTREPO=https://repo.continuum.io/archive/
# Stepwise filtering of the html at $CONTREPO
# Get the topmost line that matches our requirements, extract the file name.
ANACONDA_LATEST_FILE=$(wget -q -O - $CONTREPO index.html | grep "Anaconda3-" | grep "Linux" | grep "86_64" | head -n 1 | cut -d \" -f 2)
wget -O ~/Downloads/anacondaInstallScript.sh "$CONTREPO$ANACONDA_LATEST_FILE"
bash ~/Downloads/anacondaInstallScript.sh

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
    echo "export PATH=~/anaconda3/bin:\$PATH"

    echo "if [ -f ~/.bash_aliases ]; then"
    echo "  source ~/.bash_aliases"
    echo "fi"
} >> ~/.zshrc

echo "The script has finished. The terminal will now exit and tilda will open. Continue the other scripts from within that"
echo "Look out for the shortcut key for maximizing"
read -p "Press [Enter] to continue..." temp
nohup tilda &
sleep 3
kill -9 $PPID
# Reason this is being done is so that the next time you open a shell emulator, it opens tilda, and the rest of the script continues there
