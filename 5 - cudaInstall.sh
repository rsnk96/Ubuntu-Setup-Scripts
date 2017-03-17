#!/usr/bin/zsh

echo "NOTE: This File is to be run *************ONLY AFTER YOU HAVE INSTALLED CUDA*******************"
read -r -p " Hit [Enter] if you have, [Ctrl+C] if you have not!" temp

{
    echo "export PATH=/usr/local/cuda-8.0/bin:\$PATH"
    echo "export LD_LIBRARY_PATH=/usr/local/cuda/lib64:/usr/local/cuda/extras/CUPTI/lib64:\$LD_LIBRARY_PATH"
    echo "export CUDA_HOME=/usr/local/cuda"
} >> ~/.zshrc
source ~/.zshrc

source activate py35
pip install tensorflow-gpu keras


# If above doesn't work, then do this
# export TF_BINARY_URL=https://storage.googleapis.com/tensorflow/linux/gpu/tensorflow_gpu-0.12.1-cp35-cp35m-linux_x86_64.whl

#If installing on non anaconda
# pip3 install --upgrade $TF_BINARY_URL

#If installing on anaconda
# pip install --ignore-installed --upgrade $TF_BINARY_URL
