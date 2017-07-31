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
	arg="$1"
	conf_file=".dynbw_config"

	case "$arg" in
	conf_init)
		# Register variables based on the configuration
		# Only register if the configuration exists
		if [ -f "$conf_file" ]; then
			cores="$(grep "cores=" "$conf_file" | cut -d"=" -f2 | sed -e '1{q;}')"
			toolchain_arm="$(grep "toolchain_arm=" "$conf_file" | cut -d"=" -f2 | sed -e '1{q;}')"
			toolchain_arm64="$(grep "toolchain_arm64=" "$conf_file" | cut -d"=" -f2 | sed -e '1{q;}')"
			toolchain_i686="$(grep "toolchain_i686=" "$conf_file" | cut -d"=" -f2 | sed -e '1{q;}')"
			toolchain_x86_64="$(grep "toolchain_x86_64=" "$conf_file" | cut -d"=" -f2 | sed -e '1{q;}')"
		else
			echo "/i\ Configuration file not found"
			echo "Run 'config init' to create configuration file"
		fi
	;;
	ccache_init)
		# Try and find ccache
		# If ccache exists, prompts the user
		if command -v ccache 2>/dev/null; then
			echo "/i\ Valid ccache installation found"
			hasccache=true
		else
			echo "/i\ No valid ccache installation found"
			hasccache=false
		fi
	;;
	esac
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
	import_var conf_init
	import_var ccache_init
	flag="$1"
	defconfig="$2"

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
		echo "Executes build process"
		echo
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
		echo "build clean generic_arm64_defconfig"
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
	if [ "$ARCH" = "arm" ]; then
		if [ "$toolchain_arm" = "" ]; then
			echo "/!\ Unable to find toolchain for ARM, exiting.."
			return
		fi
		export CROSS_COMPILE="$toolchain_arm"
	elif [ "$ARCH" = "arm64" ]; then
		if [ "$toolchain_arm64" = "" ]; then
			echo "/!\ Unable to find toolchain for ARM64, exiting.."
			return
		fi
		export CROSS_COMPILE="$toolchain_arm64"
	elif [ "$ARCH" = "i686" ]; then
		if [ "$toolchain_i686" = "" ]; then
			echo "/!\ Unable to find toolchain for Intel 32-bit, exiting.."
			return
		fi
		export CROSS_COMPILE="$toolchain_i686"
	elif [ "$ARCH" = "x86_64" ]; then
		if [ "$toolchain_x86_64" = "" ]; then
			echo "/!\ Unable to find toolchain for Intel 64-bit, exiting.."
			return
		fi
		export CROSS_COMPILE="$toolchain_x86_64"
	fi
	if [ "$cores" = "auto" ]; then
		if [ "$(uname -s)" = "Darwin" ]; then
			cores="$(sysctl -n hw.ncpu)"
		elif [ "$(uname -s)" = "Linux" ]; then
			cores="$(nproc --all)"
		else
			cores="1"
		fi
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
		import_var conf_init
		temp_conf_file=".dynbw_config_temp"
		if [ -f "$conf_file" ]; then
			echo "/!\ Existing configuration file found, exiting..."
			return
		fi
		echo "Initialising configuration..."
		touch "$temp_conf_file"
		printf "Automatically detect CPU cores count for build system [Y/n]? "
		read -r a_cores
		if [ "$(echo "$a_cores" | tr "[:upper:]" "[:lower:]")" = "y" ]; then
			printf "cores=auto\n" >> "$temp_conf_file"
		else
			echo
			printf "How many CPU cores should the build system use? "
			read -r p_cores
			case "$p_cores" in
			''|*[!0-9]*) 
				echo "/!\ Invalid input detected, using automated cores detection instead"
				printf "cores=auto\n" >> "$temp_conf_file"
				;;
			*)
				printf "cores=%s\n" "$p_cores" >> "$temp_conf_file"
				;;
		esac
		fi
		echo
		echo "Example toolchain path: /home/user/toolchain/bin/aarch64-linux-android-"
		echo "Do not forget to include the hyphen at the end of the path!"
		printf "Toolchain path: "
		read -r toolchain
		if [ "$toolchain" = "" ]; then
			echo "/!\ Empty input, exiting..."
			rm "$temp_conf_file"
			return
		fi
		toolchain_arm="$(echo "$toolchain" | grep -c "arm" | sed -e '1{q;}')"
		toolchain_arm64="$(echo "$toolchain" | grep -c "aarch64" | sed -e '1{q;}')"
		toolchain_i686="$(echo "$toolchain" | grep -c "i686" | sed -e '1{q;}')"
		toolchain_x86_64="$(echo "$toolchain" | grep -c "x86_64" | sed -e '1{q;}')"
		no_arch=0
		if [ "$toolchain_arm" -gt 0 ]; then
			echo "/i\ ARM-compatible toolchain detected"
			toolchain_arch=arm
			toolchain_exclude="arm64, i686, x86_64"
		elif [ "$toolchain_arm64" -gt 0 ]; then
			echo "/i\ ARM64-compatible toolchain detected"
			toolchain_arch=arm64
			toolchain_exclude="arm, i686, x86_64"
		elif [ "$toolchain_i686" -gt 0 ]; then
			echo "/i\ Intel 32-bit toolchain detected"
			toolchain_arch=i686
			toolchain_exclude="arm, arm64, x86_64"
		elif [ "$toolchain_x86_64" -gt 0 ]; then
			echo "/i\ Intel 64-bit toolchain detected"
			toolchain_arch=x86_64
			toolchain_exclude="arm, arm64, i686"
		else
			echo "/!\ Unable to automatically detect toolchain architecture"
			echo "/i\ Please manually enter the architecture"
			no_arch=1
		fi
		if [ "$no_arch" = "0" ]; then
			printf "Is the detection correct [Y/n]? "
			read -r confirm_toolchain
			if [ "$(echo "$confirm_toolchain" | tr "[:upper:]" "[:lower:]")" = "n" ]; then
				no_arch="1"
			else
				echo "toolchain_$toolchain_arch=$toolchain" >> "$temp_conf_file"
				c=1;
				while [ "$c" -le 3 ]; do
					exc_t="$(echo "$toolchain_exclude" | cut -d"," -f$c | xargs)";
					c=$((c+1));
					echo "toolchain_$exc_t=" >> "$temp_conf_file"
				done;
			fi
		fi
		if [ "$no_arch" = "1" ]; then
			echo "Available architecture"
			echo
			echo "1. ARM, 32-bit"
			echo "2. ARM, 64-bit"
			echo "3. Intel, 32-bit"
			echo "4. Intel, 64-bit"
			echo
			printf "Select architecture [1-4]: "
			read -r manual_arch
			if [ "$manual_arch" = "1" ]; then
				{
					echo "toolchain_arm=$toolchain"
					echo "toolchain_arm64="
					echo "toolchain_i686="
					echo "toolchain_x86_64="
				} >> "$temp_conf_file"
			elif [ "$manual_arch" = "2" ]; then
				{
					echo "toolchain_arm64=$toolchain"
					echo "toolchain_arm="
					echo "toolchain_i686="
					echo "toolchain_x86_64="
				} >> "$temp_conf_file"
			elif [ "$manual_arch" = "3" ]; then
				{
					echo "tooclhain_i686=$toolchain"
					echo "toolchain_arm="
					echo "toolchain_arm64="
					echo "toolchain_x86_64="
				} >> "$temp_conf_file"
			elif [ "$manual_arch" = "4" ]; then
				{
					echo "toolchain_x86_64=$toolchain"
					echo "toolchain_arm="
					echo "toolchain_arm64="
					echo "toolchain_i686="
				} >> "$temp_conf_file"
			else
				echo "/!\ Invalid input, exiting..."
				rm "$temp_conf_file"
				return
			fi
		fi
		echo
		mv "$temp_conf_file" "$conf_file"
		echo "Configuration done!"
		;;
	--reconfig|-r)
		import_var conf_init
		if [ ! -f "$conf_file" ]; then
			echo "/!\ Configuration file not found, exiting..."
			return
		fi
		if [ "$cores" = "auto" ]; then
			cores_display="Automatic"
		else
			cores_display="$cores"
		fi
		if [ "$toolchain_arm" = "" ]; then
			arm_path="Empty"
		else
			arm_path="$toolchain_arm"
		fi
		if [ "$toolchain_arm64" = "" ]; then
			arm64_path="Empty"
		else
			arm64_path="$toolchain_arm64"
		fi
		if [ "$toolchain_i686" = "" ]; then
			i686_path="Empty"
		else
			i686_path="$toolchain_i686"
		fi
		if [ "$toolchain_x86_64" = "" ]; then
			x86_64_path="Empty"
		else
			x86_64_path="$toolchain_x86_64"
		fi
		echo "List of available configuration"
		echo
		echo "1.) Cores count        : $cores_display"
		echo "2.) ARM Toolchain      : $arm_path"
		echo "3.) ARM64 Toolchain    : $arm64_path"
		echo "4.) Intel-32 Toolchain : $i686_path"
		echo "5.) Intel-64 Toolchain : $x86_64_path"
		echo
		printf "Configuration to modify [1-5]: "
		read -r c_re
		if [ "$c_re" = "1" ]; then
			echo
			printf "Change cores count to [auto][0-99]: "
			read -r re_cores
			sed -i -e "s/cores=$cores/cores=$re_cores/g" "$conf_file"
			echo "/i\ Cores count changed to $re_cores"
			return
		elif [ "$c_re" -gt "1" ]; then
			if [ "$c_re" = "2" ]; then
				c_toolchain="toolchain_arm"
				v_toolchain="$toolchain_arm"
			elif [ "$c_re" = "3" ]; then
				c_toolchain="toolchain_arm64"
				v_toolchain="$toolchain_arm64"
			elif [ "$c_re" = "4" ]; then
				c_toolchain="toolchain_i686"
				v_toolchain="$toolchain_i686"
			elif [ "$c_re" = "5" ]; then
				c_toolchain="toolchain_x86_64"
				v_toolchain="$toolchain_x86_64"
			fi
			echo
			printf "New toolchain path: "
			read -r re_toolchain
			sed -i -e "s#$c_toolchain=$v_toolchain#$c_toolchain=$re_toolchain#g" "$conf_file"
			echo "/i\ Toolchain path changed to $re_toolchain"
			return
		elif [ "$c_re" -gt "5" ]; then
			echo "/!\ $c_re: Input out of range"
			return
		else
			echo "/!\ $c_re: Invalid input"
		fi
		;;
	--help|-h|*)
		echo "DynBW v$dynbw_version"
		echo
		echo "Helper function to manage configuration file"
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

