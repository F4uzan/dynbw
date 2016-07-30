#!/bin/bash
# Installation script for DynBW
# Symlinks dynbw.sh to a kernel directory

read -p "Folder to install DynBW to: " install_to
if [ -e $install_to/dynbw.sh ]; then
	echo "dynbw.sh already exists in installation directory!"
	read -p "Do you want to delete the conflicting file [y/N]? " delete
	if [ $delete == "y" ]; then
		rm $install_to/dynbw.sh
		echo "File deleted!"
		echo "Continuing installation.."
		ln -s $PWD/dynbw.sh $install_to/dynbw.sh
		echo "Installation complete! Launch build.sh in $install_to to use DynBW"
	else
		echo "Please delete or move the file to continue installation"
	fi
	exit
else
	ln -s $PWD/dynbw.sh $install_to/dynbw.sh
	echo "Installation complete! Launch build.sh in $install_to to use DynBW"
	exit
fi