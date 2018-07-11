#!/bin/bash

source activate py36
pip install --upgrade pip
if [[ -n $(echo $SHELL | grep "zsh") ]] ; then
  SHELLRC=~/.zshrc
elif [[ -n $(echo $SHELL | grep "bash") ]] ; then
  SHELLRC=~/.bashrc
elif [[ -n $(echo $SHELL | grep "ksh") ]] ; then
  SHELLRC=~/.kshrc
else
  echo "Unidentified shell $SHELL"
  exit # Ain't nothing I can do to help you buddy :P
fi


if [[ (! -n $(echo $PATH | grep 'cuda')) && ( -d "/usr/local/cuda" )]]; then
    echo "Adding Cuda location to PATH"
    {
        echo "# Cuda"
        echo "export PATH=/usr/local/cuda/bin:\$PATH"
        echo "export LD_LIBRARY_PATH=/usr/local/cuda/lib64:/usr/local/cuda/extras/CUPTI/lib64:\$LD_LIBRARY_PATH"
        echo "export CUDA_HOME=/usr/local/cuda"
    } >> $SHELLRC
    source $SHELLRC
fi

sudo apt-get install -y build-essential cmake pkg-config openjdk-8-jdk

echo "deb [arch=amd64] http://storage.googleapis.com/bazel-apt stable jdk1.8" | sudo tee /etc/apt/sources.list.d/bazel.list
curl https://bazel.build/bazel-release.pub.gpg | sudo apt-key add -

sudo apt-get update
sudo apt-get upgrade -y
sudo apt-get install -y libprotobuf-dev libleveldb-dev libsnappy-dev libhdf5-serial-dev protobuf-compiler libopencv-dev libcupti-dev bazel cmake zlib1g-dev libjpeg-dev xvfb libav-tools xorg-dev python-opengl libboost-all-dev libsdl2-dev swig

if ! echo "$PATH" | grep -q 'conda' ; then
	if which nvcc > /dev/null; then
		pip install tensorflow-gpu 
	else
		pip install tensorflow
	fi
	pip install torch torchvision "gym" keras tabulate python-dateutil gensim networkx --upgrade
else
	if which nvcc > /dev/null; then
		sudo pip3 install tensorflow-gpu 
	else
		sudo pip3 install tensorflow
	fi
	sudo pip3 install torch torchvision "gym" keras tabulate python-dateutil gensim networkx --upgrade
fi

echo ""
echo "This script has finished"