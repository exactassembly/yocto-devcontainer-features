#!/usr/bin/env bash
#-------------------------------------------------------------------------------------------------------------
# Copyright (c) Exact Assembly, LLC
# Licensed under GNU AFFERO v3.0
#
# OpenOCD with FTDI/MPSSE support — apt-installs by default, can be switched to
# a source build at a pinned tag if a feature newer than the distro package
# is required (e.g., 0.12.0 RTT improvements).
#-------------------------------------------------------------------------------------------------------------
set -e

set -a
. ./devcontainer-features.env
set +a

FROM_SOURCE="${FROM_SOURCE:-false}"
OPENOCD_VERSION="${VERSION:-0.12.0}"
INSTALL_UDEV="${INSTALL_UDEV_RULES:-true}"

if [ "$(id -u)" -ne 0 ]; then
    echo "ERROR: install.sh must run as root." >&2
    exit 1
fi

export DEBIAN_FRONTEND=noninteractive
apt-get update -y

if [ "${FROM_SOURCE}" != "true" ]; then
    echo "Installing OpenOCD via apt (set from_source=true to build a pinned version)"
    apt-get install -y --no-install-recommends \
        openocd \
        libftdi1-2 \
        libusb-1.0-0
else
    echo "Building OpenOCD ${OPENOCD_VERSION} from source"
    apt-get install -y --no-install-recommends \
        build-essential \
        autoconf \
        automake \
        libtool \
        pkg-config \
        git \
        ca-certificates \
        libftdi1-dev \
        libusb-1.0-0-dev \
        libhidapi-dev

    cd /tmp
    git clone --depth 1 --branch "v${OPENOCD_VERSION}" \
        https://github.com/openocd-org/openocd.git openocd-src
    cd openocd-src
    ./bootstrap
    ./configure \
        --enable-ftdi \
        --enable-stlink \
        --enable-jlink \
        --enable-cmsis-dap \
        --disable-werror
    make -j"$(nproc)"
    make install
    cd /
    rm -rf /tmp/openocd-src
fi

# FT232H udev rule.
if [ "${INSTALL_UDEV}" = "true" ]; then
    install -d /etc/udev/rules.d
    cat > /etc/udev/rules.d/99-ftdi-ft232h.rules <<'EOF'
# FTDI FT232H — JTAG/SWD/UART/SPI/I2C breakout
SUBSYSTEM=="usb", ATTRS{idVendor}=="0403", ATTRS{idProduct}=="6014", MODE="0660", GROUP="plugdev", TAG+="uaccess"
EOF
    chmod 0644 /etc/udev/rules.d/99-ftdi-ft232h.rules
fi

apt-get clean
rm -rf /var/lib/apt/lists/*

openocd --version 2>&1 | head -3 || true
echo "openocd feature install complete."
