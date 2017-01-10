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

chsh -s /usr/bin/zsh

bash Anaconda3-4.2.0-Linux-x86_64.sh

echo "Adding anaconda to path variables in zshrc"
echo "alias jn=\"jupyter notebook\"" >> ~/.zshrc
echo "alias maxvol=\"pactl set-sink-volume @DEFAULT_SINK@ 150%\"" >> ~/.zshrc
echo "export PATH=/home/rsnk96/anaconda3/bin:\$PATH" >> ~/.zshrc
source ~/.zshrc
cat ~/.zshrc
