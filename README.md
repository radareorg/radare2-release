radare2-release
===============

This repository contains the scripts needed to create a new release of radare2.

Dependencies
------------
* OSX (required to build iOS and OSX packages), but Linux works too
* Docker. Required to build the debian packages for amd64 and i686
* NDK (for the android builds), eventually dockerified
* make and sh
* rsync to publish the bins

Usage
-----
* Edit `CONFIG` and update the version if needed
* Run `make`
* Check `out/${VERSION}`

What it builds right now:
-------------------------

	[*] radare2-1.0.2 tarball is ok
	[*] Already got radare2-extras-1.0.tar.gz
	[*] Already got radare2-bindings-1.0.tar.gz
	[*] Already got radare2-r2pipe-1.0.tar.gz
	[*] radare2-1.0.2-android-x86 is already done
	[*] radare2-1.0.2-android-mips is already done
	[*] radare2-1.0.2-android-arm is already done
	[*] radare2-1.0.2-android-aarch64 is already done
	[*] Mingw32 package already done...
	[*] Linux amd64 package already done...
	[*] Linux i686 package already done...
	[*] macOS package already done...
	[*] iOS arm package already done...
	[*] iOS arm64 package already done...
	[*] iOS appstore package already done...
	[*] Computing checksums...
	[*] Publishing Cydia packages...
	[*] Building the android app...
	[*] Publishing Android binaries...
	[*] Already published 1.0.2 android build for radare2-x86
	[*] Already published 1.0.2 android build for radare2-arm
	[*] Already published 1.0.2 android build for radare2-mips
	[*] Already published 1.0.2 android build for radare2-aarch64
	[*] Updating IRC channel title...
	[*] Updating the website...


Future (aka TODO)
-----------------
* Update website taking credentials from `CONFIG`
* Also release acr, valabind, ired and sdb
* Sign releases
