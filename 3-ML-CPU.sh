#!/bin/bash

source activate py36

pip install --upgrade pip

if test -n $(echo $SHELL | grep "zsh") ; then

  SHELLRC=~/.zshrc

elif test -n $(echo $SHELL | grep "bash") ; then

  SHELLRC=~/.bashrc

elif test -n $(echo $SHELL | grep "ksh") ; then

  SHELLRC=~/.kshrc

else

  exit # Ain't nothing I can do to help you buddy :P

fi


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

    pip install tensorflow

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

    if locate intel-mkl > /dev/null; then

        bazel build --config=opt --config=mkl --config=cuda //tensorflow/tools/pip_package:build_pip_package

    else

        bazel build --config=opt --config=cuda //tensorflow/tools/pip_package:build_pip_package

    fi

    cd ../

    

    # cp -r bazel-bin/tensorflow/tools/pip_package/build_pip_package.runfiles/main/* bazel-bin/tensorflow/tools/pip_package/build_pip_package.runfiles/

    bazel-bin/tensorflow/tools/pip_package/build_pip_package /tmp/tensorflow_pkg

    pip install /tmp/tensorflow_pkg/*.whl --force-reinstall

    cd ../


elif test "$tempvar" = "q";then

    echo "Skipping this step"

fi



echo ""

echo "This script has finished"
