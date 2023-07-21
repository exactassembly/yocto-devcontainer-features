#!/bin/bash
#-------------------------------------------------------------------------------------------------------------
# Copyright (c) Exact Assembly, LLC
# Licensed under GNU AFFERO v3.0
#-------------------------------------------------------------------------------------------------------------
set -e

# The install.sh script is the installation entrypoint for any dev container 'features' in this repository. 
#
# The tooling will parse the devcontainer-features.json + user devcontainer, and write 
# any build-time arguments into a feature-set scoped "devcontainer-features.env"
# The author is free to source that file and use it however they would like.
set -a
. ./devcontainer-features.env
set +a

USERNAME="${USERNAME:-"${_REMOTE_USER:-"automatic"}"}"
# Determine the appropriate non-root user
if [ "${USERNAME}" = "auto" ] || [ "${USERNAME}" = "automatic" ]; then
    USERNAME=""
    POSSIBLE_USERS=("vscode" "node" "codespace" "$(awk -v val=1000 -F ":" '$3==val{print $1}' /etc/passwd)")
    for CURRENT_USER in "${POSSIBLE_USERS[@]}"; do
        if id -u ${CURRENT_USER} > /dev/null 2>&1; then
            USERNAME=${CURRENT_USER}
            break
        fi
    done
    if [ "${USERNAME}" = "" ]; then
        USERNAME=vscode
    fi
elif [ "${USERNAME}" = "none" ] || ! id -u ${USERNAME} > /dev/null 2>&1; then
    USERNAME=vscode
fi

FEATURE_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PYTHON_SRC=$(which python)

sudo_if() {
    COMMAND="$*"
    if [ "$(id -u)" -eq 0 ] && [ "$USERNAME" != "root" ]; then
        su - "$USERNAME" -c "$COMMAND"
    else
        "$COMMAND"
    fi
}

sudo_if "${PYTHON_SRC}" "-m pip install --user --upgrade --no-cache-dir git+https://github.com/cpb-/yocto-cooker.git"

mkdir -p /opt/cooker/scripts
#cp -f "${FEATURE_DIR}/configure-cooker.sh" /opt/cooker/scripts/
#chmod +rx /opt/cooker/scripts/configure-cooker.sh
touch /opt/cooker/scripts/cooker.env
if [ "$COOKER_MENU_FILE" != "" ]; then
    echo "export COOKER_MENU_FILE=\"${COOKER_MENU_FILE}\"" >> /opt/cooker/scripts/cooker.env
fi
if [ "$COOKER_SSTATE_CACHE_DIR" != "" ]; then
    echo "export COOKER_SSTATE_CACHE_DIR=\"${COOKER_SSTATE_CACHE_DIR}\"" >> /opt/cooker/scripts/cooker.env
fi
if [ "$COOKER_DLCACHE_DIR" != "" ]; then
    echo "export COOKER_DLCACHE_DIR=\"${COOKER_DLCACHE_DIR}\"" >> /opt/cooker/scripts/cooker.env
fi
