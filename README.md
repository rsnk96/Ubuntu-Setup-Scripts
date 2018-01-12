# Ubuntu-Setup-Scripts
Everyone who has tried to mess around with their Ubuntu distro knows the pain of having to reinstall Ubuntu and set it up to their liking again

These are the scripts that I use to set my Ubuntu up as quick as possible.

Feel free to fork it and create your own version

## Usage instructions
Run 
`chmod u+x *.sh` to make all scripts executable
Then execute them in the terminal in the sequence of filenames.
<br><br>

## Major Alterations
* Default python will be changed to Anaconda, with the latest Python 3, and a conda environment called py27 running Python2.7 will be your alternate Python2 environment. Another Conda environment called py35 with Python 3.5 will also be set up
* Default shell is changed to Zim, a zsh plugin, instead of bash. Why zsh? Because it simply has a much better autocomplete. And why zim? Because it's much faster than Oh My Zsh and Prezto

## Aliases that are added
* `maxvol` : Will set your volume to 150%
* `download <webpage-name>`: Download the webpage and all sub-directories linked to it
* `server` : Sets up a server for file sharing in your local network. Whatever is in your current directory will be visible on the ip. It will also print the possible set of IP addresses. To access from another computer, shoot up a browser and simply hit `ip_add:port`
* `weather` : Will show weather forecast for the next three days
* `gpom` : Alias for `git push origin master`. Will push your current directory
* `jn` : Starts a jupyter notebook in that directory
* `ydl "URL"`: Downloads the song at `URL` at 12kbps, 44100Hz in m4a format with the title and song name automatically set in the metadata

<br>

## Programs that are installed
`Tmux`, `Tilda`, `Ubuntu-Restricted-Extras`, `Lyx`, `VLC`, `Chromium and Firefox`, `Dropbox`, `Gparted`, `Boot-Repair`, `Shutter`,`Grub Customizer`, `Ffmpeg`, `Qt5`, `CUDA`, `OpenCV` (Python + C++ with VTK, V4L, QT and Optionally CUDA), `gimp`, `meld`(To be used with `git mergetool`), `axel`

## Python Packages
* Machine Learning Libraries: Tensorflow, Caffe and Pytorch built from source, optimized for user hardware. Theano, Keras, Gym installed from pip
* Autopep8
* scdl - a soundcloud downloader
* org-e - An app to sort and declutter folders (like ~/Downloads/)
* youtube-dl: A youtube downloader

## Important points about the OpenCV Installation
* OpenCV will be linked to Anaconda Python by default, and will be built for that, not the Linux default python. If you would like to compile for the Linux default Python, remove Anaconda from your path before running the `opencvDirectInstall.sh` script
* If you would like to install with OpenCV for CUDA, change the flag in the file `7 - opencvInstall.sh` for `WITH_CUDA` to `ON`
* After installation, if you get an error of the sort `illegal hardware instructions` when you try to run a python or c++ program, that is because your CPU is an older one (Pentium/Celeron/...). You can overcome this by adding the following to the end of the cmake (just before the `..`)

  ```bash
   -DENABLE_SSE=OFF \
   -DENABLE_SSE2=OFF \
   -DENABLE_SSE3=OFF ..
  ```

  If you still want to be able to receive the benefits of CPU optimization to whatever extent you can, then hit `cat /proc/cpuinfo` and see what `sse`s are available under flags

## To Dos 
- [] Fail Proof checks
