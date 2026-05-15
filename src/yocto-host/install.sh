#!/usr/bin/env bash
#-------------------------------------------------------------------------------------------------------------
# Copyright (c) Exact Assembly, LLC
# Licensed under GNU AFFERO v3.0
#
# Yocto host prerequisites — apt-installs the package set the Yocto host needs
# to run bitbake/west, scoped by the target Yocto release.
#
# Inspired by willmmiles/devcontainer-feature-yocto (2023). Refreshed for
# current Yocto releases (walnascar, scarthgap, styhead) and modernized
# package list (drops python3-distutils, adds python3-setuptools, file).
#-------------------------------------------------------------------------------------------------------------
set -e

# Map release names to numeric versions. Anything past 3.0 should map to a
# 'modern' package set; legacy entries kept for back-compat with old projects
# that still build dunfell / kirkstone.
declare -A release_version_map
release_version_map[walnascar]=5.2
release_version_map[styhead]=5.1
release_version_map[scarthgap]=5.0
release_version_map[nanbield]=4.3
release_version_map[mickledore]=4.2
release_version_map[langdale]=4.1
release_version_map[kirkstone]=4.0
release_version_map[honister]=3.4
release_version_map[hardknott]=3.3
release_version_map[gatesgarth]=3.2
release_version_map[dunfell]=3.1
release_version_map[zeus]=3.0

# Resolve release → version.
RELEASE_RAW="${RELEASE:-walnascar}"
if [[ ${RELEASE_RAW} =~ ^[0-9]+\.[0-9]+ ]]; then
    release_version="${RELEASE_RAW}"
else
    release_version="${release_version_map[${RELEASE_RAW,,}]}"
fi

if [[ -z "${release_version}" ]]; then
    echo "ERROR: Unrecognized Yocto release '${RELEASE_RAW}'" >&2
    echo "  Known names: ${!release_version_map[*]}" >&2
    echo "  Numeric versions like '5.2' also accepted." >&2
    exit 1
fi

echo "Yocto host prereqs: release=${RELEASE_RAW} (version ${release_version})"

if [ "$(id -u)" -ne 0 ]; then
    echo "ERROR: install.sh must run as root. Use sudo or USER root in your Dockerfile." >&2
    exit 1
fi

INSTALL_MULTILIB="${INSTALL_MULTILIB:-true}"

install_debian_packages() {
    export DEBIAN_FRONTEND=noninteractive

    # Modern Yocto host package set per
    # https://docs.yoctoproject.org/dev/ref-manual/system-requirements.html
    # (walnascar / scarthgap entries) merged with the willmmiles legacy list.
    #
    # trixie compatibility notes:
    #  - 'liblz4-tool' was a transitional package removed in trixie; the lz4
    #    binary is now in the 'lz4' top-level package.
    #  - 'libegl1-mesa' was renamed: runtime is 'libegl1', dev headers are
    #    'libegl-dev'. Yocto's official prereq list never required it; we
    #    drop it entirely.
    #  - 'libsdl1.2-dev' is gone (SDL1.2 EOL upstream). Not needed by Yocto.
    local package_list="gawk \
        wget \
        git \
        diffstat \
        unzip \
        texinfo \
        gcc \
        build-essential \
        chrpath \
        socat \
        cpio \
        python3 \
        python3-pip \
        python3-pexpect \
        python3-git \
        python3-jinja2 \
        python3-subunit \
        python3-setuptools \
        xz-utils \
        debianutils \
        iputils-ping \
        pylint \
        xterm \
        iproute2 \
        zstd \
        lz4 \
        file \
        locales \
        libacl1 \
        screen \
        tmux \
        sudo \
        sysstat"

    # 32-bit multilib for amd64 — only needed by some recipes; configurable.
    if [ "${INSTALL_MULTILIB}" = "true" ] && [ "$(dpkg --print-architecture 2>/dev/null)" = "amd64" ]; then
        package_list="${package_list} gcc-multilib g++-multilib"
    fi

    # Pre-3.1 releases needed python2 — only matters for legacy back-compat.
    if (( $(echo "3.1 ${release_version}" | awk '{if ($1 > $2) print 1;}') )); then
        if [[ -n "$(apt-cache --names-only search ^python2$ 2>/dev/null)" ]]; then
            package_list="${package_list} python2"
        elif [[ -n "$(apt-cache --names-only search ^python$ 2>/dev/null)" ]]; then
            package_list="${package_list} python"
        fi
    fi

    rm -rf /var/lib/apt/lists/*
    apt-get update -y
    apt-get install -y --no-install-recommends ${package_list} \
        2> >( grep -v 'debconf: delaying package configuration, since apt-utils is not installed' >&2 )

    apt-get clean
    rm -rf /var/lib/apt/lists/*
}

# Distro detection — only debian/ubuntu supported today (matches reference
# Yocto build hosts; alpine and rhel not validated).
. /etc/os-release
case "${ID}-${ID_LIKE}" in
    debian-*|ubuntu-*|*-debian|*-ubuntu)
        install_debian_packages
        ;;
    *)
        echo "ERROR: yocto-host feature only supports Debian/Ubuntu hosts (got ID=${ID})." >&2
        exit 1
        ;;
esac

# Generate en_US.UTF-8 locale (Yocto bitbake requires it).
if ! locale -a 2>/dev/null | grep -qi '^en_us\.utf-\?8$'; then
    sed -i -e 's/^# *\(en_US\.UTF-8 UTF-8\)/\1/' /etc/locale.gen 2>/dev/null || true
    locale-gen en_US.UTF-8
fi

# Switch /bin/sh away from dash — many bitbake recipes assume bash semantics.
echo 'dash dash/sh boolean false' | debconf-set-selections
DEBIAN_FRONTEND=noninteractive dpkg-reconfigure dash

echo "yocto-host feature install complete."
