#!/bin/bash

sudo -E bash -c '
	/home/build/linuxcompile.sh
	/home/build/zfscompile.sh
	/home/build/build/debootstrap/scripts/bsys.sh
'
