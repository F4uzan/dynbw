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