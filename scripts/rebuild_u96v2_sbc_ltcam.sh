# ----------------------------------------------------------------------------
#
#        ** **        **          **  ****      **  **********  ********** ®
#       **   **        **        **   ** **     **  **              **
#      **     **        **      **    **  **    **  **              **
#     **       **        **    **     **   **   **  *********       **
#    **         **        **  **      **    **  **  **              **
#   **           **        ****       **     ** **  **              **
#  **  .........  **        **        **      ****  **********      **
#     ...........
#                                     Reach Further™
#
# ----------------------------------------------------------------------------
#
#  This design is the property of Avnet.  Publication of this
#  design is not authorized without written consent from Avnet.
#
#  Please direct any questions to the Ultra96 community support forum:
#     http://avnet.me/Ultra96_Forum
#
#  Product information is available at:
#     http://avnet.me/ultra96-v2
#
#  Disclaimer:
#     Avnet, Inc. makes no warranty for the use of this code or design.
#     This code is provided  "As Is". Avnet, Inc assumes no responsibility for
#     any errors, which may appear in this code, nor does it make a commitment
#     to update the information contained herein. Avnet, Inc specifically
#     disclaims any implied warranties of fitness for a particular purpose.
#                      Copyright(c) 2021 Avnet, Inc.
#                              All rights reserved.
#
# ----------------------------------------------------------------------------
#
#  Create Date:         Dec 20, 2021
#  Design Name:         Ultra96v2 LT Camera Mezzanine BSP
#  Module Name:         make_u96v2_sbc_ltcam.sh
#  Project Name:        Ultra96v2 LT Camera Mezzanine BSP
#  Target Devices:      Xilinx Zynq UltraScale+ 3EG
#  Hardware Boards:     Ultra96v2 Board + LT Camera Mezzanine
#
# ----------------------------------------------------------------------------

#!/bin/bash

# Stop the script whenever we had an error (non-zero returning function)
set -e

# MAIN_SCRIPT_FOLDER is the folder where this current script is
MAIN_SCRIPT_FOLDER=$(realpath $0 | xargs dirname)

FSBL_PROJECT_NAME=zynqmp_fsbl

HDL_PROJECT_NAME=base
HDL_BOARD_NAME=u96v2_sbc

ARCH="aarch64"
SOC="zynqMP"

PETALINUX_BOARD_FAMILY=u96v2
PETALINUX_BOARD_NAME=${HDL_BOARD_NAME}
# PETALINUX_BOARD_PROJECT=${HDL_PROJECT_NAME}
PETALINUX_BOARD_PROJECT=ltcam
PETALINUX_PROJECT_ROOT_NAME=${PETALINUX_BOARD_NAME}_${PETALINUX_BOARD_PROJECT}

PETALINUX_BUILD_IMAGE=avnet-image-full

KEEP_CACHE="true"
KEEP_WORK="false"
DEBUG="no"

#NO_BIT_OPTION can be set to 'yes' to generate a BOOT.BIN without bitstream
NO_BIT_OPTION='yes'

source ${MAIN_SCRIPT_FOLDER}/common.sh

create_petalinux_project_append()
{
    META_LT_CAMERA_URL="https://github.com/funshine/meta-lt-camera.git"
    META_LT_CAMERA_BRANCH="dev"
    echo "Fetching meta-lt-camera ..."
    rm -rf ./project-spec/meta-lt-camera
    git clone -b ${META_LT_CAMERA_BRANCH} ${META_LT_CAMERA_URL} project-spec/meta-lt-camera
}

rebuild_bsp ()
{
#   configure_boot_method

  # Build project
  echo -e "\nBuilding project...\n"

  # Sometimes the build fails because of fetch or setscene issues, so we try another time
  petalinux-build -c ${PETALINUX_BUILD_IMAGE} || petalinux-build -c ${PETALINUX_BUILD_IMAGE}

  if [ "$NO_BIT_OPTION" = "yes" ]
  then
    # Create boot image which does not contain the bistream image.
    petalinux-package --boot --fsbl images/linux/${FSBL_PROJECT_NAME}.elf --uboot --force
    cp images/linux/BOOT.BIN BOOT_${BOOT_METHOD}_NO_BIT.BIN
  fi

  # Create boot image which DOES contain the bistream image.
  petalinux-package --boot --fsbl ./images/linux/${FSBL_PROJECT_NAME}.elf --fpga ./images/linux/system.bit --uboot --force
  cp images/linux/BOOT.BIN BOOT_${BOOT_METHOD}${BOOT_SUFFIX}.BIN

  cp images/linux/image.ub image_${BOOT_METHOD}${BOOT_SUFFIX}.ub
  
  cp images/linux/boot.scr boot_${BOOT_METHOD}${BOOT_SUFFIX}.scr

  # save wic images, if any (don't output messages if not found)
  cp images/linux/*.wic . > /dev/null  2>&1 || true
}

verify_repositories
verify_environment
check_git_tag

build_hw_platform
# create_petalinux_project
PETALINUX_PROJECT_NAME=${PETALINUX_PROJECT_ROOT_NAME}_${PLNX_VER}
cd ${PETALINUX_PROJECTS_FOLDER}/${PETALINUX_PROJECT_NAME}
create_petalinux_project_append
# configure_petalinux_project

# BOOT_METHOD='INITRD'
# BOOT_SUFFIX='_MINIMAL'
# INITRAMFS_IMAGE='avnet-image-minimal'
# build_bsp

BOOT_METHOD='EXT4'
unset BOOT_SUFFIX
unset INITRAMFS_IMAGE
rebuild_bsp

# package_bsp