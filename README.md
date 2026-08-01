# About

___

TinyLive is a set of scripts that prepares a tiny live-boot Debian-based OS that's around 130 megabytes.

To that end, the final output files are:

- vmlinuz

- initramfs.img

- rootfs.squashfs

The original intent to create an OS small enough to be PXE-boot hosted on an Ubiquti EdgeRouter-X. This way, a target PC can run it in RAM so as to leave that target PC's drives uncontested for [fio](https://github.com/axboe/fio) benchmarking.

However, it should be easy to repurpose TinyLive by customizing [scripts/bsys.sh](scripts/bsys.sh).

Fundamentally, this relies on Debian's debootstrap and live-boot combined with the Linux Kernel. Other major components include OpenZFS, fio, and PERCCLI.

### Requirements

---

A Debian system with root access that includes the ability to mount to `/proc`, `/sys`, `/dev/`, and `/dev/pts`.

This was created and tested on Debian 13 "trixie".

See [scripts/install.sh](scripts/install.sh) for a bigger list of required packages. Of course, keep in mind that those also have their own requirements that get installed automatically.

Also included are scripts to download and compile OpenZFS and also to download and include Dell's PERCCLI aka MegaRAID.

### Customizations you may want to set or need updating

___

- [scripts/install.sh](scripts/install.sh) has a USER_AGENT variable that wget uses to download PERCCLI aka MegaRAID. The default is set to Firefox.

- [scripts/linuxcompile.sh](scripts/linuxcompile.sh) has variable `BRANCH` at the top that is where you put one of the branches from `https://git.kernel.org/pub/scm/linux/kernel/git/stable/linux.git/`. This may require frequent updating if not set to an LTS. At the moment of writing, it is set to "linux-7.1.y".

- [scripts/rsyncCopy.sh](scripts/rsyncCopy.sh) has three variables that you may want to export to your shell
  
  - RSYNC_TFTP_TARGET_SSH_PORT
  
  - RSYNC_TFTP_TARGET_DIR
  
  - RSYNC_TFTP_TARGET_USERHOST

- You may rename [scripts/rsyncCopy.sh](scripts/rsyncCopy.sh) to keep it from running at all--such as to `rsyncCopy.sh.bak`. 

> [!TIP]
> Try `mv scripts/rsyncCopy.sh{,.bak}` to rename and append `.bak` without having to type out the path twice.

[customizations/authorized_keys](customizations/authorized_keys) your public ssh keys for remote shell access

### How to use

___

All scripts here are in reference to `scripts/`.

Most basically, run `install.sh` once, and then `sudo -E compile.sh` to create all output files. Of course, if you're already root, you don't need `sudo`.

Final output is exported to `/srv/tftp/`.

Once set up, when the OS is booted, run `tmux`, and then press `ctrl-b` followed by `ctrl-r` to restore an assortment of info panes and a window for running fio. Info panes include iostat, zarcstat, zpool iostat, and htop--those are in the second window.

### What each file does

___

#### scripts/

- `bsys.sh` puts everything together. It runs `debootstrap` to download the packages listed in it. Then, combines that with the Linux Kernel, ZFS, and PERCCLI. You can run this to download and reassemble the `rootfs.squashfs` with the latest packages.
  
  - Currently set up to require `PERCCLI_7.3208.0_Linux_A01`. Feel free to edit that out.

- `linuxcompile.sh` clones and compiles a Linux Kernel. It bases the configuration from [customizations/kernel_config](customizations/kernel_config). Please check `BRANCH=` for what branch it is set to, and change it if necessary.

- `zfscompile.sh` clones and compiles OpenZFS modules. It requires `linuxcompile.sh` to have already run. It currently set to the `main` branch.

- `rsyncCopy.sh` copies all files in `/srv/tftp` (where these scripts output files into) to a target system.

- `chr.sh` was used for debugging during design. It's not used automatically.
  
  - Requires root or sudo. NOPASSWD option for user in `sudoers` may be required.

#### customizations/

- `authorized_keys` your ssh public keys to be built into the system so to have remote control

- `customize.sh` a script that runs in the TinyLive system before it is made into a squashfs. I used it for dotfiles relating to vim / tmux + plugins including [**[tmux-resurrect](https://github.com/tmux-plugins/tmux-resurrect)**](https://github.com/tmux-plugins/tmux-resurrect).

- `kernel_config` the config file for compiling the Linux Kernel during that stage. The goal was to remove as many modules as possible and build in as many to minimize the kernel size. I did have to include at least one module as OpenZFS would refuse to compile without one--even if modules were enabled.

- `man_reinstall.service` & `man_reinstall.sh` a service to run a script that reinstalls `man` pages back onto the system after it's finished booting. Building in those pages took up too much space (~20MB, if I recall correctly), so this is a workaround to get them included automatically.

- `session.tar` has a tmux-resurrect setup that opens up an assortment of info panes and a window for running fio scripts. Info panes include iostat, zarcstat, zpool iostat, and htop. Run `tmux`, and then press `ctrl-b` followed by `ctrl-r` to load it.
