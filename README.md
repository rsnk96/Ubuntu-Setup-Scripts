# Ubuntu-Setup-Scripts
Everyone who has tried to mess around with their Ubuntu distro knows the pain of having to reinstall Ubuntu and set it up to their liking again

These are the scripts that I use to set my Ubuntu up as quick as possible. Feel free to fork it and create your own version, and any contributions are more than welcome :)

## Build Status:

Every script is stable and validates with [CI](https://github.com/features/actions) to make sure everything works as expected. The scripts are tested on Ubuntu 24.04 (Noble) and 26.04 (Oracular) LTS releases.

You can see the build results in the [Actions tab](https://github.com/rsnk96/Ubuntu-Setup-Scripts/actions) of this repository.

## Usage instructions
First download/clone this repository

Then execute them in the terminal in the sequence of filenames using `./1-BasicSetUp.sh` and `./2-GenSoftware.sh`.
* `1-BasicSetUp.sh` - Sets up terminal configuration (Zsh + Zim), download accelerator (aria2), Anaconda Python, shell aliases, Docker, Nvidia drivers (if detected), Neovim with LazyVim, and other essential tools. **Note:** After running this script, you should reboot your PC if you have an Nvidia GPU so that the display driver loads properly.
* `2-GenSoftware.sh` - Installs general purpose software including VS Code, Cursor IDE, browsers (Brave, Chrome), system monitoring tools, screenshot tools, media players, and other utilities.


## Major Alterations
* Default python will be changed to Anaconda (Miniconda), with the latest Python 3. Anaconda Python will be installed in `/opt/anaconda3/` so that it is accessible by multiple users
* Default shell is changed to Zsh with Zim framework, instead of bash. Why zsh? Because it simply has a much better autocomplete. And why zim? Because it's much faster than Oh My Zsh and Prezto
* Docker and Docker Compose will be installed, along with Nvidia Container Toolkit if an Nvidia GPU is detected
* Neovim will be installed with LazyVim configuration for a modern editor experience
* Zellij terminal multiplexer will be installed as an alternative to tmux
* Display manager will be configured to use X11 (Xorg) instead of Wayland for better compatibility

## Aliases that are added
* `maxvol` : Will set your volume to 150%
* `download <webpage-name>`: Download the webpage and all sub-directories linked to it
* `file_server` : Sets up a server for file sharing in your local network. Whatever is in your current directory will be visible on the ip. It will also print the possible set of IP addresses. To access from another computer, shoot up a browser and simply hit `ip_add:port`
* `gpom` : Alias for `git push origin master`. Will push your current directory
* `glog` : Shows a rich, annotated git log graph with commits from your current branch, main, and their remote counterparts. Commits show date, relative time, decorations (branches/tags), subject, and author, making it easy to visualize your branch's history in relation to main and remotes.
* `jn` : Starts a jupyter notebook in that directory
* `jl` : Starts a jupyter lab in that directory
* `update`: Runs `sudo apt-get update && sudo apt-get dist-upgrade && sudo apt-get autoremove -y`
* `aria`: For accelerated download of files using aria2c. Runs the following command: `aria2c --file-allocation=none -c -x 10 -s 10 -d aria2-downloads`

<br>

## Notes
* **Adding a new OS user:** If setting up multiple users on the OS, try to use the script `./add_new_user.sh` in this repo. It will set the correct settings for them to also benefit from zsh, conda, etc.
* Make sure that your system time and date is correct and synchronized before running the scripts, otherwise this will cause failure while trying to download the packages.
* These scripts are written and tested on the following configurations:
  * Ubuntu 24.04 (Noble) and 26.04 (Oracular) LTS releases
  * 64-bit Intel/AMD Processors
  * NVIDIA GPUs (drivers will be automatically installed if detected)

  Although it should work on other configurations out of the box, they have not been tested

* Docker Images
  * An example `Dockerfile` is present in the repository for reference. Customize it as required for specific requirements.

## Tmux configuration shortctus:

The tmux configuration used is inspired from [https://github.com/gpakosz/.tmux](https://github.com/gpakosz/.tmux)

In the description of shortcuts below, meaning of connectors:
* `+`: The second key is to be pressed while keeping the first key pressed
* ` `(space): The previous key/keys are to be released before the next key is pressed
* `/`: You can choose any of the specified keys

The shortcuts within `tsux`/`tmux` that you can use are:
* Pane control:
  * `Ctrl+b \`: Split existing window into two panes vertically
  * `Ctrl+b -`: Split existing window into two panes horizontally
  * `Alt+Right/Left/Up/Down`: Switch between the panes of the same window
* Window control:
  * `Ctrl+b c`: Create a new window within the tmux session
  * `Ctrl+b Shift+Left/Right`: Switch between the windows of the tmux session
* Copy-paste:
  * When you highlight any text with the mouse, it's automatically copied
  * `Ctrl+b [`: Go into tmux copy-mode (enable selection of text from the tmux buffer quickly using just your keyboard). Go to your preferred start point, press `Space` to start the selection of the copy section. Press `Enter` at the end point


## Alternatives
* A Ubuntu customization dedicated to [robotics](https://github.com/ahundt/robotics_setup)


## Maintainers
* [@rsnk96](https://github.com/rsnk96)
* [@rajat2004](https://github.com/rajat2004)