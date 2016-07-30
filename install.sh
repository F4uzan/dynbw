#!/bin/bash
# Installation script for DynBW
# Symlinks build.sh to a kernel directory

read -p "Folder to install DynBW to: " install_to
if [ -e $install_to/build.sh ]; then
	echo "build.sh already exists in installation directory!"
	echo "Please delete or move the file to continue installation"
	exit
else
	ln -s $PWD/build.sh $install_to
	echo "Installation complete! Launch build.sh in $install_to to use DynBW"
fi