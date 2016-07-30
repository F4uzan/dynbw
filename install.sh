#!/bin/bash
# Installation script for DynBW
# Symlinks dynbw.sh to a kernel directory

read -p "Folder to install DynBW to: " install_to
if [ -e $install_to/dynbw.sh ]; then
	echo "build.sh already exists in installation directory!"
	echo "Please delete or move the file to continue installation"
	exit
else
	ln -s $PWD/dynbw.sh $install_to/dynbw.sh
	echo "Installation complete! Launch build.sh in $install_to to use DynBW"
	exit
fi