#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"

sudo -E bash -c '
	/home/build/linuxcompile.sh
	/home/build/zfscompile.sh
	/home/build/build/debootstrap/scripts/bsys.sh
'

if [[ -a ${SCRIPT_DIR}/rsyncCopy.sh ]]; then 
	sudo "${SCRIPT_DIR}"/rsyncCopy.sh
fi
