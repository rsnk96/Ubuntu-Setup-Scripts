
echo "This opencv installation script was created by rsnk, CVG, IIT Madras."
echo "Usually, if this script doesn't work, it's because the library versions may have been updated (of libvtk, libtiff, libjpeg and other dependencies) or OpenCV might have added new modules to contrib which require you to install additional dependencies"
echo
echo "NOTE: Enable Cannonical Partners in your Software Sources. If you have, press [Enter]. Otherwise, [Ctrl+C]"
read temp

sudo apt-get update
sudo apt-get upgrade -y

sudo apt-get install build-essential -y
sudo apt-get install cmake git pkg-config libavcodec-dev libavformat-dev libswscale-dev -y
sudo apt-get install libatlas-base-dev gfortran -y

# sudo apt-get install python3 python3-dev python3-numpy python3-pip python3-scipy python3-matplotlib python-dev python-matplotlib python-numpy python-scipy python-pip python-tk -y

sudo apt-get install libeigen3-dev yasm libfaac-dev libopencore-amrnb-dev libopencore-amrwb-dev libtheora-dev libvorbis-dev libxvidcore-dev libx264-dev sphinx-common texlive-latex-extra libv4l-dev libdc1394-22-dev libavcodec-dev libavformat-dev libswscale-dev default-jdk ant -y


echo "GUI and openGL extensions"
# First line disabled as OpenCV doesn't support newer versions of VTK +QT till now'
sudo apt-get install qt5-default libqt5opengl5-dev libvtk6-dev libvtk6-qt-dev libvtk6.2 libvtk6.2-qt libgtk2.0-dev libgtkglext1 libgtkglext1-dev -y
#sudo apt-get install qt4-default libqt4-dev libqt4-opengl-dev libvtk5-qt4-dev libgtk2.0-dev libgtkglext1 libgtkglext1-dev -y

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
git config --global http.postBuffer 1048576000
if [ ! -d "opencv" ]; then
	git clone https://github.com/Itseez/opencv
fi
if [ ! -d "opencv_contrib" ]; then
	git clone https://github.com/Itseez/opencv_contrib
fi

sudo apt-get install cmake-curses-gui -y
