#!/bin/bash

if [[ -n $(echo $SHELL | grep "zsh") ]] ; then
  SHELLRC=~/.zshrc
elif [[ -n $(echo $SHELL | grep "bash") ]] ; then
  SHELLRC=~/.bashrc
elif [[ -n $(echo $SHELL | grep "ksh") ]] ; then
  SHELLRC=~/.kshrc
else
  echo "Unidentified shell $SHELL"
  exit # Ain't nothing I can do to help you buddy :P. And if you're using FISH shell, just use zsh-autosuggestions instead for heaven's sake!!! xD
fi

spatialPrint() {
    echo ""
    echo ""
    echo "$1"
	echo "================================"
}

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

if [[ $(command -v conda) || (-n $CIINSTALL) ]]; then
    PIP="pip install"
else
    execute sudo apt-get install python3 python3-dev python3-tk -y
    if [[ ! -n $CIINSTALL ]]; then sudo apt-get install python3-pip; fi
    PIP="sudo pip3 install"
fi
if which nvcc > /dev/null; then GPU_PRESENT="-gpu"; fi  #for tensorflow-gpu if gpu is present



if [[ ! -n $CIINSTALL ]]; then
    echo        "*******************RUN AFTER YOU HAVE INSTALLED CUDA IF YOU HAVE A GPU*******************"
    read -r -p "***************** Hit [Enter] if you have, [Ctrl+C] if you have not!********************" temp
fi

if [[ (! -n $(echo $PATH | grep 'cuda')) && ( -d "/usr/local/cuda" ) ]]; then
    echo "Adding Cuda location to PATH"
    {
        echo ""
        echo "# Cuda"
        echo "export PATH=/usr/local/cuda/bin:\$PATH"
        echo "export LD_LIBRARY_PATH=/usr/local/cuda/lib64:/usr/local/cuda/extras/CUPTI/lib64:\$LD_LIBRARY_PATH"
        echo "export CUDA_HOME=/usr/local/cuda"
    } >> $SHELLRC
    source $SHELLRC
else
    echo "Not adding Cuda to the PATH"
fi

if which nvidia-smi > /dev/null; then
    spatialPrint "Installing nvtop"
    execute sudo apt-get install cmake libncurses5-dev git -y
    if [[ ! -d "nvtop" ]]; then
        execute git clone --quiet https://github.com/Syllo/nvtop.git
    else
    (
        cd nvtop || exit
        execute git pull origin master
    )
    fi
    execute mkdir -p nvtop/build
    cd nvtop/build
    execute cmake -DCMAKE_BUILD_TYPE=Optimized -DNVML_RETRIEVE_HEADER_ONLINE=True ..
    execute make
    execute sudo make install
    cd ../../
fi

execute $PIP numpy
execute sudo apt-get install -y build-essential cmake pkg-config openjdk-8-jdk libhdf5-dev

# To install the latest Bazel version, which has been commented out as of tensorflow v1.13 because the latest version is not supported yet
# Uncomment the following lines and comment out the Bazel installation further down below in order to install the latest Bazel release
# echo "deb [arch=amd64] http://storage.googleapis.com/bazel-apt stable jdk1.8" | sudo tee /etc/apt/sources.list.d/bazel.list
# curl https://bazel.build/bazel-release.pub.gpg | sudo apt-key add -
# execute sudo apt-get update
# execute sudo apt-get install bazel -y

execute $PIP wheel
execute sudo apt-get install software-properties-common swig -y

if which nvcc > /dev/null; then execute sudo apt-get install libcupti-dev -y; fi

execute $PIP keras tabulate python-dateutil gensim six networkx keras_applications keras_preprocessing --upgrade

spatialPrint "Now installing Tensorflow"
if [[ ! -n $CIINSTALL ]]; then
    read -p "Would you like to install tensorflow from source or PyPi (pip)?. Press q to skip this. Default is from PyPi [s/p/q]: " tempvar
fi
tempvar=${tempvar:-s}

if test "$tempvar" = "p"; then
    execute $PIP tensorflow$GPU_PRESENT
