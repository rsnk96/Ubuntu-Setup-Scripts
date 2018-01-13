#!/bin/zsh

chsh -s /bin/zsh
source ~/.zshrc

# Desktop settings
dconf write /org/compiz/profiles/unity/plugins/unityshell/launcher-hide-mode 1 
dconf write /org/compiz/profiles/unity/plugins/unityshell/icon-size 34

# TLP manager 
sudo add-apt-repository ppa:linrunner/tlp -y
sudo apt-get update
sudo apt-get install tlp tlp-rdw -y
sudo tlp start

sudo apt-get install python-pip -y
pip install autopep8 scdl youtube-dl
sudo pip install --upgrade youtube_dl -y
echo "alias ydl=\"youtube-dl -f 140 --add-metadata --metadata-from-title \\\"%(artist)s - %(title)s\\\" -o \\\"%(title)s.%(ext)s\\\"\"" >> ~/.bash_aliases

# refer :[https://github.com/rg3/youtube-dl/blob/master/README.md#readme] for documentation of youtube downloader 

# Multiload and other sensor applets
sudo apt-add-repository ppa:sneetsher/copies -y
sudo apt update 
sudo apt install indicator-sensors indicator-multiload -y
sudo apt-add-repository -r ppa:sneetsher/copies -y
sudo apt update

sudo apt-get install redshift redshift-gtk -y


## If you want to install the bleeding edge Nvidia drivers, uncomment the next set of lines
# echo "Now choose gdm3 as your default display manager. Hit Enter"
# read temp

# sudo add-apt-repository ppa:graphics-drivers/ppa -y
# sudo apt-get update
# sudo ubuntu-drivers autoinstall
# echo "The PC will restart now. Check if your display is working, as your display driver would have been updated. Hit [Enter]"
# echo "Also, when installing CUDA next, ********don't******* install display drivers."
# echo "In case your drivers don't work, purge gdm3 and use lightdm (sudo apt-get purge lightdm && sudo dpkg-reconfigure gdm3)"
# read temp
# sudo reboot

echo "The script has finished"
