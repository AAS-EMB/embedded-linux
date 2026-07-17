FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \
    build-essential gcc g++ make cmake \
    libncurses-dev libssl-dev \
    wget curl git unzip bc \
    cpio rsync file \
    gcc-arm-linux-gnueabihf \
    g++-arm-linux-gnueabihf \
    libgtest-dev \
    clang-format \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /build