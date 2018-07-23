# Ubuntu-Setup-Scripts
Everyone who has tried to mess around with their Ubuntu distro knows the pain of having to reinstall Ubuntu and set it up to their liking again

These are the scripts that I use to set my Ubuntu up as quick as possible. Feel free to fork it and create your own version, and any contributions are more than welcome :)

## Build Status:

Every script is rock stable and runs against https://travis-ci.org to make sure everything works as expected. Note that `3-ML-Build.sh` is not shown here as it takes >2 hours to build TF+Pytorch on the Travis systems from source, and 2 hours is the system limit for free accounts on Travis. You can, however, still see the results of it running [here](https://travis-ci.org/rsnk96/Ubuntu-Setup-Scripts)


| 1-BasicSetUp and 2-GenSoftware | opencvDirectInstall |  ML-Basic            
|-------------------|-------------------|-------------------|
| [![Build1][1]][5] | [![Build2][2]][5] | [![Build4][4]][5] |

[1]: https://travis-matrix-badges.herokuapp.com/repos/rsnk96/Ubuntu-Setup-Scripts/branches/master/1
[2]: https://travis-matrix-badges.herokuapp.com/repos/rsnk96/Ubuntu-Setup-Scripts/branches/master/2
[4]: https://travis-matrix-badges.herokuapp.com/repos/rsnk96/Ubuntu-Setup-Scripts/branches/master/4
[5]: https://travis-ci.org/rsnk96/Ubuntu-Setup-Scripts

## Usage instructions
First download/clone this repository

Run 
`chmod u+x *.sh` to make all scripts executable
Then execute them in the terminal in the sequence of filenames.
* `1-BasicSetUp.sh` - Sets up terminal configuration, a download accelerator, anaconda python, and shell aliases.
* `2-GenSoftware.sh` - Sets up tools for programming(editor, etc), and other general purpose software I use
* `3-ML-Build.sh` - Compiles commonly used ML/DL libraries from source, so that it is optimized to run on your computer
* `opencvDirectInstall.sh` - Compiles the latest tag of OpenCV+Contrib from source on your machine with focus on optimization of execution of OpenCV code.
* `ML-Basic.sh` - Installs from pip commonly used DL libraries
<br><br>

## Major Alterations
* Default python will be changed to Anaconda, with the latest Python 3, and conda environments called py27 and py36 running Python2.7 and Python3.6 respectively will be your alternate Python2 and Python 3.6 environments. Anaconda Python will be installed in `/opt/anaconda3/` so that it is accessible by multiple users
* Default shell is changed to Zim, a zsh plugin, instead of bash. Why zsh? Because it simply has a much better autocomplete. And why zim? Because it's much faster than Oh My Zsh and Prezto

## Aliases that are added
* `maxvol` : Will set your volume to 150%
* `download <webpage-name>`: Download the webpage and all sub-directories linked to it
* `server` : Sets up a server for file sharing in your local network. Whatever is in your current directory will be visible on the ip. It will also print the possible set of IP addresses. To access from another computer, shoot up a browser and simply hit `ip_add:port`
* `gpom` : Alias for `git push origin master`. Will push your current directory
* `jn` : Starts a jupyter notebook in that directory
* `jl` : Starts a jupyter lab in that directory
* `ydl "URL"`: Downloads the song at `URL` at 128kbps, 44.1kHz in m4a format with the title and song name automatically set in the metadata
* `update`: Runs `sudo apt-get update && sudo apt-get dist-upgrade && sudo apt-get autoremove -y`
* `tsux`: Create a tmux session with `-u` (so that the icons(battery, etc) are properly displayed at the bottom), and with a window with `htop`, `nvidia-smi -l 1` and `lm-sensors` automatically activated.
    - Reason for not making this the default tmux: You cannot attach tmux sessions if you alias the `tmux` command itself

<br>

