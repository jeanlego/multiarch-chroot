#!/bin/bash

# ensure running as root
if [ "$(id -u)" != "0" ]; then
    echo "This script requires root."
    exec sudo "$0" "$USER"
    exit 0
fi

die () {
    echo "$@"
    exit 1
}

declare -a DEBOOSTRAP_ARCHES
DEBOOSTRAP_ARCHES=(
    "amd64"
    "i386"
    "armhf"
    "arm64"
    "ppc64el"
    "s390x"
    "mipsel"
    "mips64el"
)

QEMU_ARCHES=(
    "x86_64"
    "i386"
    "arm"
    "aarch64"
    "ppc64le"
    "s390x"
    "mipsel"
    "mips64el"
)


SCRIPT_DIR=${PWD}

BASE_DIR="/opt/multiarch"

mkdir -p ${BASE_DIR}   

cd ${BASE_DIR} || die "${BASE_DIR} does not exist"

echo ${DEBOOSTRAP_ARCHES[@]} | tr [:space:] '\0' | xargs -P$(nproc --all) -l1 -0 -I DEB_ARCH /bin/bash -c '
    QEMU_ARCH=""
    case "DEB_ARCH" in 
        "amd64")
        QEMU_ARCH="x86_64"
        ;;
        "i386")
        QEMU_ARCH="i386"
        ;;
        "armhf")
        QEMU_ARCH="arm"
        ;;
        "arm64")
        QEMU_ARCH="aarch64"
        ;;
        "ppc64el")
        QEMU_ARCH="ppc64le"
        ;;
        "s390x")
        QEMU_ARCH="s390x"
        ;;
        "mipsel")
        QEMU_ARCH="mipsel"
        ;;
        "mips64el")
        QEMU_ARCH="mips64el"
        ;;
    esac

    ARCH_ROOTFS="/opt/multiarch/${QEMU_ARCH}"

    mkdir -p ${ARCH_ROOTFS}

    if [ ! -e "${ARCH_ROOTFS}/usr/bin/qemu-${QEMU_ARCH}-static" ]
    then
        debootstrap --no-check-gpg --arch DEB_ARCH stretch ${ARCH_ROOTFS} http://deb.debian.org/debian/

        echo "Initializing chroot environment ... "
        cp $(which qemu-${QEMU_ARCH}-static) ${ARCH_ROOTFS}/usr/bin/qemu-${QEMU_ARCH}-static
        cp /etc/resolv.conf ${ARCH_ROOTFS}/etc/
        cp /etc/hosts ${ARCH_ROOTFS}/etc/

        echo "OK, rootfs located @${ARCH_ROOTFS}"

        echo "installing base dependencies ..."
        cp init_image.sh ${ARCH_ROOTFS}/opt/init_image.sh
        systemd-nspawn -D ${ARCH_ROOTFS} "/opt/init_image.sh"
        rm -f ${ARCH_ROOTFS}/opt/init_image.sh
        echo "Done"
    fi
'

chown -Rf $1: $BASE_DIR

