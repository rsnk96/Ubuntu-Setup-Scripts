# Ubuntu-Setup-Scripts
Everyone who has tried to mess around with their Ubuntu distro knows the pain of having to reinstall Ubuntu and set it up to their liking again

These are the scripts that I use to set my Ubuntu up as quick as possible. Feel free to fork it and create your own version, and any contributions are more than welcome :)

## Build Status:

Every script is rock stable and runs against [Travis CI](https://travis-ci.org) to make sure everything works as expected. Note that `Build-ML.sh` is not shown here as it takes >2 hours to build TF+Pytorch on the Travis systems from source, and 2 hours is the system limit for free accounts on Travis. You can, however, still see the results of it running [here](https://travis-ci.org/rsnk96/Ubuntu-Setup-Scripts)


| 1-BasicSetUp and 2-GenSoftware | 3-ML-Basic | Build-OpenCV  | Build-OpenCV in a conda env |
|-------------------|-------------------|-------------------|--------------------|
| [![Build1][5]][11] | [![Build2][7]][11] | [![Build3][6]][11] | [![Build4][8]][11] |

[5]: https://travis-matrix-badges.herokuapp.com/repos/rsnk96/Ubuntu-Setup-Scripts/branches/master/5
[6]: https://travis-matrix-badges.herokuapp.com/repos/rsnk96/Ubuntu-Setup-Scripts/branches/master/6
[7]: https://travis-matrix-badges.herokuapp.com/repos/rsnk96/Ubuntu-Setup-Scripts/branches/master/7
[8]: https://travis-matrix-badges.herokuapp.com/repos/rsnk96/Ubuntu-Setup-Scripts/branches/master/8
[11]: https://travis-ci.org/rsnk96/Ubuntu-Setup-Scripts

## Usage instructions
First download/clone this repository

Then execute them in the terminal in the sequence of filenames using `./1-BasicSetUp.sh`, `/2-GenSoftware.sh`, and so on.
* `1-BasicSetUp.sh` - Sets up terminal configuration, a download accelerator, anaconda python, and shell aliases.
* Now is a good time to restart your PC if you have an Nvidia GPU so that the display driver loads
* `2-GenSoftware.sh` - Sets up tools for programming(editor, etc), and other general purpose software I use
* `3-ML-Basic.sh` - Installs from pip/conda commonly used DL libraries, and also installs the latest cuda if no cuda is detected

Additional scripts to built libraries from source:
* `Build-ML.sh` - Compiles commonly used ML/DL libraries from source, so that it is optimized to run on your computer
* `Build-OpenCV.sh` - Compiles the latest tag of OpenCV+Contrib from source on your machine with focus on optimization of execution of OpenCV code.


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
    * You need to run these scripts using **only one** user, say `first_user`. But make sure you have **logged in at least once** into the new user so that the home directory of the other user is instantiated.
    * We need to copy the configuration files to the new user, say `new_user`. From `first_user`'s account, run the following after entering the username of the `new_user` in the second line of this snippet
        ```bash
        cd ~
        export NEW_USER=<username_of_new_user>
        sudo cp /opt/.zsh/bash_aliases /home/$NEW_USER/.bash_aliases
        sudo cp -r ~/.zim/ /home/$NEW_USER/.zim
        sudo cp ~/.zimrc /home/$NEW_USER/.zimrc
        sudo cp ~/.zlogin /home/$NEW_USER/.zlogin
        sudo cp ~/.zshrc /home/$NEW_USER/.zshrc
        sudo cp ~/.zshenv /home/$NEW_USER/.zshenv

        sudo cp ~/.xbindkeysrc /home/$NEW_USER
        sudo mkdir -p /home/$NEW_USER/.config/tilda
        sudo cp ~/.config/tilda/config_0 /home/$NEW_USER/.config/tilda/config_0
        sudo mkdir -p /home/$NEW_USER/.config/micro
        sudo cp ~/.config/micro/bindings.json /home/$NEW_USER/.config/micro/bindings.json
        sudo cp ~/.tmux.conf* /home/$NEW_USER/

        sudo chown -R $NEW_USER: /home/$NEW_USER/.zim /home/$NEW_USER/.bash_aliases /home/$NEW_USER/.zimrc /home/$NEW_USER/.zlogin /home/$NEW_USER/.zshrc /home/$NEW_USER/.xbindkeysrc /home/$NEW_USER/.config/tilda /home/$NEW_USER/.config/micro /home/$NEW_USER/.tmux.conf*
        ```
* Make sure that your system time and date is correct and synchronized before running the scripts, otherwise this will cause failure while trying to download the packages.
* `Build-OpenCV.sh`
    * OpenCV is built to link to an `ffmpeg` that is built from scratch using [Markus' script](https://github.com/markus-perl/ffmpeg-build-script). The `ffmpeg` that is built is stored in `/opt/ffmpeg-build-script`. While the binaries are copied to `/usr/local/bin`, the specific versions of `libavcodec` and other referenced libraries are still maintained at `/opt/ffmpeg-build-script/workspace/lib`
    * If you have Anaconda Python, OpenCV will be linked to Anaconda Python by default, not the Linux default python. If you would like to compile for the Linux default Python, remove Anaconda from your path before running the `Build-OpenCV.sh` script
    * If CUDA is already installed when building OpenCV from source, it'll be detected and the corresponding flags (`-D WITH_CUDA`, `-D WITH_CUBLAS`, `-D WITH_CUFFT`,`-D CUDA_FAST_MATH`) are enabled.
    * Similarly, if CuDNN is also installed, then support for that will be enabled. By default, if CuDNN is installed, then OpenCV's DNN module with support for Nvidia GPUS (only in OpenCV >= 4.2.0) will also be built. Note that this requires GPUs with Compute Capability (i.e. architecture) 5.3 or higher. Default behaviour is build for all supported architectures, but you can speed up the compilation by specifying the architecture in the `CUDA_ARCH_BIN` flag as described below.
    * Building OpenCV with CUDA enabled can take a very long time, since it has to build the same code for all GPU architectures. If you don't need to compile for all architectures, you can specify the architecture using `CUDA_ARCH_BIN` such as 30 for Kepler, 61 for Pascal, etc. Information about your GPU can be found at [Nvidia's page](https://developer.nvidia.com/cuda-gpus)
    * Non-free & patented algorithms in OpenCV such as SIFT & SURF have been enabled, for disabling them, set the flag `-D OPENCV_ENABLE_NONFREE=ON` to off
    * OpenCV will be built without support for Python 2. If you would like to build it with Python 2 support, then add back the lines removed in [this commit](https://github.com/rsnk96/Ubuntu-Setup-Scripts/commit/1e50b5fabff0026300879eb73ed36bb9b34ed6c9)
    * After OpenCV installation, if you get an error of the sort `illegal hardware instructions` when you try to run a python or c++ program, that is because your CPU is an older one (Pentium/Celeron/...). You can overcome this by adding the following to the end of the cmake (just before the `..`)

      ```bash
      -D ENABLE_SSE=OFF \
      -D ENABLE_SSE2=OFF \
      -D ENABLE_SSE3=OFF ..
      ```

      If you still want to be able to receive the benefits of CPU optimization to whatever extent you can, then hit `cat /proc/cpuinfo` and see what `sse`s are available under flags
    * If you run into compilation problems or something else during OpenCV installation, make sure to remove the entire `build` folder inside `opencv` directory before rebuilding, otherwise strange errors can pop up.
* `Build-ML.sh`
    * Building Tensorflow from source has different configuration options, info on which can be seen on [Tensorflow's Build from Source page](https://www.tensorflow.org/install/source). Note that by default, 2.x version of Tensorflow will be built, to build 1.x version, add `--config=v1` to the bazel build command
* If you want to install a specific version of OpenCV or Tensorflow, i.e different from the latest release, make the following changes. The scripts should work with different versions but they haven't been tested
  * OpenCV
  Comment out the [line fetching the latest release tag](https://github.com/rsnk96/Ubuntu-Setup-Scripts/blob/master/Build-OpenCV.sh#L170) in the `Build-OpenCV` script.
  Add the line below the above commented out one specifying the OpenCV version which you want like this: `latest_tag="3.4.5"`
  Alternatively, you could just replace `$latest_tag` with the tag of the version in the following 2 lines: `git checkout -f $latest_tag`
  Make sure that the tag of the OpenCV version you want is correct. The tags of all the releases can be checked here - [https://github.com/opencv/opencv/tags](https://github.com/opencv/opencv/tags)

  * Tensorflow
  Similar to above, locate the [line fetching the latest release tag](https://github.com/rsnk96/Ubuntu-Setup-Scripts/blob/master/Build-ML.sh#L120) of Tensorflow and replace with the tag of the version required.
  The tags of all the Tensorflow releases can be checked here - [https://github.com/tensorflow/tensorflow/tags](https://github.com/tensorflow/tensorflow/tags)
* These scripts are written and tested on the following configurations -
  * Ubuntu 16.04 & 18.04
  * 32-bit and 64-bit Intel Processors
  * `ML-Build.sh` - NVIDIA GPUs including but not limited to GeForce GTX 1080, 1070, 940MX, 850M, and Titan X

  Although it should work on other configurations out of the box, I have not tested them

* Docker Images
  * An example `Dockerfile` is present in the repository, which builds OpenCV with CUDA support enabled. Customize it as required for specific requirements such as different CUDA versions, CPU-only images, etc.
  * Some images built using these scripts can be found at [Docker Hub](https://hub.docker.com/r/rajat2004/ubuntu-setup-scripts)

## Tmux shortcuts conf:
In the description of shortcuts below, if two keys are connected with a `+`, then the second key is to be pressed while keeping the first key pressed. If two keys are connected with a ` `(space), then the previous key/keys are to be released before the next key is pressed. If two keys are separated by a `/`, then it means you can choose any of the specified keys
* `Ctrl+b c`: Create a new window within the tmux session
* `Ctrl+b \`: Split existing window into two panes vertically
* `Ctrl+b -`: Split existing window into two panes horizontally
* `Alt+Right/Left/Up/Down`: Switch between the panes of the same window
* `Ctrl+b Shift+Left/Right`: Switch between the windows of the tmux session
* `Ctrl+b [`: Go into tmux copy mode (enable selection of text from the tmux buffer quickly using just your keyboard). Go to your preferred start point, press `Space` to start the selection of the copy section. Press `Enter` at the end point


## Alternatives
* A Ubuntu customization dedicated to [robotics](https://github.com/ahundt/robotics_setup)
