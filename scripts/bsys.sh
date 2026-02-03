#!/bin/bash
set -e

export DEBDIR=/home/build/build/debootstrap
KVER=6.18.7
VMLINUX=/home/build/build/debootstrap/bzImage
kernelfiles=/home/build/build/debootstrap/kernelfiles

#Remove old chroot
sudo rm -rf "$DEBDIR/chroot"

#Boostrap Debian rootfs
sudo debootstrap --arch=amd64 --variant=minbase \
	--include=bash,coreutils,apt,curl,ca-certificates,live-boot,fio,openssh-server,vim,tmux,tree,dbus,dbus-daemon,iproute2,systemd-sysv,udev,pciutils,udhcpc,xz-utils,efibootmgr,initramfs-tools \
	stable $DEBDIR/chroot http://deb.debian.org/debian 

#Copy already built kernel into chroot
sudo mkdir -p "$DEBDIR/chroot/boot"
sudo cp -r $kernelfiles/kernel/. $DEBDIR/chroot/boot/
sudo cp "$kernelfiles/kernel/vmlinuz-6.18.7" /srv/tftp/vmlinuz

#Copy modules
sudo cp -R $kernelfiles/modules/lib/. $DEBDIR/chroot/lib/

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

#Configure initramfs-tools to build without modules
sudo chroot "$DEBDIR/chroot" /bin/bash -c "
cat <<'EOF' > /etc/initramfs-tools/conf.d/settings.conf
MODULES=list
BUSYBOX=y
COMPRESS=xz
EOF
"

#Generate initramfs
sudo chroot "$DEBDIR/chroot" /bin/bash -c "
update-initramfs -c -k $KVER       # create fresh initramfs for the kernel
"

#Copy initramfs for pxe boot
sudo cp $DEBDIR/chroot/boot/initrd.img* /srv/tftp/initramfs.img

#Cleanup unnecessary files
sudo chroot "$DEBDIR/chroot" /bin/bash -c "
rm -rf /var/cache/apt/* /usr/share/doc/* /usr/share/man/* /usr/share/locale/* /usr/share/info/*
apt-get purge -y initramfs-tools
apt-get autoremove -y
apt-get clean
echo 'root:root' | chpasswd
/usr/bin/busybox --install
"
sudo rm -rf $DEBDIR/chroot/boot

#Enable Networking
sudo chroot "$DEBDIR/chroot" /bin/bash -c "
cat <<'EOF' > /etc/systemd/network/20-dhcp.network
[Match]
Name=*

[Network]
DHCP=yes
EOF
"

#Copy ZFS module and /etc files
sudo tar kxvJf $DEBDIR/zfs.tar.xz -C $DEBDIR/chroot/

#Activate modules and zfs systemd service files
sudo chroot "$DEBDIR/chroot" /bin/bash -c "
depmod -a $KVER
"

#Add authorized keys
sudo mkdir -p -m 0700 $DEBDIR/chroot/root/.ssh
sudo cp "$DEBDIR/authorized_keys" "$DEBDIR/chroot/root/.ssh/"
sudo chmod 0600 $DEBDIR/chroot/root/.ssh/authorized_keys

#Remove resolv.conf
sudo rm "$DEBDIR/chroot/etc/resolv.conf"

#Unmount after chroot
sudo umount "$DEBDIR/chroot/dev/pts"
sudo umount "$DEBDIR/chroot/dev"
sudo umount "$DEBDIR/chroot/sys"
sudo umount "$DEBDIR/chroot/proc"

#Clear trap
trap - EXIT

#Compress the rootfs into a squashfs image
sudo mksquashfs "$DEBDIR/chroot" "/srv/tftp/rootfs.squashfs" -comp xz -Xbcj x86 -noappend

#Show final size
ls -lh "/srv/tftp/rootfs.squashfs"
                                 
