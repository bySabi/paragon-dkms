#!/bin/bash

# load_file_version()
source VERSION

#isrootuser(){
if ! [ $(id -u) = 0 ]; then
	echo "This script must be run as root" 1>&2
	exit 1
fi

SCRIPTDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd $SCRIPTDIR

pkgname=ufsd-module
pkgdir=${pkgname}-${pkgver}

ufsd_status=$(dkms status -m ${pkgname} -v ${pkgver})
if ! [ "$ufsd_status" == ""  ]; then
	dkms remove -m ${pkgname} -v ${pkgver} --all
fi

# clean_dir()
#rm -fr /usr/src/${pkgdir}

sed -i '/ufsd/d' /etc/modules

sed -i '/ufsd/d' /etc/fstab
