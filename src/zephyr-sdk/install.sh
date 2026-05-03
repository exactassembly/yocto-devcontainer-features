#!/usr/bin/env bash
#-------------------------------------------------------------------------------------------------------------
# Copyright (c) Exact Assembly, LLC
# Licensed under GNU AFFERO v3.0
#
# Zephyr SDK install — downloads sdk-ng release tarball and unpacks under
# ${INSTALL_DIR}/zephyr-sdk-${VERSION}, runs setup.sh to register CMake
# packages and install host tools, optionally pip-installs west.
#
# Single source of truth for the version is the feature option `version`
# (default 0.17.4). The SDK install dir is exported via ZEPHYR_SDK_INSTALL_DIR.
#-------------------------------------------------------------------------------------------------------------
set -e

set -a
. ./devcontainer-features.env
set +a

ZSDK_VERSION="${VERSION:-0.17.4}"
ZSDK_PARENT="${INSTALL_DIR:-/opt}"
ZSDK_TOOLCHAINS="${TOOLCHAINS:-minimal}"
ZSDK_INSTALL_WEST="${INSTALL_WEST:-true}"

ZSDK_HOME="${ZSDK_PARENT}/zephyr-sdk-${ZSDK_VERSION}"
GH_RELEASES="https://github.com/zephyrproject-rtos/sdk-ng/releases/download/v${ZSDK_VERSION}"

if [ "$(id -u)" -ne 0 ]; then
    echo "ERROR: install.sh must run as root." >&2
    exit 1
fi

# Need wget + xz + tar; they should already be present from yocto-host, but
# don't assume — we may be installed standalone.
DEBIAN_FRONTEND=noninteractive apt-get update -y
DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    wget xz-utils file ca-certificates

# Detect host arch.
case "$(uname -m)" in
    x86_64)  HOST_ARCH="x86_64" ;;
    aarch64) HOST_ARCH="aarch64" ;;
    *)       echo "ERROR: unsupported host arch $(uname -m)" >&2; exit 1 ;;
esac

# Pick the bundle. 'minimal' uses zephyr-sdk-${V}_linux-${ARCH}_minimal.tar.xz
# (ships only host tools, toolchains added later); 'all' uses the full bundle;
# a specific triple is installed in two steps (minimal + per-toolchain tarball).
case "${ZSDK_TOOLCHAINS}" in
    minimal)
        BUNDLE_URL="${GH_RELEASES}/zephyr-sdk-${ZSDK_VERSION}_linux-${HOST_ARCH}_minimal.tar.xz"
        ;;
    all)
        BUNDLE_URL="${GH_RELEASES}/zephyr-sdk-${ZSDK_VERSION}_linux-${HOST_ARCH}.tar.xz"
        ;;
    arm-zephyr-eabi|aarch64-zephyr-elf|riscv64-zephyr-elf|x86_64-zephyr-elf|*)
        BUNDLE_URL="${GH_RELEASES}/zephyr-sdk-${ZSDK_VERSION}_linux-${HOST_ARCH}_minimal.tar.xz"
        TOOLCHAIN_URL="${GH_RELEASES}/toolchain_linux-${HOST_ARCH}_${ZSDK_TOOLCHAINS}.tar.xz"
        ;;
esac

mkdir -p "${ZSDK_PARENT}"
cd "${ZSDK_PARENT}"

echo "Downloading Zephyr SDK ${ZSDK_VERSION} (${ZSDK_TOOLCHAINS}) for ${HOST_ARCH}"
wget -q --show-progress -O sdk.tar.xz "${BUNDLE_URL}"
tar -xf sdk.tar.xz
rm sdk.tar.xz

if [ -n "${TOOLCHAIN_URL:-}" ]; then
    echo "Downloading toolchain ${ZSDK_TOOLCHAINS}"
    cd "${ZSDK_HOME}"
    wget -q --show-progress -O toolchain.tar.xz "${TOOLCHAIN_URL}"
    tar -xf toolchain.tar.xz
    rm toolchain.tar.xz
    cd "${ZSDK_PARENT}"
fi

# Run the SDK's setup script — registers cmake packages, drops udev rules
# under /etc/udev/rules.d (-h for "host tools install host_tools_only" mode if
# we want to skip toolchains; we use -t arm-zephyr-eabi style for selective).
cd "${ZSDK_HOME}"
yes | bash setup.sh -c -t "${ZSDK_TOOLCHAINS}" 2>&1 | tail -20 || \
    yes | bash setup.sh -c 2>&1 | tail -20 || \
    echo "WARNING: setup.sh exited non-zero; SDK may still be usable. Check $(pwd)"

# Optional: install west via pip into the system python (kept under the
# vscode user via --user where possible).
if [ "${ZSDK_INSTALL_WEST}" = "true" ]; then
    USERNAME="${_REMOTE_USER:-vscode}"
    if id -u "${USERNAME}" > /dev/null 2>&1; then
        su - "${USERNAME}" -c "python3 -m pip install --user --upgrade --no-cache-dir west" || true
    else
        python3 -m pip install --upgrade --no-cache-dir --break-system-packages west || \
        python3 -m pip install --upgrade --no-cache-dir west
    fi
fi

# Patch containerEnv in /etc/profile.d so the SDK install dir env var lands
# even if the feature's containerEnv default doesn't match the requested version.
cat > /etc/profile.d/zephyr-sdk.sh <<EOF
export ZEPHYR_SDK_INSTALL_DIR="${ZSDK_HOME}"
EOF
chmod +rx /etc/profile.d/zephyr-sdk.sh

echo "Zephyr SDK ${ZSDK_VERSION} installed at ${ZSDK_HOME}"
