#!/bin/sh
# @author: kaiwang

# set -o xtrace

DEV_USER="root"
DEV_MACHINE="10.13.20.60"
DEV_SRC_DIR=$DEV_MACHINE":/synosrc/Env64"

ENABLE_SCP=false
SCP_DEST=$DEV_USER"@"$DEV_MACHINE":Desktop/"

FILE_POSTFIX=$(hostname).$(date +%m-%d-%H-%M)
GDB_SO_LIB_PATH="/root/lib"
SQLITE_BUSY_TIMEOUT=5000
DEV_SCRIPT_ALIAS="x"

#####################
##    FUNCTIONS    ##
#####################

Main()
{
	opt="$1"

	case $opt in
		"-m")
			# common nfs mount opt: https://www.centos.org/docs/5/html/Deployment_Guide-en-US/s1-nfs-client-config-options.html
			mount -o nfsvers=3 -n $DEV_SRC_DIR /mnt ;;
		"-M")
			umount -f /mnt ;;
		"-k")
			LinkCode "$2" ;;    # LinkCode projectCode
		"-g")
			GetValOfKey "$1" ;;
		"-db")
			RunSql "$2" "$3" ;; # RunSql dbCode SqlCmd
		"-u")
			/var/packages/SurveillanceStation/target/bin/ssupgrader ${2:-0} ;; # ssupgrader version
		"-sql")
			/var/packages/SurveillanceStation/target/scripts/sql/sql.sh ;;
		"-l")
			ShowLog "$2" ;;
		"-L")
			CollectLog "$2";;
		"-s")
			/usr/syno/bin/synopkg start SurveillanceStation ;;
		"-S")
			/usr/syno/bin/synopkg stop SurveillanceStation ;;
		"-r")
			/usr/syno/bin/synopkg restart SurveillanceStation ;;
		"-i")
			PrintDsInfo ;;
		"-b")
			BackupSSEnv ;;
		"-B")
			RestoreSSEnv ;;
		"-R")
			RemoveCoreFiles ;;
		"-x")
			RepeatCmd "$2" "$3" "$4";;
		"-H")
			PrintDbgHelp ;;
		"-e")
			BootstrapPrepDevEnv $0 ;;
		"-t")
			Test ;;
		*)
			ShowHelp ;;
	esac
} # END OF Main()

ShowHelp()
{
	printf "Usage: $0 OPTIONS [OPTARGS]\n"
	printf "    %-25s %s\n" "-h" "Show help"
	printf "    %-25s %s\n" "-m" "Mount dev-machine"
	printf "    %-25s %s\n" "-M" "Umount dev-machine"
	printf "    %-25s %s\n" "-k ss|sd" "Run SS link script"
	printf "    %-25s %s\n" "" "ss: link surveillance "
	printf "    %-25s %s\n" "" "sd: link devicepack "
	printf "    %-25s %s\n" "-db s|r|e|c [sql]" "Run sql command on db"
	printf "    %-25s %s\n" "" "s: system.db, r: recording.db"
	printf "    %-25s %s\n" "" "e: recordingX.db c:recording_cnt.db"
	printf "    %-25s %s\n" "-u [version]" "Run ssupgrader SS version"
	printf "    %-25s %s\n" "-sql" "Run sql.sh"
	printf "    %-25s %s\n" "-l s|m" "Show log (s: SS log, m: messages log)"
	printf "    %-25s %s\n" "-L ss|ds" "Collect log (ss: SS log, ds: whole ds debug info)"
	printf "    %-25s %s\n" "-s" "Start SS"
	printf "    %-25s %s\n" "-S" "Stop SS"
	printf "    %-25s %s\n" "-r" "Restart SS"
	printf "    %-25s %s\n" "-i" "Print DS/SS information "
	printf "    %-25s %s\n" "-b" "Backup SS environment"
	printf "    %-25s %s\n" "-B" "Restore SS environment from backup file"
	printf "    %-25s %s\n" "-R" "Remove core files"
	printf "    %-25s %s\n" "-x 'CMD' DELAY [COUNT]" "Execute cmd repeatly"
	printf "    %-25s %s\n" "-H" "Print debug help information "
	printf "    %-25s %s\n" "-e" "Bootstrap dev environment"
}

PrintMainContent()
{
	local str=$(grep -n "^Main()" $0 | cut -d':' -f1)
	local end=$(grep -n "END OF Main()$" $0 | head -n1 | cut -d':' -f1)

	sed -n "$str,$end p" $0
}

PrintDbgHelp()
{
		# Print help info
	cat <<EOF

####################
##    DBG INFO    ##
####################

==> To insert crontab:
	- vi /etc/crontab
         (e.g. top -bn1  >> /var/log/sslog-CPU.log
               top -Mbn1 >> /var/log/sslog-MEM.log)
	- pkill crontab

EOF

	# Print script content
	PrintMainContent
}

