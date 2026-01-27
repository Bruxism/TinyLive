#!/bin/bash
set -e

DEBDIR=~/build/debootstrap

#Remove old chroot

sudo rm -rf "$DEBDIR/chroot"

#Boostrap Debian rootfs
sudo debootstrap --arch=amd64 --variant=minbase \
	--include=bash,coreutils,apt,curl,ca-certificates,fio,live-boot,openssh-server,vim,tmux,ifupdown,isc-dhcp-client,iproute2,sysvinit-core,pciutils,udev,linux-image-amd64,initramfs-tools \
	stable $DEBDIR/chroot http://deb.debian.org/debian 

#Copy kernel and initramfs for pxe boot
sudo cp $DEBDIR/chroot/vmlinuz /srv/tftp/vmlinuz
sudo cp $DEBDIR/chroot/initrd.img /srv/tftp/initramfs.img

#Cleanup unnecessary files
sudo chroot "$DEBDIR/chroot" /bin/bash -c "
apt-get clean
rm -rf /var/cache/apt/* /usr/share/doc/* /usr/share/man/* /usr/share/locale/* /usr/share/info/*
apt-get purge -y linux-image-amd64 initramfs-tools
apt-get autoremove -y
echo 'root:root' | chpasswd
/usr/bin/busybox --install
"

#Add authorized keys
sudo chroot "$DEBDIR/chroot" /bin/bash -c "
umask 077
mkdir -p /root/.ssh
cat <<'EOF' > /root/.ssh/authorized_keys
ssh-ed25519 SECRET
ssh-ed25519 SECRET
"

#Compress the rootfs into a squashfs image
sudo mksquashfs "$DEBDIR/chroot" "/srv/tftp/rootfs.squashfs" -comp xz -Xbcj x86 -noappend


#Show final size
ls -lh "/srv/tftp/rootfs.squashfs"
                                 
