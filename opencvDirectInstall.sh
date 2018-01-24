#!/bin/bash

echo "This is intended to be a universal OpenCV installation script, which supports installing on Anaconda Python too"
echo "Usually, if this script doesn't work, it's because the library versions may have been updated (of libvtk, libtiff, libjpeg and other dependencies) or OpenCV might have added new modules to contrib which require you to install additional dependencies. In such a scenario, kindly create in issue in the github repository."
echo
echo "NOTE: Enable Cannonical Partners in your Software Sources for ffmpeg installation. If you have, press [Enter]. Otherwise, [Ctrl+C], enable it, and re-run this script"
read -r temp

#sudo apt-get update
sudo apt-get upgrade -y

sudo apt-get install build-essential -y
sudo apt-get install cmake git pkg-config libavcodec-dev libavformat-dev libswscale-dev -y
sudo apt-get install libatlas-base-dev gfortran -y
sudo apt-get install cmake-curses-gui -y

if ! echo "$PATH" | grep -q 'conda' ; then
    sudo apt-get install python3 python3-dev python3-numpy python3-pip python3-scipy python3-matplotlib python-dev python-matplotlib python-numpy python-scipy python-pip python-tk -y
else
    pip install numpy scipy matplotlib
fi

sudo apt-get install libeigen3-dev yasm libfaac-dev libopencore-amrnb-dev libopencore-amrwb-dev libtheora-dev libvorbis-dev libxvidcore-dev libx264-dev sphinx-common texlive-latex-extra libv4l-dev libdc1394-22-dev libavcodec-dev libavformat-dev libswscale-dev ant -y

spatialPrint() {
    echo ""
    echo ""
    echo "$1"
    echo ""
    echo ""
}

spatialPrint "GUI and openGL extensions"
sudo apt-get install qt5-default libqt5opengl5-dev libgtk2.0-dev libgtkglext1 libgtkglext1-dev -y
sudo apt-get install libvtk6-dev libvtk6-qt-dev libvtk6.2 libvtk6.2-qt -y

spatialPrint "Image manipulation libraries"
sudo apt-get install libpng3 pngtools libpng-dev libpng16-dev libpng16-16 libpng++-dev -y
sudo apt-get install libjpeg-dev libjpeg9 libjpeg9-dbg libjpeg-progs libtiff5-dev libtiff5 libtiffxx5 libtiff-tools libjasper-dev libjasper1  libjasper-runtime zlib1g zlib1g-dbg zlib1g-dev -y

spatialPrint "Video manipulation libraries"
sudo apt-get install libavformat-dev libavutil-ffmpeg54 libavutil-dev libxine2-dev libxine2 libswscale-dev libswscale-ffmpeg3 libdc1394-22 libdc1394-22-dev libdc1394-utils -y

spatialPrint "Codecs"
sudo apt-get install libavcodec-dev -y
sudo apt-get install libfaac-dev libmp3lame-dev -y
sudo apt-get install libopencore-amrnb-dev libopencore-amrwb-dev -y
sudo apt-get install libtheora-dev libvorbis-dev libxvidcore-dev -y
sudo apt-get install ffmpeg x264 libx264-dev -y
sudo apt-get install libv4l-0 libv4l v4l-utils -y

spatialPrint "Java"
sudo apt-get install -y ant default-jdk

spatialPrint "Multiproccessing library"
sudo apt-get install libtbb-dev -y

spatialPrint "Documentation"
sudo apt-get install -y doxygen

spatialPrint "Finally download and install opencv"
git config --global http.postBuffer 1048576000


mkdir /opt/opencvs -p
cd /opt/opencvs

if [ ! -d "opencv" ]; then
	git clone https://github.com/Itseez/opencv
else
# Putting the git pull commands in paranthesis runs it in a subshell and avoids having to do cd ..
    (
        cd opencv || exit
        git pull
    )
fi
cd ./opencv
git checkout tags/3.3.0 
cd .. 
if [ ! -d "opencv_contrib" ]; then
	git clone https://github.com/Itseez/opencv_contrib
else
    (
        cd opencv_contrib || exit
        git pull
    )
fi
cd opencv_contrib

git checkout tags/3.3.0 
cd .. 
cd opencv
mkdir -p build
cd build

py2Ex=$(which python2)
py2In=$(python2 -c "from distutils.sysconfig import get_python_inc; print(get_python_inc())")
py2Pack=$(python2 -c "from distutils.sysconfig import get_python_lib; print(get_python_lib())")
py3Ex=$(which python3)
py3In=$(python3 -c "from distutils.sysconfig import get_python_inc; print(get_python_inc())")
py3Pack=$(python3 -c "from distutils.sysconfig import get_python_lib; print(get_python_lib())")

# This removes both Anaconda from the path, if it's there.
# Don't worry, your OpenCV WILL STILL BE INSTALLED FOR ANACONDA PYTHON if it is the default python
# This is important as anaconda has a malformed MKL library, and has different versions for a lot of other libraries too, and you'd like to use the full version instead
# Do note: If you are using anaconda, I would recommend creating a python 2.x environment in that, and adding that too to the env variable before running this script
export TEMP=$PATH
if echo "$PATH" | grep -q 'conda' ; then
    echo "Your PATH variable will be changed for the installation. Anaconda will be removed from the PATH because it messes the linkings and dependencies"
    export PATH=$(echo "$PATH" | tr ':' '\n' | grep -v "conda[2-9]\?" | uniq | tr '\n' ':')
fi


# Build tiff on as opencv supports tiff4, which is older version, which ubuntu has dropped
#  If you get an error, try disabling freetype by adding the following line in between the cmake command
#  -DBUILD_opencv_freetype=OFF \
cmake -DCMAKE_BUILD_TYPE=RELEASE \
 -DCMAKE_INSTALL_PREFIX=/usr/local \
 -DBUILD_opencv_cvv=OFF \
 -DOPENCV_EXTRA_MODULES_PATH=../../opencv_contrib/modules \
 -DBUILD_NEW_PYTHON_SUPPORT=ON \
 -DPYTHON2_EXECUTABLE="$py2Ex" \
 -DPYTHON2_INCLUDE_DIR="$py2In" \
 -DPYTHON2_PACKAGES_PATH="$py2Pack" \
 -DPYTHON3_EXECUTABLE="$py3Ex" \
 -DPYTHON3_INCLUDE_DIR="$py3In" \
 -DPYTHON3_PACKAGES_PATH="$py3Pack" \
 -DWITH_TBB=ON \
 -DWITH_V4L=ON \
 -DWITH_QT=ON \
 -DWITH_OPENGL=ON \
 -DWITH_VTK=ON \
 -DWITH_IPP=OFF \
 -DWITH_CUDA=OFF \
 -DBUILD_TESTS=OFF \
 -DBUILD_TIFF=ON \
 -DBUILD_opencv_java=ON \
 -DENABLE_AVX=ON ..

read -p -r "Press [Enter] to continue" temp

# De-comment the next line if you would like an interactive cmake menu to check if everything is alright and make some tweaks
# ccmake ..

spatialPrint "Making and installing"
make -j8
sudo make install

spatialPrint "Finishing off installation"
sudo /bin/bash -c 'echo "/usr/local/lib" > /etc/ld.so.conf.d/opencv.conf'
sudo ldconfig

export PATH=$TEMP

echo "The installation just completed. If it shows an error in the end, kindly post an issue on the git repo"

