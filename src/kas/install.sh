#!/bin/bash
#-------------------------------------------------------------------------------------------------------------
# Copyright (c) Exact Assembly, LLC
# Licensed under GNU AFFERO v3.0
#
# Installs kas (Siemens) — a setup tool for bitbake-based projects.
# https://kas.readthedocs.io/  https://github.com/siemens/kas
#
# Required base: a Python interpreter on PATH (devcontainers/features/python is
# declared in installsAfter so the order is enforced).
#-------------------------------------------------------------------------------------------------------------
set -e

# Source the env file written by the devcontainers tooling.
set -a
. ./devcontainer-features.env
set +a

# --------------------------------------------------------------------------- #
# Resolve install user
# --------------------------------------------------------------------------- #
USERNAME="${USERNAME:-"${_REMOTE_USER:-"automatic"}"}"
if [ "${USERNAME}" = "auto" ] || [ "${USERNAME}" = "automatic" ]; then
    USERNAME=""
    POSSIBLE_USERS=("vscode" "node" "codespace" "$(awk -v val=1000 -F ":" '$3==val{print $1}' /etc/passwd)")
    for CURRENT_USER in "${POSSIBLE_USERS[@]}"; do
        if id -u "${CURRENT_USER}" > /dev/null 2>&1; then
            USERNAME="${CURRENT_USER}"
            break
        fi
    done
    if [ -z "${USERNAME}" ]; then
        USERNAME=vscode
    fi
elif [ "${USERNAME}" = "none" ] || ! id -u "${USERNAME}" > /dev/null 2>&1; then
    USERNAME=vscode
fi

FEATURE_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PYTHON_SRC="$(command -v python3 || command -v python)"
if [ -z "${PYTHON_SRC}" ]; then
    echo "ERROR: kas feature requires Python on PATH. Add the python feature before kas." >&2
    exit 1
fi

# --------------------------------------------------------------------------- #
# Helper: run a command as the target user (or directly if not root).
# --------------------------------------------------------------------------- #
run_as_user() {
    if [ "$(id -u)" -eq 0 ] && [ "${USERNAME}" != "root" ]; then
        su - "${USERNAME}" -c "$*"
    else
        bash -c "$*"
    fi
}

# --------------------------------------------------------------------------- #
# Pip-install kas.
# kas option 'latest' → install latest from PyPI; otherwise pin to the version.
# --------------------------------------------------------------------------- #
KAS_VERSION="${VERSION:-5.2}"

if [ "${KAS_VERSION}" = "latest" ]; then
    PIP_SPEC="kas"
else
    PIP_SPEC="kas==${KAS_VERSION}"
fi

echo "Installing ${PIP_SPEC} via pip for user ${USERNAME}"
run_as_user "${PYTHON_SRC} -m pip install --user --upgrade --no-cache-dir '${PIP_SPEC}'"

# --------------------------------------------------------------------------- #
# Drop the wrapper script.
# --------------------------------------------------------------------------- #
mkdir -p /opt/kas/scripts
cp -f "${FEATURE_DIR}/kas-build.sh" /opt/kas/scripts/
chmod +rx /opt/kas/scripts/kas-build.sh

# Ensure the wrapper is on PATH for the target user (login + non-login).
PROFILE_LINE='export PATH="/opt/kas/scripts:$PATH"'
USER_HOME="$(getent passwd "${USERNAME}" | cut -d: -f6)"
if [ -n "${USER_HOME}" ]; then
    BASHRC="${USER_HOME}/.bashrc"
    PROFILE="${USER_HOME}/.profile"
    for f in "${BASHRC}" "${PROFILE}"; do
        if [ -f "${f}" ] && ! grep -qF '/opt/kas/scripts' "${f}"; then
            echo "${PROFILE_LINE}" >> "${f}"
        fi
    done
fi

# Persist option-driven env defaults. Anything in containerEnv (set by
# devcontainers tooling) wins at runtime; the .env file is for shells that
# don't inherit containerEnv (e.g., direct `docker exec /bin/bash`).
mkdir -p /opt/kas/scripts
touch /opt/kas/scripts/kas.env
{
    [ -n "${MENU_FILE}" ]   && echo "export KAS_MENU_FILE=\"${MENU_FILE}\""
    [ -n "${KAS_BUILD_DIR}" ] && echo "export KAS_BUILD_DIR=\"${KAS_BUILD_DIR}\""
    [ -n "${SSTATE_DIR}" ]  && echo "export SSTATE_DIR=\"${SSTATE_DIR}\""
    [ -n "${DL_DIR}" ]      && echo "export DL_DIR=\"${DL_DIR}\""
} > /opt/kas/scripts/kas.env

echo "kas feature install complete (kas ${KAS_VERSION})."
