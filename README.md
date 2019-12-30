# Ubuntu-Setup-Scripts
Everyone who has tried to mess around with their Ubuntu distro knows the pain of having to reinstall Ubuntu and set it up to their liking again

These are the scripts that I use to set my Ubuntu up as quick as possible. Feel free to fork it and create your own version, and any contributions are more than welcome :)

## Build Status:

Every script is rock stable and runs against https://travis-ci.org to make sure everything works as expected. Note that `3-ML-Build.sh` is not shown here as it takes >2 hours to build TF+Pytorch on the Travis systems from source, and 2 hours is the system limit for free accounts on Travis. You can, however, still see the results of it running [here](https://travis-ci.org/rsnk96/Ubuntu-Setup-Scripts)


| 1-BasicSetUp and 2-GenSoftware | opencvDirectInstall |  ML-Basic            
|-------------------|-------------------|-------------------|
| [![Build1][5]][9] | [![Build2][6]][9] | [![Build3][8]][9] |

[5]: https://travis-matrix-badges.herokuapp.com/repos/rsnk96/Ubuntu-Setup-Scripts/branches/master/5
[6]: https://travis-matrix-badges.herokuapp.com/repos/rsnk96/Ubuntu-Setup-Scripts/branches/master/6
[8]: https://travis-matrix-badges.herokuapp.com/repos/rsnk96/Ubuntu-Setup-Scripts/branches/master/8
[9]: https://travis-ci.org/rsnk96/Ubuntu-Setup-Scripts

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


## Major Alterations
* Default python will be changed to Anaconda, with the latest Python 3. Anaconda Python will be installed in `/opt/anaconda3/` so that it is accessible by multiple users
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
* `aria`: For accelerated download of files using aria2c. Runs the following command: `aria2c --file-allocation=none -c -x 10 -s 10 -d aria2-downloads`

<br>

## Notes
* If you are using this script to set up a computer with many users,
    * You need to run these scripts using only one user, say `first_user`
    * We need to copy the configuration files to the new user, say `new_user`. From `first_user`'s account, run the following after entering the username of the `new_user` in the second line of this snippet
        ```bash
        cd ~
        export NEW_USER=<username_of_new_user>
        sudo cp /opt/.zsh/zim/ /home/$NEW_USER/.zim
        sudo cp /opt/.zsh/bash_aliases /home/$NEW_USER/.bash_aliases
        sudo cp /opt/.zsh/zim/templates/zimrc /home/$NEW_USER/.zimrc
        sudo cp /opt/.zsh/zim/templates/zlogin /home/$NEW_USER/.zlogin
        sudo cp ~/zshrc /home/$NEW_USER/.zshrc

        sudo cp ~/.xbindkeysrc /home/$NEW_USER
        sudo mkdir -p /home/$NEW_USER/.config/tilda
        sudo cp ~/.config/tilda/config_0 /home/$NEW_USER/.config/tilda/config_0
        sudo mkdir -p /home/$NEW_USER/.config/micro
        sudo cp ~/.config/micro/bindings.json /home/$NEW_USER/.config/micro/bindings.json
        sudo cp ~/.tmux.conf* /home/$NEW_USER/

        sudo chown -R $NEW_USER: /home/$NEW_USER/.zim /home/$NEW_USER/.bash_aliases /home/$NEW_USER/.zimrc /home/$NEW_USER/.zlogin /home/$NEW_USER/.zshrc /home/$NEW_USER/.xbindkeysrc /home/$NEW_USER/.config/tilda /home/$NEW_USER/.config/micro /home/$NEW_USER/.tmux.conf*
        ```
