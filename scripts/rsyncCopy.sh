#!/bin/bash

rsync -avr --info=progress2 --inplace -e \
	"ssh -p ${RSYNC_TFTP_TARGET_SSH_PORT:-22}" \
	"${RSYNC_TFTP_TARGET_DIR:-/srv/tftp/}" \
	"${RSYNC_TFTP_TARGET_USERHOST:-root@openwrt:}"
