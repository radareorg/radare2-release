CWD="${PWD}"
LOG="${CWD}/log.txt"


mkdir -p tmp out
msg() {
	echo "\033[32m[*] $@\033[0m"
}

output() {(
	file="$1"
	mkdir -p "${CWD}/out/${VERSION}"
	cp -f "${file}" "${CWD}/out/${VERSION}" || exit 1
)}

prepare() {
	namver="$1"
	wrkdir="$2"
	action="$3"
	if [ ! -f "tmp/${namver}.tar.gz" ]; then
		download radare2
	fi
	msg "Preparing ${namver} in ${wrkdir}..."
	case "$action" in
	noclean)
		if [ ! -d "${wrkdir}" ]; then
			mkdir -p "${wrkdir}"
			tar xzf "tmp/${namver}.tar.gz" -C "${wrkdir}" || exit 1
		fi
		;;
	*)
		rm -rf "${wrkdir}"
		mkdir -p "${wrkdir}"
		tar xzf "tmp/${namver}.tar.gz" -C "${wrkdir}" || exit 1
		;;
	esac
	cd "${wrkdir}/${namver}" || exit 1
}

download() {(
	repo="$1"
	[ -z "${vers}" ] && vers="${VERSION}" || vers="$2"
	if [ -d "tmp/${repo}-${vers}" ]; then
		msg "${repo}-${vers} tarball is ok"
		return
	fi
	msg "Downloading ${repo} ${vers}"
	mkdir -p tmp
	cd tmp
	wget -O orig-${repo}-${vers}.tar.gz -qc "https://github.com/radare/${repo}/archive/${vers}.tar.gz" || exit 1
	msg "Caching capstone clone in a new dist tarball"
	tar xzf orig-${repo}-${vers}.tar.gz
	(
		cd "${repo}-${vers}"
		./configure > /dev/null
		(
			cd shlr
			make capstone
			rm -rf capstone/.git
		)
	)
	tar czf ${repo}-${vers}.tar.gz ${repo}-${vers}
	output ${repo}-${vers}.tar.gz
)}

android_build() {(
	arch="$1"
	mode="$2"
	mkdir -p tmp
	case "$mode" in
	shell|bash|sh)
		prepare radare2-${VERSION} tmp/android-${arch} noclean
		sys/android-shell.sh ${arch}
		;;
	*)
		check radare2-${VERSION}-android-${arch}.tar.gz && return
		prepare radare2-${VERSION} tmp/android-${arch} noclean
		msg "Building android-${arch}..."
		:> libr/libr.a
		sys/"android-${arch}.sh" >> ${LOG}
		output radare2-${VERSION}-android-${arch}.tar.gz
		;;
	esac
)}

check() {
	file="$1"
	test -f "${CWD}/out/${VERSION}/${file}"
	ret=$?
	[ "$ret" = 0 ] && msg "found $file"
	return ${ret}
}

osx_build() {(
	if [ "`uname`" != "Darwin" ]; then
		echo "osx_build is only suposed to run on macOS"
		return 1
	fi
	mode="$2"
	case "$mode" in
	shell|sh|bash)
		prepare radare2-${VERSION} tmp/osx-pkg
		bash
		;;
	*)
		check radare2-${VERSION}.pkg && return
		prepare radare2-${VERSION} tmp/osx-pkg
		msg "Building macOS package..."
		sys/osx-pkg.sh >> ${LOG}
		ls sys/osx-pkg
		output sys/osx-pkg/radare2-${VERSION}.pkg
		;;
	esac
)}

