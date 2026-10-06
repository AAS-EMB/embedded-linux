FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive
ENV PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        bc \
        binutils \
        build-essential \
        bzip2 \
        ca-certificates \
        cpio \
        diffutils \
        file \
        findutils \
        gawk \
        git \
        libncurses-dev \
        libssl-dev \
        make \
        patch \
        perl \
        python3 \
        python3-setuptools \
        rsync \
        tar \
        unzip \
        wget \
        xz-utils \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /workspace

CMD ["bash", "scripts/build.sh", "rpi0_2w", "base"]
