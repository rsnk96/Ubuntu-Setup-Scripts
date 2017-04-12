#!/bin/bash

sudo apt-get install libboost-all-dev -y

sudo apt-get install clang-format -y

sudo apt-get install lyx -y

# Install code editor of your choice
echo
echo
read -p "Download and Install VS Code / Atom / Sublime. Press q to skip this. Default is VS Code [v/a/s/q]: " tempvar
tempvar=${tempvar:-v}

if [ "$tempvar" = "v" ]; then
    curl https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > microsoft.gpg
    sudo mv microsoft.gpg /etc/apt/trusted.gpg.d/microsoft.gpg
    sudo sh -c 'echo "deb [arch=amd64] http://packages.microsoft.com/repos/vscode stable main" > /etc/apt/sources.list.d/vscode.list'
    sudo apt-get update
    sudo apt-get install code # or code-insiders
    echo
    echo
    echo
    echo "If you are using VS Code, note that you have to remove the line which modifies \$TMPDIR in your .zprofile."
elif [ "$tempvar" = "a" ]; then
    sudo add-apt-repository ppa:webupd8team/atom
    sudo apt update; sudo apt install atom
elif [ "$tempvar" = "s" ]; then
    sudo add-apt-repository ppa:webupd8team/sublime-text-3
    sudo apt-get update
    sudo apt-get install sublime-text-installer
elif [ "$tempvar" = "q" ];then
    echo "Skipping this step"
fi

#Recommended libraries for Nvidia CUDA
sudo apt-get install libglu1-mesa libxi-dev libxmu-dev libglu1-mesa-dev libx11-dev -y
