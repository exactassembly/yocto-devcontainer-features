#!/usr/bin/env bash
#-------------------------------------------------------------------------------------------------------------
# Copyright (c) Exact Assembly, LLC
# Licensed under GNU AFFERO v3.0
#
# Zephyr SDK install — downloads one or more sdk-ng release tarballs and
# unpacks each under ${INSTALL_DIR}/zephyr-sdk-${V}, runs setup.sh per SDK to
# register CMake packages and install host udev rules, optionally pip-installs
# west.
#
# Two-axis configuration:
#   * version          — primary SDK (a single tag like "1.0.1"). Always installed.
#   * extra_versions   — comma-separated list of *additional* tags to install
#                        alongside `version` (e.g. "0.17.4,0.16.8"). Each lands
#                        in its own /opt/zephyr-sdk-X.Y.Z/. Zephyr CMake's
#                        find_zephyr_sdk() then auto-selects the highest one
#                        that satisfies each project's zephyr/SDK_VERSION min.
#
# Single source of truth for the default version is the `version` option in
# devcontainer-feature.json. ZEPHYR_SDK_INSTALL_DIR is exported through a
# /opt/zephyr-sdk symlink that always points at `version` (the primary).
# Set ZEPHYR_SDK_INSTALL_DIR=  (empty) in your build env to let CMake auto-pick
# the right SDK when multiple are installed.
#-------------------------------------------------------------------------------------------------------------
set -e

set -a
. ./devcontainer-features.env
set +a

ZSDK_PRIMARY="${VERSION:-1.0.1}"
ZSDK_EXTRAS="${EXTRA_VERSIONS:-}"
ZSDK_PARENT="${INSTALL_DIR:-/opt}"
ZSDK_TOOLCHAINS="${TOOLCHAINS:-minimal}"
ZSDK_INSTALL_WEST="${INSTALL_WEST:-true}"
ZSDK_HOST_DEPS="${HOST_DEPS:-true}"

if [ "$(id -u)" -ne 0 ]; then
    echo "ERROR: install.sh must run as root." >&2
    exit 1
fi

# Build the version list: primary first, then dedup'd extras.
declare -a SDK_VERSIONS=("${ZSDK_PRIMARY}")
if [ -n "${ZSDK_EXTRAS}" ]; then
    IFS=',' read -ra EXTRA_ARR <<<"${ZSDK_EXTRAS}"
    for v in "${EXTRA_ARR[@]}"; do
        v="${v// /}"   # strip spaces
        [ -z "${v}" ] && continue
        # Skip if duplicate of primary
        [ "${v}" = "${ZSDK_PRIMARY}" ] && continue
        SDK_VERSIONS+=("${v}")
    done
fi

echo "==> zephyr-sdk: will install SDK version(s): ${SDK_VERSIONS[*]}"
echo "==> zephyr-sdk: toolchains=${ZSDK_TOOLCHAINS}, host_deps=${ZSDK_HOST_DEPS}, install_west=${ZSDK_INSTALL_WEST}"

# ------------------------------------------------------------------ apt deps
# wget/xz/tar/file/ca-certificates are needed unconditionally to fetch + unpack
# the SDK bundle. host_deps adds the Zephyr build-host package set (cmake,
# ninja-build, gperf, device-tree-compiler, ccache). These are pulled at image
# build time so they land in the feature's Docker layer and are cached across
# container rebuilds — DO NOT move them into a post-create step.
export DEBIAN_FRONTEND=noninteractive
apt-get update -y

APT_PKGS=(wget xz-utils file ca-certificates)

if [ "${ZSDK_HOST_DEPS}" = "true" ]; then
    # Zephyr's "Install Dependencies" host-tool set, trimmed to what west build
    # actually needs at the host level (SDK ships the cross-toolchain itself).
    # build-essential gets us make + gcc + libc headers (needed by Zephyr's
    # native_posix / unit_testing boards even when cross-compiling).
    APT_PKGS+=(build-essential cmake ninja-build gperf device-tree-compiler ccache)
fi

apt-get install -y --no-install-recommends "${APT_PKGS[@]}"

# Detect host arch (sdk-ng publishes linux-x86_64 and linux-aarch64 bundles).
case "$(uname -m)" in
    x86_64)  HOST_ARCH="x86_64" ;;
    aarch64) HOST_ARCH="aarch64" ;;
    *)       echo "ERROR: unsupported host arch $(uname -m)" >&2; exit 1 ;;
esac

mkdir -p "${ZSDK_PARENT}"

