#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
export DEBDIR="${SCRIPT_DIR%/*}"

#Cleanup function
cleanup_chroot() {
    umount -l "${DEBDIR}/chroot/dev/pts" || true
    umount -l "${DEBDIR}/chroot/dev" || true
    umount -l "${DEBDIR}/chroot/sys" || true
    umount -l "${DEBDIR}/chroot/proc" || true
}
trap cleanup_chroot EXIT

#Mount for chroot
mount --make-rprivate /
mount -t proc /proc "${DEBDIR}"/chroot/proc
mount -t sysfs /sys "${DEBDIR}"/chroot/sys
mount --bind /dev "${DEBDIR}"/chroot/dev
mount --bind /dev/pts "${DEBDIR}"/chroot/dev/pts

#Cleanup unnecessary files
chroot "${DEBDIR}"/chroot /bin/bash 