ExitOnErr()
{
	local errMsg=$1
	printf "$errMsg\n"
	exit 1
}

GetValOfKey()
{
	local key="$1"
	local conf="/var/packages/SurveillanceStation/etc/settings.conf"

	if [ -n "$key" ]; then
		grep $key $conf
	else
		cat $conf | sed '/^$/d'
	fi
}

BackupSSEnv()
{
	local TARGET_FILE="/root/target.$FILE_POSTFIX.tgz"
	local SHARED_FILE="/root/shared.$FILE_POSTFIX.tgz"

	printf "==> Backup settings...\n"
	cd /var/packages/SurveillanceStation/target
	tar -zcf $TARGET_FILE @SSData @SSEmap axisacsctrl.db system.db
	cd - >/dev/null

	printf "==> Backup db in shared folder...\n"
	cd /var/services/surveillance/
	tar -zcf $SHARED_FILE *.db @CmsSyncData
	cd - >/dev/null

	if $ENABLE_SCP; then
		printf "==> Copy settings to '%s'...\n" $SCP_DEST
		scp $TARGET_FILE $SHARED_FILE $SCP_DEST && rm -f $TARGET_FILE $SHARED_FILE
	fi
}

RestoreSSEnv()
{
	if [ $(ls target.*.tgz | wc -l) -eq 1 ] && [ $(ls shared.*.tgz | wc -l) -eq 1 ]; then
		tar -zxf /root/target.*.tgz -C /var/packages/SurveillanceStation/target
		tar -zxf /root/shared.*.tgz -C /var/services/surveillance/
	else
		ExitOnErr "Number of target & shared backup files must be exactly one."
	fi
}

PrintBanner()
{
	if [ -n "$1" ];then
		printf "[%s]:\n" "$1"
	else
		printf "%s\n\n" "-----------------------"
	fi
}

ListCorefiles()
{
	for volume in $(ls / | grep volume); do
		printf "in /$volume:\n"
		ls -al /$volume/*.core 2>/dev/null
	done
}

RemoveCoreFiles()
{
	for coreFile in $(ls /volume*/@*\.core 2> /dev/null); do
		printf "=> rm $coreFile\n"
		rm -f $coreFile
	done
}

PrintDsInfo()
{
	PrintBanner " /usr/syno/etc/private/session/current.users "
	tail -5 /usr/syno/etc/private/session/current.users
	PrintBanner

	PrintBanner " /var/packages/SurveillanceStation/etc/settings.conf (partial) "
	sed '/^$/d' /var/packages/SurveillanceStation/etc/settings.conf \
		| egrep -v "notischedule|notifilter|snapshot" | more
	PrintBanner

	if [ -f "/var/packages/SurveillanceStation/etc/test.conf" ]; then
	   PrintBanner " /var/packages/SurveillanceStation/etc/test.conf "
	   cat /var/packages/SurveillanceStation/etc/test.conf
	   PrintBanner
	fi

	PrintBanner "limit"
	grep "surveillance_camera_max" /etc.defaults/synoinfo.conf
	grep "MaxClients" /etc/httpd/conf/extra/httpd-mpm.conf-max-connection
	PrintBanner

	PrintBanner " /etc/synoinfo.conf (partial) "
	egrep "ss_|surveillance" /etc/synoinfo.conf
	PrintBanner

	PrintBanner " /var/packages/SurveillanceStation/INFO (partial)"
	head -10 /var/packages/SurveillanceStation/INFO
	PrintBanner

	PrintBanner " /etc.defaults/VERSION "
	cat //etc.defaults/VERSION
	PrintBanner

	PrintBanner "uname"
	uname -a
	PrintBanner

	PrintBanner "core files"
	ListCorefiles
	PrintBanner
}

GetMntDirName()
{
	# platform
	local platform=$(grep unique /etc.defaults/synoinfo.conf | cut -d'=' -f2 | cut -d'_' -f2)

	case $platform in
		88f6282) platform=6281 ;;
		avoton) platform=x64 ;;
		bromolow) platform=x64 ;;
	esac

	# DSM version
	# local majorVersion=$(grep majorversion /etc.defaults/VERSION | cut -d'=' -f2 | cut -d'"' -f2)
	# local minorVersion=$(grep minorversion /etc.defaults/VERSION | cut -d'=' -f2 | cut -d'"' -f2)
	# local version=$majorVersion.$minorVersion
	local version="6.0" # Hard-code to dsm v5.0

	# e.g. "ds.evansport-5.0"
	echo ds.$platform-$version
}

