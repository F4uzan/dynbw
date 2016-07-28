#!/bin/bash
# Installation script for DynBW
# Symlinks build.sh to a kernel directory

read -p "Folder to install DynBW to: " install_to
ln -s $PWD/build.sh $install_to
echo "Installation complete! Launch build.sh in $install_to to use DynBW"