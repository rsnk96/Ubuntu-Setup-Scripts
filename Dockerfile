FROM nvidia/cuda:10.1-cudnn7-devel-ubuntu18.04

# To avoid tzdata configuration during Docker build - https://stackoverflow.com/a/44333806
RUN ln -fs /usr/share/zoneinfo/America/New_York /etc/localtime

WORKDIR /workspace

RUN DEBIAN_FRONTEND=noninteractive apt-get update && apt-get install -y \
    git \
    curl \
    wget \
    lsb-release \
    sudo \
    tzdata \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* && \
    dpkg-reconfigure -f noninteractive tzdata
