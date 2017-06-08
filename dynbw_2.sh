#!/bin/sh
# Dynamic Build Wrapper for Android-compatible kernel source (DynBW)
# Version 1.0
# Handmade by F4, with parts picked from the internet
# Licensed under WTFPL, do whatever you want with it

# Import the script to the current environment using:
# "source dynbw.sh" (for BASH and other compatible Shells)
# ". dynbw.sh" (compatible with all Shells)

dynbw_version=1.0

# Internal function: Imports variable
import_var() {
	# Misc. configuration-related variables
	conf_file=".dynbw_config"

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
# - help: Shows help
#
# Example:
# build generic_arm64_defconfig
build() {
	flag="$1"
	defconfig="$2"
	export CROSS_COMPILE="$toolchain_path"

	case "$flag" in
	--clean|-c) make clean ;;
	--mrproper|-m) make mrproper ;;
	--wipe|-w)
		if [ "$hasccache" = "true" ]; then
			ccache -c
		fi
		make mrproper
		;;
	--help|-h|"")
		echo "DynBW v$dynbw_version"
		echo
		echo "Builds kernel using configuration file"
		echo "Usage:"
		echo "build <optional argument> <defconfig>"
		echo
		echo "Optional argument:"
		echo "--clean: Do make clean before build"
		echo "--mrproper: Do make mrproper before building"
		echo "--wipe: Cleans kernel directory (mrproper) and ccache"
		echo "--help: Display this help text"
		echo
		echo "Example:"
		echo "build generic_arm64_defconfig"
		return
		;;
	*) defconfig="$1" ;;
	esac

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

# Configuration-related function
# Used to create or modify configuration
#
# Usage:
# config <argument>
#
# Argument:
# --init: Creates a configuration file
# --reconfig: Modifies existing configuration file
# --help: Shows help
config() {
	arg="$1"
	case "$arg" in
	--init|-i)
		import_var
		if [ -f "$conf_file" ]; then
			echo "/!\ Existing configuration file found, exiting..."
			return
		fi
		echo "Initialising configuration..."
		touch "$conf_file"
		printf "Automatically detect CPU cores count for build system [Y/n]? "
		read -r a_cores
		if [ "$a_cores" = "y" ]; then
			printf "cores=auto\n" >> "$conf_file"
		else
			echo
			printf "How many CPU cores should the build system use? "
			read -r p_cores
			case "$p_cores" in
			''|*[!0-9]*) 
				echo "/!\ Invalid input detected, using automated cores detection instead"
				printf "cores=auto\n" >> "$conf_file"
				;;
			*)
				printf "cores=%s\n" "$p_cores" >> "$conf_file"
				;;
		esac
		fi
		echo
		echo "Example toolchain path: /home/user/toolchain/bin/aarch64-linux-android-"
		echo "Do not forget to include the hyphen at the end of the path!"
		printf "Toolchain path: "
		read -r toolchain
		printf "toolchain_path=%s\n" "$toolchain" >> "$conf_file"
		echo
		echo "Configuration done!"
		;;
	--reconfig|-r)
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
			sed -i -e "s/cores=$cores/cores=$re_cores/g" "$conf_file"
			echo "/i\ Cores count changed to $re_cores"
			return
		elif [ "$c_re" = "2" ]; then
			echo
			printf "New toolchain path: "
			read -r re_toolchain
			sed -i -e "s#toolchain_path=$toolchain_path#toolchain_path=$re_toolchain#g" "$conf_file"
			echo "/i\ Toolchain path changed to $re_toolchain"
			return
		else
			echo "/!\ $c_re: Invalid input"
			return
		fi
		;;
	--help|-h|*)
		echo "DynBW v$dynbw_version"
		echo
		echo "Configuration-related function"
		echo "Used to create or modify configuration"
		echo
		echo "Usage:"
		echo "config <argument>"
		echo
		echo "Argument:"
		echo "--init: Creates a configuration file"
		echo "--reconfig: Modifies existing configuration file"
		echo "--help: Shows help"
	esac
}