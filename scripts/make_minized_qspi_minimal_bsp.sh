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
#  Please direct any questions to the MiniZed community support forum:
#     http://avnet.me/minized_forum
# 
#  Product information is available at:
#     http://avnet.me/minized
# 
#  Disclaimer:
#     Avnet, Inc. makes no warranty for the use of this code or design.
#     This code is provided  "As Is". Avnet, Inc assumes no responsibility for
#     any errors, which may appear in this code, nor does it make a commitment
#     to update the information contained herein. Avnet, Inc specifically
#     disclaims any implied warranties of fitness for a particular purpose.
#                      Copyright(c) 2017 Avnet, Inc.
#                              All rights reserved.
# 
# ----------------------------------------------------------------------------
# 
#  Create Date:         Mar 26, 2016
#  Design Name:         MiniZed PetaLinux BSP Generator
#  Module Name:         make_minized_emmc_enhanced_bsp.sh
#  Project Name:        MiniZed PetaLinux BSP Generator
#  Target Devices:      Xilinx Zynq-7000
#  Hardware Boards:     MiniZed
# 
#  Tool versions:       Xilinx Vivado 2019.1
# 
#  Description:         Build Script for MiniZed eMMC Boot PetaLinux BSP
#                       This script builds the eMMC-only boot OS image
#                       The rootfs config contains features that do not
#                       fit in the QSPI-only boot OS image
# 
#  Dependencies:        None
#
#  Revision:            Sep 12, 2019: 1.00 Initial version
# 
# ----------------------------------------------------------------------------

#!/bin/bash

# Set global variables here.
APP_PETALINUX_INSTALL_PATH=/opt/petalinux-v2019.1-final
APP_VIVADO_INSTALL_PATH=/opt/Xilinx/Vivado/2019.1
PLNX_VER=2019_1
BUILD_BOOT_QSPI_OPTION=yes
BUILD_BOOT_EMMC_OPTION=no
BUILD_BOOT_EMMC_NO_BIT_OPTION=no



FSBL_PROJECT_NAME=zynq_fsbl
HDL_HARDWARE_NAME=minized_hw
HDL_PROJECT_NAME=minized_petalinux
HDL_PROJECTS_FOLDER=../../hdl/Projects
HDL_SCRIPTS_FOLDER=../../hdl/Scripts
PETALINUX_APPS_FOLDER=../../petalinux/apps
PETALINUX_CONFIGS_FOLDER=../../petalinux/configs
PETALINUX_PROJECTS_FOLDER=../../petalinux/projects
PETALINUX_SCRIPTS_FOLDER=../../petalinux/scripts
START_FOLDER=`pwd`
TFTP_HOST_FOLDER=/tftpboot

PLNX_BUILD_SUCCESS=-1

source_tools_settings ()
{
  # Source the tools settings scripts so that both Vivado and PetaLinux can 
  # be used throughout this build script.
  source ${APP_VIVADO_INSTALL_PATH}/settings64.sh
  source ${APP_PETALINUX_INSTALL_PATH}/settings.sh
}

# This function checks to see if any board specific device-tree is available 
# and, if so, installs it into the meta-user BSP recipes folder.
petalinux_project_configure_devicetree ()
{
  # Check to see if a device (usually related to the SOM) specific system-user
  # devicetree source file is available.  According to PetaLinux methodology,
  # the system-user.dtsi file is where all of the non-autogenerated devicetree
  # information is supposed to be included.  The benefit of using this 
  # approach over modifying system-conf.dtsi is that the petalinux-config tool
  # is designed to leave system-user.dtsi untouched in case you need to go 
  # back and configure your PetaLinux project further after this bulid 
  # automation has been applied.
  #
  # If available, overwrite the board specific top level devicetree source 
  # with the revision controlled source files.
  if [ -f ${START_FOLDER}/${PETALINUX_CONFIGS_FOLDER}/device-tree/system-user.dtsi.${HDL_BOARD_NAME} ]
    then
    echo " "
    echo "Overwriting system-user level devicetree source include file..."
    echo " "
    cp -rf ${START_FOLDER}/${PETALINUX_CONFIGS_FOLDER}/device-tree/system-user.dtsi.${HDL_BOARD_NAME} \
    ${START_FOLDER}/${PETALINUX_PROJECTS_FOLDER}/${PETALINUX_PROJECT_NAME}/project-spec/meta-user/recipes-bsp/device-tree/files/system-user.dtsi
  else
    echo " "
    echo "WARNING: No board specific devicetree file found, "
    echo "PetaLinux devicetree config is not touched for this build ..."
    echo " "
  fi
}

