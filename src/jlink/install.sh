#!/usr/bin/env bash
#-------------------------------------------------------------------------------------------------------------
# Copyright (c) Exact Assembly, LLC
# Licensed under GNU AFFERO v3.0
#
# Segger J-Link install — downloads the official .deb from segger.com using the
# documented CLI license-accept POST, then installs it via `apt-get install
# ./jlink.deb` so apt resolves the declared X11/xcb/xkbcommon runtime deps
# (libxcb-*, libxkbcommon*, libx11-xcb1, …).
#
# The `apt-get install ./file.deb` form is load-bearing here: `dpkg -i jlink.deb`
# leaves the package in `iU` (unpacked, unconfigured) state on slim base images
# because dpkg does not resolve dependencies. Using apt with a local .deb path
# pulls the runtime libs from the distro repos in the same transaction.
#-------------------------------------------------------------------------------------------------------------
set -e

set -a
. ./devcontainer-features.env
set +a

JLINK_VERSION="${VERSION:-latest}"

if [ "$(id -u)" -ne 0 ]; then
    echo "ERROR: install.sh must run as root." >&2
    exit 1
fi

# Idempotency: a re-run on an already-built layer is cheap, but skip if the
# binary is already on PATH (e.g., a downstream feature reinvocation).
if command -v JLinkExe >/dev/null 2>&1; then
    echo "==> jlink: JLinkExe already present, skipping install"
    exit 0
fi

case "$(uname -m)" in
    aarch64) ARCH_SUFFIX="arm64"  ;;
    x86_64)  ARCH_SUFFIX="x86_64" ;;
    *)       echo "ERROR: unsupported host arch $(uname -m)" >&2; exit 1 ;;
esac

# Segger URL conventions (observed on https://www.segger.com/downloads/jlink/):
#   latest  : JLink_Linux_<arch>.deb
#   archive : JLink_Linux_<version>_<arch>.deb   (e.g. JLink_Linux_V844a_x86_64.deb)
if [ "${JLINK_VERSION}" = "latest" ]; then
    PKG="JLink_Linux_${ARCH_SUFFIX}.deb"
else
    PKG="JLink_Linux_${JLINK_VERSION}_${ARCH_SUFFIX}.deb"
fi

export DEBIAN_FRONTEND=noninteractive
apt-get update -y
apt-get install -y --no-install-recommends wget ca-certificates

TMP="$(mktemp -d)"
trap 'rm -rf "${TMP}"' EXIT

echo "==> jlink: downloading ${PKG} from segger.com"
# The accept_license_agreement + non_emb_ctr POST is Segger's documented CLI
# download path. It has been stable for years but is not formally supported;
# if Segger changes the form, mirror the .deb yourself and bump `version`.
wget -q --post-data "accept_license_agreement=accepted&non_emb_ctr=confirmed&submit=Download+software" \
    "https://www.segger.com/downloads/jlink/${PKG}" \
    -O "${TMP}/jlink.deb"

# Load-bearing: apt resolves declared deps; dpkg -i would not.
apt-get install -y "${TMP}/jlink.deb"

apt-get clean
rm -rf /var/lib/apt/lists/*

# Probe for confirmation. JLinkExe with no controlling tty prints its banner
# (including version) on stderr and exits non-zero waiting for input — pipe it
# through head and swallow status.
echo "==> jlink: installed: $(JLinkExe -version 2>&1 | head -1 || echo 'binary present, version probe non-zero')"
