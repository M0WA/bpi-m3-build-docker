#!/bin/bash

CONTAINERNAME=bpi-m3-build
IMAGENAME=bpi-m3:latest
LINUX_CHECKOUT=/root/bpi-linux-vanilla
UBOOT_CHECKOUT=/root/bpi-uboot-vanilla
ROOTFSDIR=/root/bpi-rootfs

IMAGEDIR=/root/bpi-image
IMAGEFILE=${IMAGEDIR}/bpi-m3.img
IMAGESIZE=2
IMAGEBS=1GB
IMAGEDEV=

LINUX_TAGNAME=v5.7
LINUX_REPOSITORY=https://github.com/M0WA/linux
UBOOT_REPOSITORY=git://git.denx.de/u-boot.git

function make_image_file {
	dd if=/dev/zero of=${IMAGEFILE} count=${IMAGESIZE} bs=${IMAGEBS} status=progress
	IMAGEDEV=`losetup --show -fP ${IMAGEFILE}`
	(
	echo o # Create a new empty DOS partition table
	echo n # Add a new partition
	echo p # Primary partition
	echo 1 # Partition number
	echo   # First sector (Accept default: 1)
	echo   # Last sector (Accept default: varies)
	echo w # Write changes
	) | fdisk ${IMAGEDEV}
	mkfs.ext4 -O ^metadata_csum,^64bit ${IMAGEDEV}p1
}

function run_docker_image {
	docker run -it --privileged \
	-h ${CONTAINERNAME} \
	-e IMAGEDEV=${IMAGEDEV} \
	-e LINUX_TAGNAME=${LINUX_TAGNAME} \
	-e LINUX_REPOSITORY=${LINUX_REPOSITORY} \
	-e LINUX_CHECKOUTDIR=/root/linux \
	-e UBOOT_REPOSITORY=${UBOOT_REPOSITORY} \
	-e UBOOT_CHECKOUTDIR=/root/uboot \
	-e ROOTFSDIR=${ROOTFSDIR} \
	-e PARALLEL=-j4 \
	-v ${LINUX_CHECKOUT}:/root/linux \
	-v ${UBOOT_CHECKOUT}:/root/uboot \
	-v ${ROOTFSDIR}:/root/rootfs \
	-w /root \
	${IMAGENAME} \
	/bin/bash -c /root/build_internal.sh
}

mkdir -p ${LINUX_CHECKOUT} ${UBOOT_CHECKOUT} ${IMAGEDIR} ${ROOTFSDIR}
make_image_file
run_docker_image
losetup -d ${IMAGEDEV}
echo "dd bs=4M status=progress if=${IMAGEFILE} of=/dev/sdcard"