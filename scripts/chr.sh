#!/bin/bash
set -e

export DEBDIR=/home/build/build/debootstrap

#Cleanup function
cleanup_chroot() {
    sudo umount -l "$DEBDIR/chroot/dev/pts" || true
    sudo umount -l "$DEBDIR/chroot/dev" || true
    sudo umount -l "$DEBDIR/chroot/sys" || true
    sudo umount -l "$DEBDIR/chroot/proc" || true
}
trap cleanup_chroot EXIT

#Mount for chroot
sudo mount --make-rprivate /
sudo mount -t proc /proc $DEBDIR/chroot/proc
sudo mount -t sysfs /sys $DEBDIR/chroot/sys
sudo mount --bind /dev "$DEBDIR/chroot/dev"
sudo mount --bind /dev/pts "$DEBDIR/chroot/dev/pts"

#Cleanup unnecessary files
sudo chroot "$DEBDIR/chroot" /bin/bash 
