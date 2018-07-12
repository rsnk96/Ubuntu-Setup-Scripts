#!/bin/bash

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

if which nvcc > /dev/null; then GPU_PRESENT="-gpu"; fi

if [[ ! $(echo $PATH | grep -q 'conda') ]] ; then
    PIP="pip"
else
    sudo apt-get update
    sudo apt-get install python3 python3-dev python3-pip python-dev python-pip python-tk -y
    PIP="sudo pip3"
fi

$PIP install --upgrade pip setuptools numpy
$PIP install keras tabulate python-dateutil gensim networkx --upgrade
$PIP install tensorflow$GPU_PRESENT --upgrade
$PIP install torch torchvision "gym"--upgrade

echo ""
echo "This script has finished"