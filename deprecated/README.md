DynBW, a dynamic kernel builder wrapper
------
This README is valid only for the files contained in this folder (the deprecated folder). Do not use the information stored within it as a reference for the newer script(s) outside this directory.
------

DynBW is a customizable, universal Linux kernel builder. It is highly flexible, allowing further customizations when users needs it, it also not tied to kernel versions and architecture.
Currently in alpha testing, it lacks any advanced features but I'm working to improve it.

Compatibility:
- Any Linux that uses BASH
- Probably other shell types (SH, ZSH, et cetera), but it is untested

You also need a properly working kernel source and a cross compiler, but if you have compiled a kernel before, you probably know the gist already.

How to use :
- Use the install.sh to symlink dynbw.sh to the root of your kernel directory
- Launch dynbw.sh in the install path previously used in install.sh
- Finish up the first-start configuration
- Relaunch dynbw.sh to compile your kernel