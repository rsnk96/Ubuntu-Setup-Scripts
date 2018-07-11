#!/bin/bash

echo "This is intended to be a universal OpenCV installation script, which supports installing on Anaconda Python too"
echo "Additionally, FFmpeg will be compiled from source and OpenCV will be linked to this ffmpeg. Press Enter to Continue"
if [[ ! -n DIRECTINSTALL ]]; then
    read -r temp
fi

spatialPrint() {
    echo ""
    echo ""
    echo "$1"
    echo ""
    echo ""
}

if [[ -n $(echo $SHELL | grep "zsh") ]] ; then
  SHELLRC=~/.zshrc
elif [[ -n $(echo $SHELL | grep "bash") ]] ; then
  SHELLRC=~/.bashrc
elif [[ -n $(echo $SHELL | grep "ksh") ]] ; then
  SHELLRC=~/.kshrc
else
  echo "Unidentified shell $SHELL"
  exit # Ain't nothing I can do to help you buddy :P
fi

# Speed up the process
# Env Var NUMJOBS overrides automatic detection
if [[ -n $NUMJOBS ]]; then
    MJOBS=$NUMJOBS
elif [[ -f /proc/cpuinfo ]]; then
    MJOBS=$(grep -c processor /proc/cpuinfo)
elif [[ "$OSTYPE" == "darwin"* ]]; then
	MJOBS=$(sysctl -n machdep.cpu.thread_count)
else
    MJOBS=4
fi


sudo apt-get update
sudo apt-get install build-essential curl g++ cmake cmake-curses-gui git pkg-config -y
sudo apt-get install libopenblas-dev liblapack-dev libatlas-base-dev gfortran -y

if [[ ! -n $(echo "$PATH" | grep 'conda') ]] ; then
    sudo apt-get install python3 python3-dev python3-numpy python3-pip python3-scipy python3-matplotlib python-dev python-matplotlib python-numpy python-scipy python-pip python3-pip python-tk -y
else
    pip install numpy scipy matplotlib
fi
# Also instlaling dlib and moviepy as CV libraries
pip3 install msgpack cython dlib moviepy -y

if [[ ! -n $(cat $SHELLRC | grep '# ffmpeg-build-script') ]]; then
    spatialPrint "Building FFmpeg now"
    sudo apt-get -qq remove x264 libx264-dev ffmpeg -y
    sudo apt-get --purge remove libav-tools -y
    sudo mkdir /opt/ffmpeg-build-script && sudo chmod ugo+w /opt/ffmpeg-build-script
    (
        cd /opt/ffmpeg-build-script
        git clone https://github.com/markus-perl/ffmpeg-build-script.git .
        # Build libraries with --enable-shared so that they can be used by OpenCV
        sed -i 's/--disable-shared/--enable-shared/g' build-ffmpeg
        sed -i 's/--enable-shared\ \\/--enable-shared\ --cc="gcc -fPIC"\ \\/g' build-ffmpeg
        AUTOINSTALL=yes ./build-ffmpeg --build
        echo "Adding ffmpeg's libraries to LD_LIBRARY_PATH"
        {
            echo ""
            echo "# ffmpeg-build-script"
            echo "export LD_LIBRARY_PATH=\$LD_LIBRARY_PATH:$(pwd)/workspace/lib"
            echo "export PKG_CONFIG_PATH=\$(pkg-config --variable pc_path pkg-config)\${PKG_CONFIG_PATH:+:}$(pwd)/workspace/lib/pkgconfig"
            echo "export PKG_CONFIG_LIBDIR=\$PKG_CONFIG_LIBDIR:$(pwd)/workspace/lib/"

        } >> $SHELLRC
    )
    source $SHELLRC
fi

spatialPrint "GUI and openGL extensions"
sudo apt-get install qt5-default libqt5opengl5-dev libx11-dev libgtk-3-dev libgtk2.0-dev libgtkglext1-dev -y
sudo apt-get install libvtk6-dev libvtk6-qt-dev -y

spatialPrint "Image manipulation libraries"
sudo apt-get install libpng-dev libjpeg-dev libtiff5-dev libjasper-dev zlib1g-dev libwebp-dev libopenexr-dev libgdal-dev -y

spatialPrint "Video manipulation libraries"
sudo apt-get install libavformat-dev libavutil-dev libxine2-dev libswscale-dev libdc1394-22-dev libdc1394-utils -y

spatialPrint "Codecs"
sudo apt-get install libavcodec-dev yasm -y
sudo apt-get install libfaac-dev libmp3lame-dev -y
sudo apt-get install libopencore-amrnb-dev libopencore-amrwb-dev -y
sudo apt-get install libtheora-dev libvorbis-dev libxvidcore-dev -y
sudo apt-get install libv4l-dev v4l-utils -y

