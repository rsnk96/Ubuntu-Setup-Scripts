#!/bin/zsh
# This will install CUDA and Nvidia Drivers 
wget developer.download.nvidia.com/compute/cuda/repos/ubuntu1604/x86_64/cuda-repo-ubuntu1604_9.0.176-1_amd64.deb
sudo dpkg -i cuda-repo-ubuntu1604_9.0.176-1_amd64.deb
sudo apt-key adv --fetch-keys http://developer.download.nvidia.com/compute/cuda/repos/ubuntu1604/x86_64/7fa2af80.pub
sudo apt-get update
sudo apt-get install cuda-9-0 -y
rm *.deb
echo ""
echo "Adding Paths"
{
	echo "export PATH=/usr/local/cuda-9.0/bin${PATH:+:${PATH}}"
	echo "$ export LD_LIBRARY_PATH=/usr/local/cuda-9.0/lib64${LD_LIBRARY_PATH:+:${LD_LIBRARY_PATH}}"
} >> ~/.zshrc 


