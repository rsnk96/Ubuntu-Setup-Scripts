#!/bin/bash

if which nautilus > /dev/null; then
    sudo apt-get install nautilus-dropbox -y
elif which caja > /dev/null; then
    sudo apt-get install caja-dropbox -y
fi

sudo apt-get install htop -y

sudo apt-get install gparted -y

sudo apt-get install task -y

sudo add-apt-repository ppa:yannubuntu/boot-repair -y
sudo apt-get update
sudo apt-get install -y boot-repair

#sudo apt-get install gnome-themes-standard
sudo apt-get install shutter -y

echo 'GRUB Customization'
echo 'http://www.ostechnix.com/configure-grub-2-boot-loader-settings-ubuntu-16-04/'

# If you want an image for your grub background:
#sudo cp /etc/default/grub /etc/default/grub.bak
#sudo cp <location to image> /boot/grub
#sudo update-grub

sudo add-apt-repository ppa:danielrichter2007/grub-customizer -y
sudo apt-get update
sudo apt-get install grub-customizer -y

sudo apt-add-repository ppa:jtaylor/keepass -y
sudo apt-get update -y
sudo apt-get install xdotool keepass2 -y

sudo apt-get install vlc -y

## To install chrome, uncomment the next set of lines
#wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | sudo apt-key add - 
#sudo sh -c 'echo "deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main" >> /etc/apt/sources.list.d/google-chrome.list'
#sudo apt-get update  -y
#sudo apt-get install google-chrome-stable -y

sudo apt-get install chromium-browser -y
sudo apt-get install adobe-flashplugin -y
sudo apt-get install firefox -y

## Install tor
sudo add-apt-repository ppa:webupd8team/tor-browser -y
sudo apt-get update -y
sudo apt-get install tor-browser -y

## Install I2P
sudo apt-add-repository ppa:i2p-maintainers/i2p -y
sudo apt-get update -y
sudo apt-get install i2p -y

echo
echo
echo 'Note: Set shortcuts for Franz and screenshot manually'
echo "For screenshot, command: shutter -s -o '/tmp/%y-%m-%d_\$w_\$h.png' -c -e"

echo "Script finished"
