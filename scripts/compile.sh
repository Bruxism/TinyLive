#!/bin/bash

export SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"

bash -c '
	"${SCRIPT_DIR}"/linuxcompile.sh
	"${SCRIPT_DIR}"/zfscompile.sh
	"${SCRIPT_DIR}"/bsys.sh
'

if [[ -a "${SCRIPT_DIR}"/rsyncCopy.sh ]]; then 
	"${SCRIPT_DIR}"/rsyncCopy.sh
fi
