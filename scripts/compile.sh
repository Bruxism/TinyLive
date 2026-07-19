#!/bin/bash

export SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"

sudo -E bash -c '
	"${SCRIPT_DIR}"/linuxcompile.sh
	"${SCRIPT_DIR}"/zfscompile.sh
	"${SCRIPT_DIR}"/bsys.sh
'

if [[ -a "${SCRIPT_DIR}"/rsyncCopy.sh ]]; then 
	sudo "${SCRIPT_DIR}"/rsyncCopy.sh
fi
