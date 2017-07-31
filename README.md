DynBW, a dynamic kernel build wrapper
------
DynBW is an easy-to-use kernel buildscript for Android-compatible kernel source. It is highly flexible and practical - all without a fancy semi-graphical interface. Its goal is to simplify and automate the process of building kernels, leaning towards newcomers to the kernel-building scenario.

Compatible with practically everything that uses POSIX SH. This guarantees a vast and wide compatibility with most Linux distributions and even those that are not inherently Linux but can use POSIX SH, such as macOS.

This README is for the newest DynBW version. Those looking for older and deprecated version of DynBW can check the "deprecated" folder. Do note that the deprecated version will not be updated and is susceptible to issues.

Installation
-----
Simply clone this repository or download it as a ZIP to get started. Copy "dynbw.sh" to your kernel directory and start building!

Usage
------
DynBW is not meant to be launched directly. Instead, you should export its function to your current terminal session:

	. dynbw.sh

Alternatively, you can use "source" if your shell supports it:

	source dynbw.sh

After exporting, you can use DynBW's function directly in the terminal session. It is recommended for you to create an initial configuration file before building:

	config -i

To build, simply launch the build command:

	build your_defconfig

With "**your_defconfig**" being the kernel defconfig.

Command help can also be accessed through their internal "--help" argument:

	build --help
	config --help
	
Using 'sync'
------
Sync is used to mass-clone repositories defined in sync.txt - as a cheap replacement of the famous 'repo' tool, it works almost the same way as 'repo'.

To start using sync, you need to create the sync.txt. This file **must** be in the same directory as the dynbw script. In a future update, I'll try implementing a function similar to 'repo' where sync searches for the file in the current folder instead of in the same folder as dynbw.

The sync_fetch.txt is parsed using this format:

	folder destination|branch|link to repository
	
So, if you were to add the master branch of dynbw, it'll be like so:

	dynbw|master|https://github.com/F4uzan/dynbw
	
The repository is saved in the folder defined when calling sync. It is the argument you have to supply to call sync:

	sync where_to_save
	
Following the dynbw example above, the command below will save the 'dynbw' folder to 'synced' and thus it'll be vieweable in 'synced/dynbw':

	sync synced
	
Sync is _still_ in its very early stage. It is no way a replacement for the actual repo tool and will never be. It is meant to be a dumbed-down, easy-to-approach alternative for repo and should _only_ be used alongside dynbw.