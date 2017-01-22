# Ubuntu-Install-Scripts
These are the personal scripts I use to set my Ubuntu up as quick as possible.

Feel free to fork them them and modify them if you like them

## Usage instructions
Run 
`chmod +x *.sh` to make all scripts executable
Then execute them in the terminal in the sequence of filenames.
<br><br>
**NOTE:**: Do not execute `opencvDirectInstall.sh` if you have executed files numbered from 1 to 7. That file is to be executed only if you want to set up OpenCV alone in your system

## Significant Changes that will be done to your system
* Default python will be changed to Anaconda, with Python 3.5, and a conda environment called py27 running Python2.7 will be your alternate Python2 environment
* Default shell is changed to Oh My Zsh!, a zsh plugin, instead of bash

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
