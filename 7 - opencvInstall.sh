echo  "Press [Enter] to start cmake"
echo ". Remember dude, both anaconda environemtns (2.7 and 3.5) have to be removed from the path environment before proceeding. If not, take a hike."
read temp

cd opencv
mkdir build
cd build

#Build tiff on as opencv supports tiff4, which is older version, which ubuntu has dropped
# This may work as CMAKE parameter
# -DCMAKE_INSTALL_PREFIX=$(python3 -c "import sys; print(sys.prefix)") \

cmake -DCMAKE_BUILD_TYPE=RELEASE \
 -DCMAKE_INSTALL_PREFIX=/usr/local \
 -DBUILD_opencv_cvv=OFF \
 -DOPENCV_EXTRA_MODULES_PATH=../../opencv_contrib/modules \
 -DBUILD_NEW_PYTHON_SUPPORT=ON \
 -DPYTHON2_EXECUTABLE=$(which python2) \
 -DPYTHON2_INCLUDE_DIR=$(python2 -c "from distutils.sysconfig import get_python_inc; print(get_python_inc())") \
 -DPYTHON2_PACKAGES_PATH=$(python2 -c "from distutils.sysconfig import get_python_lib; print(get_python_lib())") \
 -DPYTHON3_EXECUTABLE=$(which python3) \
 -DPYTHON3_INCLUDE_DIR=$(python3 -c "from distutils.sysconfig import get_python_inc; print(get_python_inc())") \
 -DPYTHON3_PACKAGES_PATH=$(python3 -c "from distutils.sysconfig import get_python_lib; print(get_python_lib())") \
 -DWITH_TBB=ON \
 -DWITH_V4L=ON \
 -DWITH_QT=ON \
 -DWITH_OPENGL=ON \
 -DWITH_VTK=ON \
 -DWITH_IPP=OFF \
 -DWITH_CUDA=OFF \
 -DBUILD_TESTS=OFF \
 -DBUILD_TIFF=ON \
 -DBUILD_opencv_java=OFF \
 -DENABLE_AVX=ON \
 -DBUILD_opencv_freetype=OFF ..

echo "Press [Enter] to configure cmake"
read temp

ccmake ..

echo "making and installing"
make -j8
sudo make install

echo "finishing off installation"
sudo /bin/bash -c 'echo "/usr/local/lib" > /etc/ld.so.conf.d/opencv.conf'
sudo ldconfig

echo "Congratulations! You have just installed OpenCV. And that's all, folks! :P"
