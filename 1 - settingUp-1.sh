#!/bin/bash
sudo add-apt-repository ppa:gnome-terminator -y
sudo apt-get update -y
sudo apt-get install terminator -y
sudo apt-get install ubuntu-restricted-extras -y
sudo apt-get install tilda -y

sudo apt-get install zsh -y
sudo apt-get install git -y
git clone --recursive https://github.com/sorin-ionescu/prezto.git "${ZDOTDIR:-$HOME}/.zprezto"
ln -s ~/.zprezto/runcoms/zlogin ~/.zlogin
ln -s ~/.zprezto/runcoms/zlogout ~/.zlogout
ln -s ~/.zprezto/runcoms/zpreztorc ~/.zpreztorc
ln -s ~/.zprezto/runcoms/zprofile ~/.zprofile
ln -s ~/.zprezto/runcoms/zshenv ~/.zshenv
ln -s ~/.zprezto/runcoms/zshrc ~/.zshrc

CONTREPO=https://repo.continuum.io/archive/
# Stepwise filtering of the html at $CONTREPO
# Get the topmost line that matches our requirements, extract the file name.
ANACONDA_LATEST_NICCCCEEEE_URL=$(wget -q -O - $CONTREPO index.html | grep "Anaconda3-" | grep "Linux" | grep "86_64" | head -n 1 | cut -d \" -f 2)
wget -O ~/Downloads/anacondaInstallScript.sh $CONTREPO$ANACONDA_LATEST_NICCCCEEEE_URL
bash ~/Downloads/anacondaInstallScript.sh

touch ~/.bash_aliases
echo "Adding aliases to ~/.bash_aliases"
echo "alias jn=\"jupyter notebook\"" >> ~/.bash_aliases
echo "alias maxvol=\"pactl set-sink-volume @DEFAULT_SINK@ 150%\"" >> ~/.bash_aliases
echo "alias download=\"wget --random-wait -r -p --no-parent -e robots=off -U mozilla\"" >> ~/.bash_aliases
echo "alias server=\"ifconfig | grep inet\\ addr && python3 -m http.server\"" >> ~/.bash_aliases
echo "weather() {curl wttr.in/\"\$1\";}" >> ~/.bash_aliases
echo "alias gpom=\"git push origin master\"" >> ~/.bash_aliases
echo "alias update=\"sudo apt-get update && sudo apt-get upgrade -y\"" >> ~/.bash_aliases

echo "Adding anaconda to path variables"
echo "\nexport OLDPATH=\$PATH" >> ~/.zshrc
echo "export PATH=~/anaconda3/bin:\$PATH" >> ~/.zshrc

echo "if [ -f ~/.bash_aliases ]; then\n  source ~/.bash_aliases\nfi" >> ~/.zshrc

echo "The script has finished. The terminal will now exit. Hit [Enter]"
read temp
kill -9 $PPID
# Reason this is being done is so that the next time you open a shell emulator, it opens terminator, and the rest of the script continues there