elif test "$tempvar" = "s"; then
    if ! test -d "tensorflow"; then
        git clone --recurse-submodules https://github.com/tensorflow/tensorflow
    else
    (
        cd tensorflow || exit
        execute git checkout master -f
        execute git pull origin master
    )
    fi

    cd tensorflow
#     Checkout the latest release candidate, as it should be relatively stable
    latest_tag="$(git tag --sort=-creatordate | egrep -v '-' | head -1)"
    git checkout $latest_tag

    # Install latest version of Bazel supported for the Tensorflow version being installed
    BAZEL_VERSION="$(cat configure.py | grep "_TF_MAX_BAZEL_VERSION = " | grep -o -E "[0-9]{1,}.[0-9]{1,}.[0-9]{1,}")"
    execute sudo apt-get install -y g++ zlib1g-dev bash-completion
    cd ..
    execute curl -LO "https://github.com/bazelbuild/bazel/releases/download/${BAZEL_VERSION}/bazel_${BAZEL_VERSION}-linux-x86_64.deb"
    sudo dpkg -i bazel_*.deb
    cd tensorflow

    if [[ ! -n $CIINSTALL ]]; then
        read -p "Starting Configuration process. Be alert for the queries it will throw at you. Press [Enter]" temp
        execute ./configure
        if which nvcc > /dev/null; then GPU_OPTIM=" --config=cuda";  fi
        if locate intel-mkl > /dev/null; then   MKL_OPTIM=" --config=mkl";   fi
    else
        echo "Configuring script now"
        PYTHON_BIN_PATH=$(which python3) PYTHON_LIB_PATH="$($PYTHON_BIN_PATH -c 'from distutils.sysconfig import get_python_inc; print(get_python_inc())')" \
        TF_CUDA_CLANG=0 TF_NEED_CUDA=0 TF_NEED_OPENCL_SYCL=0 TF_NEED_COMPUTECPP=0 TF_NEED_OPENCL=0  TF_NEED_TENSORRT=0 TF_ENABLE_XLA=0 TF_NEED_VERBS=0 TF_DOWNLOAD_CLANG=0 TF_NEED_ROCM=0 TF_NEED_MPI=0 TF_SET_ANDROID_WORKSPACE=0 CC_OPT_FLAGS="-march=native" ./configure
    fi

    cd tensorflow
    execute bazel shutdown
    spatialPrint "Now using bazel to build Tensorflow"

    bazel build --config=opt${MKL_OPTIM}${GPU_OPTIM} //tensorflow/tools/pip_package:build_pip_package
    cd ../

    execute bazel-bin/tensorflow/tools/pip_package/build_pip_package /tmp/tensorflow_pkg
    execute $PIP /tmp/tensorflow_pkg/*.whl --force-reinstall
    cd ../

elif test "$tempvar" = "q";then
    echo "Skipping this step"
fi


spatialPrint "Now installing PyTorch. If you do not have anaconda, it will install from pip. If you do, it will be compiled from source"
if which conda > /dev/null; then
    export CMAKE_PREFIX_PATH="$(dirname $(which conda))/../" # [anaconda root directory]
    # Install basic dependencies
    execute conda install numpy pyyaml mkl mkl-include setuptools cmake cffi typing -y
    execute conda install -c mingfeima mkldnn -y
    # Add LAPACK support for the GPU
    if which nvcc > /dev/null; then execute conda install -c soumith magma-cuda100 -y; fi
    if ! test -d "pytorch"; then
        execute git clone --quiet --recursive https://github.com/pytorch/pytorch
    else
    (
        cd pytorch || exit
        execute git submodule update --recursive
        execute git pull
    )
    fi
    cd pytorch
    execute python setup.py clean
    execute python setup.py install
    echo "Now installing torchvision"
    execute $PIP torchvision
    execute $PIP tensorboardX
    cd ..
else
    execute $PIP torch torchvision
fi

spatialPrint "Now installing OpenAI Gym"
execute $PIP gym


spatialPrint "This script has finished"