# This function checks to see if any user configuration is available for the
# kernel and, if so, sets up the meta-user kernel recipes folder and installs
# the user kernel configuration into that folder.
petalinux_project_configure_kernel ()
{
  # Check to see if a device (usually related to the SOM or reference design) 
  # specific kernel user configuration file is available.  
  #
  # If available, copy the kernel user configuration file to the meta-user
  # kernel recipes folder.
  if [ -f ${START_FOLDER}/${PETALINUX_CONFIGS_FOLDER}/kernel/user.cfg.${HDL_BOARD_NAME} ]
    then

    # Create the meta-user kernel recipes folder structure if it does not 
    # already exist (for a new PetaLinux project, it usually doesn't).
    if [ ! -d ${START_FOLDER}/${PETALINUX_PROJECTS_FOLDER}/${PETALINUX_PROJECT_NAME}/project-spec/meta-user/recipes-kernel ]
      then
      mkdir ${START_FOLDER}/${PETALINUX_PROJECTS_FOLDER}/${PETALINUX_PROJECT_NAME}/project-spec/meta-user/recipes-kernel
    fi
    if [ ! -d ${START_FOLDER}/${PETALINUX_PROJECTS_FOLDER}/${PETALINUX_PROJECT_NAME}/project-spec/meta-user/recipes-kernel/linux ]
      then
      mkdir ${START_FOLDER}/${PETALINUX_PROJECTS_FOLDER}/${PETALINUX_PROJECT_NAME}/project-spec/meta-user/recipes-kernel/linux
    fi
    if [ ! -d ${START_FOLDER}/${PETALINUX_PROJECTS_FOLDER}/${PETALINUX_PROJECT_NAME}/project-spec/meta-user/recipes-kernel/linux/linux-xlnx ]
      then
      mkdir ${START_FOLDER}/${PETALINUX_PROJECTS_FOLDER}/${PETALINUX_PROJECT_NAME}/project-spec/meta-user/recipes-kernel/linux/linux-xlnx
    fi

    # Copy the kernel user config over to the meta-user kernel recipe folder.
    echo " "
    echo "Overwriting kernel user configuration file..."
    echo " "
    cp -rf ${START_FOLDER}/${PETALINUX_CONFIGS_FOLDER}/kernel/user.cfg.${HDL_BOARD_NAME} \
    ${START_FOLDER}/${PETALINUX_PROJECTS_FOLDER}/${PETALINUX_PROJECT_NAME}/project-spec/meta-user/recipes-kernel/linux/linux-xlnx/user_${HDL_BOARD_NAME}.cfg
    
    # Create the kernel user config .bbappend file if it does not already exist.
    if [ ! -f ${START_FOLDER}/${PETALINUX_PROJECTS_FOLDER}/${PETALINUX_PROJECT_NAME}/project-spec/meta-user/recipes-kernel/linux/linux-xlnx_%.bbappend ]
      then
      echo "SRC_URI += \"file://user_${HDL_BOARD_NAME}.cfg\"" > ${START_FOLDER}/${PETALINUX_PROJECTS_FOLDER}/${PETALINUX_PROJECT_NAME}/project-spec/meta-user/recipes-kernel/linux/linux-xlnx_%.bbappend
      echo "" >> ${START_FOLDER}/${PETALINUX_PROJECTS_FOLDER}/${PETALINUX_PROJECT_NAME}/project-spec/meta-user/recipes-kernel/linux/linux-xlnx_%.bbappend
      echo "FILESEXTRAPATHS_prepend := \"\${THISDIR}/\${PN}:\"" >> ${START_FOLDER}/${PETALINUX_PROJECTS_FOLDER}/${PETALINUX_PROJECT_NAME}/project-spec/meta-user/recipes-kernel/linux/linux-xlnx_%.bbappend
    fi 
  else
    echo " "
    echo "WARNING: No board specific kernel user configuration files found, "
    echo "PetaLinux kernel user config recipe is not touched for this build ..."
    echo " "
  fi
}