GetSSVersion()
{
	local version=$(egrep version /var/packages/SurveillanceStation/INFO | egrep -o "[0-9]\.[0-9]")
	[ "7.1" == "$version" ] && version="7.0"
	echo "$version"
}

GetMntRoot()
{
	local mntDir=/mnt/build_env/$(GetMntDirName)

	if [ -d $mntDir ]; then
		echo $mntDir
	fi
}

LinkCode()
{
	local projectCode=$1
	local project=""
	local LinkScript=""

	case "$projectCode" in
		"ss")
			project="Surveillance" ;;
		"sd")
			project="SurvDevicePack" ;;
		*) ExitOnErr "Valid project codes are: ss|sd|ssh|sdh" ;;
	esac

	LinkScript=$(GetMntRoot)/source/$project/test/link2target.sh
	echo $LinkScript
	sh $LinkScript
}

RunSql()
{
	local dbCode=$1
	local db=$2
	local sqlCmd=$2
	local sqlite3=""

	if [ -f "/var/packages/SurveillanceStation/target/bin/sqlite3" ]; then
		sqlite3="/var/packages/SurveillanceStation/target/bin/sqlite3"
	elif [ -f "/usr/syno/bin/sqlite3" ]; then
		sqlite3="/usr/syno/bin/sqlite3"
	else
		sqlite3="sqlite3"
	fi

	case "$dbCode" in
		"s") db="/var/packages/SurveillanceStation/target/system.db" ;;
		"r") db="/var/services/surveillance/recording.db" ;;
		"c") db="/var/services/surveillance/recording_cnt.db" ;;
		*) ExitOnErr "Valid db code are: s|r|c|e"
	esac

	if [ -n "$sqlCmd" ]; then
		$sqlite3 -cmd ".timeout $SQLITE_BUSY_TIMEOUT" $db "$sqlCmd"
	else
		$sqlite3 -cmd ".timeout $SQLITE_BUSY_TIMEOUT" $db
	fi
}

ShowLog()
{
	local logCode=$1

	case "$logCode" in
		"s") tail -F /var/log/surveillance/surveillance.log ;;
		"m") tail -F /var/log/messages ;;
		*) ExitOnErr "Valid logCode are s|m."
	esac
}

CollectLog()
{
	local logCode=$1

	case "$logCode" in
		"ds") CollectDsLog ;;
		"ss") CollectSSLog ;;
		*) ExitOnErr "Valid logCode are ds|ss."
	esac
}

CollectDsLog()
{
	local LOG_FILE="debug-log.$FILE_POSTFIX.tgz"
	local LOG_TMP_DIR="log_tmp"

	printf "\n==> Collecting debug log...\n\n"
	synomsg_collector2 $LOG_TMP_DIR

	tar --hard-dereference -zchf $LOG_FILE $LOG_TMP_DIR
	rm -rf $LOG_TMP_DIR

	if $ENABLE_SCP; then
		printf "\n==> Coping log file to '%s'...\n\n" $SCP_DEST
		scp $LOG_FILE $SCP_DEST && rm $LOG_FILE
	fi
}

CollectSSLog()
{
	local LOG_FILE="sslog.$FILE_POSTFIX.tgz"

	tar -zcf $LOG_FILE /var/log/ss* /var/log/surveillance*

	if $ENABLE_SCP; then
		printf "\n==> Coping sslog file to '%s'...\n\n" $SCP_DEST
		scp $LOG_FILE $SCP_DEST && rm $LOG_FILE
	fi
}

Test()
{
	printf "==> Hello World\n"
}

