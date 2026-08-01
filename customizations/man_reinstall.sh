#!/bin/bash

apt update

apt install --reinstall manpages manpages-dev man-db -y

dpkg -l | awk '/^ii/ {print $2}' | xargs apt install --reinstall -y

mandb

source ~/.bashrc