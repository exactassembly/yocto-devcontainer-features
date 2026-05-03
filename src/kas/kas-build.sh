#!/bin/bash
#-------------------------------------------------------------------------------------------------------------
# Copyright (c) Exact Assembly, LLC
# Licensed under GNU AFFERO v3.0
#
# kas wrapper for VSCode tasks and CI.
#
# Reads the same env vars the kas feature exports (KAS_MENU_FILE, KAS_BUILD_DIR,
# SSTATE_DIR, DL_DIR). Honors KAS_MENU_DIR for menu-file resolution; defaults to
# the workspace root.
#
# Usage: kas-build.sh <subcommand> [extra-args...]
#   build           — kas build $KAS_MENU_FILE
#   shell           — kas shell  $KAS_MENU_FILE  (drops you into bitbake env)
#   checkout        — kas checkout $KAS_MENU_FILE  (clone layers, no build)
#   for-all         — kas for-all $KAS_MENU_FILE -- "$@"
#   cleansstate     — kas shell  $KAS_MENU_FILE -c "bitbake -c cleansstate <recipes from $@>"
#-------------------------------------------------------------------------------------------------------------
set -e

# Pick up persistent defaults if not already in env.
[ -f /opt/kas/scripts/kas.env ] && . /opt/kas/scripts/kas.env || true

KAS_MENU_DIR="${KAS_MENU_DIR:-${CONTAINER_WORKSPACE_FOLDER:-$(pwd)}}"
KAS_MENU_FILE="${KAS_MENU_FILE:-kas-menu.yml}"
MENU_PATH="${KAS_MENU_DIR}/${KAS_MENU_FILE}"

if [ ! -f "${MENU_PATH}" ]; then
    echo "ERROR: kas menu not found at ${MENU_PATH}" >&2
    echo "  Set KAS_MENU_DIR or KAS_MENU_FILE, or pass an explicit path as the second argument." >&2
    exit 2
fi

# Surface the cache dirs to bitbake — kas honors local.conf snippets in the
# menu, but a top-level export is a sane fallback for plain bitbake invocations.
[ -n "${SSTATE_DIR}" ] && export SSTATE_DIR
[ -n "${DL_DIR}" ]     && export DL_DIR
[ -n "${KAS_BUILD_DIR}" ] && export KAS_WORK_DIR="${KAS_BUILD_DIR}"

cmd="$1"
shift || true

case "${cmd}" in
    build)
        kas build "${MENU_PATH}" "$@"
        ;;
    shell)
        kas shell "${MENU_PATH}" "$@"
        ;;
    checkout)
        kas checkout "${MENU_PATH}" "$@"
        ;;
    for-all)
        kas for-all "${MENU_PATH}" -- "$@"
        ;;
    cleansstate)
        if [ "$#" -lt 1 ]; then
            echo "Usage: kas-build.sh cleansstate <recipe> [recipe...]" >&2
            exit 2
        fi
        kas shell "${MENU_PATH}" -c "bitbake -c cleansstate $*"
        ;;
    *)
        echo "kas-build.sh <subcommand> [args...]"
        echo "  build | shell | checkout | for-all | cleansstate"
        echo ""
        echo "Reads (with defaults shown):"
        echo "  KAS_MENU_DIR    = ${KAS_MENU_DIR}"
        echo "  KAS_MENU_FILE   = ${KAS_MENU_FILE}"
        echo "  KAS_BUILD_DIR   = ${KAS_BUILD_DIR:-(unset)}"
        echo "  SSTATE_DIR      = ${SSTATE_DIR:-(unset)}"
        echo "  DL_DIR          = ${DL_DIR:-(unset)}"
        exit 2
        ;;
esac