## Programs that are installed
`Tmux`, `Tilda`, `Ubuntu-Restricted-Extras`, `Lyx`, `VLC`, `Chromium and Firefox`, `Dropbox`, `Gparted`, `Boot-Repair`, `Shutter`,`Grub Customizer`, `Ffmpeg`, `Qt5`, `gimp`, `meld`(To be used with `git mergetool`), `axel`, `tor` & `i2p`, `redshift`, `lm-sensors`, `ffmpeg`(might've missed some)

## Python Packages
* Machine Learning Libraries: Tensorflow built from source, optimized for user hardware. Theano, Keras, OpenAI Gym and Pytorch installed from pip
* OpenCV: Compiled from source, multithreaded and optimized to use your hardware
* Autopep8
* scdl - a soundcloud downloader
* org-e - An app to sort and declutter folders (like ~/Downloads/)
* youtube-dl: A youtube downloader

## Notes
* If you are using this script to set up a computer with many users,
    * You need to run these scripts using only one user, say `first_user`
    * We need to copy the configuration files to the new user, say `new_user`. From `first_user`'s account, run the following
        ```bash
        cp ~/.zshrc /home/<new_user>
        cp ~/.bash_aliases /home/<new_user>
        cp ~/.xbindkeysrc /home/<new_user>
        mkdir -p /home/<new_user>/.config/tilda
        cp ~/.config/tilda/config_0 /home/<new_user>/.config/tilda/config_0

        ln -s /opt/.zim/templates/zimrc /home/<new_user>/.zimrc
        ln -s /opt/.zim/templates/zlogin /home/<new_user>/.zlogin
        ln -s /opt/.zim/templates/zshrc /home/<new_user>/.zshrc
        
        sudo chown <new_user>: /home/<new_user>/*
        ```
    * Symoblically link the zim files for each new user with the following commands (from the `1-BasicSetUp.sh` script)
* OpenCV is built to link to an `ffmpeg` that is built from scratch using [Markus' script](https://github.com/markus-perl/ffmpeg-build-script). The `ffmpeg` that is built is stored in `/opt/ffmpeg-build-script`. While the binaries are copied to `/usr/local/bin`, the specific versions of `libavcodec` and other referenced libraries are still maintained at `/opt/ffmpeg-build-script/workspace/lib`
* If you have Anaconda Python, OpenCV will be linked to Anaconda Python by default, not the Linux default python. If you would like to compile for the Linux default Python, remove Anaconda from your path before running the `opencvDirectInstall.sh` script
* If you would like to install with OpenCV for CUDA, change the flags `-D WITH_NVCUVID=0`, `-D WITH_CUDA=0`, `-D WITH_CUBLAS=0`, `-D WITH_CUFFT`,`-D CUDA_FAST_MATH` in the file `opencvDirectInstall.sh` to `ON`
* After OpenCV installation, if you get an error of the sort `illegal hardware instructions` when you try to run a python or c++ program, that is because your CPU is an older one (Pentium/Celeron/...). You can overcome this by adding the following to the end of the cmake (just before the `..`)

  ```bash
   -D ENABLE_SSE=OFF \
   -D ENABLE_SSE2=OFF \
   -D ENABLE_SSE3=OFF ..
  ```

  If you still want to be able to receive the benefits of CPU optimization to whatever extent you can, then hit `cat /proc/cpuinfo` and see what `sse`s are available under flags
* These scripts are written and tested on the following configurations - 
  * Ubuntu 14.04 & 16.04
  * 32-bit and 64-bit Intel Processors
  * `ML-Build.sh` - NVIDIA GPUs including but not limited to GeForce GTX 1080, 1070, 940MX, 850M, and Titan X
  
  Although it should work on other configurations out of the box, I have not tested them


## Alternatives
* A [docker image](https://hub.docker.com/r/varun19299/cvi-iitm/) for this set-up (last updated Jan 30th, 2017)
* A Ubuntu customization dedicated to [robotics](https://github.com/ahundt/robotics_setup)

## To Dos 
- [x] CI
- [ ] configuring default wifi settings