RepeatCmd()
{
	if [ "$1" = '-h' ] || [ -z "$1" ] || [ $# -lt 2 ]; then
		printf "Usage: RepeatCmd \"cmd\" delay [count]\n";
		printf "you may wanna use quoting like $' \\\'ooo\\\' '\n";
		return 1;
	fi;

	cmd="$1";
	delay=${2:-1};
	cnt=${3:-0}

	if [ $cnt -gt 0 ]; then
		while [ $cnt -gt 0 ]; do
			date
			eval "$cmd";
			sleep $delay;
			cnt=$((cnt - 1))
		done
	else
		while :; do
			date
			eval "$cmd";
			sleep $delay;
		done
	fi
}

CreateQuickLinks()
{
	ln -sf /var/packages/SurveillanceStation/target/ /root/target
	ln -sf /var/packages/SurveillanceStation/

	ln -sf /usr/syno/synoman/webapi/synoscgi /root/synoscgi

	ln -sf /mnt/source /source
}

BootstrapPrepDevEnv()
{
	local script=$1

	cp $script /usr/bin/$DEV_SCRIPT_ALIAS && rm $script

	PrepareDotProfile > /root/.profile
	PrepareGdbEnv

	CreateQuickLinks
}

PrepareDotProfile()
{
	cat <<EOF
PATH=/opt/sbin:/opt/bin:/root/bin:/var/packages/DiagnosisTool/target/usr/sbin/:/var/packages/DiagnosisTool/target/usr/bin/:/var/packages/SurveillanceStation/target/bin:/var/packages/SurveillanceStation/target/sbin:$PATH

alias ldd="LD_TRACE_LOADED_OBJECTS=1 /lib/ld-*"
export dst=$SCP_DEST
EOF
}

###################
##    For GDB    ##
###################

PrepareGdbEnv()
{
	GenGdbInit > /root/.gdbinit
	GenGdbStdInspector > /root/.gdb-std-inspector
	MkLibDir
	FetchGdb
}

MkLibDir()
{
	mkdir -p $GDB_SO_LIB_PATH

	cd $GDB_SO_LIB_PATH >/dev/null
	for dso in $(find /var/packages/SurveillanceStation/target/webapi/ -name "*.so"); do
		ln -sf $dso .
	done
	cd - >/dev/null
}

FetchGdb()
{
	local gdb="undefined"
	case $(uname -m) in
		i686|x86_64) gdb=gdb.x86_32 ;;
		# x86_64) gdb=gdb.x64 ;;
		ppc) gdb=gdb.ppc ;;
		armv5tel) gdb=gdb-7.6.1-628x ;;
	esac

	if [ -f $(GetMntRoot)/usr/local/tool/$gdb ]; then
		cp $(GetMntRoot)/usr/local/tool/$gdb /root/
	fi
}

GenGdbInit()
{
	cat <<EOF
# specify solib loading path
# (use "info shared" to find more solib-search-path)
set solib-absolute-prefix /dev/null
set solib-search-path $GDB_SO_LIB_PATH:/root/target/lib:/root/target/device_pack/lib/:/lib
# set debug libthread-db 1

# general
set auto-load safe-path /
set height 0
set pagination off
set print static-members off
set print element 0
set print pretty on
set print object on
set print demangle on
set demangle-style gnu-v3
# set print thread-events off

# c++
source .gdb-std-inspector

# ==========================
# b slaveds.cpp:1915
# commands
#   silent
#   printf "=> Status of DS[%d] is %d.", DSObj.m_Id, Status
#   c
# end


EOF
}

