FROM debian:latest

RUN apt -y update
RUN apt -y install \
	u-boot-tools git bison flex bc wget \
	python3 python3-distutils python3-dev swig \
	kmod build-essential libncurses-dev \
	binutils-arm-linux-gnueabihf cpp-arm-linux-gnueabihf \
	g++-arm-linux-gnueabihf gcc-arm-linux-gnueabihf
ADD build_internal.sh /root/build_internal.sh
RUN chmod 0744 /root/build_internal.sh
ADD boot.cmd /root/boot.cmd