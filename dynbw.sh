#!/bin/sh
# Dynamic Build Wrapper for Android-compatible kernel source (DynBW)
# Version 1.6.0706
# Handmade by F4, with parts picked from the internet.
# Licensed under WTFPL, do whatever you want with it.

# Import the script to the current environment using:
# "source dynbw.sh" (for Bash and other compatible Shells)
# ". dynbw.sh" (generally compatible with all Shells)

dynbw_version="1.6.0706"

# Internal function: Imports variable
import_var() {
	arg="$1"
	extra_arg="$2"
	conf_file=".dynbw_config"

	case "$arg" in
	conf_init)
		# Register variables based on the configuration
		# Only register if the configuration exists
		if [ -f "$conf_file" ]; then
			cores="$(grep "cores=" "$conf_file" | cut -d"=" -f2 | sed -e '1{q;}')"
			toolchain_arm="$(grep "toolchain_arm=" "$conf_file" | cut -d"=" -f2 | sed -e '1{q;}')"
			toolchain_arm64="$(grep "toolchain_arm64=" "$conf_file" | cut -d"=" -f2 | sed -e '1{q;}')"
			toolchain_ia32="$(grep "toolchain_ia32=" "$conf_file" | cut -d"=" -f2 | sed -e '1{q;}')"
			toolchain_ia64="$(grep "toolchain_ia64=" "$conf_file" | cut -d"=" -f2 | sed -e '1{q;}')"
		else
			if [ ! "$extra_arg" = "--mkconfig" ]; then
				echo "/!\ Configuration file not found"
				echo "Run 'config init' to create configuration file"
				return
			fi
		fi
	;;
	ccache_init)
		# Try and find ccache
		# If ccache exists, prompts the user
		if command -v ccache > /dev/null 2>&1; then
			echo "[i] Valid ccache installation found"
			hasccache=true
		else
			echo "[i] No valid ccache installation found"
			hasccache=false
		fi
	;;
	esac
}