# ------------------------------------------------------------------ install each SDK
install_one_sdk() {
    local v="$1"
    local home="${ZSDK_PARENT}/zephyr-sdk-${v}"
    local gh="https://github.com/zephyrproject-rtos/sdk-ng/releases/download/v${v}"
    local bundle_url toolchain_url tc_prefix

    if [ -d "${home}" ] && [ -f "${home}/setup.sh" ]; then
        echo "==> zephyr-sdk ${v}: already present at ${home}, skipping download"
        return 0
    fi

    # Per-toolchain asset naming changed at SDK 1.x:
    #   0.16.x / 0.17.x : toolchain_linux-<arch>_<tc>.tar.xz
    #   1.x and later   : toolchain_gnu_linux-<arch>_<tc>.tar.xz (also _llvm_ variant)
    # Detect by major version. The base 'minimal' / 'all' bundle naming is
    # unchanged across both lines.
    local major="${v%%.*}"
    if [ "${major}" -ge 1 ] 2>/dev/null; then
        tc_prefix="toolchain_gnu_linux"
    else
        tc_prefix="toolchain_linux"
    fi

    case "${ZSDK_TOOLCHAINS}" in
        minimal)
            bundle_url="${gh}/zephyr-sdk-${v}_linux-${HOST_ARCH}_minimal.tar.xz"
            ;;
        all)
            bundle_url="${gh}/zephyr-sdk-${v}_linux-${HOST_ARCH}.tar.xz"
            ;;
        arm-zephyr-eabi|aarch64-zephyr-elf|riscv64-zephyr-elf|x86_64-zephyr-elf|*)
            bundle_url="${gh}/zephyr-sdk-${v}_linux-${HOST_ARCH}_minimal.tar.xz"
            toolchain_url="${gh}/${tc_prefix}-${HOST_ARCH}_${ZSDK_TOOLCHAINS}.tar.xz"
            ;;
    esac

    echo "==> zephyr-sdk ${v}: downloading ${ZSDK_TOOLCHAINS} bundle for ${HOST_ARCH}"
    cd "${ZSDK_PARENT}"
    wget -q --show-progress -O "sdk-${v}.tar.xz" "${bundle_url}"
    tar -xf "sdk-${v}.tar.xz"
    rm "sdk-${v}.tar.xz"

    if [ -n "${toolchain_url:-}" ]; then
        echo "==> zephyr-sdk ${v}: downloading toolchain ${ZSDK_TOOLCHAINS}"
        cd "${home}"
        wget -q --show-progress -O toolchain.tar.xz "${toolchain_url}"
        tar -xf toolchain.tar.xz
        rm toolchain.tar.xz
        cd "${ZSDK_PARENT}"
    fi

    # setup.sh: -c registers CMake package (system + user registries), -t
    # selects toolchains. We tolerate non-zero exit because Zephyr's setup.sh
    # has historically returned 1 even after a successful registration on some
    # base images; the install dir is what Zephyr CMake actually finds.
    cd "${home}"
    yes | bash setup.sh -c -t "${ZSDK_TOOLCHAINS}" 2>&1 | tail -10 || \
        yes | bash setup.sh -c 2>&1 | tail -10 || \
        echo "    WARNING: setup.sh exited non-zero for ${v}; SDK likely still usable"
    cd "${ZSDK_PARENT}"
}

for v in "${SDK_VERSIONS[@]}"; do
    install_one_sdk "${v}"
done

# ------------------------------------------------------------------ default-pointer symlink
# /opt/zephyr-sdk is the stable path that containerEnv.ZEPHYR_SDK_INSTALL_DIR
# refers to. It always points at the PRIMARY version (first entry in the
# install list). Users wanting multi-SDK auto-selection can `unset
# ZEPHYR_SDK_INSTALL_DIR` in their build env — Zephyr CMake will then scan
# /opt/zephyr-sdk-* and pick the highest version satisfying SDK_VERSION.
ln -sfn "${ZSDK_PARENT}/zephyr-sdk-${ZSDK_PRIMARY}" "${ZSDK_PARENT}/zephyr-sdk"

# Also write /etc/profile.d for login shells (containerEnv covers the
# non-shell case for VSCode-spawned tools).
cat > /etc/profile.d/zephyr-sdk.sh <<EOF
# Auto-generated by ghcr.io/exactassembly/yocto-devcontainer-features/zephyr-sdk.
# Points at the PRIMARY installed SDK. With multiple SDKs installed, unset
# this var in a per-build shell to let Zephyr CMake auto-pick by SDK_VERSION.
export ZEPHYR_SDK_INSTALL_DIR="${ZSDK_PARENT}/zephyr-sdk"
EOF
chmod +rx /etc/profile.d/zephyr-sdk.sh

# ------------------------------------------------------------------ west
# Pip-install west (idempotent: setuptools updates an existing install). Done
# AFTER the SDKs so a failed SDK install doesn't get hidden by a later west
# success.
if [ "${ZSDK_INSTALL_WEST}" = "true" ]; then
    USERNAME="${_REMOTE_USER:-vscode}"
    if id -u "${USERNAME}" > /dev/null 2>&1; then
        su - "${USERNAME}" -c "python3 -m pip install --user --upgrade --no-cache-dir west" || true
    else
        python3 -m pip install --upgrade --no-cache-dir --break-system-packages west || \
        python3 -m pip install --upgrade --no-cache-dir west
    fi
fi

# ------------------------------------------------------------------ layer slim
apt-get clean
rm -rf /var/lib/apt/lists/*

echo "==> zephyr-sdk: installed SDK(s): ${SDK_VERSIONS[*]}"
echo "==> zephyr-sdk: default = ${ZSDK_PARENT}/zephyr-sdk -> zephyr-sdk-${ZSDK_PRIMARY}"
