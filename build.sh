#!/bin/sh
# Dynamic Builder Wrapper (DynBW), version 0.2
# Handmade by F4uzan, with parts picked up from the internet
# Licensed under GPLv3

# Initialize variables
conf=dynbw/conf
hasconf=dynbw/hasconf
this_arch=$(cat $conf/arch)>nul
cc=$(cat $conf/cc)>nul
defconfig=$(cat $conf/defconfig)>nul
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
	read -p "Multiply cores count [y/N]? " thread_num
	echo
	echo "Saving configuration.."
	echo $this_arch  > $conf/arch
	echo $cc > $conf/cc
	echo $defconfig > $conf/defconfig
	echo true > $hasconf
	echo $quick_build > $conf/quick_build
	echo $thread_num > $conf/thread_num
	echo $clean > $conf/clean
fi

# Multiply core count if "thread_num" is enabled
if [ $thread_num == "y" ]; then
	core_count=$(($cores*2))
else
	core_count=$cores
fi

# Clean kerneldir if "clean" is enabled
if [ $clean == "y" ]; then
	export ARCH=$this_arch
	make $defconfig
	make clean && make mrproper
fi

# Skip menu and just build Quick Build is enabled
if [ $quick_build == "y" ]; then
	export ARCH=$this_arch
	export CROSS_COMPILE=$cc
	make $defconfig
	make -j$core_count
	exit
fi

# Menu, user selects an option here
clear
echo "// Dynamic Builder Wrapper"
echo "--------------------------"
echo "1.) Direct build"
echo "2.) Clean then build"
echo "3 ) Clean"
echo "0.) Exit"
read -p "Selection: " menu
case "$menu" in
1 ) export ARCH=$this_arch ; export CROSS_COMPILE=$cc; make $defconfig; make -j$core_count ;;
2 ) export ARCH=$this_arch ; export CROSS_COMPILE=$cc; make $defconfig; make mrproper; make -j$core_count ;;
3 ) export ARCH=$this_arch ; make $defconfig; make mrproper ;;
0 ) exit ;;
* ) echo "Invalid choice" ; sleep 2 ; $0 ;;
esac