#~/bin/bash
sudo apt-get install nautilus-dropbox -y

echo
echo
echo
echo
echo
echo
echo "Installed dropbox for your nautilus. If using different file explorer (caja,etc), change it"

echo "Download and Install VS Code / Sublime / Atom. I recommend VS Code. If you are using VS Code, note that you have to remove the line which modifies $TMPDIR in your .zprofile."
read temp

sudo apt-get install htop -y

sudo apt-get install clang-format -y
#sudo apt-get install clang-format-3.8
#sudo ln -s /usr/bin/clang-format-3.8 /usr/bin/clang-format

sudo apt-get install gparted -y

sudo add-apt-repository ppa:yannubuntu/boot-repair -y
sudo apt-get update
sudo apt-get install -y boot-repair

#sudo apt-get install gnome-themes-standard
sudo apt-get install shutter -y

echo 'GRUB Customization'
echo 'http://www.ostechnix.com/configure-grub-2-boot-loader-settings-ubuntu-16-04/'

#sudo cp /etc/default/grub /etc/default/grub.bak
#sudo cp ~/Dropbox/Linux\ Post\ install\ scripts/grubBg.png /boot/grub
#sudo update-grub

sudo add-apt-repository ppa:danielrichter2007/grub-customizer -y
sudo apt-get update
sudo apt-get install grub-customizer -y

# Uncomment the next set of lines if you want to set up your normal Python too
#sudo -H pip install jupyter notebook
#sudo -H pip install cython
#sudo -H pip install pep8
#sudo -H pip install autopep8
#sudo -H pip3 install jupyter notebook
#sudo -H pip3 install cython
#sudo -H pip3 install pep8
#sudo -H pip3 install autopep8

pip install autopep8 scdl org-e

sudo apt-get install firefox -y
jupyter notebook --generate-config
echo "\nc.NotebookApp.browser = u'firefox'" >> ~/.jupyter/jupyter_notebook_config.py

echo 'Note: Set shortcuts for Franz and screenshot manually'
echo "For screenshot, command: shutter -s -o '/tmp/%y-%m-%d_\$w_\$h.png' -c -e"

echo "Script finished"
