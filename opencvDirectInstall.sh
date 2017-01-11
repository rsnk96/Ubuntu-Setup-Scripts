echo "This opencv installation script was created by rsnk, CVG, IIT Madras, to work on the vanilla python that comes with every Ubuntu"
echo "Most of it is in reference to http://www.askaswiss.com/2016/01/how-to-install-opencv-3-1-python-ubuntu-14-04.html"
echo "Usually, if this script doesn't work, it's because the library versions may have been updated (of libvtk, libtiff, libjpeg and other dependencies)"

sudo apt-get update
sudo apt-get upgrade -y

sudo apt-get install build-essential -y
sudo apt-get install cmake git libgtk-3-dev pkg-config libavcodec-dev libavformat-dev libswscale-dev -y

sudo apt-get install python3-numpy python3-pip python3-scipy python3-matplotlib python-dev python-matplotlib python-numpy python-scipy -y

sudo apt-get install python-pip python-tk libeigen3-dev yasm libfaac-dev libopencore-amrnb-dev libopencore-amrwb-dev libtheora-dev libvorbis-dev libxvidcore-dev libx264-dev sphinx-common texlive-latex-extra libv4l-dev libdc1394-22-dev libavcodec-dev libavformat-dev libswscale-dev default-jdk ant -y


echo "GUI and openGL extensions"
sudo apt-get install qt5-default libqt5opengl5-dev libvtk6-dev libvtk6-qt-dev libgtk-3-dev libgtkglext1 libgtkglext1-dev -y

echo "image manipulation libraries"
sudo apt-get install libpng3 pngtools libpng12-dev libpng12-0 libpng++-dev -y
sudo apt-get install libjpeg-dev libjpeg9 libjpeg9-dbg libjpeg-progs libtiff5-dev libtiff5 libtiffxx5 libtiff-tools libjasper-dev libjasper1  libjasper-runtime zlib1g zlib1g-dbg zlib1g-dev -y

echo "video manipulation libraries"
sudo apt-get install libavformat-dev libavutil-ffmpeg54 libavutil-dev libxine2-dev libxine2 libswscale-dev libswscale-ffmpeg3 libdc1394-22 libdc1394-22-dev libdc1394-utils -y

echo "codecs"
sudo apt-get install libavcodec-dev -y
sudo apt-get install libfaac-dev libmp3lame-dev -y
sudo apt-get install libopencore-amrnb-dev libopencore-amrwb-dev -y
sudo apt-get install libtheora-dev libvorbis-dev libxvidcore-dev -y
sudo apt-get install ffmpeg x264 libx264-dev -y
sudo apt-get install libv4l-0 libv4l v4l-utils -y

echo "multiproccessing library"
sudo apt-get install libtbb-dev -y

echo "finally download and install opencv"
mkdir opencv
cd opencv
git clone https://github.com/Itseez/opencv
git clone https://github.com/Itseez/opencv_contrib
cd opencv
mkdir build
cd build
cmake -DCMAKE_BUILD_TYPE=RELEASE \
 -DCMAKE_INSTALL_PREFIX=/usr/local \
 -DINSTALL_C_EXAMPLES=ON \
 -DBUILD_opencv_freetype=OFF \
 -DWITH_CUDA=OFF \
 -DINSTALL_PYTHON_EXAMPLES=ON \
 -DBUILD_EXAMPLES=ON \
 -DBUILD_opencv_cvv=OFF \
 -DOPENCV_EXTRA_MODULES_PATH=../../opencv_contrib/modules \
 -DBUILD_NEW_PYTHON_SUPPORT=ON \
 -DWITH_TBB=ON \
 -DWITH_V4L=ON \
 -DWITH_QT=ON \
 -DWITH_OPENGL=ON \
 -DWITH_VTK=ON ..

echo "making and installing"
make -j8
sudo make install

echo "finishing off installation"
sudo /bin/bash -c 'echo "/usr/local/lib" > /etc/ld.so.conf.d/opencv.conf'
sudo ldconfig

echo "Congratulations! You have just installed OpenCV. And that's all, folks! :P"
