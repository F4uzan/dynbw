#!/bin/sh
# Dynamic Build Wrapper for Android-compatible kernel source (DynBW)
# Version 1.0
# Handmade by F4, with parts picked from the internet
# Licensed under WTFPL, do whatever you want with it

# Import the script to the current environment using:
# "source dynbw.sh" (for BASH and other compatible Shells)
# ". dynbw.sh" (compatible with all Shells)

# Internal function: Imports variable
import_var() {
	# Misc. configuration-related variables
	conf_file=.dynbw_config

	# Register variables based on the configuration
	# Only register if the configuration exists
	if [ -f "$conf_file" ]; then
		cores="$(grep "cores=" "$conf_file" | cut -d"=" -f2 | sed -e "1{q}")"
		toolchain_path="$(grep "toolchain_path=" "$conf_file" | cut -d"=" -f2 | sed -e "1{q}")"

	else
		echo "/i\ Configuration file not found"
		echo "Run 'init' to create configuration file"
	fi

	# Try and find ccache
	# If ccache exists, prompts the user
	if command -v ccache 2>/dev/null; then
		echo "/i\ Valid ccache installation found"
		hasccache=true
	else
		echo "/i\ No valid ccache installation found"
		hasccache=false
	fi
}

# Builds kernel using configuration file
# Usage:
# build <argument> <defconfig>
#
# Argument:
# - clean: Do make clean before build
# - mrproper: Do make mrproper before building
# - wipe: Cleans kernel directory (mrproper) and ccache
#
# Example:
# build generic_arm64_defconfig
build() {
	flag="$1"
	defconfig="$2"
	export CROSS_COMPILE="$toolchain_path"
	if [ "$flag" = "clean" ]; then
		make clean
	elif [ "$flag" = "mrproper" ]; then
		make mrproper
	elif [ "$flag" = "wipe" ]; then
		if [ "$hasccache" = "true" ]; then
			ccache -c
		fi
		make mrproper
	else
		defconfig="$1"
	fi
	if [ -f "arch/arm/configs/$defconfig" ]; then
		export ARCH=arm
	elif [ -f "arch/arm64/configs/$defconfig" ]; then
		export ARCH=arm64
	elif [ -f "arch/x86/configs/$defconfig" ]; then
		export ARCH=x86
	else
		echo "/!\ $defconfig: Defconfig not found, exiting.."
		return
	fi
	if [ "$cores" = "auto" ]; then
		cores="$(nproc --all)"
	fi
	make "$defconfig" && make -j"$cores"
}

# Initialise configuration, use if configuration file is nonexistent
# To modify configuration, use "config" instead
init() {
	import_var
	if [ -f "$conf_file" ]; then
		echo "/!\ Existing configuration file found, exiting..."
		return
	fi
	echo "Initialising configuration..."
	touch .dynbw_config
	printf "Automatically detect CPU cores count for build system [Y/n]? "
	read -r a_cores
	if [ "$a_cores" = "y" ]; then
		printf "cores=auto\n" >> .dynbw_config
	else
		echo
		printf "How many CPU cores should the build system use? "
		read -r p_cores
		case "$p_cores" in
		    ''|*[!0-9]*) 
			printf "cores=%s\n" "$p_cores" >> .dynbw_config
			;;
		    *)
			echo "/!\ Invalid input detected, using automated cores detection instead"
			printf "cores=auto\n" >> .dynbw_config
			;;
		esac
	fi
	echo
	echo "Example toolchain path: /home/user/toolchain/bin/aarch64-linux-android-"
	echo "Do not forget to include the hyphen at the end of the path!"
	printf "Toolchain path: "
	read -r toolchain
	printf "toolchain_path=%s\n" "$toolchain" >> .dynbw_config
	echo
	echo "Configuration done!"
}

# Reconfigure the configuration file
# Does not initialise configuration, use init instead
reconfig() {
	import_var
	if [ ! -f "$conf_file" ]; then
		echo "/!\ Configuration file not found, exiting..."
		return
	fi
	if [ "$cores" = "auto" ]; then
		cores_display="Automatic"
	else
		cores_display="$cores"
	fi 
	echo "List of available configuration"
	echo
	echo "1.) Cores count   : $cores_display"
	echo "2.) Toolchain path: $toolchain_path"
	echo
	printf "Configuration to modify [1-2]: "
	read -r c_re
	if [ "$c_re" = "1" ]; then
		echo
		printf "Change cores count to [auto][0-99]: "
		read -r re_cores
		sed -i -e "s/cores=$cores/cores=$re_cores/g" .dynbw_config
		echo "/i\ Cores count changed to $re_cores"
		return
	elif [ "$c_re" = "2" ]; then
		echo
		printf "New toolchain path: "
		read -r re_toolchain
		sed -i -e "s#toolchain_path=$toolchain_path#toolchain_path=$re_toolchain#g" .dynbw_config
		echo "/i\ Toolchain path changed to $re_toolchain"
		return
	else
		echo "/!\ $c_re: Invalid input"
		return
	fi
}