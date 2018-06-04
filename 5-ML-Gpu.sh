#!/bin/bash

if test -n $(echo $SHELL | grep "zsh") ; then
  SHELLRC=~/.zshrc
elif test -n $(echo $SHELL | grep "bash") ; then
  SHELLRC=~/.bashrc
elif test -n $(echo $SHELL | grep "ksh") ; then
  SHELLRC=~/.kshrc
else
  exit # Ain't nothing I can do to help you buddy :P
fi

echo        "***************************RUN AFTER YOU HAVE INSTALLED CUDA***************************"
read -r -p "***************** Hit [Enter] if you have, [Ctrl+C] if you have not!********************" temp

if ! test -n "$(echo "$PATH" | grep 'cuda')"; then
    echo "Adding Cuda location to PATH"
{
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

pip install keras tabulate python-dateutil gensim networkx --upgrade

read -p "Would you like to install tensorflow from source or PyPi (pip)?. Press q to skip this. Default is from PyPi [s/p/q]: " tempvar
tempvar=${tempvar:-p}

if test "$tempvar" = "p"; then
    pip install tensorflow-gpu
elif test "$tempvar" = "s"; then
    if ! test -d "tensorflow"; then
        git clone --recurse-submodules https://github.com/tensorflow/tensorflow
    else
    (
        cd tensorflow || exit
        git checkout master -f
        git pull origin master
    )
    fi
    
    #Checkout the latest release candidate, as it should be relatively stable
    cd tensorflow
    git checkout $(git tag | egrep -v '-' | tail -1)
    
    read -p "Starting Configuration process. Be alert for the queries it will throw at you. Press [Enter]" temp

    ./configure
	cd tensorflow
    bazel build --config=opt --config=cuda --incompatible_load_argument_is_label=false --action_env="LD_LIBRARY_PATH=${LD_LIBRARY_PATH}" //tensorflow/tools/pip_package:build_pip_package
    cd ../
    # cp -r bazel-bin/tensorflow/tools/pip_package/build_pip_package.runfiles/main/* bazel-bin/tensorflow/tools/pip_package/build_pip_package.runfiles/
    bazel-bin/tensorflow/tools/pip_package/build_pip_package /tmp/tensorflow_pkg

    pip install /tmp/tensorflow_pkg/*.whl --force-reinstall
    cd ../

elif test "$tempvar" = "q";then
    echo "Skipping this step"
fi


echo ""
echo "Now installing PyTorch"
export CMAKE_PREFIX_PATH="$(dirname $(which conda))/../" # [anaconda root directory]
# Install basic dependencies
conda install numpy pyyaml mkl setuptools cmake cffi -y
# Add LAPACK support for the GPU
conda install -c soumith magma-cuda80 -y # or magma-cuda75 if CUDA 7.5, UPDATE IF CUDA IS UPDATED (assuming soumith has uploaded magma package)
if ! test -d "pytorch"; then
    git clone --recursive https://github.com/pytorch/pytorch
else
(
    cd pytorch || exit
    git submodule update --recursive
    git pull
)
fi
cd pytorch
python setup.py clean
python setup.py install
echo "Now installing torchvision"
pip install torchvision
pip install tensorboardX
cd ..

echo ""
echo "Now installing OpenAI Gym"
pip install "gym"


echo "This script has finished"
