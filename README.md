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

	dynbw config -i

To build, simply launch the build command:

	dynbw build your_defconfig

With "**your_defconfig**" being the kernel defconfig.

Command help can also be accessed through their internal "--help" argument:

	dynbw build --help
	dynbw config --help

Using 'sync'
------
Sync is used to mass-clone repositories defined in sync.txt - as a cheap replacement of the famous 'repo' tool, it works almost in the same way as 'repo'.

To start using sync, you need to create the sync.txt. DynBW will search for sync.txt in the current directory you are in, hence you can have multiple sync.txt for different kernel _without_ having multiple copies of the DynBW script.

The sync.txt is parsed using this format:

	folder destination|branch|link to repository

Sync also accepts commenting on lines using Shell style comments (pound/hash):

	# This is a comment!
	folder destination|branch|link to repository

Comments are ignored and won't be parsed by sync, much like a comment on a Shell script.

As a small example, if you were to add the master branch of DynBW, it'll be like so:

	# Add DynBW
	dynbw|master|https://github.com/F4uzan/dynbw

The repository is saved in the folder defined in sync.txt using "/save_to", this has to be set on the top of sync.txt for it to work:

	/save_to:where_to_save

Following the 'dynbw' example above, if we enter "synced" in "/save_to", sync will save the 'dynbw' folder inside "synced":

	/save_to:synced

Our sync.txt should look somewhat like this now:

	/save_to:synced
	
	# Add DynBW
	dynbw|master|https://github.com/F4uzan/dynbw

After finishing the sync.txt, run sync to clone all of the repository you have defined:

	dynbw sync

Sync is _still_ in its very early stage. It is no way a replacement for the actual repo tool and will never be. It is meant to be a dumbed-down, easy-to-approach alternative for repo and should _only_ be used alongside DynBW.