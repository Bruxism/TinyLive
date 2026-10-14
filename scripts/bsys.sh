#!/bin/bash
# `set -e` = stop on any failure
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
export DEBDIR="${SCRIPT_DIR%/*}"
CUSTOM_DIR="${DEBDIR}/customizations"

DEPS_DIR="${DEBDIR}/deps"
COMPILED_DIR="${DEPS_DIR}/compiled"
KERNELFILES="${COMPILED_DIR}/kernel"
MODULEFILES="${COMPILED_DIR}/modules"

kernel="$(ls ${KERNELFILES}/vmlinuz-*)"
kver="${kernel#*-}"

#Make sure `/srv/tftp/` exists as it'll be the output
mkdir -p /srv/tftp

#Remove old chroot
rm -rf "${DEBDIR}"/chroot

#Create chroot
mkdir -p "${DEBDIR}"/chroot

#Boostrap Debian rootfs
debootstrap --arch=amd64 --variant=minbase \
	--include=bash,coreutils,apt,less,gawk,curl,ca-certificates,live-boot,fio,openssh-server,btop,htop,iotop,hdparm,e2fsprogs,parted,sdparm,sysstat,sg3-utils,nvme-cli,smartmontools,fastfetch,vim,tmux,tree,dbus,dbus-daemon,libpam-systemd,iproute2,git,systemd-sysv,udev,pciutils,udhcpc,xz-utils,efibootmgr,initramfs-tools \
	stable "${DEBDIR}/chroot" http://deb.debian.org/debian

#Copy already built kernel into chroot
mkdir -p "${DEBDIR}"/chroot/boot
cp "${KERNELFILES}"/config-* "${DEBDIR}"/chroot/boot/
cp "${kernel}" "${DEBDIR}"/chroot/boot/
cp "${kernel}" /srv/tftp/vmlinuz

#Copy modules
rsync -a --no-links "${MODULEFILES}"/lib/. "${DEBDIR}"/chroot/lib/

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
mount -t proc /proc "${DEBDIR}/chroot/proc"
mount -t sysfs /sys "${DEBDIR}/chroot/sys"
mount --bind /dev "${DEBDIR}/chroot/dev"
mount --bind /dev/pts "${DEBDIR}/chroot/dev/pts"

#Configure initramfs-tools to build without modules
chroot "${DEBDIR}"/chroot /usr/bin/env -i su -lc /bin/bash -c "
cat <<'EOF' > /etc/initramfs-tools/conf.d/settings.conf
MODULES=list
BUSYBOX=y
COMPRESS=xz
EOF
"

#Generate initramfs
chroot "${DEBDIR}"/chroot /usr/bin/env -i su -lc /bin/bash -c "
update-initramfs -c -k \"${kver}\"       # create fresh initramfs for the kernel
"

#Copy initramfs for pxe boot
cp "${DEBDIR}"/chroot/boot/initrd.img* /srv/tftp/initramfs.img

#Enable Bash aliases
echo -e "\nsource ~/.bash_aliases" | tee -a "${DEBDIR}/chroot/root/.bashrc"

#Install PERCCLI and configure
cp "${DEPS_DIR}/PERCCLI_7.3208.0_Linux_A01/perccli_007.3208.0000.0000_all.deb" "${DEBDIR}/chroot/root/perccli.deb"
chroot "${DEBDIR}"/chroot /usr/bin/env -i /bin/bash -lc "
dpkg -i /root/perccli.deb
"
echo -e "\nalias p='/opt/MegaRAID/perccli/perccli64'" | tee -a "${DEBDIR}"/chroot/root/.bash_aliases

#Add DNS Nameserver
chroot "${DEBDIR}"/chroot /usr/bin/env -i su -lc /bin/bash -c "
echo \"nameserver 1.1.1.1\" > /etc/resolv.conf
"

#Run customizations
cp "${CUSTOM_DIR}"/customize.sh "${DEBDIR}"/chroot/root/
chroot "${DEBDIR}/chroot" /usr/bin/env -i su -lc /bin/bash -c "
sh /root/customize.sh
"

#Copy tmux resurrect session for watching zfs and drive activity
mkdir -p "${DEBDIR}"/chroot/root/.local/share/tmux/resurrect
cp -a "${CUSTOM_DIR}"/tmux_session/* "${DEBDIR}"/chroot/root/.local/share/tmux/resurrect

#Copy man_reinstall.sh to be run manually when system is booted
cp "${CUSTOM_DIR}"/man_reinstall.sh "${DEBDIR}"/chroot/root

#Install man_reinstall.sh service for it to run after boot and an Internet connection is detected
cp "${CUSTOM_DIR}/man_reinstall.service" "${DEBDIR}/chroot/etc/systemd/system"
chroot "${DEBDIR}/chroot" /usr/bin/env -i su -lc /bin/bash -c "
systemctl enable man_reinstall.service
"


#Cleanup unnecessary files
chroot "${DEBDIR}/chroot" /usr/bin/env -i su -lc /bin/bash -c "
rm -rf /var/cache/apt/* /usr/share/doc/* /usr/share/man/* /usr/share/locale/* /usr/share/info/*
apt-get purge -y initramfs-tools git
apt-get autoremove -y
apt-get clean
echo 'root:root' | chpasswd
/usr/bin/busybox --install
rm /root/perccli.deb
rm /root/customize.sh
"
rm -rf "${DEBDIR}"/chroot/boot

#Enable Networking
chroot "${DEBDIR}/chroot" /usr/bin/env -i su -lc /bin/bash -c "
cat <<'EOF' > /etc/systemd/network/20-dhcp.network
[Match]
Name=eno1*

[Network]
DHCP=yes
EOF
"

#Copy ZFS module and /etc files
rsync -rl --ignore-existing "${COMPILED_DIR}"/zfs/. "${DEBDIR}/chroot/"

#Activate modules and zfs systemd service files
chroot "${DEBDIR}/chroot" /usr/bin/env -i su -lc /bin/bash -c "
depmod -a \"${kver}\"
"

#Add authorized keys
mkdir -p -m 0700 "${DEBDIR}/chroot/root/.ssh"
cp "${CUSTOM_DIR}/authorized_keys" "${DEBDIR}/chroot/root/.ssh/"
chmod 0600 ${DEBDIR}/chroot/root/.ssh/authorized_keys

#Remove resolv.conf
rm "${DEBDIR}/chroot/etc/resolv.conf"

#Unmount after chroot
umount "${DEBDIR}/chroot/dev/pts"
umount "${DEBDIR}/chroot/dev"
umount "${DEBDIR}/chroot/sys"
umount "${DEBDIR}/chroot/proc"

#Clear trap
trap - EXIT

#Compress the rootfs into a squashfs image
mksquashfs "${DEBDIR}/chroot" "/srv/tftp/rootfs.squashfs" -comp xz -Xbcj x86 -noappend

#Show final size
ls -lh "/srv/tftp/rootfs.squashfs"
                                 
