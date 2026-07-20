#!/bin/bash
set -e

#Requires:
#apt install alien autoconf automake build-essential debhelper-compat dh-autoreconf dh-dkms dh-python dkms fakeroot gawk git libaio-dev libattr1-dev libblkid-dev libcurl4-openssl-dev libelf-dev libffi-dev libpam0g-dev libssl-dev libtirpc-dev libtool libudev-dev linux-headers-generic parallel po-debconf python3 python3-all-dev python3-cffi python3-dev python3-packaging python3-setuptools python3-sphinx uuid-dev zlib1g-dev

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
DEPS_DIR="${SCRIPT_DIR%/*}"/deps

KERNEL_SRC_DIR="${DEPS_DIR}"/linux
ZFS_SRC_DIR="${DEPS_DIR}"/zfs
INSTALL_DIR="${DEPS_DIR}"/compiled/zfs

if [[ ! -d "${KERNEL_SRC_DIR}" ]]; then
	echo "Linux Kernel Directory not detected. ZFS compilation requires it. Exiting..."
	exit 1
fi

if [[ ! -d "${ZFS_SRC_DIR}/.git" ]]; then
        echo "ZFS repo hasn't been cloned. Cloning now..."
        git clone --single-branch --branch "master" --depth 1 "https://github.com/openzfs/zfs.git" "${ZFS_SRC_DIR}"
fi

cd "${ZFS_SRC_DIR}"

git fetch origin master
git reset --hard origin/master
git clean -fdx

sh autogen.sh
./configure --with-linux="${KERNEL_SRC_DIR}" --with-linux-obj="${KERNEL_SRC_DIR}" --enable-shared --enable-static=no

make -j $(nproc)

mkdir -p "${INSTALL_DIR}"
rm -rf "${INSTALL_DIR}"/*

make DESTDIR="${INSTALL_DIR}" install -j $(nproc)

rm -rf "${INSTALL_DIR}"/usr/local/share/zfs/zfs-tests
strip --strip-unneeded "${INSTALL_DIR}"/usr/local/lib/libzpool.so.7.0.0
