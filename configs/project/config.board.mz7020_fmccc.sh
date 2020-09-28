#!/bin/bash

KCONFIG_EDIT=${PETALINUX}/tools/common/petalinux/utils/petalinux-kconfig-edit
CONFIG_FILE=project-spec/configs/config

${KCONFIG_EDIT} -c ${CONFIG_FILE} -o CONFIG_SUBSYSTEM_HOSTNAME -v "\"mz7020-fmccc-2020-1\""
${KCONFIG_EDIT} -c ${CONFIG_FILE} -o CONFIG_YOCTO_MACHINE_NAME -v "\"mz7020-fmccc\""
${KCONFIG_EDIT} -c ${CONFIG_FILE} -o CONFIG_USER_LAYER_0 -v "\"\${PROOT}/project-spec/meta-avnet\""