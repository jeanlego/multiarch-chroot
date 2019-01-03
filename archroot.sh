#!/bin/bash

SCRIPT_REAL=$(readlink -f "$0")

SCRIPT_NAME=$(basename ${SCRIPT_REAL})
SCRIPT_DIR=$(dirname ${SCRIPT_REAL})

# ensure running as root
if [ "$(id -u)" != "0" ]; then
	echo "This script requires root."
	sudo ${SCRIPT_DIR}/${SCRIPT_NAME} "$@"
	exit 0
fi

ROOTFS_DIR="${SCRIPT_DIR}/rootfs"
[ ! -e ${ROOTFS_DIR} ] && mkdir -p ${ROOTFS_DIR}

SCRIPT=""
DEB_ARCH=""
QEMU_ARCH=""
ARCH_ROOTFS=""
INTERRACTIVE=0


die () {
	echo "$@"
	exit 1
}

help () {
	echo "\
This program allows you to run a bootstrapped architecture within your system
	Usage:
		--script|-s         pass in a script to execute within the bootstrapped environement
		--arch|-a           the architecture to use to run in a bootstrapped environment
		--interactive|-it	start and attach your shell to the chroot
"
}

initScript() {
echo "#!/bin/bash

LC_ALL=C 
export DEBIAN_FRONTEND=noninteractive

apt-setup

echo \"\\
#------------------------------------------------------------------------------#
#                   OFFICIAL DEBIAN REPOS                    
#------------------------------------------------------------------------------#

###### Debian Main Repos
deb http://deb.debian.org/debian/ stable main contrib non-free
deb-src http://deb.debian.org/debian/ stable main contrib non-free

deb http://deb.debian.org/debian/ stable-updates main contrib non-free
deb-src http://deb.debian.org/debian/ stable-updates main contrib non-free

deb http://deb.debian.org/debian-security stable/updates main
deb-src http://deb.debian.org/debian-security stable/updates main

deb http://ftp.debian.org/debian stretch-backports main
deb-src http://ftp.debian.org/debian stretch-backports main
\" > /etc/apt/sources.list

apt-get update -qq
apt-get install -y build-essential locales

sed -i 's/^# *\(en_US.UTF-8\)/\1/' /etc/locale.gen

locale-gen
exit 0
"
}

buildBaseImage() {
	mkdir -p ${ARCH_ROOTFS}

	if [ ! -e "${ARCH_ROOTFS}/usr/bin/qemu-${QEMU_ARCH}-static" ]
	then
		debootstrap --no-check-gpg --arch ${DEB_ARCH} stretch ${ARCH_ROOTFS} http://deb.debian.org/debian/

		echo "Initializing chroot environment ... "
		cp $(which qemu-${QEMU_ARCH}-static) ${ARCH_ROOTFS}/usr/bin/qemu-${QEMU_ARCH}-static
		cp /etc/resolv.conf ${ARCH_ROOTFS}/etc/
		cp /etc/hosts ${ARCH_ROOTFS}/etc/

		echo "OK, rootfs located @${ARCH_ROOTFS}"

		echo "installing base dependencies ..."
		initScript > ${ARCH_ROOTFS}/opt/script.sh
		chmod +x ${ARCH_ROOTFS}/opt/script.sh
		systemd-nspawn -D ${ARCH_ROOTFS} "/opt/script.sh"
		rm -f ${ARCH_ROOTFS}/opt/script.sh

		echo "Done building base image"
	fi
}

main () {
	if [ "_${SCRIPT}" != "_" ]
	then
		cp ${SCRIPT} ${ARCH_ROOTFS}/opt/script.sh
		chmod +x ${ARCH_ROOTFS}/opt/script.sh
		systemd-nspawn -D ${ARCH_ROOTFS} "/opt/script.sh"
		rm -f ${ARCH_ROOTFS}/opt/script.sh
	fi
	
	if [ "_${INTERRACTIVE}" == "_1" ]
	then
		systemd-nspawn -D ${ARCH_ROOTFS} "/bin/bash"
	fi
}


while true; do
	arg=$(echo $1 | tr -s [:space:] | tr -d ' ')
	[ "_${arg}" == "_" ] && break
	shift

	case "${arg}" in
		--script|-s)
			SCRIPT=$1
			shift
			[ -f ${SCRIPT} ] || die "script ${SCRIPT} does not exist"
		;;
		--arch|-a)
			QEMU_ARCH=$1
			shift
			case "${QEMU_ARCH}" in
				"x86_64")	DEB_ARCH="amd64";;
				"i386")		DEB_ARCH="i386";;
				"arm")		DEB_ARCH="armhf";;
				"aarch64")	DEB_ARCH="arm64";;
				"ppc64le")	DEB_ARCH="ppc64el";;
				"s390x")	DEB_ARCH="s390x";;
				*)			die "ERROR: invalid architecture <${QEMU_ARCH}>, use one of: x86_64, i386, arm, aarch64, ppc64le, s390x";;
			esac
			ARCH_ROOTFS="${ROOTFS_DIR}/${QEMU_ARCH}"
		;;
		--interactive|-it)
			INTERRACTIVE=1
		;;
		*)
			echo "ERROR: invalid entry ${arg} in args $@"
			help
			die "Exiting"
	esac
done

#check that the arch has been initialized
[ -e ${ARCH_ROOTFS} ] || buildBaseImage
main

