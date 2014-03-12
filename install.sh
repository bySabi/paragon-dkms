#!/bin/bash
set -e
set +x

## CUSTOM
pkgver=8.9.0
paragon_file="Paragon-147-FRE_NTFS_Linux_8.9.0_Express.tar.gz"

#isrootuser(){
if ! [ $(id -u) = 0 ]; then
	echo "This script must be run as root" 1>&2
	exit 1
fi

SCRIPTDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd $SCRIPTDIR

LP=`pwd`

pkgname=ufsd-module
pkgdir=${pkgname}-${pkgver}
MODULE_NAME=ufsd
MODULE_NAME2=jnl


if ! which dkms > /dev/null
then
	apt-get install -y --no-install-recommends dkms
fi

clean_dir() {
	rm -fr ${pkgdir}
}
clean_dir
source uninstall.sh

mkdir -p ${pkgdir}
cp dkms.conf ${pkgdir}/
sed "s/PACKAGE_VERSION=VERSION/PACKAGE_VERSION=\"${pkgver}\"/" -i ${pkgdir}/dkms.conf
tar -xzf ${paragon_file} -C ${pkgdir}

sudo cp -fR ${pkgdir} /usr/src/
cd /usr/src/${pkgdir}


if ! ./configure
then
	echo -e "\033[31mCan't prepare driver configuration\033[0m"
	exit 1
fi

## Makefile fix
perl -i -pe 's|/lib/modules/.*?/|\$\(KERNELDIR\)/|g' Makefile
perl -i -pe 's|SUBDIRS=\"/.*?\"|SUBDIRS=\"\$\(CURDIR\)\"|g' Makefile


echo
echo ">>> DKMS: Module add, build, and install"

ufsd_status=$(dkms status -m ${pkgname} -v ${pkgver})
if [ "$ufsd_status" == ""  ]; then
	dkms add -m ${pkgname} -v ${pkgver}
fi

dkms build -m ${pkgname} -v ${pkgver}
dkms install -m ${pkgname} -v ${pkgver} --force

echo
echo ">>> Load new module"
modprobe ${MODULE_NAME} 2>&1

if ! grep "ufsd" /etc/modules >/dev/null
then
	echo "ufsd" >> /etc/modules
fi

exit 0