# A helper function for Git
# Acts in a similar manner to that of "repo"
# Fetches everything defined in sync.txt
#
# Usage:
# sync <argument> <save directory> or sync <argument>
#
# Arguments:
# --force: Force update repositories, ignoring errors
# --help: Shows help
sync() {
	arg="$1"
	dir="$2"
	currdir="$(pwd)"
	input_fetch="$(cat sync.txt)"
	case "$arg" in
	--help|-h)
		echo "DynBW v$dynbw_version"
		echo
		echo "Synces repositories defined in sync.txt"
		echo "Please read the supplied README before using sync"
		echo
		echo "Usage:"
		echo "sync <argument> <save directory> or sync <argument>"
		echo
		echo "Argument:"
		echo "--force: Force update repositories, ignoring errors"
		echo "--help: Shows help"
		return
		;;
	--force|-f)
		use_force=true
		;;
	*)
		dir="$1"
		use_force=false
		;;
	esac
	if [ ! -d "$dir" ]; then
		mkdir -p "$dir"
	fi
	local IFS=$'\n'
	for line in $input_fetch; do
		is_comment="$(echo "$line" | head -c1)"
		if [ "$is_comment" != "#" ]; then
			dest="$(echo "$line" | cut -d"|" -f1)"
			branch="$(echo "$line" | cut -d"|" -f2)"
			link="$(echo "$line" | cut -d"|" -f3)"
			if [ ! -d "$dir/$dest" ]; then
				git clone -b "$branch" "$link" "$dir/$dest"
			else
				if [ "$(git rev-parse --resolve-git-dir "$dir/$dest/.git")" = "$dir/$dest/.git" ]; then
					if [ "$use_force" = "true" ]; then
						echo "/!\ $dir/$dest found. Force updating instead"
						cd "$dir/$dest" || return
						git pull
						cd "$currdir" || return
					else
						echo "/!\ $dir/$dest found. Updating instead"
						cd "$dir/$dest" || return
						git pull -f
						cd "$currdir" || return
					fi
				else
					echo "/!\ $dir/$dest found, but it's not a valid Git repository. Ignoring sync for $dest"
				fi
			fi
		fi
	done
	unset IFS
}