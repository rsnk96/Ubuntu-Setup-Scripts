#!/bin/bash

#REMEMBER TO MAKE THE sudo cp cudnn... to sudo cp -r cudn...
#NOTE: For symbolic links, that dipshit has reversed the order...put it as below
# sudo ln -s /usr/local/cudnn/lib64/libcudnn.so /usr/local/cuda/lib64/libcudnn.so
# sudo ln -s /usr/local/cudnn/lib64/libcudnn.so.5 /usr/local/cuda/lib64/libcudnn.so.5
# sudo ln -s /usr/local/cudnn/lib64/libcudnn.so.5.1.3 /usr/local/cuda/lib64/libcudnn.so.5.1.3
# sudo ln -s /usr/local/cudnn/lib64/libcudnn_static.a /usr/local/cuda/lib64/libcudnn_static.a
#ALSO NOTE: CUDNN VERSION MIGHT DEFER...HE USES CUDNN 4, that's why the 4 everywhere
# https://devtalk.nvidia.com/default/topic/936429/-solved-tensorflow-with-gpu-in-anaconda-env-ubuntu-16-04-cuda-7-5-cudnn-/

chmod +x cuda_8.0.44_linux.run
./cuda_8.0.44_linux.run
echo "export PATH=/usr/local/cuda-8.0/bin:\$PATH" >> ~/.zshrc
echo "export LD_LIBRARY_PATH=/usr/local/cuda-8.0/lib64:\$LD_LIBRARY_PATH" >> ~/.zshrc
source ~/.zshrc
