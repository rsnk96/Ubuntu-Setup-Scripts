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

# Executes first command passed &
# echo's it to the file passed as second argument 
run_and_echo () {
    eval $1
    echo "$1" >> $2
}

# For utilities such as lspci
execute sudo apt-get install pciutils

if [[ (-n $(lspci | grep -i nvidia)) && (! ( -d "/usr/local/cuda" ) ) ]]; then
    echo "Installing the latest cuda"
    cuda_instr_block=$(wget -q -O - 'https://developer.nvidia.com/cuda-downloads' | grep wget | head -n 1)
    cuda_download_command=$(echo ${cuda_instr_block} | sed 's#\(.*\)"cudaBash">.*#\1#' | sed 's#.*"cudaBash">\([^<]*\).*#\1#' )
    cuda_install_command=$(echo ${cuda_instr_block} | sed 's#.*"cudaBash">\([^<]*\).*#\1#' | sed 's#&nbsp;# ./extras/#' ) # Get everything after the last `"cudaBash"` block till the next `<` character, replace the &nbsp; with a download path
    if [[ $(command -v aria2c) ]]; then
        cuda_download_command=$(echo ${cuda_download_command} | sed 's#wget#aria2c --file-allocation=none -c -x 10 -s 10 --dir extras#' )
    else
        cuda_download_command=$(${cuda_download_command} -P ./extras)
    fi

    $cuda_download_command
    execute $cuda_install_command --silent --toolkit --run-nvidia-xconfig
fi


if [[ (! -n $(echo $PATH | grep 'cuda')) && ( -d "/usr/local/cuda" ) ]]; then
    echo "Adding Cuda location to PATH"
    run_and_echo "# Cuda" $SHELLRC
    run_and_echo "export PATH=/usr/local/cuda/bin:\$PATH" $SHELLRC
    run_and_echo "export LD_LIBRARY_PATH=/usr/local/cuda/lib64:/usr/local/cuda/extras/CUPTI/lib64:\$LD_LIBRARY_PATH" $SHELLRC
    run_and_echo "export CUDA_HOME=/usr/local/cuda" $SHELLRC
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

execute sudo apt-get install libhdf5-dev exiftool ffmpeg -y

# Install opencv from pip only if it isn't already installed. Need to use `pkgutil` because opencv built from source does not appear in `pip list`
if [[ ! $(python3 -c "import pkgutil; print([p[1] for p in pkgutil.iter_modules()])" | grep cv2) ]]; then
    $PIP opencv-contrib-python --upgrade
fi

execute $PIP --upgrade numpy pandas tabulate python-dateutil
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
