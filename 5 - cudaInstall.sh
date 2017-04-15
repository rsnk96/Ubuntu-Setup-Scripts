#!/bin/bash

echo "NOTE: This File is to be run *************ONLY AFTER YOU HAVE INSTALLED CUDA*******************"
read -r -p " Hit [Enter] if you have, [Ctrl+C] if you have not!" temp

{
    echo "export PATH=/usr/local/cuda-8.0/bin:\$PATH"
    echo "export LD_LIBRARY_PATH=/usr/local/cuda/lib64:/usr/local/cuda/extras/CUPTI/lib64:\$LD_LIBRARY_PATH"
    echo "export CUDA_HOME=/usr/local/cuda"
} >> ~/.zshrc

source activate py35
pip install keras

read -p "Would you like to install tensorflow from source or PyPi (pip)?. Press q to skip this. Default is from PyPi [s/p/q]: " tempvar
tempvar=${tempvar:-p}

if [ "$tempvar" = "p" ]; then
    pip install tensorflow-gpu
elif [ "$tempvar" = "s" ]; then
    pip uninstall tensorflow-gpu tensorflow

    sudo apt-get install libcupti-dev
    git clone https://github.com/tensorflow/tensorflow
    cd tensorflow

    echo "deb [arch=amd64] http://storage.googleapis.com/bazel-apt stable jdk1.8" | sudo tee /etc/apt/sources.list.d/bazel.list
    curl https://bazel.build/bazel-release.pub.gpg | sudo apt-key add -

    sudo apt-get update && sudo apt-get install bazel
    sudo apt-get upgrade bazel

    read -p "Starting Configuration process. Be alert for the queries it will throw at you. Press [Enter]" temp

    ./configure

    bazel build --config=opt --config=cuda //tensorflow/tools/pip_package:build_pip_package
    bazel-bin/tensorflow/tools/pip_package/build_pip_package /tmp/tensorflow_pkg

    pip install /tmp/tensorflow_pkg/*.whl
elif [ "$tempvar" = "q" ];then
    echo "Skipping this step"
fi

echo "This script has finished"
