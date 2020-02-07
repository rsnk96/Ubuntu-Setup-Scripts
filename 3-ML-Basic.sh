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

if [[ (! -n $(echo $PATH | grep 'cuda')) && ( -d "/usr/local/cuda" ) ]]; then
    echo "Adding Cuda location to PATH"
    {
        echo "# Cuda"
        echo "export PATH=/usr/local/cuda/bin:\$PATH"
        echo "export LD_LIBRARY_PATH=/usr/local/cuda/lib64:/usr/local/cuda/extras/CUPTI/lib64:\$LD_LIBRARY_PATH"
        echo "export CUDA_HOME=/usr/local/cuda"
    } >> $SHELLRC
    source $SHELLRC
fi

if which nvidia-smi > /dev/null; then 
    echo "Installing nvtop"
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

if [[ $(command -v conda) || (-n $CIINSTALL) ]]; then
    PIP="pip install"
else
    execute sudo apt-get install python3 python3-dev -y
    if [[ ! -n $CIINSTALL ]]; then execute sudo apt-get install python3-pip -y; fi
    PIP="sudo pip3 install"
fi

execute sudo apt-get install libhdf5-dev

# Install opencv from pip only if it isn't already installed. Need to use `pkgutil` because opencv built from source does not appear in `pip list`
if [[ ! $(python3 -c "import pkgutil; print([p[1] for p in pkgutil.iter_modules()])" | grep cv2) ]]; then
    $PIP opencv-contrib-python --upgrade
fi

execute $PIP --upgrade numpy tabulate python-dateutil
execute $PIP --upgrade keras

if [[ -n $(command -v nvidia-smi) ]]; then

    # If Anaconda is present, use conda
    if [[ -n $(command -v conda) ]]; then
        execute conda install tensorflow-gpu -y
        execute conda install pytorch torchvision -c pytorch -y
    else
        # Else use pip
        execute $PIP --upgrade tensorflow
        execute $PIP --upgrade torch torchvision
    fi

else
    # If Anaconda is present, use conda
    if [[ -n $(command -v conda) ]]; then
        execute conda install tensorflow -y
        execute conda install pytorch torchvision cpuonly -c pytorch -y
    else
        execute $PIP --upgrade tensorflow
        execute $PIP --upgrade torch==1.4.0+cpu torchvision==0.5.0+cpu -f https://download.pytorch.org/whl/torch_stable.html
    fi
fi

echo ""
echo "This script has finished"
