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

# To note: the execute() function doesn't handle pipes well
execute () {
	echo "$ $*"
	OUTPUT=$($@ 2>&1)
	if [ $? -ne 0 ]; then
        echo "$OUTPUT"
        echo ""
        echo "Failed to Execute $*" >&2
        exit 1
    fi
}

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

if [[ $(command -v conda) || (-n $CIINSTALL) ]]; then
    PIP="pip install"
else
    execute sudo apt-get update
    execute sudo apt-get install python3 python3-dev python-dev python-tk -y
    if [[ ! -n $CIINSTALL ]]; then execute sudo apt-get install python3-pip python-pip; fi
    PIP="sudo pip3 install"
fi

$PIP --upgrade numpy tabulate python-dateutil
execute $PIP keras gensim networkx --upgrade
execute $PIP tensorflow$GPU_PRESENT --upgrade
execute $PIP torch torchvision gym --upgrade

echo ""
echo "This script has finished"