linux_build() {(
	arch="`uname -m`"
	mode="$2"
	case "$mode" in
	shell|bash|sh)
		prepare radare2-${VERSION} tmp/linux-${arch}
		bash
		;;
	*)
		check radare2-${VERSION}-${arch}.deb && return
		prepare radare2-${VERSION} tmp/linux-${arch}
		msg "Building Debian GNU/Linux package..."
		sys/debian.sh >> ${LOG}
		output sys/debian/radare2/*.deb
		;;
	esac
)}

docker_android_build() {(
	arch="$1"
	mode="$2"
ANDROID_PREFIX="/data/data/org.radare.radare2installer/radare2"
	case "$mode" in
	shell|bash|sh)
		prepare radare2-${VERSION} tmp/android-${arch}
		${CWD}/dockcross --image dockcross/android-${arch} \
			./configure \
				--host="linux-android-${arch}" \
				--with-ostype=android \
				--without-pic --with-nonpic \
				--prefix=${ANDROID_PREFIX}
		${CWD}/dockcross --image dockcross/android-${arch} bash
		# sys/android-shell.sh $arch
		;;
	*|static)
		check radare2-${VERSION}-android-${arch}.tar.gz && return
		prepare radare2-${VERSION} tmp/android-${arch} noclean
		${CWD}/dockcross --image dockcross/android-${arch} \
			./configure \
				--host="linux-android-${arch}" \
				--with-ostype=android \
				--without-pic --with-nonpic \
				--prefix=${ANDROID_PREFIX}
		${CWD}/dockcross --image dockcross/android-${arch} touch binr/preload/libr2.so
		${CWD}/dockcross --image dockcross/android-${arch} \
			make -s -j 4 ANDROID=1 || return 1
		${CWD}/dockcross --image dockcross/android-${arch} \
			bash -c "ANDROID=1 BUILD=0 sys/android-${arch}.sh" || return 1
		${CWD}/dockcross --image dockcross/android-${arch} sys/"android-${arch}.sh" >> ${LOG}
		output radare2-${VERSION}-android-${arch}.tar.gz
		;;
	esac
)}

docker_linux_build() {(
	arch="$1"
	arg="$2"
	[ -z "$arch" ] && arch="x86"
	debarch="$arch"
	case "$arch" in
	x86)
		debarch="i686"
		;;
	x64)
		debarch="amd64"
		;;
	esac
	check radare2_${VERSION}_${debarch}.deb && return
	prepare radare2-${VERSION} tmp/debian-${debarch}
	case "$arg" in
	static)
		${CWD}/dockcross --image dockcross/linux-${arch} \
			bash -c "sys/build.sh --without-pic --with-nonpic ; sys/debian.sh"
		output sys/debian/radare2/*.deb
		;;
	shell|bash|sh)
		${CWD}/dockcross --image dockcross/linux-${arch} bash
		;;
	*)
		${CWD}/dockcross --image dockcross/linux-${arch} bash -c \
			"./configure --with-compiler=${arch} --host=${arch} && sys/build.sh && sys/debian.sh"
		output sys/debian/radare2/*.deb
		;;
	esac
)}

docker_asmjs_build() {(
	arch="$1"
	mode="$2"
	[ -z "$arch" ] && arch="asmjs"
	X=radare2-${VERSION}-${arch}
	case "$mode" in
	shell|bash|sh)
		prepare radare2-${VERSION} tmp/radare2-asmjs noclean
		${CWD}/dockcross --image dockcross/browser-asmjs bash
		;;
	*)
		check "$X".tar.gz && return
		prepare radare2-${VERSION} tmp/radare2-asmjs noclean
		${CWD}/dockcross --image dockcross/browser-asmjs sys/emscripten.sh
		rm -rf "$X"
		mkdir -p "$X"
		cp -f binr/*/*.js "$X"
		tar czf "$X".tar.gz "$X"
		output "$X".tar.gz
		;;
	esac
)}

docker_windows_build() {(
	arch="$1"
	mode="$2"
	cd tmp/radare*
	case "$mode" in
	shell|sh|bash)
		${CWD}/dockcross --image dockcross/windows-x64 bash
		;;
	*)
		if [ "${arch}" = "x86_64-w64-mingw32.static-gcc" ]; then
			check radare2-w64-${VERSION}.zip && return
			prepare radare2-${VERSION} tmp/windows-x64
			${CWD}/dockcross --image dockcross/windows-x64 bash -c "
				./configure --with-compiler=${arch} --host=${arch} &&
				make -j4 && make w64dist"
			output radare2-w64-${VERSION}.zip
		else
			check radare2-w32-${VERSION}.zip && return
			prepare radare2-${VERSION} tmp/windows-x32
			${CWD}/dockcross --image dockcross/windows-x64 bash -c "
				./configure --with-compiler=${arch} --host=${arch} &&
				make -j4 && make w32dist"
			output radare2-w32-${VERSION}.zip
		fi
		;;
	esac
)}

