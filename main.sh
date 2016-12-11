#!/bin/sh

alias include=.

include CONFIG
include build.sh
include publish.sh

case "$1" in
-h|help)
	echo "Usage: make [release|init|...]"
	;;
esac

# include docker.mk
download radare2
download_others

capstone() {(
	cd tmp
	git clone https://github.com/aquynh/capstone.git
)}


# TODO: dockerify
android_build x86
android_build mips
android_build arm
android_build aarch64

# TODO: dockerify
w32_build

docker_linux_build amd64
docker_linux_build i686

case "`uname`" in
Darwin)
	osx_build
	ios_build arm
	ios_build arm64
	#ios_appstore arm
	ios_appstore arm64
	;;
Linux)
	# linux_build
	:
	;;
esac

publish_checksums

publish_irc
publish_www