GenGdbStdInspector()
{
	cat <<EOF
#
#   STL GDB evaluators/views/utilities - 1.03
#
#   The new GDB commands:
#		are entirely non instrumental
#		do not depend on any "inline"(s) - e.g. size(), [], etc
#       are extremely tolerant to debugger settings
#
#   This file should be "included" in .gdbinit as following:
#   source stl-views.gdb or just paste it into your .gdbinit file
#
#   The following STL containers are currently supported:
#
#       std::vector<T> -- via pvector command
#       std::list<T> -- via plist or plist_member command
#       std::map<T,T> -- via pmap or pmap_member command
#       std::multimap<T,T> -- via pmap or pmap_member command
#       std::set<T> -- via pset command
#       std::multiset<T> -- via pset command
#       std::deque<T> -- via pdequeue command
#       std::stack<T> -- via pstack command
#       std::queue<T> -- via pqueue command
#       std::priority_queue<T> -- via ppqueue command
#       std::bitset<n> -- via pbitset command
#       std::string -- via pstring command
#       std::widestring -- via pwstring command
#
#   The end of this file contains (optional) C++ beautifiers
#   Make sure your debugger supports \$argc
#
#   Simple GDB Macros writen by Dan Marinescu (H-PhD) - License GPL
#   Inspired by intial work of Tom Malnar,
#     Tony Novac (PhD) / Cornell / Stanford,
#     Gilad Mishne (PhD) and Many Many Others.
#   Contact: dan_c_marinescu@yahoo.com (Subject: STL)
#
#   Modified to work with g++ 4.3 by Anders Elton
#   Also added _member functions, that instead of printing the entire class in map, prints a member.



#
# std::vector<>
#

define pvector
	if \$argc == 0
		help pvector
	else
		set \$size = \$arg0._M_impl._M_finish - \$arg0._M_impl._M_start
		set \$capacity = \$arg0._M_impl._M_end_of_storage - \$arg0._M_impl._M_start
		set \$size_max = \$size - 1
	end
	if \$argc == 1
		set \$i = 0
		while \$i < \$size
			printf "elem[%u]: ", \$i
			p *(\$arg0._M_impl._M_start + \$i)
			set \$i++
		end
	end
	if \$argc == 2
		set \$idx = \$arg1
		if \$idx < 0 || \$idx > \$size_max
			printf "idx1, idx2 are not in acceptable range: [0..%u].\n", \$size_max
		else
			printf "elem[%u]: ", \$idx
			p *(\$arg0._M_impl._M_start + \$idx)
		end
	end
	if \$argc == 3
	  set \$start_idx = \$arg1
	  set \$stop_idx = \$arg2
	  if \$start_idx > \$stop_idx
		set \$tmp_idx = \$start_idx
		set \$start_idx = \$stop_idx
		set \$stop_idx = \$tmp_idx
	  end
	  if \$start_idx < 0 || \$stop_idx < 0 || \$start_idx > \$size_max || \$stop_idx > \$size_max
		printf "idx1, idx2 are not in acceptable range: [0..%u].\n", \$size_max
	  else
		set \$i = \$start_idx
		while \$i <= \$stop_idx
			printf "elem[%u]: ", \$i
			p *(\$arg0._M_impl._M_start + \$i)
			set \$i++
		end
	  end
	end
	if \$argc > 0
		printf "Vector size = %u\n", \$size
		printf "Vector capacity = %u\n", \$capacity
		printf "Element "
		whatis \$arg0._M_impl._M_start
	end
end

document pvector
	Prints std::vector<T> information.
	Syntax: pvector <vector> <idx1> <idx2>
	Note: idx, idx1 and idx2 must be in acceptable range [0..<vector>.size()-1].
	Examples:
	pvector v - Prints vector content, size, capacity and T typedef
	pvector v 0 - Prints element[idx] from vector
	pvector v 1 2 - Prints elements in range [idx1..idx2] from vector
end

#
# std::list<>
#

define plist
	if \$argc == 0
		help plist
	else
		set \$head = &\$arg0._M_impl._M_node
		set \$current = \$arg0._M_impl._M_node._M_next
		set \$size = 0
		while \$current != \$head
			if \$argc == 2
				printf "elem[%u]: ", \$size
				p *(\$arg1*)(\$current + 1)
			end
			if \$argc == 3
				if \$size == \$arg2
					printf "elem[%u]: ", \$size
					p *(\$arg1*)(\$current + 1)
				end
			end
			set \$current = \$current._M_next
			set \$size++
		end
		printf "List size = %u \n", \$size
		if \$argc == 1
			printf "List "
			whatis \$arg0
			printf "Use plist <variable_name> <element_type> to see the elements in the list.\n"
		end
	end
end

document plist
	Prints std::list<T> information.
	Syntax: plist <list> <T> <idx>: Prints list size, if T defined all elements or just element at idx
	Examples:
	plist l - prints list size and definition
	plist l int - prints all elements and list size
	plist l int 2 - prints the third element in the list (if exists) and list size
end

define plist_member
	if \$argc == 0
		help plist_member
	else
		set \$head = &\$arg0._M_impl._M_node
		set \$current = \$arg0._M_impl._M_node._M_next
		set \$size = 0
		while \$current != \$head
			if \$argc == 3
				printf "elem[%u]: ", \$size
				p (*(\$arg1*)(\$current + 1)).\$arg2
			end
			if \$argc == 4
				if \$size == \$arg3
					printf "elem[%u]: ", \$size
					p (*(\$arg1*)(\$current + 1)).\$arg2
				end
			end
			set \$current = \$current._M_next
			set \$size++
		end
		printf "List size = %u \n", \$size
		if \$argc == 1
			printf "List "
			whatis \$arg0
			printf "Use plist_member <variable_name> <element_type> <member> to see the elements in the list.\n"
		end
	end
end

document plist_member
	Prints std::list<T> information.
	Syntax: plist <list> <T> <idx>: Prints list size, if T defined all elements or just element at idx
	Examples:
	plist_member l int member - prints all elements and list size
	plist_member l int member 2 - prints the third element in the list (if exists) and list size
end


#
# std::map and std::multimap
#

define pmap
	if \$argc == 0
		help pmap
	else
		set \$tree = \$arg0
		set \$i = 0
		set \$node = \$tree._M_t._M_impl._M_header._M_left
		set \$end = \$tree._M_t._M_impl._M_header
		set \$tree_size = \$tree._M_t._M_impl._M_node_count
		if \$argc == 1
			printf "Map "
			whatis \$tree
			printf "Use pmap <variable_name> <left_element_type> <right_element_type> to see the elements in the map.\n"
		end
		if \$argc == 3
			while \$i < \$tree_size
				set \$value = (void *)(\$node + 1)
				printf "elem[%u].left: ", \$i
				p *(\$arg1*)\$value
				set \$value = \$value + sizeof(\$arg1)
				printf "elem[%u].right: ", \$i
				p *(\$arg2*)\$value
				if \$node._M_right != 0
					set \$node = \$node._M_right
					while \$node._M_left != 0
						set \$node = \$node._M_left
					end
				else
					set \$tmp_node = \$node._M_parent
					while \$node == \$tmp_node._M_right
						set \$node = \$tmp_node
						set \$tmp_node = \$tmp_node._M_parent
					end
					if \$node._M_right != \$tmp_node
						set \$node = \$tmp_node
					end
				end
				set \$i++
			end
		end
		if \$argc == 4
			set \$idx = \$arg3
			set \$ElementsFound = 0
			while \$i < \$tree_size
				set \$value = (void *)(\$node + 1)
				if *(\$arg1*)\$value == \$idx
					printf "elem[%u].left: ", \$i
					p *(\$arg1*)\$value
					set \$value = \$value + sizeof(\$arg1)
					printf "elem[%u].right: ", \$i
					p *(\$arg2*)\$value
					set \$ElementsFound++
				end
				if \$node._M_right != 0
					set \$node = \$node._M_right
					while \$node._M_left != 0
						set \$node = \$node._M_left
					end
				else
					set \$tmp_node = \$node._M_parent
					while \$node == \$tmp_node._M_right
						set \$node = \$tmp_node
						set \$tmp_node = \$tmp_node._M_parent
					end
					if \$node._M_right != \$tmp_node
						set \$node = \$tmp_node
					end
				end
				set \$i++
			end
			printf "Number of elements found = %u\n", \$ElementsFound
		end
		if \$argc == 5
			set \$idx1 = \$arg3
			set \$idx2 = \$arg4
			set \$ElementsFound = 0
			while \$i < \$tree_size
				set \$value = (void *)(\$node + 1)
				set \$valueLeft = *(\$arg1*)\$value
				set \$valueRight = *(\$arg2*)(\$value + sizeof(\$arg1))
				if \$valueLeft == \$idx1 && \$valueRight == \$idx2
					printf "elem[%u].left: ", \$i
					p \$valueLeft
					printf "elem[%u].right: ", \$i
					p \$valueRight
					set \$ElementsFound++
				end
				if \$node._M_right != 0
					set \$node = \$node._M_right
					while \$node._M_left != 0
						set \$node = \$node._M_left
					end
				else
					set \$tmp_node = \$node._M_parent
					while \$node == \$tmp_node._M_right
						set \$node = \$tmp_node
						set \$tmp_node = \$tmp_node._M_parent
					end
					if \$node._M_right != \$tmp_node
						set \$node = \$tmp_node
					end
				end
				set \$i++
			end
			printf "Number of elements found = %u\n", \$ElementsFound
		end
		printf "Map size = %u\n", \$tree_size
	end
end

document pmap
	Prints std::map<TLeft and TRight> or std::multimap<TLeft and TRight> information. Works for std::multimap as well.
	Syntax: pmap <map> <TtypeLeft> <TypeRight> <valLeft> <valRight>: Prints map size, if T defined all elements or just element(s) with val(s)
	Examples:
	pmap m - prints map size and definition
	pmap m int int - prints all elements and map size
	pmap m int int 20 - prints the element(s) with left-value = 20 (if any) and map size
	pmap m int int 20 200 - prints the element(s) with left-value = 20 and right-value = 200 (if any) and map size
end


define pmap_member
	if \$argc == 0
		help pmap_member
	else
		set \$tree = \$arg0
		set \$i = 0
		set \$node = \$tree._M_t._M_impl._M_header._M_left
		set \$end = \$tree._M_t._M_impl._M_header
		set \$tree_size = \$tree._M_t._M_impl._M_node_count
		if \$argc == 1
			printf "Map "
			whatis \$tree
			printf "Use pmap <variable_name> <left_element_type> <right_element_type> to see the elements in the map.\n"
		end
		if \$argc == 5
			while \$i < \$tree_size
				set \$value = (void *)(\$node + 1)
				printf "elem[%u].left: ", \$i
				p (*(\$arg1*)\$value).\$arg2
				set \$value = \$value + sizeof(\$arg1)
				printf "elem[%u].right: ", \$i
				p (*(\$arg3*)\$value).\$arg4
				if \$node._M_right != 0
					set \$node = \$node._M_right
					while \$node._M_left != 0
						set \$node = \$node._M_left
					end
				else
					set \$tmp_node = \$node._M_parent
					while \$node == \$tmp_node._M_right
						set \$node = \$tmp_node
						set \$tmp_node = \$tmp_node._M_parent
					end
					if \$node._M_right != \$tmp_node
						set \$node = \$tmp_node
					end
				end
				set \$i++
			end
		end
		if \$argc == 6
			set \$idx = \$arg5
			set \$ElementsFound = 0
			while \$i < \$tree_size
				set \$value = (void *)(\$node + 1)
				if *(\$arg1*)\$value == \$idx
					printf "elem[%u].left: ", \$i
					p (*(\$arg1*)\$value).\$arg2
					set \$value = \$value + sizeof(\$arg1)
					printf "elem[%u].right: ", \$i
					p (*(\$arg3*)\$value).\$arg4
					set \$ElementsFound++
				end
				if \$node._M_right != 0
					set \$node = \$node._M_right
					while \$node._M_left != 0
						set \$node = \$node._M_left
					end
				else
					set \$tmp_node = \$node._M_parent
					while \$node == \$tmp_node._M_right
						set \$node = \$tmp_node
						set \$tmp_node = \$tmp_node._M_parent
					end
					if \$node._M_right != \$tmp_node
						set \$node = \$tmp_node
					end
				end
				set \$i++
			end
			printf "Number of elements found = %u\n", \$ElementsFound
		end
		printf "Map size = %u\n", \$tree_size
	end
end

document pmap_member
	Prints std::map<TLeft and TRight> or std::multimap<TLeft and TRight> information. Works for std::multimap as well.
	Syntax: pmap <map> <TtypeLeft> <TypeRight> <valLeft> <valRight>: Prints map size, if T defined all elements or just element(s) with val(s)
	Examples:
	pmap_member m class1 member1 class2 member2 - prints class1.member1 : class2.member2
	pmap_member m class1 member1 class2 member2 lvalue - prints class1.member1 : class2.member2 where class1 == lvalue
end


#
# std::set and std::multiset
#

define pset
	if \$argc == 0
		help pset
	else
		set \$tree = \$arg0
		set \$i = 0
		set \$node = \$tree._M_t._M_impl._M_header._M_left
		set \$end = \$tree._M_t._M_impl._M_header
		set \$tree_size = \$tree._M_t._M_impl._M_node_count
		if \$argc == 1
			printf "Set "
			whatis \$tree
			printf "Use pset <variable_name> <element_type> to see the elements in the set.\n"
		end
		if \$argc == 2
			while \$i < \$tree_size
				set \$value = (void *)(\$node + 1)
				printf "elem[%u]: ", \$i
				p *(\$arg1*)\$value
				if \$node._M_right != 0
					set \$node = \$node._M_right
					while \$node._M_left != 0
						set \$node = \$node._M_left
					end
				else
					set \$tmp_node = \$node._M_parent
					while \$node == \$tmp_node._M_right
						set \$node = \$tmp_node
						set \$tmp_node = \$tmp_node._M_parent
					end
					if \$node._M_right != \$tmp_node
						set \$node = \$tmp_node
					end
				end
				set \$i++
			end
		end
		if \$argc == 3
			set \$idx = \$arg2
			set \$ElementsFound = 0
			while \$i < \$tree_size
				set \$value = (void *)(\$node + 1)
				if *(\$arg1*)\$value == \$idx
					printf "elem[%u]: ", \$i
					p *(\$arg1*)\$value
					set \$ElementsFound++
				end
				if \$node._M_right != 0
					set \$node = \$node._M_right
					while \$node._M_left != 0
						set \$node = \$node._M_left
					end
				else
					set \$tmp_node = \$node._M_parent
					while \$node == \$tmp_node._M_right
						set \$node = \$tmp_node
						set \$tmp_node = \$tmp_node._M_parent
					end
					if \$node._M_right != \$tmp_node
						set \$node = \$tmp_node
					end
				end
				set \$i++
			end
			printf "Number of elements found = %u\n", \$ElementsFound
		end
		printf "Set size = %u\n", \$tree_size
	end
end

document pset
	Prints std::set<T> or std::multiset<T> information. Works for std::multiset as well.
	Syntax: pset <set> <T> <val>: Prints set size, if T defined all elements or just element(s) having val
	Examples:
	pset s - prints set size and definition
	pset s int - prints all elements and the size of s
	pset s int 20 - prints the element(s) with value = 20 (if any) and the size of s
end



#
# std::dequeue
#

define pdequeue
	if \$argc == 0
		help pdequeue
	else
		set \$size = 0
		set \$start_cur = \$arg0._M_impl._M_start._M_cur
		set \$start_last = \$arg0._M_impl._M_start._M_last
		set \$start_stop = \$start_last
		while \$start_cur != \$start_stop
			p *\$start_cur
			set \$start_cur++
			set \$size++
		end
		set \$finish_first = \$arg0._M_impl._M_finish._M_first
		set \$finish_cur = \$arg0._M_impl._M_finish._M_cur
		set \$finish_last = \$arg0._M_impl._M_finish._M_last
		if \$finish_cur < \$finish_last
			set \$finish_stop = \$finish_cur
		else
			set \$finish_stop = \$finish_last
		end
		while \$finish_first != \$finish_stop
			p *\$finish_first
			set \$finish_first++
			set \$size++
		end
		printf "Dequeue size = %u\n", \$size
	end
end

document pdequeue
	Prints std::dequeue<T> information.
	Syntax: pdequeue <dequeue>: Prints dequeue size, if T defined all elements
	Deque elements are listed "left to right" (left-most stands for front and right-most stands for back)
	Example:
	pdequeue d - prints all elements and size of d
end



#
# std::stack
#

define pstack
	if \$argc == 0
		help pstack
	else
		set \$start_cur = \$arg0.c._M_impl._M_start._M_cur
		set \$finish_cur = \$arg0.c._M_impl._M_finish._M_cur
		set \$size = \$finish_cur - \$start_cur
		set \$i = \$size - 1
		while \$i >= 0
			p *(\$start_cur + \$i)
			set \$i--
		end
		printf "Stack size = %u\n", \$size
	end
end

document pstack
	Prints std::stack<T> information.
	Syntax: pstack <stack>: Prints all elements and size of the stack
	Stack elements are listed "top to buttom" (top-most element is the first to come on pop)
	Example:
	pstack s - prints all elements and the size of s
end



#
# std::queue
#

define pqueue
	if \$argc == 0
		help pqueue
	else
		set \$start_cur = \$arg0.c._M_impl._M_start._M_cur
		set \$finish_cur = \$arg0.c._M_impl._M_finish._M_cur
		set \$size = \$finish_cur - \$start_cur
		set \$i = 0
		while \$i < \$size
			p *(\$start_cur + \$i)
			set \$i++
		end
		printf "Queue size = %u\n", \$size
	end
end

document pqueue
	Prints std::queue<T> information.
	Syntax: pqueue <queue>: Prints all elements and the size of the queue
	Queue elements are listed "top to bottom" (top-most element is the first to come on pop)
	Example:
	pqueue q - prints all elements and the size of q
end



#
# std::priority_queue
#

define ppqueue
	if \$argc == 0
		help ppqueue
	else
		set \$size = \$arg0.c._M_impl._M_finish - \$arg0.c._M_impl._M_start
		set \$capacity = \$arg0.c._M_impl._M_end_of_storage - \$arg0.c._M_impl._M_start
		set \$i = \$size - 1
		while \$i >= 0
			p *(\$arg0.c._M_impl._M_start + \$i)
			set \$i--
		end
		printf "Priority queue size = %u\n", \$size
		printf "Priority queue capacity = %u\n", \$capacity
	end
end

document ppqueue
	Prints std::priority_queue<T> information.
	Syntax: ppqueue <priority_queue>: Prints all elements, size and capacity of the priority_queue
	Priority_queue elements are listed "top to buttom" (top-most element is the first to come on pop)
	Example:
	ppqueue pq - prints all elements, size and capacity of pq
end



#
# std::bitset
#

define pbitset
	if \$argc == 0
		help pbitset
	else
		p /t \$arg0._M_w
	end
end

document pbitset
	Prints std::bitset<n> information.
	Syntax: pbitset <bitset>: Prints all bits in bitset
	Example:
	pbitset b - prints all bits in b
end



#
# std::string
#

define pstring
	if \$argc == 0
		help pstring
	else
		printf "String \t\t\t= \"%s\"\n", \$arg0._M_data()
		printf "String size/length \t= %u\n", \$arg0._M_rep()._M_length
		printf "String capacity \t= %u\n", \$arg0._M_rep()._M_capacity
		printf "String ref-count \t= %d\n", \$arg0._M_rep()._M_refcount
	end
end

document pstring
	Prints std::string information.
	Syntax: pstring <string>
	Example:
	pstring s - Prints content, size/length, capacity and ref-count of string s
end

#
# std::wstring
#

define pwstring
	if \$argc == 0
		help pwstring
	else
		call printf("WString \t\t= \"%ls\"\n", \$arg0._M_data())
		printf "WString size/length \t= %u\n", \$arg0._M_rep()._M_length
		printf "WString capacity \t= %u\n", \$arg0._M_rep()._M_capacity
		printf "WString ref-count \t= %d\n", \$arg0._M_rep()._M_refcount
	end
end

document pwstring
	Prints std::wstring information.
	Syntax: pwstring <wstring>
	Example:
	pwstring s - Prints content, size/length, capacity and ref-count of wstring s
end

EOF
}

####################
##    RUN MAIN    ##
####################

Main "$@"