spatialPrint "Java"
sudo apt-get install -y ant default-jdk

spatialPrint "Parallelism library"
sudo apt-get install libeigen3-dev libtbb-dev -y

spatialPrint "Optional Dependencies"
sudo apt-get install libprotobuf-dev protobuf-compiler -y
sudo apt-get install libgoogle-glog-dev libgflags-dev -y
sudo apt-get install libgphoto2-dev libhdf5-dev doxygen sphinx-common texlive-latex-extra -y
sudo apt-get install libfreetype6-dev libharfbuzz-dev -y

spatialPrint "Finally download and install opencv"
git config --global http.postBuffer 1048576000
if [[ ! -d "opencv" ]]; then
	git clone https://github.com/Itseez/opencv
else
# Putting the git pull commands in paranthesis runs it in a subshell and avoids having to do cd ..
    (
        cd opencv || exit
        # Note: Any changes to the opencv directory, if you're a developer developing for opencv, will be lost with the below command
        git checkout master -f
        git pull origin master
    )
fi
if [[ ! -d "opencv_contrib" ]]; then
	git clone https://github.com/Itseez/opencv_contrib
else
    (
        cd opencv_contrib || exit
        git checkout master -f
        git pull origin master
    )
fi

cd opencv
# Check out the latest tag, which has to be the version you check out in contrib too
latest_tag="$(git tag | egrep -v '-' | tail -1)"
echo "Installing OpenCV Version: $latest_tag"
git checkout -f $latest_tag
cd ../opencv_contrib
git checkout -f $latest_tag
cd ../opencv
# rm -rf build
mkdir -p build
cd build

py2Ex=$(which python2)
py2In=$(python2 -c "from distutils.sysconfig import get_python_inc; print(get_python_inc())")
py2Pack=$(python2 -c "from distutils.sysconfig import get_python_lib; print(get_python_lib())")
py3Ex=$(which python3)
py3In=$(python3 -c "from distutils.sysconfig import get_python_inc; print(get_python_inc())")
py3Pack=$(python3 -c "from distutils.sysconfig import get_python_lib; print(get_python_lib())")

# This removes Anaconda from the path, if it's there.
# Don't worry, your OpenCV WILL STILL BE INSTALLED FOR ANACONDA PYTHON if it is the default python
# This is important as anaconda has a malformed MKL library
export TEMP=$PATH
if [[ -n $(echo "$PATH" | grep 'conda') ]] ; then
    echo "Your PATH variable will be changed for the installation. Anaconda will be removed from the PATH because it messes the linkings and dependencies"
    export PATH=$(echo "$PATH" | tr ':' '\n' | grep -v "conda[2-9]\?" | uniq | tr '\n' ':')
fi


# Build tiff on as opencv supports tiff4, which is older version, which ubuntu has dropped

cmake -D CMAKE_BUILD_TYPE=RELEASE \
 -D CMAKE_INSTALL_PREFIX=/usr/local \
 -D OPENCV_EXTRA_MODULES_PATH=../../opencv_contrib/modules \
 -D PYTHON2_EXECUTABLE="$py2Ex" \
 -D PYTHON2_INCLUDE_DIR="$py2In" \
 -D PYTHON2_PACKAGES_PATH="$py2Pack" \
 -D PYTHON3_EXECUTABLE="$py3Ex" \
 -D PYTHON3_INCLUDE_DIR="$py3In" \
 -D PYTHON3_PACKAGES_PATH="$py3Pack" \
 -D PYTHON_DEFAULT_EXECUTABLE="$py3Ex" \
 -D WITH_TBB=1 \
 -D WITH_IPP=1 \
 -D ENABLE_FAST_MATH=1 \
 -D BUILD_EXAMPLES=0 \
 -D BUILD_DOCS=0 \
 -D BUILD_PERF_TESTS=0 \
 -D BUILD_TESTS=0 \
 -D WITH_QT=1 \
 -D WITH_OPENGL=1 \
 -D WITH_VTK=0 \
 -D BUILD_opencv_java=0 \
 -D ENABLE_CXX11=1 \
 -D WITH_NVCUVID=0 \
 -D WITH_CUDA=0 \
 -D WITH_CUBLAS=0 \
 -D WITH_CUFFT=0 \
 -D CUDA_FAST_MATH=0 ..
#  -D BUILD_opencv_freetype=ON \

# De-comment the next line if you would like an interactive cmake menu to check if everything is alright and make some tweaks
# ccmake ..

spatialPrint "Making and installing"
make -j $MJOBS
sudo make install

spatialPrint "Finishing off installation"
sudo sh -c 'echo "/usr/local/lib" > /etc/ld.so.conf.d/opencv.conf'
sudo ldconfig

export PATH=$TEMP

echo "The installation just completed. If it shows an error in the end, kindly post an issue on the git repo"
