# Ubuntu-Setup-Scripts
Every serious coder who has tried to mess around with their Ubuntu distro knows the pain of having to reinstall Ubuntu and set up their environment again

These are the scripts that I use to set my Ubuntu up as quick as possible. Feel free to fork it and create your own version

## Major Alterations
* Default python will be changed to Anaconda, with Python 3.5, and a conda environment called py27 running Python2.7 will be your alternate Python2 environment
* Default shell is changed to Oh My Zsh!, a zsh plugin, instead of bash. Why zsh? Because it simply has a much better autocomplete

## Aliases that are added
* `maxvol` : Will set your volume to 150%
* `download <webpage-name>`: Will download the webpage and any directory that is linked to it. Ex: `download http://www.iarcs.org.in/inoi/online-study-material/` will download the entire set of tutorials on competitive programming that span from that website
* `server` : Will set up a server for file sharing in your local network. Whatever is in your current directory will be visible on the ip. It will also print the possible set of IP addresses. To access from another computer, shoot up a browser and simply hit `ip_add:port`
* `weather` : Will show weather forecast for the next three days
* `gpom` : Alias for `git push origin master`. Will push your current directory
* `jn` : Starts a jupyter notebook in that directory

<br>
**NOTE**: All these aliases are installed in the first script `1 - settingUp-1.sh`. They are installed for zsh, and not bash, which should become your default shell when you run the second script

## Usage instructions
Run 
`chmod +x *.sh` to make all scripts executable
Then execute them in the terminal in the sequence of filenames.
<br><br>
**NOTE:**: Do not execute `opencvDirectInstall.sh` if you have executed files numbered from 1 to 7. That file is to be executed only if you want to set up OpenCV alone in your system

## Programs that are installed
* Terminator
* Tilda
* Ubuntu-Restricted-Extras
* Bleeding Edge Nvidia Driver
* Lyx
* VLC
* Chromium and Firefox
* Dropbox
* Gparted
* Boot-Repair
* Shutter
* Grub Customizer
* Ffmpeg
* Qt5
* CUDA
* OpenCV (Python + C++ with VTK, V4L, QT and Optionally CUDA)

## Python Packages
* Tensorflow
* Keras
* Autopep8

## Important points about the OpenCV Installation
* OpenCV will be linked to Anaconda Python by default, and will be built for that, not the Linux default python. If you would like to compile for that instead, remove all python related flags in the CMAKE command in 7, or even better, simply use `opencvDirectInstall.sh`
* If you would like to install with OpenCV for CUDA, change the flag in the file `7 - opencvInstall.sh` for `WITH_CUDA` to `ON`
