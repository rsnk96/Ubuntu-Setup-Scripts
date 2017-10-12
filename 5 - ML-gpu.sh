#!/bin/bash

echo "This script will install tensorflow, keras, pytorch and torch vision, and assumes you have set up anaconda as done in the second script of this repository. If not, please modify this file before executing it"
echo "NOTE: This File is to be run ***************************ONLY AFTER YOU HAVE INSTALLED CUDA***************************"
read -r -p "Hit [Enter] if you have, [Ctrl+C] if you have not!" temp

{
    echo "export PATH=/usr/local/cuda-8.0/bin:\$PATH"
    echo "export LD_LIBRARY_PATH=/usr/local/cuda/lib64:/usr/local/cuda/extras/CUPTI/lib64:\$LD_LIBRARY_PATH"
    echo "export CUDA_HOME=/usr/local/cuda"
} >> ~/.zshrc

source activate py35
pip install keras tabulate python-dateutil gensim "networkx[all]" --upgrade

read -p "Would you like to install tensorflow from source or PyPi (pip)?. Press q to skip this. Default is from PyPi [s/p/q]: " tempvar
tempvar=${tempvar:-p}

if [ "$tempvar" = "p" ]; then
    pip install tensorflow-gpu
elif [ "$tempvar" = "s" ]; then
    pip uninstall tensorflow-gpu tensorflow

    sudo apt-get install libcupti-dev
    if [ ! -d "tensorflow" ]; then
        git clone https://github.com/tensorflow/tensorflow
    else
        (
            cd tensorflow || exit
            git pull
        )
    fi
    
    cd tensorflow

    echo "deb [arch=amd64] http://storage.googleapis.com/bazel-apt stable jdk1.8" | sudo tee /etc/apt/sources.list.d/bazel.list
    curl https://bazel.build/bazel-release.pub.gpg | sudo apt-key add -

    sudo apt-get update && sudo apt-get install bazel
    sudo apt-get upgrade bazel

    read -p "Starting Configuration process. Be alert for the queries it will throw at you. Press [Enter]" temp

    ./configure

	cd tensorflow
    bazel build --config=opt --config=cuda //tensorflow/tools/pip_package:build_pip_package
    cp -r bazel-bin/tensorflow/tools/pip_package/build_pip_package.runfiles/main/* bazel-bin/tensorflow/tools/pip_package/build_pip_package.runfiles/
    bazel-bin/tensorflow/tools/pip_package/build_pip_package /tmp/tensorflow_pkg

    pip install /tmp/tensorflow_pkg/*.whl
    cd ../

elif [ "$tempvar" = "q" ];then
    echo "Skipping this step"
fi


echo ""
echo "Now installing PyTorch"
export CMAKE_PREFIX_PATH="$(dirname $(which conda))/../" # [anaconda root directory]
# Install basic dependencies
conda install numpy pyyaml mkl setuptools cmake cffi -y
# Add LAPACK support for the GPU
conda install -c soumith magma-cuda80 -y # or magma-cuda75 if CUDA 7.5, UPDATE IF CUDA IS UPDATED (assuming soumith has uploaded magma package)
if [ ! -d "pytorch" ]; then
    git clone --recursive https://github.com/pytorch/pytorch
else
    (
        cd pytorch || exit
        git submodule update --recursive
        git pull
    )
fi
cd pytorch
python setup.py install
pip install torchvision
cd ..

echo ""
echo "Now installing Theano"
conda install theano pygpu -y

echo ""
echo "Now installing OpenAI Gym"
sudo apt-get install -y python-numpy python-dev cmake zlib1g-dev libjpeg-dev xvfb libav-tools xorg-dev python-opengl libboost-all-dev libsdl2-dev swig
pip install "gym[all]"


echo "This script has finished"
