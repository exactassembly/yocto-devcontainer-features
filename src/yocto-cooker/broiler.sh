#!/bin/bash
#-------------------------------------------------------------------------------------------------------------
# Copyright (c) Exact Assembly, LLC
# Licensed under GNU AFFERO v3.0
#-------------------------------------------------------------------------------------------------------------
set -e

COOKER_BUILD_DIR="${COOKER_BUILD_DIR:-"/home/${USER}/yocto-build"}"
COOKER_LAYERS_DIR="${COOKER_LAYERS_DIR:-"/home/${USER}/yocto-layers"}"
COOKER_MENU_DIR="${COOKER_MENU_DIR:-"/workspace"}"
COOKER_MENU_FILE="${COOKER_MENU_FILE:-"cooker-menu.json"}"

COOKER_SSTATE_OPT=""
if [ "${COOKER_USE_DL_CACHE=}" != "" ]; then
    COOKER_SSTATE_OPT="-s ${COOKER_SSTATE_CACHE_DIR}"
fi

COOKER_DL_OPT=""
if [ "${COOKER_USE_DL_CACHE=}" != "" ]; then
    COOKER_DL_OPT="-d ${COOKER_DLCACHE_DIR}"
fi

cd ~

if [[ ! -e ~/.cookerconfig ]]; then
    cooker init \
        -l ${COOKER_LAYERS_DIR} \
        -b ${COOKER_BUILD_DIR} \
        ${COOKER_SSTATE_OPT} \
        ${COOKER_DL_OPT} \
        ${COOKER_MENU_DIR}/${COOKER_MENU_FILE}
         
fi


case $1 in
    download)
        cooker update
        cooker generate
        cooker build -d
        ;;
    broil)
        cooker update
        cooker generate
        cooker build
        ;;
    *)
        echo "broiler.sh download|broil"
        echo "uses shell env overrides:"
        echo "\tCOOKER_BUILD_DIR"
        echo "\tCOOKER_LAYERS_DIR"
        echo "\tCOOKER_MENU_DIR"
        echo "\tCOOKER_MENU_FILE"
esac
