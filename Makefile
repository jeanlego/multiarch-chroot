.DEFAULT_GOAL := help

.PHONY: help run/x86_64 run/i386 run/arm run/aarch64 run/ppc64le run/s390x all clean

help:
	@echo -e "\
	Usage:\t\t rootfs/[arch] run/[arch] all clean\n\
	Possible arch:\t x86_64 i386 arm aarch64 ppc64le s390x\
	"

#############
# base
rootfs/x86_64:
	./archroot.sh -a x86_64 -s customized_image.sh

rootfs/i386:
	./archroot.sh -a i386 -s customized_image.sh

rootfs/arm:
	./archroot.sh -a arm -s customized_image.sh

rootfs/aarch64:
	./archroot.sh -a aarch64 -s customized_image.sh

rootfs/ppc64le:
	./archroot.sh -a ppc64le -s customized_image.sh

rootfs/s390x:
	./archroot.sh -a s390x -s customized_image.sh

all: rootfs/x86_64 rootfs/i386 rootfs/arm rootfs/aarch64 rootfs/ppc64le rootfs/s390x


############
# run
run/x86_64: rootfs/x86_64
	./archroot.sh -a x86_64 -it

run/i386: rootfs/i386
	./archroot.sh -a i386 -it

run/arm: rootfs/arm
	./archroot.sh -a arm -it

run/aarch64: rootfs/aarch64
	./archroot.sh -a aarch64 -it

run/ppc64le: rootfs/ppc64le
	./archroot.sh -a ppc64le -it

run/s390x: rootfs/s390x
	./archroot.sh -a s390x -it

clean:
	\rm -Rf rootfs 