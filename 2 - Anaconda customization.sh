#!/usr/bin/zsh
chsh -s /usr/bin/zsh
source ~/.zshrc

conda update conda


# Note: These set of lines are done as matplotlib finds older version of libpng at installation time but finds newer version at runtime, and this affects display ability at runtime
conda uninstall matplotlib
conda clean --all
cd /usr/include/libpng
sudo mv png.h _png.h
sudo mv pngconf.h _pngconf.h
conda install matplotlib scikit-image
sudo mv _png.h png.h
sudo mv _pngconf.h pngconf.h


# conda create --name py35 python=3.5 numpy scipy matplotlib
conda create --name py27 python=2.7 numpy scipy matplotlib scikit-learn scikit-image jupyter notebook
sed -i.bak "/anaconda3/d" ~/.zshrc
echo "export PATH=~/anaconda3/envs/py27/bin:\$PATH" >> ~/.zshrc
echo "export PATH=~/anaconda3/bin:\$PATH" >> ~/.zshrc
echo "alias ipython=\"ipython3\"" >> ~/.zshrc
source ~/.zshrc

conda info --envs

echo "Bro. If you ever mess up your anaconda installation somehow, do \$conda remove anaconda matplotlib mkl mkl-service nomkl openblas, then \$conda clean --all. Do this for each environment as well as your root. Then reinstall all except nomkl. Nvidia will now be installed"
echo "Now choose gdm3 as your default display manager. Hit Enter"
read temp

sudo add-apt-repository ppa:graphics-drivers/ppa -y
sudo apt-get update
sudo ubuntu-drivers autoinstall
echo "The PC will restart now. Check if your display is working, as your display driver would have been updated. Hit Enter. Also, when installing CUDA next, don't install display drivers."
read temp
sudo reboot