# Internal function: hosts all dynbw function
dynbw() {
	cmd="$1"
	arg="$2"
	e_arg="$3"
	
	case "$cmd" in
	build)
		# Builds kernel using configuration file
		# Usage:
		# dynbw build <argument> <defconfig>
		#
		# Argument:
		# - clean: Do make clean before build
		# - mrproper: Do make mrproper before building
		# - wipe: Cleans kernel directory (mrproper) and ccache
		# - help: Shows help
		
		flag="$arg"
		defconfig="$e_arg"

		case "$flag" in
		--clean|-c)
			import_var conf_init
			import_var ccache_init
			make clean ;;
		--mrproper|-m)
			import_var conf_init
			import_var ccache_init
			make mrproper ;;
		--wipe|-w)
			import_var conf_init
			import_var ccache_init
			if [ "$hasccache" = "true" ]; then
				ccache -c
			fi
			make mrproper
			;;
		--help|-h|"")
			echo "usage: dynbw build [<argument>] <defconfig>"
			echo
			echo "Executes build process"
			echo
			echo "Arguments:"
			echo "	--clean/-c		: Do make clean before build"
			echo "	--mrproper/-m		: Do make mrproper before building"
			echo "	--wipe/-w		: Cleans kernel directory (mrproper) and ccache"
			echo "	--help/-h		: Display this help text"
			return
			;;
		*)
			shift
			defconfig="$1"
			;;
		esac
		
		import_var conf_init
		import_var ccache_init

		if [ -f "arch/arm/configs/$defconfig" ]; then
			export ARCH=arm
			export SUBARCH=arm
		elif [ -f "arch/arm64/configs/$defconfig" ]; then
			export ARCH=arm64
			export SUBARCH=arm64
		elif [ -f "arch/x86/configs/$defconfig" ]; then
			export ARCH=x86
			export SUBARCH=x86
		else
			echo "/!\ $defconfig not found, exiting.."
			return
		fi
		
		case "$ARCH" in
		arm)
			if [ "$toolchain_arm" = "" ]; then
				echo "/!\ Unable to find toolchain for ARM, exiting.."
				return
			fi
			export CROSS_COMPILE="$toolchain_arm"
			;;
		arm64)
			if [ "$toolchain_arm64" = "" ]; then
				echo "/!\ Unable to find toolchain for ARM64, exiting.."
				return
			fi
			export CROSS_COMPILE="$toolchain_arm64"
			;;
		#TODO: Detection for Intel is broken. Temporarily disabling the 32-bit for now.
		#i686)
		#	if [ "$toolchain_ia32" = "" ]; then
		#		echo "/!\ Unable to find toolchain for Intel 32-bit, exiting.."
		#		return
		#	fi
		#	export CROSS_COMPILE="$toolchain_ia32"
		#	;;
		x86)
			if [ "$toolchain_ia64" = "" ]; then
				echo "/!\ Unable to find toolchain for Intel 64-bit, exiting.."
				return
			fi
			export CROSS_COMPILE="$toolchain_ia64"
			;;
		esac
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
		;;
	config)
		# Configuration-related function
		# Used to create or modify configuration
		#
		# Usage:
		# dynbw config <argument>
		#
		# Argument:
		# --init: Creates a configuration file
		# --reconfig: Modifies existing configuration file
		# --help: Shows help
		
		c_arg="$arg"
		case "$c_arg" in
		--init|-i)
			import_var conf_init --mkconfig
			temp_conf_file=".dynbw_config_temp"
			if [ -f "$conf_file" ]; then
				echo "/!\ Existing configuration file found, exiting..."
				return
			fi
			if [ -f "$temp_conf_file" ]; then
				rm "$temp_conf_file"
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
			echo "Example toolchain path: /home/user/aarch64-eabi-4.9"
			printf "Toolchain path: "
			read -r input_toolchain
			if [ "$input_toolchain" = "" ]; then
				echo "/!\ Empty input, exiting..."
				rm "$temp_conf_file"
				return
			fi
			if [ ! -d "$input_toolchain" ]; then
				echo "/!\ Defined path not found or is not a directory"
				return
			fi
			find_gcc="$(ls $input_toolchain/bin/ | grep -m 1 "\-gcc" | sed "s/gcc//g")"
			if [ "$find_gcc" = "" ]; then
				echo "/!\ Unable to find toolchain in defined path"
				return
			fi
			toolchain="$input_toolchain/bin/$find_gcc"
			toolchain_arm="$(echo "$toolchain" | grep -c "arm" | sed -e '1{q;}')"
			toolchain_arm64="$(echo "$toolchain" | grep -c "aarch64" | sed -e '1{q;}')"
			toolchain_ia32="$(echo "$toolchain" | grep -c "i686" | sed -e '1{q;}')"
			toolchain_ia64="$(echo "$toolchain" | grep -c "x86_64" | sed -e '1{q;}')"
			no_arch=0
			if [ "$toolchain_arm" -gt 0 ]; then
				echo "[i] ARM-compatible toolchain detected"
				toolchain_arch=arm
				toolchain_exclude="arm64, ia32, ia64"
			elif [ "$toolchain_arm64" -gt 0 ]; then
				echo "[i] ARM64-compatible toolchain detected"
				toolchain_arch=arm64
				toolchain_exclude="arm, ia32, ia64"
			elif [ "$toolchain_ia32" -gt 0 ]; then
				echo "[i] Intel 32-bit toolchain detected"
				toolchain_arch=ia32
				toolchain_exclude="arm, arm64, ia64"
			elif [ "$toolchain_ia64" -gt 0 ]; then
				echo "[i] Intel 64-bit toolchain detected"
				toolchain_arch=ia64
				toolchain_exclude="arm, arm64, ia32"
			else
				echo "/!\ Unable to automatically detect toolchain architecture"
				echo "[i] Please manually enter the architecture"
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
						echo "toolchain_ia32="
						echo "toolchain_ia64="
					} >> "$temp_conf_file"
				elif [ "$manual_arch" = "2" ]; then
					{
						echo "toolchain_arm64=$toolchain"
						echo "toolchain_arm="
						echo "toolchain_ia32="
						echo "toolchain_ia64="
					} >> "$temp_conf_file"
				elif [ "$manual_arch" = "3" ]; then
					{
						echo "tooclhain_ia32=$toolchain"
						echo "toolchain_arm="
						echo "toolchain_arm64="
						echo "toolchain_ia64="
					} >> "$temp_conf_file"
				elif [ "$manual_arch" = "4" ]; then
					{
						echo "toolchain_ia64=$toolchain"
						echo "toolchain_arm="
						echo "toolchain_arm64="
						echo "toolchain_ia32="
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
			if [ "$toolchain_ia32" = "" ]; then
				ia32_path="Empty"
			else
				ia32_path="$toolchain_ia32"
			fi
			if [ "$toolchain_ia64" = "" ]; then
				ia64_path="Empty"
			else
				ia64_path="$toolchain_ia64"
			fi
			echo "List of available configuration"
			echo
			echo "1.) Cores count        : $cores_display"
			echo "2.) ARM Toolchain      : $arm_path"
			echo "3.) ARM64 Toolchain    : $arm64_path"
			echo "4.) Intel-32 Toolchain : $ia32_path"
			echo "5.) Intel-64 Toolchain : $ia64_path"
			echo
			printf "Configuration to modify [1-5]: "
			read -r c_re
			if [ "$c_re" = "1" ]; then
				echo
				printf "Change cores count to [auto][0-99]: "
				read -r re_cores
				sed -i -e "s/cores=$cores/cores=$re_cores/g" "$conf_file"
				echo "[i] Cores count changed to $re_cores"
				return
			elif [ "$c_re" -gt "1" ]; then
				if [ "$c_re" = "2" ]; then
					c_toolchain="toolchain_arm"
					v_toolchain="$toolchain_arm"
				elif [ "$c_re" = "3" ]; then
					c_toolchain="toolchain_arm64"
					v_toolchain="$toolchain_arm64"
				elif [ "$c_re" = "4" ]; then
					c_toolchain="toolchain_ia32"
					v_toolchain="$toolchain_ia32"
				elif [ "$c_re" = "5" ]; then
					c_toolchain="toolchain_ia64"
					v_toolchain="$toolchain_ia64"
				fi
				echo
				echo "Example toolchain path: /home/user/aarch64-eabi-4.9"
				printf "New toolchain path: "
				read -r re_toolchain
				if [ ! -d "$re_toolchain" ]; then
					echo "/!\ Defined path not found or is not a directory"
					return
				fi
				find_gcc="$(ls $re_toolchain/bin/ | grep -m 1 "\-gcc" | sed "s/gcc//g")"
				if [ "$find_gcc" = "" ]; then
					echo "/!\ Unable to find toolchain in defined path"
					return
				fi
				g_toolchain="$re_toolchain/bin/$find_gcc"
				sed -i -e "s#$c_toolchain=$v_toolchain#$c_toolchain=$g_toolchain#g" "$conf_file"
				echo "[i] Toolchain path changed to $g_toolchain"
				return
			elif [ "$c_re" -gt "5" ]; then
				echo "/!\ $c_re: Input out of range"
				return
			else
				echo "/!\ $c_re: Invalid input"
				return
			fi
			;;
		--help|-h|*)
			echo "usage: dynbw config [<argument>]"
			echo
			echo "Helper function to manage configuration file"
			echo
			echo "Arguments:"
			echo "	--init/-i		: Creates a configuration file"
			echo "	--reconfig/-r		: Modifies existing configuration file"
			echo "	--help/-h		: Display this help text"
		esac
		;;
		
	sync)
		# A helper function for Git
		# Acts in a similar manner to that of "repo"
		# Fetches everything defined in sync.txt
		#
		# Usage:
		# dynbw sync <argument>
		#
		# Arguments:
		# --force: Force update repositories, ignoring errors
		# --help: Shows help
		
		if ! command -v git > /dev/null 2>&1; then
			echo "/!\ No valid Git installation found, canceling sync"
			return
		fi
		c_arg="$arg"
		if [ ! -f "sync.txt" ]; then
			echo "/!\ Cannot find sync.txt in the current directory"
			return
		fi
		case "$c_arg" in
		--help|-h)
			echo "usage: dynbw sync [<argument>]"
			echo
			echo "Synces repositories defined in sync.txt"
			echo "Please read the supplied README before using sync"
			echo
			echo "Arguments:"
			echo "	--force/-f	: Force update repositories, ignoring errors"
			echo "	--help/-h	: Display this help text"
			return
			;;
		--force|-f)
			use_force=true
			;;
		esac
		IFS="$(printf '%b_' '\n')"; IFS="${IFS%_}"
		sed '/^[ \t]*$/d' sync.txt | while read -r line; do
			first_char="$(echo "$line" | head -c1)"
			if [ "$first_char" = "/" ]; then
				com="$(echo "$line" | cut -d":" -f1)"
				arg="$(echo "$line" | cut -d":" -f2)"
				case $com in
				/save_to|"/ save_to")
					dir="$(echo "$arg" | xargs)"
					if [ ! -d "$dir" ]; then
						mkdir -p "$dir"
					fi
					;;
				/note|"/ note")
					text="$arg"
					if [ "$text" = "" ]; then
						echo "/!\ /note received no text to display"
					else
						echo "$text"
					fi
					;;
				*) echo "/!\ $com: command not found" ;;
				esac
			elif [ "$first_char" != "#" ]; then
				dest="$(echo "$line" | cut -d"|" -f1)"
				branch="$(echo "$line" | cut -d"|" -f2)"
				link="$(echo "$line" | cut -d"|" -f3)"
				if [ "$dir" = "" ]; then
					echo "/!\ No sync directory is set, canceling sync"
					return
				fi
				if [ ! -d "$dir/$dest" ]; then
					git clone -b "$branch" "$link" "$dir/$dest"
				else
					if [ "$(git rev-parse --resolve-git-dir "$dir/$dest/.git")" = "$dir/$dest/.git" ]; then
						if [ "$use_force" = "true" ]; then
							echo "[i] $dir/$dest found. Force updating instead"
							git -C "$dir/$dest" pull
						else
							echo "[i] $dir/$dest found. Updating instead"
							git -C "$dir/$dest" pull -f
						fi
					else
						echo "[i] $dir/$dest found, but it's not a valid Git repository. Ignoring sync for $dest"
					fi
				fi
			fi
		done
		unset IFS
		;;
	--version)
		echo "DynBW version $dynbw_version"
		return
		;;
	-h|--help)
		echo "usage: dynbw [--version] [--help] <command> [<arguments>]"
		echo
		echo "Available commands:"
		echo "	build	: Executes build process"
		echo "	config	: Creates or modify existing configuration file"
		echo "	sync	: Synces repository defined in sync.txt"
		echo
		echo "For help in a specific command, use 'dynbw <command> --help'"
		;;
	"") 
		echo "Received empty or no command. Use '--help' for the list of available commands"
		;;
	*)
		echo "Unknown option: $cmd"
		;;
	esac
}
