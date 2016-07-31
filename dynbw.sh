#!/bin/bash
# Dynamic Builder Wrapper (DynBW), version PRE-0.3
# Handmade by F4uzan, with parts picked up from the internet
# Licensed under GPLv3

# Local configuration folder
conf=dynbw/conf
hasconf=dynbw/hasconf
hasver=dynbw/confver
validver=1

# Define configuration version
# If there is no file named confver, assume the user used old DynBW before
if [ -e $hasver ]; then
	confver=$($cat $hasver)>nul
else
	confver=0
fi

# Initialize variables
this_arch=$(cat $conf/arch)>nul
cc=$(cat $conf/cc)>nul
defconfig=$(cat $conf/defconfig)>nul
multi_defconfig=$(cat $conf/multi_defconfig)>nul
if [ $multi_defconfig == "y" ]; then
	defconfig_two=$(cat $conf/defconfig_two)>nul
	defconfig_two_default=$(cat $conf/defconfig_two_default)>nul
fi
thread_num=$(cat $conf/thread_num)>nul
quick_build=$(cat $conf/quick_build)>nul
clean=$(cat $conf/clean)>nul
cores=`cat /proc/cpuinfo | grep "^processor" | wc -l` "$@"

# Detect whether configuration exists
if [ -e $hasconf ]; then
	echo "Using generated configs.."
	conf_generated=true
else
	echo "No configs found"
	conf_generated=false
	mkdir dynbw && mkdir dynbw/conf
fi

# Create configuration if it doesn't exists
if [ $conf_generated == false ]; then
	clear
	echo "Setting up DynBW.."
	echo
	echo "Basic Settings"
	echo "--------------"
	read -p "Default architecture: " this_arch
	read -p "Cross Compiler path : " cc
	read -p "Default defconfig   : " defconfig
	read -p "Clean before build [Y/n]? " clean
	echo
	echo "Advanced Settings"
	echo "-----------------"
	read -p "Quick build [y/N]? " quick_build
	read -p "Handle two defconfig (disables quick build) [y/N]? " multi_defconfig
	read -p "Multiply cores count [y/N]? " thread_num
	if [ $multi_defconfig == "y" ]; then
		echo "Set second defconfig as default [y/N]? " defconfig_two_default
		read -p "Second defconfig : " defconfig_two
	fi
	echo
	echo "Saving configuration.."
	echo $this_arch  > $conf/arch
	echo $cc > $conf/cc
	echo $defconfig > $conf/defconfig
	echo $multi_defconfig > $conf/multi_defconfig
	if [ $multi_defconfig == "y" ]; then
		echo $defconfig_two > $conf/defconfig_two
		echo $defconfig_two_default > $conf/defconfig_two_default
	fi
	echo true > $hasconf
	echo $validver > $hasver
	echo $quick_build > $conf/quick_build
	echo $thread_num > $conf/thread_num
	echo $clean > $conf/clean
	confver=$validver
fi

# Handle older configuration version
if [ $confver == "0" ]; then
	echo 1 > $hasver
	read -p "Handle two defconfig (disables quick build) [y/N]? " multi_defconfig
	if [ $multi_defconfig == "y" ]; then
		echo "Set second defconfig as default [y/N]? " defconfig_two_default
		read -p "Second defconfig : " defconfig_two
	fi
	echo $multi_defconfig > $conf/multi_defconfig
	if [ $multi_defconfig == "y" ]; then
		echo $defconfig_two > $conf/defconfig_two
		echo $defconfig_two_default > $conf/defconfig_two_default
	fi
fi

# Multiply core count if "thread_num" is enabled
if [ $thread_num == "y" ]; then
	core_count=$(($cores*2))
else
	core_count=$cores
fi

# Clean kerneldir if "clean" is enabled
# Don't do anything if multi_defconfig is enabled
if [ $clean == "y" ] && [ $multi_defconfig == "N" ]; then
	export ARCH=$this_arch
	make $defconfig
	make clean && make mrproper
fi

# Skip menu and just build if Quick Build is enabled
# Make sure that multi_defconfig isn't enabled, if it's enabled then don't do anything
if [ $quick_build == "y" ] && [ $multi_defconfig == "N" ]; then
	export ARCH=$this_arch
	export CROSS_COMPILE=$cc
	make $defconfig
	make -j$core_count
	exit
fi

# Menu, user selects an option here
if [ $multi_defconfig == "N" ]; then
	clear
	echo "// Dynamic Builder Wrapper"
	echo "--------------------------"
	echo "1.) Direct build"
	echo "2.) Clean then build"
	echo "3.) Clean"
	echo "0.) Exit"
	read -p "Selection: " menu
	case "$menu" in
	1 ) export ARCH=$this_arch ; export CROSS_COMPILE=$cc; make $defconfig; make -j$core_count ;;
	2 ) export ARCH=$this_arch ; export CROSS_COMPILE=$cc; make $defconfig; make clean; make mrproper; make -j$core_count ;;
	3 ) export ARCH=$this_arch ; make $defconfig; make mrproper ;;
	0 ) exit ;;
	* ) echo "Invalid choice" ; sleep 2 ; $0 ;;
	esac
else
	clear
	if [ $defconfig_two_default == "y" ]; then
		curr_defconfig=$defconfig_two
		switch_defconfig=$defconfig
	else
		curr_defconfig=$defconfig
		switch_defconfig=$defconfig_two
	fi
	echo "// Dynamic Builder Wrapper"
	echo "--------------------------"
	echo "Current defconfig : $curr_defconfig"
	echo "1.) Direct build"
	echo "2.) Clean then build"
	echo "3.) Clean"
	echo "0.) Exit"
	echo "9.) Switch to $switch_defconfig then build"
	read -p "Selection: " menu
	case "$menu" in
	1 ) export ARCH=$this_arch ; export CROSS_COMPILE=$cc; make $curr_defconfig; make -j$core_count ;;
	2 ) export ARCH=$this_arch ; export CROSS_COMPILE=$cc; make $curr_defconfig; make clean; make mrproper; make -j$core_count ;;
	3 ) export ARCH=$this_arch ; make $defconfig; make mrproper ;;
	0 ) exit ;;
	9 ) export ARCH=$this_arch ; export CROSS_COMPILE=$cc; make $switch_defconfig; make -j$core_count ;;
	* ) echo "Invalid choice" ; sleep 2 ; $0 ;;
	esac
fi