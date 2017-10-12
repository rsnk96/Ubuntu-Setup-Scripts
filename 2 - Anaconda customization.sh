#!/bin/bash

conda update conda -y
conda clean --all -y
conda install ipython -y

conda install libgcc -y
conda create --name py27 python=2.7 numpy scipy matplotlib scikit-learn scikit-image jupyter notebook pandas h5py -y
conda create --name py35 python=3.5 numpy scipy matplotlib scikit-learn scikit-image jupyter notebook pandas h5py -y
pip install numpy scipy matplotlib scikit-learn scikit-image jupyter notebook pandas h5py
sed -i.bak "/anaconda3/d" /tools/setup.sh
echo "export PATH=/tools/anaconda3/envs/py27/bin:\$PATH" >> /tools/setup.sh
echo "export PATH=/tools/anaconda3/bin:\$PATH" >> /tools/setup.sh
source /tools/setup.sh

sudo apt-get install libboost-all-dev clang-format htop -y

conda info --envs

echo ""
echo ""
echo "*************************** NOTICE ***************************"
echo "Python2.7 and 3.5 environments have been created. To activate them hit "
echo "$ source activate py27"
echo "or"
echo "$ source activate py35"

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
