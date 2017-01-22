#!/bin/sh

. CONFIG
. build.sh
. publish.sh

case "$1" in
-l)
	cat build.sh | grep '()' | grep build | awk -F '_build' '{print $1}'
	# cut -d '(' -f 1
	exit 0
	;;
-js)
	download radare2
	docker_asmjs_build
	exit 0
	;;
-x)
	target=`echo "$2" | sed -e s,-,_,g`
	${target}_build $3 $4
	exit 0
	;;
-a)
	release_all
	;;
-h|help|*)
	echo "Usage: ./main.sh [release|init|...]"
	echo " -a                          release all default targets"
	echo " -l                          list all targets usable via -x"
	echo " -x [target] [arch] [mode]   run the build.sh target for given"
	echo " -js                         build for asmjs"
	echo
	echo "Android NDK for ARM shell"
	echo "  ./main.sh -x docker_android arm shell"
	echo "Emscripten shell:"
	echo " ./main.sh -x docker_asmjs - shell"
	exit 0
	;;
esac

release_all() {

	download radare2
	download_others

	# docker_linux_build x86 static
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
	#docker_linux_build mipsel
	docker_linux_build mipsel static

	docker_windows_build x86_64-w64-mingw32.static-gcc
	docker_windows_build i686-w64-mingw32.static-gcc

	case "`uname`" in
	Darwin)
		osx_build
		ios_build arm
		ios_build arm64
		ios_appstore arm
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
}
