# Rise Lab Ubuntu-Setup-Scripts
These are the scripts used to set up the cluster at RISE Lab, IIT Madras

## Usage instructions

### Setting up the Cluster:
Assuming the `/tools/` directory is accessbile by all slaves and the master,
1. Clone this branch into that directory
2. Move the `config.sh` and `setmeup.sh` files to `/tools/`
2. Run `chmod u+x *.sh` to make all scripts executable. Then execute them in the terminal in the sequence of filenames.

### For a new user in an existing cluster
1. Just run
    ```bash
    source /tools/setmeup.sh
    ```
    to create a conda environment for your user in your local directory, so that you can install packages the way you like it without interfering with the master configuration
<br><br>

## Major Alterations
* Default python will be changed to Anaconda, with the latest Python 3, and a conda environment called py27 running Python2.7 will be your alternate Python2 environment. Another Conda environment called py35 with Python 3.5 will also be set up

<br>

## Python Packages (If the scripts are run directly on a node)
* Tensorflow, Caffe and Pytorch built from source, optimized for user hardware.
* Theano, Keras, Gym installed from pip
* Autopep8

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