# This function checks to see if any board specific configuration is available
# for the rootfs and, if so, installs the rootfs configuration into the 
# PetaLinux project configs folder.
petalinux_project_configure_rootfs ()
{
  # Check to see if a device (usually related to the SOM or reference design) 
  # specific rootfs configuration file is available.  
  #
  # If available, overwrite the board specific rootfs configuration file with
  # the revision controlled config file.
  if [ -f ${START_FOLDER}/${PETALINUX_CONFIGS_FOLDER}/rootfs/config.${PETALINUX_ROOTFS_NAME} ]
    then
    echo " "
    echo "Overwriting rootfs configuration file..."
    echo " "
    cp -rf ${START_FOLDER}/${PETALINUX_CONFIGS_FOLDER}/rootfs/config.${PETALINUX_ROOTFS_NAME} \
    ${START_FOLDER}/${PETALINUX_PROJECTS_FOLDER}/${PETALINUX_PROJECT_NAME}/project-spec/configs/rootfs_config
  else
    echo " "
    echo "WARNING: No board specific rootfs configuration files found, "
    echo "PetaLinux rootfs config is not touched for this build ..."
    echo " "
  fi

  if [ -d ${START_FOLDER}/${PETALINUX_CONFIGS_FOLDER}/meta-user/${PETALINUX_ROOTFS_NAME} ]
    then
    # Copy the meta-user rootfs folder to the PetaLinux project.
    echo " "
    echo "Adding custom rootfs ..."
    echo " "
    cp -rf ${START_FOLDER}/${PETALINUX_CONFIGS_FOLDER}/meta-user/${PETALINUX_ROOTFS_NAME}/* \
    ${START_FOLDER}/${PETALINUX_PROJECTS_FOLDER}/${PETALINUX_PROJECT_NAME}/project-spec/meta-user/.
    # If the meta-user folder does not exist, then look for a bbappend file
    # Not every PetaLinux scripted build will have a custom rootfs with user applications, etc. and will instead 
    # use a bbappend file to specify PetaLinux-supplied applications
  elif [ -f ${START_FOLDER}/${PETALINUX_CONFIGS_FOLDER}/rootfs/bbappend.${PETALINUX_ROOTFS_NAME} ]
    then
    echo " "
    echo "Overwriting rootfs bbappend file..."
    echo " "
    cp -rf ${START_FOLDER}/${PETALINUX_CONFIGS_FOLDER}/rootfs/bbappend.${PETALINUX_ROOTFS_NAME} \
    ${START_FOLDER}/${PETALINUX_PROJECTS_FOLDER}/${PETALINUX_PROJECT_NAME}/project-spec/meta-user/recipes-core/images/petalinux-image.bbappend
  else
    echo " "
    echo "WARNING: No custom rootfs found and no rootfs bbappend files found, "
    echo "PetaLinux rootfs is not touched for this build ..."
    echo " "
  fi
}

petalinux_project_restore_boot_config ()
{
  # Restore original PetaLinux project config. Don't forget that the
  # petalinux_project_save_boot_config () should have been called at some
  # point before this function gets called, otherwise there probably is
  # nothing there to restore.
  echo " "
  echo "Restoring original PetaLinux project config ..."
  echo " "
  cd ${START_FOLDER}/${PETALINUX_PROJECTS_FOLDER}/${PETALINUX_PROJECT_NAME}/project-spec/configs/
  cp config.orig config
  cd ${START_FOLDER}/${PETALINUX_PROJECTS_FOLDER}/${PETALINUX_PROJECT_NAME}

  # Restore original U-Boot top level configuration.
  echo " "
  echo "Restoring original U-Boot top level configuration..."
  echo " "
  cd ${START_FOLDER}/${PETALINUX_PROJECTS_FOLDER}/${PETALINUX_PROJECT_NAME}/project-spec/meta-user/recipes-bsp/u-boot/files/
  cp platform-top.h.orig platform-top.h
  cd ${START_FOLDER}/${PETALINUX_PROJECTS_FOLDER}/${PETALINUX_PROJECT_NAME}
}

petalinux_project_save_boot_config ()
{
  # Save original PetaLinux project config.
  echo " "
  echo "Saving original PetaLinux project config ..."
  echo " "
  cd ${START_FOLDER}/${PETALINUX_PROJECTS_FOLDER}/${PETALINUX_PROJECT_NAME}/project-spec/configs/
  cp config config.orig
  cd ${START_FOLDER}/${PETALINUX_PROJECTS_FOLDER}/${PETALINUX_PROJECT_NAME}

  # Save original U-Boot top level configuration.
  echo " "
  echo "Saving original U-Boot top level configuration..."
  echo " "
  cd ${START_FOLDER}/${PETALINUX_PROJECTS_FOLDER}/${PETALINUX_PROJECT_NAME}/project-spec/meta-user/recipes-bsp/u-boot/files/
  cp platform-top.h platform-top.h.orig
  cd ${START_FOLDER}/${PETALINUX_PROJECTS_FOLDER}/${PETALINUX_PROJECT_NAME}
}

petalinux_project_set_boot_config_qspi ()
{ 
  # Change PetaLinux project config to boot from QSPI.
  echo " "
  echo "Patching project config for QSPI boot support..."
  echo " "
  cd ${START_FOLDER}/${PETALINUX_PROJECTS_FOLDER}/${PETALINUX_PROJECT_NAME}/project-spec/configs
  patch < ${START_FOLDER}/${PETALINUX_CONFIGS_FOLDER}/project/config.qspi_boot.patch
  cd ${START_FOLDER}/${PETALINUX_PROJECTS_FOLDER}/${PETALINUX_PROJECT_NAME}
  
  # Apply the meta-user level BSP platform-top.h file to establish a baseline
  # override for anything that was directly generated by petalinux-config by
  # overwriting the file found in the following folder with the board specific
  # revision controlled version:
  #  
  # project-spec/meta-user/recipes-bsp/u-boot/files/platform-top.h
  echo " "
  echo "Overriding meta-user BSP platform-top.h to add QSPI boot support in U-Boot ..."
  echo " "
  cd ${START_FOLDER}/${PETALINUX_PROJECTS_FOLDER}/${PETALINUX_PROJECT_NAME}/project-spec/meta-user/recipes-bsp/u-boot/files/
  cp -rf ${START_FOLDER}/${PETALINUX_CONFIGS_FOLDER}/u-boot/platform-top.h.minized_qspi_boot ./platform-top.h
  cd ${START_FOLDER}/${PETALINUX_PROJECTS_FOLDER}/${PETALINUX_PROJECT_NAME}
}

petalinux_project_set_boot_config_emmc ()
{ 
  # Change PetaLinux project config to boot indirect from eMMC (via QSPI).
  echo " "
  echo "Patching project config for eMMC boot support..."
  echo " "
  cd ${START_FOLDER}/${PETALINUX_PROJECTS_FOLDER}/${PETALINUX_PROJECT_NAME}/project-spec/configs
  patch < ${START_FOLDER}/${PETALINUX_CONFIGS_FOLDER}/project/config.emmc_boot.patch
  cd ${START_FOLDER}/${PETALINUX_PROJECTS_FOLDER}/${PETALINUX_PROJECT_NAME}

  # Add support for QSPI + eMMC boot to U-Boot environment configuration.
  echo " "
  echo "Applying patch to add QSPI + eMMC boot support in U-Boot ..."
  echo " "
  cd ${START_FOLDER}/${PETALINUX_PROJECTS_FOLDER}/${PETALINUX_PROJECT_NAME}/project-spec/meta-user/recipes-bsp/u-boot/files/
  cp -rf ${START_FOLDER}/${PETALINUX_CONFIGS_FOLDER}/u-boot/platform-top.h.minized_emmc_boot ./platform-top.h
  cd ${START_FOLDER}/${PETALINUX_PROJECTS_FOLDER}/${PETALINUX_PROJECT_NAME}
}

petalinux_project_set_boot_config_emmc_no_bit ()
{ 
  # Change PetaLinux project config to boot from eMMC (via QSPI).
  echo " "
  echo "Patching project config for eMMC boot support..."
  echo " "
  cd ${START_FOLDER}/${PETALINUX_PROJECTS_FOLDER}/${PETALINUX_PROJECT_NAME}/project-spec/configs
  patch < ${START_FOLDER}/${PETALINUX_CONFIGS_FOLDER}/project/config.emmc_boot.patch
  cd ${START_FOLDER}/${PETALINUX_PROJECTS_FOLDER}/${PETALINUX_PROJECT_NAME}

  # Add support for eMMC commands to U-Boot top level configuration which
  # allows for bistream to be loaded from eMMC instead of BOOT.BIN in QSPI
  # flash.
  echo " "
  echo "Applying patch to add eMMC bitstream load support in U-Boot ..."
  echo " "
  cd ${START_FOLDER}/${PETALINUX_PROJECTS_FOLDER}/${PETALINUX_PROJECT_NAME}/project-spec/meta-user/recipes-bsp/u-boot/files/
  cp -rf ${START_FOLDER}/${PETALINUX_CONFIGS_FOLDER}/u-boot/platform-top.h.minized_emmc_boot_no_bit ./platform-top.h
  cd ${START_FOLDER}/${PETALINUX_PROJECTS_FOLDER}/${PETALINUX_PROJECT_NAME}
}









































































create_petalinux_bsp ()
{ 
  # This function is responsible for creating a PetaLinux BSP around the
  # hardware platform specificed in HDL_PROJECT_NAME variable and build
  # the PetaLinux project within the folder specified by the 
  # PETALINUX_PROJECT_NAME variable.
  #
  # When complete, the BSP should boot from SD card by default.

  # Check to see if the PetaLinux projects folder even exists because when
  # you clone the source tree from Avnet Github, the projects folder is not
  # part of that tree.
  if [ ! -d ${START_FOLDER}/${PETALINUX_PROJECTS_FOLDER} ]; then
    # Create the PetaLinux projects folder.
    mkdir ${START_FOLDER}/${PETALINUX_PROJECTS_FOLDER}
  fi

  # Change to PetaLinux projects folder.
  cd ${START_FOLDER}/${PETALINUX_PROJECTS_FOLDER}

  # Create the PetaLinux project.
  petalinux-create --type project --template zynq --name ${PETALINUX_PROJECT_NAME}

  # Create the hardware definition folder.
  mkdir -p ${START_FOLDER}/${PETALINUX_PROJECTS_FOLDER}/${PETALINUX_PROJECT_NAME}/hw_platform

  # Import the hardware definition files and hardware platform bitstream from
  # implemented system products folder.
  cd ${START_FOLDER}/${HDL_PROJECTS_FOLDER}

  echo " "
  echo "Importing hardware definition ${HDL_BOARD_NAME}.dsa from impl_1 folder ..."
  echo " "

#TC  cp -f ${HDL_PROJECT_NAME}/${HDL_BOARD_NAME}_${PLNX_VER}/${HDL_PROJECT_NAME}.runs/impl_1/${HDL_PROJECT_NAME}_wrapper.sysdef \
#TC  ${START_FOLDER}/${PETALINUX_PROJECTS_FOLDER}/${PETALINUX_PROJECT_NAME}/hw_platform/${HDL_HARDWARE_NAME}.hdf

  cp -f ${HDL_PROJECT_NAME}/${HDL_BOARD_NAME}_${PLNX_VER}/${HDL_BOARD_NAME}.dsa \
  ${START_FOLDER}/${PETALINUX_PROJECTS_FOLDER}/${PETALINUX_PROJECT_NAME}/hw_platform/.


  echo " "
  echo "Importing hardware bitstream ${HDL_BOARD_NAME}_wrapper.bit from impl_1 folder ..."
  echo " "

#TC  cp -f ${HDL_PROJECT_NAME}/${HDL_BOARD_NAME}_${PLNX_VER}/${HDL_PROJECT_NAME}.runs/impl_1/${HDL_PROJECT_NAME}_wrapper.bit \
#TC  ${START_FOLDER}/${PETALINUX_PROJECTS_FOLDER}/${PETALINUX_PROJECT_NAME}/hw_platform/system_wrapper.bit

  cp -f ${HDL_PROJECT_NAME}/${HDL_BOARD_NAME}_${PLNX_VER}/${HDL_BOARD_NAME}.runs/impl_1/${HDL_BOARD_NAME}_wrapper.bit \
  ${START_FOLDER}/${PETALINUX_PROJECTS_FOLDER}/${PETALINUX_PROJECT_NAME}/hw_platform/system_wrapper.bit

  # Change directories to the hardware definition folder for the PetaLinux
  # project, at this point the .hdf file must be located in this folder 
  # for the petalinux-config step to be successful.
  cd ${START_FOLDER}/${PETALINUX_PROJECTS_FOLDER}/${PETALINUX_PROJECT_NAME}

  # Import the hardware description into the PetaLinux project.
  petalinux-config --silentconfig --get-hw-description=./hw_platform/ -p ${START_FOLDER}/${PETALINUX_PROJECTS_FOLDER}/${PETALINUX_PROJECT_NAME}
 
  # DEBUG
  echo "Compare project-spec/configs/config file to ${PETALINUX_CONFIGS_FOLDER}/project/config.${HDL_BOARD_NAME}.patch file"
  #read -p "Press ENTER to continue" 
  read -t 10 -p "Pause here for 10 seconds"

  
  # Overwrite the PetaLinux project config with some sort of revision 
  # controlled source file.
  # 
  # If a patch is available, then the patch is preferred to be used since you
  # won't unintentionally affect as many pieces of the project configuration.
  #
  # If a patch is not available, but an entire board specific configuration is 
  # available, then that has second preference but you can wipe out some
  # project configuration attributes this way.
  #
  # If neither of those are present, use the generic one by default.
  if [ -f ${START_FOLDER}/${PETALINUX_CONFIGS_FOLDER}/project/config.${PETALINUX_ROOTFS_NAME}.patch ] 
    then
    echo " "
    echo "Patching PetaLinux project config ..."
    echo " "
    cd ${START_FOLDER}/${PETALINUX_PROJECTS_FOLDER}/${PETALINUX_PROJECT_NAME}/project-spec/configs/
    patch < ${START_FOLDER}/${PETALINUX_CONFIGS_FOLDER}/project/config.${PETALINUX_ROOTFS_NAME}.patch
    cd ${START_FOLDER}/${PETALINUX_PROJECTS_FOLDER}/${PETALINUX_PROJECT_NAME}
  #read -p "Press ENTER to continue" 
  read -t 10 -p "Pause here for 10 seconds"

  elif [ -f ${START_FOLDER}/${PETALINUX_CONFIGS_FOLDER}/project/config.${PETALINUX_ROOTFS_NAME} ] 
    then
    echo " "
    echo "Overwriting PetaLinux project config ..."
    echo " "
    cp -rf ${START_FOLDER}/${PETALINUX_CONFIGS_FOLDER}/project/config.${PETALINUX_ROOTFS_NAME} \
    ${START_FOLDER}/${PETALINUX_PROJECTS_FOLDER}/${PETALINUX_PROJECT_NAME}/project-spec/configs/config
  elif [ -f ${START_FOLDER}/${PETALINUX_CONFIGS_FOLDER}/project/config.generic ]
    then
    echo " "
    echo "WARNING: Using generic PetaLinux project config ..."
    echo " "
    cp -rf ${START_FOLDER}/${PETALINUX_CONFIGS_FOLDER}/project/config.generic \
    ${START_FOLDER}/${PETALINUX_PROJECTS_FOLDER}/${PETALINUX_PROJECT_NAME}/project-spec/configs/config    
  else
    echo " "
    echo "WARNING: No board specific PetaLinux project configuration files found, "
    echo "PetaLinux project config is not touched for this build ..."
    echo " "
  fi
  echo "Compare project-spec/configs/config file to ${PETALINUX_CONFIGS_FOLDER}/project/config.${PETALINUX_ROOTFS_NAME}.patch file"
  #read -p "Press ENTER to continue" 
  read -t 10 -p "Pause here for 10 seconds"
  
  
  # Configure the device-tree.
  petalinux_project_configure_devicetree

  # Configure the root file system.
  petalinux_project_configure_rootfs

  # Configure the kernel.
  petalinux_project_configure_kernel

  # Prepare to modify project configurations.
  petalinux_project_save_boot_config

  # Do an initial project clean
  petalinux-build -x mrproper

  # DEBUG
  echo "Stop here and check for WARNING messages."
  #read -p "Press ENTER to continue."
  read -t 10 -p "Pause here for 10 seconds"

  # If the QSPI boot option is set, then perform the steps needed to build 
  # BOOT.BIN for booting from QSPI.
  if [ "$BUILD_BOOT_QSPI_OPTION" == "yes" ]
  then
    # Restore project configurations and wipe out any changes made for special boot options.
    petalinux_project_restore_boot_config

    # Modify the project configuration for QSPI boot.
    petalinux_project_set_boot_config_qspi

    # DEBUG
    echo "Stop here and go check the platform-top.h file and make sure it is set for QSPI boot"
    read -p "Press ENTER to continue."
    #read -t 10 -p "Pause here for 10 seconds"

    PLNX_BUILD_SUCCESS=-1

    echo "Entering PetaLinux build loop.  Stay here until Linux image is built successfully"
    while [ $PLNX_BUILD_SUCCESS -ne 0 ];
    do
      # Make sure that intermediary files get cleaned up.  This will also force
      # the rootfs to get rebuilt and generate a new image.ub file.
      petalinux-build -x distclean

      # Build PetaLinux project.
      petalinux-build 
      
      PLNX_BUILD_SUCCESS=$?
    done

    # Create boot image.  The kernel "--offset" must match the "kernelstart="  defined in the u-boot platform-top.h source file.
    petalinux-package --boot --fsbl images/linux/${FSBL_PROJECT_NAME}.elf --fpga ./images/linux/system.bit --uboot --kernel --offset 0x1E0000 --force

    # Copy the boot.bin file and name the new file BOOT_QSPI.bin
    cp ${START_FOLDER}/${PETALINUX_PROJECTS_FOLDER}/${PETALINUX_PROJECT_NAME}/images/linux/BOOT.BIN \
    ${START_FOLDER}/${PETALINUX_PROJECTS_FOLDER}/${PETALINUX_PROJECT_NAME}/BOOT_QSPI.bin

    # Copy the u-boot.elf file and name the new file u-boot_QSPI.elf
    cp ${START_FOLDER}/${PETALINUX_PROJECTS_FOLDER}/${PETALINUX_PROJECT_NAME}/images/linux/u-boot.elf \
    ${START_FOLDER}/${PETALINUX_PROJECTS_FOLDER}/${PETALINUX_PROJECT_NAME}/u-boot_QSPI.elf
    
    # Create script to program the QSPI Flash
    echo "#!/bin/sh" > program_boot_qspi.sh
    echo "program_flash -f ./BOOT_QSPI.bin -offset 0 -flash_type qspi_single -fsbl ./images/linux/${FSBL_PROJECT_NAME}.elf"  >> program_boot_qspi.sh
    chmod 777 ./program_boot_qspi.sh
  fi

  # If the EMMC boot option is set, then perform the steps needed to build 
  # BOOT.BIN for booting from QSPI + eMMC.
  if [ "$BUILD_BOOT_EMMC_OPTION" == "yes" ]
  then
    # Restore project configurations and wipe out any changes made for special boot options.
    petalinux_project_restore_boot_config

    # Modify the project configuration for EMMC boot.
    petalinux_project_set_boot_config_emmc

    # DEBUG
    echo "Stop here and go check the platform-top.h file and make sure it is set for eMMC boot"
    read -p "Press ENTER to continue."
    #read -t 10 -p "Pause here for 10 seconds"
    
    PLNX_BUILD_SUCCESS=-1

    echo "Entering PetaLinux build loop.  Stay here until Linux image is built successfully"
    while [ $PLNX_BUILD_SUCCESS -ne 0 ];
    do
      # Make sure that intermediary files get cleaned up.  This will also force
      # the rootfs to get rebuilt and generate a new image.ub file.
      petalinux-build -x distclean

      # Build PetaLinux project.
      petalinux-build 
      
      PLNX_BUILD_SUCCESS=$?
    done

    # Create boot image.
    petalinux-package --boot --fsbl images/linux/${FSBL_PROJECT_NAME}.elf --fpga ./images/linux/system.bit --uboot --force

    # Copy the boot.bin file and name the new file BOOT_EMMC.bin
    cp ${START_FOLDER}/${PETALINUX_PROJECTS_FOLDER}/${PETALINUX_PROJECT_NAME}/images/linux/BOOT.BIN \
    ${START_FOLDER}/${PETALINUX_PROJECTS_FOLDER}/${PETALINUX_PROJECT_NAME}/BOOT_EMMC.bin

    # Copy the u-boot.elf file and name the new file u-boot_EMMC.elf
    cp ${START_FOLDER}/${PETALINUX_PROJECTS_FOLDER}/${PETALINUX_PROJECT_NAME}/images/linux/u-boot.elf \
    ${START_FOLDER}/${PETALINUX_PROJECTS_FOLDER}/${PETALINUX_PROJECT_NAME}/u-boot_EMMC.elf
    
    # Create script to program the QSPI Flash
    echo "#!/bin/sh" > program_boot_emmc_indirect.sh
    echo "program_flash -f ./BOOT_EMMC.bin  -offset 0 -flash_type qspi_single -fsbl ./images/linux/${FSBL_PROJECT_NAME}.elf"  >> program_boot_emmc_indirect.sh
    chmod 777 ./program_boot_emmc_indirect.sh
  fi

  
  
  
  
  
  
  # If the EMMC boot no bit option is set, then perform the steps needed to build 
  # BOOT.BIN for booting from QSPI + eMMC with the bistream loaded from eMMC
  # instead of from BOOT.BIN image in QSPI.
  if [ "$BUILD_BOOT_EMMC_NO_BIT_OPTION" == "yes" ]
  then
    # Restore project configurations and wipe out any changes made for special boot options.
    petalinux_project_restore_boot_config

    # Modify the project configuration for EMMC boot.
    petalinux_project_set_boot_config_emmc_no_bit

    # DEBUG
    echo "Stop here and go check the platform-top.h and config files and make sure they are set for eMMC NO BIT boot"
    read -p "Press enter to continue"
    #read -t 10 -p "Pause here for 10 seconds"
  
    PLNX_BUILD_SUCCESS=-1

    echo "Entering PetaLinux build loop.  Stay here until Linux image is built successfully"
    while [ $PLNX_BUILD_SUCCESS -ne 0 ];
    do
      # Make sure that intermediary files get cleaned up.  This will also force
      # the rootfs to get rebuilt and generate a new image.ub file.
      petalinux-build -x distclean

      # Build PetaLinux project.
      petalinux-build 
      
      PLNX_BUILD_SUCCESS=$?
    done

    # Create boot image which does not contain the bistream image.
    petalinux-package --boot --fsbl images/linux/${FSBL_PROJECT_NAME}.elf --uboot --force

    # Copy the boot.bin file and name the new file BOOT_EMMC_No_Bit.BIN
    cp ${START_FOLDER}/${PETALINUX_PROJECTS_FOLDER}/${PETALINUX_PROJECT_NAME}/images/linux/BOOT.BIN \
    ${START_FOLDER}/${PETALINUX_PROJECTS_FOLDER}/${PETALINUX_PROJECT_NAME}/BOOT_EMMC_No_Bit.BIN

    # Copy the u-boot.elf file and name the new file u-boot_EMMC_No_Bit.elf
    cp ${START_FOLDER}/${PETALINUX_PROJECTS_FOLDER}/${PETALINUX_PROJECT_NAME}/images/linux/u-boot.elf \
    ${START_FOLDER}/${PETALINUX_PROJECTS_FOLDER}/${PETALINUX_PROJECT_NAME}/u-boot_EMMC_No_Bit.elf

    # Create a temporary Vivado TCL script which take the standard bitstream 
    # file format and modify it to allow u-boot to load it into the 
    # programmable logic on the Zynq device via PCAP interface.
    echo "write_cfgmem -format bin -interface spix1 -loadbit \"up 0x0 ./images/linux/system.bit\" -force images/linux/system.bit.bin" > swap_bits.tcl
    
    # Launch vivado in batch mode to clean output products from the hardware platform.
    vivado -mode batch -source swap_bits.tcl

    # Copy the bit-swapped bitstream to the PetaLinux project folder
    cp ${START_FOLDER}/${PETALINUX_PROJECTS_FOLDER}/${PETALINUX_PROJECT_NAME}/images/linux/system.bit.bin \
    ${START_FOLDER}/${PETALINUX_PROJECTS_FOLDER}/${PETALINUX_PROJECT_NAME}/.

    # Remove the temporary Vivado script.
    rm -f swap_bits.tcl
  fi















































































































 



































































  # Change to HDL scripts folder.
  cd ${START_FOLDER}/${HDL_SCRIPTS_FOLDER}

  # Clean the hardware project output products using the HDL TCL scripts.
  echo "set argv [list board=${HDL_BOARD_NAME}_${PLNX_VER} project=${HDL_PROJECT_NAME} clean=yes jtag=yes version_override=yes]" > cleanup.tcl
  echo "set argc [llength \$argv]" >> cleanup.tcl
  echo "source ./make.tcl -notrace" >> cleanup.tcl

  # Launch vivado in batch mode to clean output products from the hardware platform.
  # DEBUG !!!Uncomment the next line before public release!!!
  #vivado -mode batch -source cleanup.tcl

  # Change to PetaLinux project folder.
  cd ${START_FOLDER}/${PETALINUX_PROJECTS_FOLDER}/${PETALINUX_PROJECT_NAME}/

  # Package the bitstream within the PetaLinux pre-built folder.
  petalinux-package --prebuilt --fpga ./images/linux/system.bit --force

  # Package the Linux image within the PetaLinux pre-built folder.
  #petalinux-package --prebuilt -a ./images/linux/image.ub:images/. --force




  # Rename the pre-built bitstream file to download.bit so that the default 
  # format for the petalinux-boot command over jtag will not need the bit file 
  # specified explicitly.
  mv -f pre-built/linux/implementation/system.bit \
  pre-built/linux/implementation/download.bit

  # Create script to copy the image files to tftpboot folder and launch Petalinux JTAG boot
  # This will boot to u-boot, then the user can use tftpboot (run netboot) to boot the Linux image
  echo "#!/bin/sh" > cptftp_jtag.sh
  echo "rm -f ${TFTP_HOST_FOLDER}/*"  >> cptftp_jtag.sh
  echo "cp -f ./*.bin ${TFTP_HOST_FOLDER}/." >> cptftp_jtag.sh
  echo "cp -f ./images/linux/* ${TFTP_HOST_FOLDER}/." >> cptftp_jtag.sh
  echo "petalinux-boot --jtag --fpga --bitstream ./images/linux/system.bit --u-boot" >> cptftp_jtag.sh
  chmod 777 ./cptftp_jtag.sh
  
  # Create script to boot the Linux image via Petalinux JTAG boot
  echo "#!/bin/sh" > boot_jtag.sh
  echo "petalinux-boot --jtag --kernel --fpga --bitstream ./images/linux/system.bit --verbose" >> boot_jtag.sh
  chmod 777 ./boot_jtag.sh  
  
  # Change to PetaLinux projects folder.
  cd ${START_FOLDER}/${PETALINUX_PROJECTS_FOLDER}/

  # Copy the image.ub to the pre-built images folder.
  cp ${START_FOLDER}/${PETALINUX_PROJECTS_FOLDER}/${PETALINUX_PROJECT_NAME}/images/linux/image.ub \
  ${START_FOLDER}/${PETALINUX_PROJECTS_FOLDER}/${PETALINUX_PROJECT_NAME}/pre-built/linux/images/

  # If the BOOT_QSPI_OPTION is set, copy the BOOT_QSPI.BIN to the 
  # pre-built images folder.
  if [ "$BUILD_BOOT_QSPI_OPTION" == "yes" ]
  then
    cp ${START_FOLDER}/${PETALINUX_PROJECTS_FOLDER}/${PETALINUX_PROJECT_NAME}/BOOT_QSPI.bin \
    ${START_FOLDER}/${PETALINUX_PROJECTS_FOLDER}/${PETALINUX_PROJECT_NAME}/pre-built/linux/images/

    # Also copy the u-boot_QSPI.elf file to the pre-build images folder.
    cp ${START_FOLDER}/${PETALINUX_PROJECTS_FOLDER}/${PETALINUX_PROJECT_NAME}/u-boot_QSPI.elf \
    ${START_FOLDER}/${PETALINUX_PROJECTS_FOLDER}/${PETALINUX_PROJECT_NAME}/pre-built/linux/images/
  fi

  # If the BOOT_EMMC_OPTION is set, copy the BOOT_EMMC.BIN to the 
  # pre-built images folder.
  if [ "$BUILD_BOOT_EMMC_OPTION" == "yes" ]
  then
    cp ${START_FOLDER}/${PETALINUX_PROJECTS_FOLDER}/${PETALINUX_PROJECT_NAME}/BOOT_EMMC.bin \
    ${START_FOLDER}/${PETALINUX_PROJECTS_FOLDER}/${PETALINUX_PROJECT_NAME}/pre-built/linux/images/

    # Also copy the u-boot_EMMC.elf file to the pre-build images folder.
    cp ${START_FOLDER}/${PETALINUX_PROJECTS_FOLDER}/${PETALINUX_PROJECT_NAME}/u-boot_EMMC.elf \
    ${START_FOLDER}/${PETALINUX_PROJECTS_FOLDER}/${PETALINUX_PROJECT_NAME}/pre-built/linux/images/
  fi

  # If the BOOT_EMMC_NO_BIT_OPTION is set, copy the BOOT_EMMC_No_Bit.BIN and 
  # the system.bit.bin files into the pre-built images folder.
  if [ "$BUILD_BOOT_EMMC_NO_BIT_OPTION" == "yes" ]
  then
    cp ${START_FOLDER}/${PETALINUX_PROJECTS_FOLDER}/${PETALINUX_PROJECT_NAME}/BOOT_EMMC_No_Bit.BIN \
    ${START_FOLDER}/${PETALINUX_PROJECTS_FOLDER}/${PETALINUX_PROJECT_NAME}/pre-built/linux/images/

    cp ${START_FOLDER}/${PETALINUX_PROJECTS_FOLDER}/${PETALINUX_PROJECT_NAME}/system.bit.bin \
    ${START_FOLDER}/${PETALINUX_PROJECTS_FOLDER}/${PETALINUX_PROJECT_NAME}/pre-built/linux/images/

    # Also copy the u-boot_EMMC_No_Bit.elf file to the pre-build images folder.
    cp ${START_FOLDER}/${PETALINUX_PROJECTS_FOLDER}/${PETALINUX_PROJECT_NAME}/u-boot_EMMC_No_Bit.elf \
    ${START_FOLDER}/${PETALINUX_PROJECTS_FOLDER}/${PETALINUX_PROJECT_NAME}/pre-built/linux/images/
  fi













































  # Package the hardware source into a BSP package output.
  petalinux-package --bsp -p ${PETALINUX_PROJECT_NAME} \
  --hwsource ${START_FOLDER}/${HDL_PROJECTS_FOLDER}/${HDL_PROJECT_NAME}/${HDL_BOARD_NAME}_${PLNX_VER}/ \
  --output ${PETALINUX_PROJECT_NAME} --force

  # Change to PetaLinux scripts folder.
  cd ${START_FOLDER}/${PETALINUX_SCRIPTS_FOLDER}
}

build_hw_platform ()
{
  # Change to HDL projects folder.
  cd ${START_FOLDER}/${HDL_PROJECTS_FOLDER}

  # Check to see if the Vivado hardware project has not been built.  
  # If it hasn't then build it now.  
  # If it has then fall through and build the PetaLinux BSP
#TC  if [ ! -e ${HDL_PROJECT_NAME}/${HDL_BOARD_NAME}_${PLNX_VER}/${HDL_PROJECT_NAME}.runs/impl_1/${HDL_PROJECT_NAME}_wrapper.sysdef ]
  if [ ! -e ${HDL_PROJECT_NAME}/${HDL_BOARD_NAME}_${PLNX_VER}/${HDL_BOARD_NAME}.runs/impl_1/${HDL_BOARD_NAME}_wrapper.sysdef ]
  then
#TC    ls -al ${HDL_PROJECT_NAME}/${HDL_BOARD_NAME}_${PLNX_VER}/${HDL_PROJECT_NAME}.runs/impl_1/
    ls -al ${HDL_PROJECT_NAME}/${HDL_BOARD_NAME}_${PLNX_VER}/${HDL_BOARD_NAME}.runs/impl_1/
    echo "No built Vivado HW project ${HDL_PROJECT_NAME}/${HDL_BOARD_NAME}_${PLNX_VER} found."
    echo "Will build the hardware platform now."
    read -t 5 -p "Pause here for 5 seconds"
    echo " "
    
    # Change to HDL scripts folder.
    cd ${START_FOLDER}/${HDL_SCRIPTS_FOLDER}
    # Launch vivado in batch mode to build hardware platforms for the selected target boards.
    vivado -mode batch -source make_${HDL_PROJECT_NAME}.tcl
  else
    echo "Found Vivado HW project ${HDL_PROJECT_NAME}/${HDL_BOARD_NAME}_${PLNX_VER}."
    echo "Will build the PetaLinux BSP now."
    read -t 5 -p "Pause here for 5 seconds"
    echo " "
  
  fi
}

# This function is responsible for first creating all of the hardware
# platforms needed for generating PetaLinux BSPs and once the hardware
# platforms are ready, they can be specificed in HDL_BOARD_NAME variable 
# before the call to create_petalinux_bsp.
#
# Once the PetaLinux BSP creation is complete, a BSP package file with the
# name specified in the PETALINUX_PROJECT_NAME variable can be distributed
# for use to others.
#
# NOTE:  If there is more than one hardware platform to be built, they will
#        all be built before any PetaLinux projects are created.  If you
#        are looking to save some time and only build for a specific target
#        be sure to comment out the other build targets in the 
#        make_<platform>.tcl hardware platform automation script AND comment
#        out the other BSP automated projects below otherwise, everything
#        will build which can take a very long time if you have multiple
#        hardware platforms and BSP projects defined.
main_make_function ()
{
  #
  # Create the hardware platform (if necessary) 
  # and build the PetaLinux BSP for the PZ7010_FMC2 target.
  #
  HDL_BOARD_NAME=MINIZED
  PETALINUX_PROJECT_NAME=minized_qspi_minimal_${PLNX_VER}
  PETALINUX_ROOTFS_NAME=minized_qspi_minimal
  build_hw_platform
  create_petalinux_bsp

}

# First source any tools scripts to setup the environment needed to call both
# PetaLinux and Vivado from this make script.
source_tools_settings

# Call the main_make_function declared above to start building everything.
main_make_function


