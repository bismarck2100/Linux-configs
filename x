#!/bin/bash

#set -o trace

################
#   Functions  #
################

Usage() {
    printf "Usage: $0 OPTIONS [OPTARGS]\n"
    printf "    %-25s %s\n" "-e" "Bootstrap dev environment"
    printf "    %-25s %s\n" "-l" "Link confs & tools"
    printf "    %-25s %s\n" "-L" "Unlink confs & tools"
    printf "    %-25s %s\n" "-h" "Show help"
}

bootstrapEnv() {
	apt update || sudo apt update
    apt install -y ssh vim curl ctags cscope make tmux sed silversearcher-ag cifs-utils

	curl https://raw.githubusercontent.com/Shougo/neobundle.vim/master/bin/install.sh | sh

	link

	sed -i 's/PermitRootLogin.*$/PermitRootLogin yes/' /etc/ssh/sshd_config
	/etc/init.d/ssh start
	echo "Set your root password with passwd!"
}

link() {
	echo "Linking"

	[ ! -d ~/bin ] && mkdir -p ~/bin
	bins=$(find bin/ -maxdepth 1 -xtype f)
	for binary in $bins; do
		binary=$(basename $binary)
		ln -sf $(pwd)/bin/$binary /bin/$binary
	done

	configs=$(find env/ -maxdepth 1 -xtype f)
	for config in $configs; do
		config=$(basename $config)
		[ -f ~/$config ] && [ ! -f ~/${config}.bak ] && mv -f ~/$config ~/${config}.bak && echo "backup config $config to ${config}.bak"
		ln -sf $(pwd)/env/$config ~/$config
	done
}

unlink() {
	echo "Unlinking"

	bins=$(find bin/ -maxdepth 1 -xtype f)
	for binary in $bins; do
		binary=$(basename $binary)
		rm -f /bin/$binary
	done

	configs=$(find env/ -maxdepth 1 -xtype f)
	for config in $configs; do
		config=$(basename $config)
		rm -f ~/$config && mv -f ~/${config}.bak ~/$config
	done
}

Main() {
	opt="$1"

	case $opt in
	"-e")
		bootstrapEnv ;;
	"-l")
		link ;;
	"-L")
		unlink ;;
	*)
		Usage ;;
	esac
}

Main "$@"
