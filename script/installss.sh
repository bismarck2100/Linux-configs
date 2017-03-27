#!/bin/sh
# @author: kaiwang
# @revise: bismarckh

INFO="/var/packages/SurveillanceStation/INFO"
BUILD_SERVER="//192.168.252.5/DiskStation"
MNT_POINT="/root/DiskStation/"
MNT_OPTS="username=syno,password=,ro,iocharset=utf8,nounix"
SS_PKG_DIR=$MNT_POINT"Packages/SurveillanceStation/SS8.0.0/"
INSTALL_DEBUG_BUILD=false
FORCE_INSTALL=false
install_vers=""

Usage()
{
	printf "Install SurveillanceStation package if newer version is available on build server.\n"
	printf "Usage: %s [-f|-m] [-d]\n" $(basename $0)
	printf "  -d: install debug build\n"
	printf "  -f: force install\n"
	printf "  -v: assign install version\n"
}

GetPlatform()
{
	uname -a | sed -n 's/.*synology_\(.*\)_.*/\1/p'
}

GetArch()
{
	local plat=$(GetPlatform)
	local family=

	case "$plat" in
		x86 | bromolow | cedarview | avoton | bromolowESM | braswell | grantley | broadwell | dockerx64 | kvmx64 )
			family="x86_64"
			;;
		evansport )
			family="i686"
			;;
		alpine | alpine4k )
			family="armv7"
			;;
		88f6281 )
			family="armv5"
			;;
		qoriq )
			family="ppc"
			;;
		# armv7 not ready platforms.
		comcerto2k | armada370 | armada375 | armadaxp | monaco | hi3535 | armada38x)
			family="$plat"
			;;
		*)
			echo "Failed to get platform family for $family" 1>&2
			echo "Please add the mapping information into pkgscripts/pkg_util.sh:pkg_get_platform_family" 1>&2
			return 1
	esac
	echo "$family"
	return 0
}

GetCurVers()
{
	grep "^version=" $INFO | egrep -o "[0-9]{4}"
}

GetNewestVers()
{
	ls -t $SS_PKG_DIR | head -1 | egrep -o "[0-9]{4}"
}

GetAssignedPkg()
{
	local dir=$(ls -t $SS_PKG_DIR | head -1 | sed -e "s/[0-9]\{4\}/${install_vers}/g")
	local dirFullPath=$SS_PKG_DIR/$dir
	local pkg=$(ls $dirFullPath | grep "$(GetArch).*debug")

	if $INSTALL_DEBUG_BUILD; then
		pkg=$(ls $dirFullPath | grep "$(GetArch).*debug")
	else
		pkg=$(ls $dirFullPath | grep "$(GetArch)" | grep -v "debug")
	fi

	echo $dirFullPath/$pkg
}

ConfirmAndInstallSS()
{
	local pkg=$(GetAssignedPkg ${install_vers})

	read -n1 -p "Do you want to install [$(basename $pkg)] ? [Y/n] " ans

	[ -n "$ans" ] && printf "\n"

	if [ "$ans" != "n" ]; then
		InstallSS $1
	fi
}

InstallSS()
{
	local pkg=$(GetAssignedPkg ${install_vers})

	printf "Installing [%s]...\n" $(basename $pkg)
	/usr/syno/bin/synopkg install $pkg
	printf "Installation complete.\n"
}

################
##    MAIN    ##
################

while getopts ":v:hdf" opt; do
	case $opt in
		h) Usage && exit 0 ;;
		d) INSTALL_DEBUG_BUILD=true ;;
		v) install_vers=$OPTARG;;
		f) FORCE_INSTALL=true;;
		\?) Usage && exit 0 ;;
	esac
done
shift $(($OPTIND - 1))

if [ $USER != "root" ]; then
	printf "Should run the script as root.\n"
	exit 1
fi

umount -f $MNT_POINT 2>/dev/null
mkdir -p $MNT_POINT
mount.cifs $BUILD_SERVER $MNT_POINT -o $MNT_OPTS

if [ $? -ne 0 ]; then
	printf "Failed to mount build server.\n"
	exit $?
fi

cur_vers=$(GetCurVers)
if [ -z $install_vers ]; then
	install_vers=$(GetNewestVers)
fi

printf "=> Current SVS version: %s\n" $cur_vers
printf "=> Installing SVS version: %s\n" $install_vers

if [ "$cur_vers" -gt "$install_vers" ] ; then
	printf "Not support downgrade yet!\n"
elif $FORCE_INSTALL ; then
	InstallSS
elif [ "$cur_vers" != "$install_vers" -a -n "$install_vers" ]; then
	ConfirmAndInstallSS
else
	printf "No need to Install\n"
fi

umount -f $MNT_POINT

