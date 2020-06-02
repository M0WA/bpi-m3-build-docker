#!/bin/bash

FS_MOUNTPOINT=/mnt/bpi-image

function make_uboot {
	if [[ ! -d ${UBOOT_CHECKOUTDIR}/.git ]]; then
		git clone ${UBOOT_REPOSITORY} ${UBOOT_CHECKOUTDIR}
	fi
	cd ${UBOOT_CHECKOUTDIR}
	make ${PARALLEL} ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- Sinovoip_BPI_M3_defconfig
	make ${PARALLEL} ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf-
	dd if=${UBOOT_CHECKOUTDIR}/u-boot-sunxi-with-spl.bin of=${IMAGEDEV} bs=1024 seek=8
	mkdir -p ${FS_MOUNTPOINT}/boot
	mkimage -A arm -O linux -T script -C none -a 0 -e 0 -n "bpi-m3-uboot" -d /root/boot.cmd ${FS_MOUNTPOINT}/boot/boot.scr
}

function make_kernel {
	if [[ ! -d ${LINUX_CHECKOUTDIR}/.git ]]; then
		git clone --branch ${LINUX_TAGNAME} ${LINUX_REPOSITORY} ${LINUX_CHECKOUTDIR}
		cd ${LINUX_CHECKOUTDIR}
		git checkout -b BPI-M3
	else
		cd ${LINUX_CHECKOUTDIR}
	fi
	cp ${LINUX_CHECKOUTDIR}/arch/arm/configs/sunxi_defconfig ${LINUX_CHECKOUTDIR}/.config
	make ${PARALLEL} ARCH=arm CROSS_COMPILE=/usr/bin/arm-linux-gnueabihf- menuconfig
	make ${PARALLEL} ARCH=arm CROSS_COMPILE=/usr/bin/arm-linux-gnueabihf- zImage dtbs
	make ${PARALLEL} ARCH=arm CROSS_COMPILE=/usr/bin/arm-linux-gnueabihf- uImage LOADADDR=0x60008000
	make ${PARALLEL} ARCH=arm CROSS_COMPILE=/usr/bin/arm-linux-gnueabihf- modules
	make ${PARALLEL} ARCH=arm CROSS_COMPILE=/usr/bin/arm-linux-gnueabihf- INSTALL_MOD_PATH=${FS_MOUNTPOINT} modules_install 
	cp ${LINUX_CHECKOUTDIR}/arch/arm/boot/zImage ${FS_MOUNTPOINT}/boot/zImage
	cp ${LINUX_CHECKOUTDIR}/arch/arm/boot/uImage ${FS_MOUNTPOINT}/boot/uImage
	#cp ${LINUX_CHECKOUTDIR}/arch/arm/boot/dts/*.dtb ${FS_MOUNTPOINT}/boot/dts
}

function make_archlinux_rootfs {
	if [[ ! -f /root/rootfs/ArchLinuxARM-armv7-latest.tar.gz ]]; then
		(cd /root/rootfs && wget http://archlinuxarm.org/os/ArchLinuxARM-armv7-latest.tar.gz )
	fi
	(cd ${FS_MOUNTPOINT} && tar xzf /root/rootfs/ArchLinuxARM-armv7-latest.tar.gz )
}

mkdir -p ${FS_MOUNTPOINT}
mount ${IMAGEDEV}p1 ${FS_MOUNTPOINT}

make_uboot
make_archlinux_rootfs
make_kernel

umount ${FS_MOUNTPOINT}