#!/bin/bash

set -e

if test -n $(echo $SHELL | grep "zsh") ; then
  SHELLRC=~/.zshrc
elif test -n $(echo $SHELL | grep "bash") ; then
  SHELLRC=~/.bashrc
elif test -n $(echo $SHELL | grep "ksh") ; then
  SHELLRC=~/.kshrc
else
  exit # Ain't nothing I can do to help you buddy :P
fi
SHELLRC=/tools/config.sh #override as config.sh will be shared by all users

echo        "***************************RUN AFTER YOU HAVE INSTALLED CUDA***************************"
read -r -p "***************** Hit [Enter] if you have, [Ctrl+C] if you have not!******************** " temp

if ! test -n "$(echo "$PATH" | grep 'cuda')"; then
    echo "Adding Cuda location to PATH"
{
    echo "export PATH=/usr/local/cuda-8.0/bin:\$PATH"
    echo "export LD_LIBRARY_PATH=/usr/local/cuda/lib64:/usr/local/cuda/extras/CUPTI/lib64:\$LD_LIBRARY_PATH"
    echo "export CUDA_HOME=/usr/local/cuda"
} >> $SHELLRC
source $SHELLRC
fi

echo "deb [arch=amd64] http://storage.googleapis.com/bazel-apt stable jdk1.8" | sudo tee /etc/apt/sources.list.d/bazel.list
curl https://bazel.build/bazel-release.pub.gpg | sudo apt-key add -

sudo apt-get update
sudo apt-get upgrade -y
sudo apt-get install -y libprotobuf-dev libleveldb-dev libsnappy-dev libhdf5-serial-dev protobuf-compiler libopencv-dev libcupti-dev bazel cmake zlib1g-dev libjpeg-dev xvfb libav-tools xorg-dev python-opengl libboost-all-dev libsdl2-dev swig

if test -n "$(conda info --envs |grep 'py35')"; then
    source activate py35
fi

pip install keras tabulate python-dateutil gensim networkx --upgrade

read -p "Would you like to install tensorflow from source or PyPi (pip)?. Press q to skip this. Default is from PyPi [s/p/q]: " tempvar
tempvar=${tempvar:-p}

if test "$tempvar" = "p"; then
    pip install tensorflow-gpu
elif test "$tempvar" = "s"; then
    if ! test -d "tensorflow"; then
        git clone https://github.com/tensorflow/tensorflow
    else
    (
        cd tensorflow || exit
        git pull
    )
    fi
    
    #Checkout the latest release candidate, as it should be relatively stable
    cd tensorflow
    latest_rc=$(git branch -av --sort=-committerdate | grep "remotes/origin/r" | head -1 | grep -E -o "r[0-9]+\.[0-9]+ | head -1")
    git checkout "$latest_rc"
    
    read -p "Starting Configuration process. Be alert for the queries it will throw at you. Press [Enter]" temp

    ./configure
    cd tensorflow
    bazel build --config=opt --config=cuda //tensorflow/tools/pip_package:build_pip_package
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
cd ..

echo ""
echo "Now installing Caffe"
sudo apt-get install -y build-essential cmake git pkg-config
sudo apt-get install -y libprotobuf-dev libleveldb-dev libsnappy-dev protobuf-compiler
sudo apt-get install -y libatlas-base-dev 
sudo apt-get install -y --no-install-recommends libboost-all-dev
sudo apt-get install -y libgflags-dev libgoogle-glog-dev liblmdb-dev
if ! test -d "caffe"; then
    git clone https://github.com/BVLC/caffe.git    
else
(
    cd caffe || exit
    git pull
)
fi
cd caffe
mkdir -p build
cd build
cmake -D python_version=3 ..
make all
make install
cd ../python
pip install cython scikit-image ipython h5py nose pandas protobuf pyyaml jupyter
sed -i -e 's/python-dateutil>=1.4,<2/python-dateutil>=2.0/g' requirements.txt
for req in $(cat requirements.txt); do pip install $req; done
cd ../build
make runtest
cd ../python
echo "export PYTHONPATH=`pwd`\${PYTHONPATH:+:\${PYTHONPATH}}" >> $SHELLRC

echo ""
echo "Now installing Theano"
conda install theano pygpu -y

echo ""
echo "Now installing OpenAI Gym"
pip install "gym[all]"


echo "This script has finished"