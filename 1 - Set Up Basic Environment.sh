#!/bin/bash

set -e

sudo apt-get update -y

sudo apt-get install tmux -y
sudo apt-get install git -y

continuum_website=https://repo.continuum.io/archive/
latest_anaconda_steup=$(wget -q -O - $continuum_website index.html | grep "Anaconda3-" | grep "Linux" | grep "86_64" | head -n 1 | cut -d \" -f 2)
wget -O ./anacondaInstallScript.sh "$continuum_website$latest_anaconda_steup"
sudo mkdir /tools/anaconda3 && sudo chmod ugo+w /tools/anaconda3
bash ./anacondaInstallScript.sh -f -b -p /tools/anaconda3

echo "Adding anaconda to path variables"
{
    echo ""
    echo "export OLDPATH=\$PATH"
    echo "export PATH=/tools/anaconda3/bin:\$PATH"

} >> /tools/config.sh


echo "The script has finished. It is recommeneded to reboot the system now"
