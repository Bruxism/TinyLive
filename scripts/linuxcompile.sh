#!/bin/bash
set -e

BRANCH="linux-7.1.y"

#Requires:
#apt-get install git fakeroot build-essential ncurses-dev xz-utils libssl-dev bc flex libelf-dev bison

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
DEBDIR="${SCRIPT_DIR%/*}"

DEPS_DIR="${DEBDIR}"/deps
CUSTOM_DIR="${DEBDIR}/customizations"

LINUX_SRC_DIR="${DEPS_DIR}"/linux
KERNEL_INSTALL_DIR="${DEPS_DIR}"/compiled/kernel
MODULES_INSTALL_DIR="${DEPS_DIR}"/compiled/modules

#Make compile directories
mkdir -p "${KERNEL_INSTALL_DIR}" "${MODULES_INSTALL_DIR}"

#Check if repo directory exists
if [[ ! -d "${LINUX_SRC_DIR}/.git" ]]; then
        echo "Repo hasn't been cloned. Cloning now..."
        git clone --single-branch --branch "${BRANCH}" --depth 1 \
	"https://git.kernel.org/pub/scm/linux/kernel/git/stable/linux.git/" \
	"${LINUX_SRC_DIR}"
fi

cd "${LINUX_SRC_DIR}"

#Check if branch exists locally and if it doesn't, fetch remote, if it doesn't there, exit fail
if ! git rev-parse --verify --quiet "${BRANCH}" > /dev/null 2>&1; then
	echo "Branch \"${BRANCH}\" doesn't exist locally. Checking to see if it exists remotely."
	if git fetch --depth 1 origin "${BRANCH}:${BRANCH}" > /dev/null 2>&1; then
		git remote set-branches --add origin "${BRANCH}"
		git switch -f "${BRANCH}"
		git reset --hard origin/"${BRANCH}" 
		echo "Branch found and fetched. Deleting other local branches..."
		git branch | grep -v -E "^\*|${BRANCH}" | xargs git branch -D && \
		git branch -r | grep -v -E "^\*|origin/${BRANCH}" | xargs git branch -dr 
	else
		echo "Remote branch \"${BRANCH}\" not found. Exiting..."
		exit 1
	fi
else
	echo "Branch \"${BRANCH}\" found locally. Continuing with fetch, reset, and compile..."
	git fetch origin "${BRANCH}"
fi


git clean -fdx

cp "${CUSTOM_DIR}"/kernel_config ./.config

make olddefconfig

make all -j $(nproc)

rm -rf "${KERNEL_INSTALL_DIR}"/*
rm -rf "${MODULES_INSTALL_DIR}"/*

INSTALL_PATH="${KERNEL_INSTALL_DIR}" make install -j $(nproc)
INSTALL_MOD_PATH="${MODULES_INSTALL_DIR}" make modules_install -j $(nproc)