ios_appstore() {(
	arch="$1"
	[ -z "$1" ] || arch="arm64"
	check radare2-ios-${arch}-${VERSION}.tar.gz && return
	prepare radare2-${VERSION} tmp/ios-appstore
	msg "Building for the iOS appstore..."
	sys/ios-static-appstore.sh >> ${LOG}
	find *| grep gz$
	mv radare2-ios-${arch}.tar.gz radare2-ios-${arch}-${VERSION}.tar.gz
	output radare2-ios-${arch}-${VERSION}.tar.gz
)}

ios_build() {(
	arch="$1"
	mode="$2"
	case "$mode" in
	shell|sh|bash)
		prepare radare2-${VERSION} tmp/ios-cydia-${arch}
		sys/ios-sdk.sh -s
		exit 0
		;;
	esac
	S=${VERSION}_iphoneos-arm.deb
	O=radare2_${S}
	if [ "${arch}" = "arm" ]; then
		C=sys/ios-cydia32.sh
		D=radare2-arm32_${S}
		DD=radare2-dev-arm32_${S}
	else
		C=sys/ios-cydia.sh
		D=$O
		DD=radare2-dev_$S
	fi
	check $D && return
	prepare radare2-${VERSION} tmp/ios-cydia-${arch}
	msg "Building ios-${arch}..."
	$C >> ${LOG}
	cp -f sys/cydia/radare2/$O $D
	output $D
	# TODO: radare2-dev is not created with sys/ios-cydia.sh we need to use sys/ios-sdk.sh
	#output sys/cydia/radare2-dev/${DD}
)}

w32_build() {(
	arch="$1"
	mode="$2"
	[ -z "$arch" ] && arch="x86"
	if [ "$arch" = x64 ]; then
		return w64_build $arch $mode
	fi
	check radare2-w32-${VERSION}.zip && return
	prepare radare2-${VERSION} tmp/mingw32
	msg "Building mingw32 zip..."
	sys/mingw32.sh >> ${LOG}
	output radare2-w32-${VERSION}.zip
)}

w64_build() {(
	arch="$1"
	mode="$2"
	[ -z "$arch" ] && arch="x64"
	if [ "$arch" = x86 ]; then
		return w32_build $arch $mode
	fi
	check radare2-w64-${VERSION}.zip && return
	prepare radare2-${VERSION} tmp/mingw64
	msg "Building mingw64 zip..."
	sys/mingw64.sh >> ${LOG} || echo 'missing mingw64 compiler'
	output radare2-w64-${VERSION}.zip
)}

depends() {
	if [ ! -d "$1" ]; then
		git clone --depth 20 https://github.com/radare/$1
		wget -c https://github.com/radare/radare2/archive/${VERSION}.tar.gz
	else
		if [ -n "$1" -a -d "$1" ]; then
		(
			cd "$1"
			git reset --hard @~10
			git checkout master
			git pull
		)
		fi
	fi
}

grab_tarball() {(
	pkg="$1"
	ver="$2"
	[ -z "$ver" ] && ver="${VERSION}"
	mkdir -p out/${VERSION}
	cd out/${VERSION}
	# TODO: use check here
	if [ -f $pkg-${ver}.tar.gz ]; then
		msg "Already got $pkg-${ver}.tar.gz"
	else
		wget -O $pkg-${ver}.tar.gz -c https://github.com/radare/$pkg/archive/${ver}.tar.gz || (
			rm -f $pkg-${ver}.tar.gz
		)
	fi
)}

download_others() {(
	grab_tarball radare2-extras ${VERSION_EXTRAS}
	grab_tarball radare2-bindings ${VERSION_BNDNGS}
	grab_tarball radare2-r2pipe ${VERSION_R2PIPE}
	grab_tarball radare2-webui ${VERSION_WEBUI}
)}

android_app() {(
	if [ -d ../radare2-installer ]; then
		msg "Building the android app..."
		cd ../radare2-installer
		make >> ${LOG}
		mkdir -p out/${VERSION}
		cp -f org.radare.radare2installer.apk ${OLDPWD}/out/${VERSION} || msg "Cannot find the apk"
	else
		msg "Cannot find ../radare2-installer to build the android app"
	fi
)}
