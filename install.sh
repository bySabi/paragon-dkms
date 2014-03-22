#!/bin/bash
set -e
set +x


project_dir="paragon-dkms"


## goto script dir
cd "$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

script_dir_parent=${PWD##*/}


pkgname=ufsd-module
MODULE_NAME=ufsd


main() {
	isrootuser
	setup_script ${script_dir_parent}

	load_file_version
	install_dkms
#	check_paragon_file
	uninstall_old_dkms
	set_package_dir
	compiled_package_dir
	move_package_dir
	chdir_package_dir
#	configure_package_src
#	fix_makefile
	add_install_build_dkms_module
	load_kernel_module
	add_kernel_module_to_etc_modules
	add_fstab_prototype
}


load_file_version() {
	source VERSION
	pkgdir=${pkgname}-${pkgver}
}

install_dkms() {
	echo ">> Install dkms"
		if ! which dkms > /dev/null
		then
			apt-get update && apt-get install -y --no-install-recommends dkms 1>/dev/null
		fi
	exit_func $?
}

check_paragon_file() {
	echo ">> check file: ${paragon_file}"
		[ -f ${paragon_file} ] || {
			echo "File not found: ${paragon_file}"
			echo "download from: http://www.paragon-software.com/home/ntfs-linux-professional/release.html"
			exit 1
		}
	exit_func $?
}

uninstall_old_dkms() {
	echo ">> uninstall old paragon-dkms"
		rm -fr ${pkgdir}
		source uninstall.sh
		rm -fr /usr/src/${pkgdir}
	exit_func $?
}

set_package_dir() {
	echo ">> set paragon-dkms package dir"
		mkdir -p ${pkgdir}
		cp dkms.conf ${pkgdir}/
		sed "s/PACKAGE_VERSION=VERSION/PACKAGE_VERSION=\"${pkgver}\"/" -i ${pkgdir}/dkms.conf
	exit_func $?
}

compiled_package_dir() {
	echo ">> add compiled paragon-dkms package dir"
		cp files/* ${pkgdir}/
	exit_func $?
}

move_package_dir() {
	echo ">> Move paragon-dkms package to /usr/src/"
		mv ${pkgdir} /usr/src/
	exit_func $?
}

chdir_package_dir() {
	cd /usr/src/${pkgdir}
}

configure_package_src() {
	echo ">> \"./configure\" package source"
		if ! ./configure
		then
			echo -e "\033[31mCan't prepare driver configuration\033[0m"
			exit 1
		fi
	exit_func $?
}

fix_makefile() {
	echo ">> Fix package Makefile"
		perl -i -pe 's|/lib/modules/.*?/|\$\(KERNELDIR\)/|g' Makefile
		perl -i -pe 's|SUBDIRS=\"/.*?\"|SUBDIRS=\"\$\(CURDIR\)\"|g' Makefile
	exit_func $?
}

add_install_build_dkms_module() {
	echo ">> DKMS: Module add, build, and install"
		local ufsd_status=$(dkms status -m ${pkgname} -v ${pkgver})
		if [ "$ufsd_status" == ""  ]; then
			dkms add -m ${pkgname} -v ${pkgver}
		fi
		dkms build -m ${pkgname} -v ${pkgver}
		dkms install -m ${pkgname} -v ${pkgver} --force
	exit_func $?
}

load_kernel_module() {
	echo ">> Load kernel module: ${MODULE_NAME}"
		modprobe ${MODULE_NAME} 2>&1
	exit_func $?
}

add_kernel_module_to_etc_modules() {
	echo ">> Add kernel module: ${MODULE_NAME} to /etc/modules"
		if ! grep "ufsd" /etc/modules >/dev/null
		then
			echo "ufsd" >> /etc/modules
		fi
	exit_func $?
}

add_fstab_prototype() {
	echo ">> Add mount ufsd prototype to /etc/fstab"
		if ! grep "ufsd" /etc/fstab >/dev/null
		then
			echo '#UUID=007007007007 /media/usb1500gb                    ufsd    nobootwait,quiet,noatime,umask=000,fmask=000,dmask=000 0     0' >> /etc/fstab
		fi
	exit_func $?
}

isrootuser() {
	[ $(id -u) = 0 ] || {
		echo "This script must be run as root" 1>&2
		exit 1
	}
}

setup_script() {
	if [ "$1" != ${project_dir} ]; then
		if ! which git > /dev/null
		then
			echo ">> Install git"
				apt-get update && apt-get install -y --no-install-recommends git 1>/dev/null
			exit_func $?
		fi
		echo ">> clone \"${project_dir}\" repo"
			[ -d ${project_dir} ] && rm -fr ${project_dir}
			git clone -b compiled https://github.com/bySabi/${project_dir}.git
		exit_func $?
		cd ${project_dir}
		chmod +x install.sh && ./install.sh
		exit 0
	fi
}

exit_func() {
	local exitcode=${1}
	if [ $exitcode == 0 ]; then 
		echo -e "\e[00;32mOK\e[00m"
	else 
		echo -e "\e[00;31mFAIL\e[00m"
	fi
}


main "$@"
exit 0
