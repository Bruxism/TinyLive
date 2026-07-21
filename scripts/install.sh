#!/bin/bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"

apt-get update

# Kernel compile req
# Conveniently assorted/provided by:
#  https://www.linux.com/topic/desktop/how-compile-linux-kernel-0/ 
apt-get install -y git fakeroot build-essential ncurses-dev xz-utils libssl-dev bc flex libelf-dev bison

# Debian Live-Boot req
apt-get install -y debootstrap live-build squashfs-tools


# ZFS compile req
# Conveniently assorted/provided by:
# https://openzfs.github.io/openzfs-docs/Developer%20Resources/Building%20ZFS.html
apt-get install -y alien autoconf automake build-essential debhelper-compat dh-autoreconf dh-dkms dh-python dkms fakeroot gawk git libaio-dev libattr1-dev libblkid-dev libcurl4-openssl-dev libelf-dev libffi-dev libpam0g-dev libssl-dev libtirpc-dev libtool libudev-dev linux-headers-generic parallel po-debconf python3 python3-all-dev python3-cffi python3-dev python3-packaging python3-setuptools python3-sphinx uuid-dev zlib1g-dev


# Additional for included scripts
apt-get install -y rsync sudo tar


cd "${SCRIPT_DIR%/*}"
mkdir -p "./deps/PERCCLI_7.3208.0_Linux_A01"
wget https://dl.dell.com/FOLDER13074167M/1/PERCCLI_7.3208.0_Linux_A01.tar.gz -U 'anything'
tar xvzf ./PERCCLI_7.3208.0_Linux_A01.tar.gz --transform='s|.*/||' -C "./deps/PERCCLI_7.3208.0_Linux_A01/" "PERCCLI_7.3208.0_Linux_A01/Ubuntu/perccli_007.3208.0000.0000_all.deb"

rm PERCCLI_7.3208.0_Linux_A01.tar.gz
