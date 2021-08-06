require recipes-core/images/petalinux-image-common.inc

# append what's already defined by petalinux (build/conf/plnxtool.conf)
IMAGE_INSTALL_append_zynq = "\
        haveged \
        mtd-utils \
        packagegroup-core-boot \
        run-postinsts \
        tcf-agent \
        udev-extraconf \
"

IMAGE_INSTALL_append_zynqmp = "\
        bc \
        bonnie++ \
        coreutils \
        e2fsprogs \
        e2fsprogs-resize2fs \
        e2fsprogs-e2fsck \
        e2fsprogs-mke2fs \
        ethtool \
        fpga-manager-script \
        haveged \
        hdparm \
        hellopm \
        i2c-tools \
        i2c-tools-misc \
        iperf3 \
        kernel-modules \
        mtd-utils \
        nano \
        packagegroup-core-boot \
        packagegroup-core-ssh-dropbear \
        packagegroup-petalinux-lmsensors \
        parted \
        pmic-prog \
        run-postinsts \
        tcf-agent \
        udev-extraconf \
        usbutils \
        util-linux-mkfs \
        watchdog-init \
"

COMMON_FEATURES_append_zynqmp = "\
        debug-tweaks \
        hwcodecs \
        package-management \
        ssh-server-dropbear \
"

COMMON_FEATURES_append_zynq = "\
        hwcodecs \
        ssh-server-dropbear \
"