* Make sure that your system time and date is correct and synchronized before running the scripts, otherwise this will cause failure while trying to download the packages.
* During the `opencvDirectInstall` script, `yasm` package is downloaded while `ffmpeg` is being built. The download link for this package fails to work on certain networks, therefore check the download link as described below before running the script. If it doesn't work, then please switch to a different network. You can switch back to the original network after `yasm` has been downloaded if required

    * If you are on a browser, just open the following page - [http://www.tortall.net/](http://www.tortall.net/)  
      If a webpage opens up, then the download will work.

    * If you only have a terminal access, run this command : `curl -Is www.tortall.net | head -1`  
      Output with Status code `200 OK` means that the request has succeeded and the URL is reachable.

* OpenCV is built to link to an `ffmpeg` that is built from scratch using [Markus' script](https://github.com/markus-perl/ffmpeg-build-script). The `ffmpeg` that is built is stored in `/opt/ffmpeg-build-script`. While the binaries are copied to `/usr/local/bin`, the specific versions of `libavcodec` and other referenced libraries are still maintained at `/opt/ffmpeg-build-script/workspace/lib`
* If you have Anaconda Python, OpenCV will be linked to Anaconda Python by default, not the Linux default python. If you would like to compile for the Linux default Python, remove Anaconda from your path before running the `opencvDirectInstall.sh` script
* If you would like to install with OpenCV for CUDA, change the flags, `-D WITH_CUDA=0`, `-D WITH_CUBLAS=0`, `-D WITH_CUFFT`,`-D CUDA_FAST_MATH` in the file `opencvDirectInstall.sh` to `ON`
* Non-free & patented algorithms in OpenCV such as SIFT & SURF have been enabled, for disabling them, set the flag `-D OPENCV_ENABLE_NONFREE=ON` to off
* OpenCV will be built without support for Python 2. If you would like to build it with Python 2 support, then add back the lines removed in [this commit](https://github.com/rsnk96/Ubuntu-Setup-Scripts/commit/1e50b5fabff0026300879eb73ed36bb9b34ed6c9) 
* After OpenCV installation, if you get an error of the sort `illegal hardware instructions` when you try to run a python or c++ program, that is because your CPU is an older one (Pentium/Celeron/...). You can overcome this by adding the following to the end of the cmake (just before the `..`)

  ```bash
   -D ENABLE_SSE=OFF \
   -D ENABLE_SSE2=OFF \
   -D ENABLE_SSE3=OFF ..
  ```

  If you still want to be able to receive the benefits of CPU optimization to whatever extent you can, then hit `cat /proc/cpuinfo` and see what `sse`s are available under flags
* Building Tensorflow from source has different configuration options, info on which can be seen on [Tensorflow's Build from Source page](https://www.tensorflow.org/install/source). Note that by default, 2.x version of Tensorflow will be built, to build 1.x version, add `--config=v1` to the bazel build command
* If you want to install a specific version of OpenCV or Tensorflow, i.e different from the latest release, make the following changes. The scripts should work with different versions but they haven't been tested
  * OpenCV   
  Comment out the [line fetching the latest release tag](https://github.com/rsnk96/Ubuntu-Setup-Scripts/blob/master/opencvDirectInstall.sh#L170) in the `opencvDirectInstall` script.  
  Add the line below the above commented out one specifying the OpenCV version which you want like this: `latest_tag="3.4.5"`  
  Alternatively, you could just replace `$latest_tag` with the tag of the version in the following 2 lines: `git checkout -f $latest_tag`  
  Make sure that the tag of the OpenCV version you want is correct. The tags of all the releases can be checked here - [https://github.com/opencv/opencv/tags](https://github.com/opencv/opencv/tags) 

  * Tensorflow  
  Similar to above, locate the [line fetching the latest release tag](https://github.com/rsnk96/Ubuntu-Setup-Scripts/blob/master/3-ML-Build.sh#L120) of Tensorflow and replace with the tag of the version required.  
  The tags of all the Tensorflow releases can be checked here - [https://github.com/tensorflow/tensorflow/tags](https://github.com/tensorflow/tensorflow/tags)
* These scripts are written and tested on the following configurations - 
  * Ubuntu 16.04 & 18.04
  * 32-bit and 64-bit Intel Processors
  * `ML-Build.sh` - NVIDIA GPUs including but not limited to GeForce GTX 1080, 1070, 940MX, 850M, and Titan X
  
  Although it should work on other configurations out of the box, I have not tested them


## Tmux shortcuts conf:
In the description of shortcuts below, if two keys are connected with a `+`, then the second key is to be pressed while keeping the first key pressed. If two keys are connected with a ` `(space), then the previous key/keys are to be released before the next key is pressed. If two keys are separated by a `/`, then it means you can choose any of the specified keys
* `Ctrl+b c`: Create a new window within the tmux session
* `Ctrl+b \`: Split existing window into two panes vertically
* `Ctrl+b -`: Split existing window into two panes horizontally
* `Alt+Right/Left/Up/Down`: Switch between the panes of the same window
* `Ctrl+b Shift+Left/Right`: Switch between the windows of the tmux session
* `Ctrl+b [`: Go into tmux copy mode (enable selection of text from the tmux buffer quickly using just your keyboard). Go to your preferred start point, press `Space` to start the selection of the copy section. Press `Enter` at the end point


## Alternatives
* A [docker image](https://hub.docker.com/r/varun19299/cvi-iitm/) for this set-up (last updated Jan 30th, 2017)
* A Ubuntu customization dedicated to [robotics](https://github.com/ahundt/robotics_setup)


## To Dos 
- [x] CI
- [ ] configuring default wifi settings
