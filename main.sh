#!/bin/sh

. CONFIG
. build.sh
. publish.sh

case "$1" in
-h|help)
	echo "Usage: make [release|init|...]"
	;;
esac

download radare2
download_others

# TODO: dockerify
android_build x86
android_build mips
android_build arm
android_build aarch64

docker_linux_build x86
docker_linux_build x64

docker_linux_build armv5
#docker_linux_build armv6
#docker_linux_build armv7
#docker_linux_build armv64

docker_windows_build x86_64-w64-mingw32.static-gcc
docker_windows_build i686-w64-mingw32.static-gcc

case "`uname`" in
Darwin)
	osx_build
	ios_build arm
	ios_build arm64
	# ios_appstore arm
	ios_appstore arm64
	;;
Linux)
	# linux_build
	:
	;;
esac

publish_checksums

### populate all binaries
publish_cydia
publish_out
publish_android

### announce
publish_irc
publish_www
# publish_twitter
# publish_telegram
# publish_blog


