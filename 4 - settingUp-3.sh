#~/bin/bash
sudo apt-get install nautilus-dropbox -y

echo "Installed dropbox for your nautilus. If using different file explorer, change"
read temp

echo "Download and Install VS Code"
read temp

sudo apt-get install clang-format -y
#sudo apt-get install clang-format-3.8
#sudo ln -s /usr/bin/clang-format-3.8 /usr/bin/clang-format

sudo apt-get install gparted -y

sudo add-apt-repository ppa:yannubuntu/boot-repair -y
sudo apt-get update
sudo apt-get install -y boot-repair

#sudo apt-get install gnome-themes-standard
sudo apt-get install shutter -y

echo 'Note: Set shortcuts for Franz and screenshot manually'
echo "For screenshot, command: shutter -s -o '/tmp/%y-%m-%d_\$w_\$h.png' -c -e"
read temp

echo 'GRUB Customization'
echo 'http://www.ostechnix.com/configure-grub-2-boot-loader-settings-ubuntu-16-04/'

#sudo cp /etc/default/grub /etc/default/grub.bak
#sudo cp ~/Dropbox/Linux\ Post\ install\ scripts/grubBg.png /boot/grub
#sudo update-grub

sudo add-apt-repository ppa:danielrichter2007/grub-customizer -y
sudo apt-get update
sudo apt-get install grub-customizer -y

echo "Conda users go to file, change all sudo -H to conda, and rerun this. Or simply comment this set and uncomment the next"
read temp

#sudo -H pip install jupyter notebook
#sudo -H pip install cython
#sudo -H pip install pep8
#sudo -H pip install autopep8
#sudo -H pip3 install jupyter notebook
#sudo -H pip3 install cython
#sudo -H pip3 install pep8
#sudo -H pip3 install autopep8

pip install autopep8

source activate py27
pip install autopep8
source deactivate

sudo apt-get install firefox -y
jupyter notebook --generate-config
echo "\nc.NotebookApp.browser = u'firefox'" >> ~/.jupyter/jupyter_notebook_config.py

echo "Script finished"
