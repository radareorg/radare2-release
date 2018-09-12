CWD="${PWD}"
LOG="${CWD}/log.txt"


mkdir -p tmp out
msg() {
	printf "\033[32m[*] %s\033[0m\n" "$@"
}

err() {
	printf "\033[31m[-] %s\033[0m\n" "$@"
}

output() {(
	file="$1"
	mkdir -p "${CWD}/out/${VERSION}"
	cp -f "${file}" "${CWD}/out/${VERSION}" || exit 1
)}

prepare() {
	nam="$1"
	ver="$2"
	namver="$1-$2"
	wrkdir="$2"
	action="$3"
	if [ ! -f "tmp/${namver}.tar.gz" ]; then
		download $nam $ver
	fi
	msg "Preparing ${namver} in ${wrkdir}..."
	case "$action" in
	noclean)
		if [ ! -d "${wrkdir}/${namver}" ]; then
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
	echo "${wrkdir}/${namver}"
	cd "${wrkdir}/${namver}" || exit 1
}

download() {(
	repo="$1"
	vers="$2"
	[ -z "${vers}" ] && vers="${VERSION}"
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
	if [ "$repo" = radare2 ]; then
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
	else
		cp -f orig-${repo}-${vers}.tar.gz ${repo}-${vers}.tar.gz
	fi
	output ${repo}-${vers}.tar.gz
)}

android_build() {(
	arch="$1"
	mode="$2"
	mkdir -p tmp
	case "$mode" in
	-s|--shell|shell|bash|sh)
		prepare radare2 ${VERSION} tmp/android-${arch} noclean
		sys/android-shell.sh ${arch}
		;;
	*)
		check radare2-${VERSION}-android-${arch}.tar.gz && return
		prepare radare2 ${VERSION} tmp/android-${arch} noclean
		msg "Building android-${arch}..."
		:> libr/libr.a
		sys/android-build.sh ${arch} >> ${LOG}
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
	-s|--shell|shell|sh|bash)
		prepare radare2 ${VERSION} tmp/osx-pkg
		bash
		;;
	*)
		check radare2-${VERSION}.pkg && return
		prepare radare2 ${VERSION} tmp/osx-pkg
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
	-s|--shell|shell|bash|sh)
		prepare radare2 ${VERSION} tmp/linux-${arch}
		bash
		;;
	*)
		check radare2-${VERSION}-${arch}.deb && return
		prepare radare2 ${VERSION} tmp/linux-${arch}
		msg "Building Debian GNU/Linux package..."
		sys/debian.sh >> ${LOG}
		output sys/debian/radare2/*.deb
		;;
	esac
)}

r2b_build() {
	echo "[*] Pre-generating radare2-bindings ${VERSION_BNDNGS} ..."
	check radare2-bindings-${VERSION_BNDNGS}.tar.gz && return
	prepare radare2-bindings ${VERSION_BNDNGS} tmp/radare2-bindings noclean
	# TODO: create a new make target that just creates the .cxx files and not compile them
	./configure ; cd python && make
	# TODO: generate tarball with different name :? radare2-bindings-(something)
}

docker_linux_r2frida_build() {(
	arch="x64"
	mode="$2"
	case "$mode" in
	-s|--shell|shell|bash|sh)
		echo "No shell here"
		exit 0
		;;
	*)
		msg "Building amd64 Debian GNU/Linux r2frida package..."
		# XXX r2frida version hardcoded
		check r2frida_${R2FRIDA_VERSION}_amd64.deb && return
		if [ -d tmp/r2frida ]; then
			( cd tmp/r2frida ; git pull )
		else
			mkdir -p tmp
			git clone --depth 20 https://github.com/nowsecure/r2frida tmp/r2frida
		fi
		(
			cd tmp/r2frida
			make clean ; make -j4
			cd dist/debian
			make >> ${LOG}
		)
		output tmp/r2frida/dist/debian/*.deb
		;;
	esac
)}

docker_android_build() {(
	arch="$1"
	mode="$2"
	ANDROID_PREFIX="/data/data/org.radare.radare2installer/radare2"
	case "$mode" in
	-s|--shell|shell|bash|sh)
		prepare radare2 ${VERSION} tmp/android-${arch}
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
		prepare radare2 ${VERSION} tmp/android-${arch} noclean
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
	cmparch="$arch"
	case "$arch" in
	x86)
		debarch="i686"
		cmparch="i686"
		;;
	x64)
		debarch="amd64"
		cmparch="x86_64"
		;;
	armv5)
		CFGARGS="--with-compiler=${arch}"
		debarch="armv5"
		cmparch="armel"
		;;
	mipsel)
		CFGARGS="--with-compiler=${arch}"
		debarch="mipsel"
		cmparch="mipsel"
		;;
	esac
	check radare2_${VERSION}_${debarch}.deb
	check radare2-dev_${VERSION}_${debarch}.deb && return
	prepare radare2 ${VERSION} tmp/debian-${debarch}
	case "$arg" in
	static)
		${CWD}/dockcross --image dockcross/linux-${arch} \
			bash -c "sys/build.sh --without-pic --with-nonpic ; ARCH=${debarch} sys/debian.sh"
		output sys/debian/radare2/*.deb
		;;
	-s|--shell|shell|bash|sh)
		${CWD}/dockcross --image dockcross/linux-${arch} bash
		;;
	*)
		${CWD}/dockcross --image dockcross/linux-${arch} bash -c \
			"export AR=${cmparch}-linux-gnu-ar ;
			export CC=${cmparch}-linux-gnu-gcc ;
			export CFLAGS=-O2 ;
			export ARCH=${debarch} ;
			export MAKE='make V=1' ;
			./configure ${CFGARGS} --prefix=/usr --host=${cmparch}-linux-gnu && make -j4 V=1 && sys/debian.sh"
		output sys/debian/radare2/*.deb
		output sys/debian/radare2-dev/*.deb
		;;
	esac
)}

docker_asmjs_build() {(
	arch="$1"
	mode="$2"
	[ -z "$arch" ] && arch="asmjs"
	X=radare2-${VERSION}-${arch}
	case "$mode" in
	-s|--shell|shell|bash|sh)
		prepare radare2 ${VERSION} tmp/radare2-asmjs noclean
		${CWD}/dockcross --image dockcross/browser-asmjs bash
		;;
	*)
		check "$X".tar.gz && return
		prepare radare2 ${VERSION} tmp/radare2-asmjs noclean
		${CWD}/dockcross --image dockcross/browser-asmjs sys/emscripten.sh
		rm -rf "$X"
		mkdir -p "$X"
		cp -f binr/*/*.js "$X"
		tar czf "$X".tar.gz "$X"
		output "$X".tar.gz
		;;
	esac
)}

docker_wasm_build() {(
	arch="$1"
	mode="$2"
	[ -z "$arch" ] && arch="wasm"
	X=radare2-${VERSION}-${arch}
	case "$mode" in
	-s|--shell|shell|bash|sh)
		prepare radare2 ${VERSION} tmp/radare2-wasm noclean
		${CWD}/dockcross --image dockcross/browser-asmjs bash
		;;
	*)
		check "$X".tar.gz && return
		prepare radare2 ${VERSION} tmp/radare2-wasm noclean
		${CWD}/dockcross --image dockcross/browser-asmjs sys/wasm.sh
		rm -rf "$X"
		mkdir -p "$X"
		cp -f binr/*/*.wasm "$X"
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
	-s|--shell|shell|sh|bash)
		${CWD}/dockcross --image dockcross/windows-x64 bash
		;;
	*)
		if [ "${arch}" = "x86_64-w64-mingw32.static-gcc" ]; then
			check radare2-w64-${VERSION}.zip && return
			prepare radare2 ${VERSION} tmp/windows-x64
			${CWD}/dockcross --image dockcross/windows-x64 bash -c "
				./configure --with-compiler=${arch} --host=${arch} &&
				make -j4 && make w64dist"
			output radare2-w64-${VERSION}.zip
		else
			check radare2-w32-${VERSION}.zip && return
			prepare radare2 ${VERSION} tmp/windows-x32
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
	[ -z "$1" ] && arch="arm64"
	check radare2-ios-${arch}-${VERSION}.tar.gz && return
	prepare radare2 ${VERSION} tmp/ios-appstore
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
	-s|--shell|shell|sh|bash)
		prepare radare2 ${VERSION} tmp/ios-cydia-${arch}
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
	prepare radare2 ${VERSION} tmp/ios-cydia-${arch}
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
	prepare radare2 ${VERSION} tmp/mingw32
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
	prepare radare2 ${VERSION} tmp/mingw64
	msg "Building mingw64 zip..."
	sys/mingw64.sh >> ${LOG} || echo 'missing mingw64 compiler'
	output radare2-w64-${VERSION}.zip
)}

msvc64_build() {(
	ZIP="radare2-msvc_64-${VERSION}.zip"
	builder="vs2015_64"
	check "${ZIP}" && return
	appveyor_download ${ZIP} ${builder}
	output "${ZIP}"
	rm "${ZIP}"
)}

msvc32_build() {(
	ZIP="radare2-msvc_32-${VERSION}.zip"
	builder="vs2015_32"
	check "${ZIP}" && return
	appveyor_download ${ZIP} ${builder}
	output "${ZIP}"
	rm "${ZIP}"
)}

msvc64_installer() {(
	EXE="radare2_installer-msvc_64-${VERSION}.exe"
	builder="vs2015_64"
	check "${EXE}" && return
	appveyor_download ${EXE} ${builder} 1
	output "${EXE}"
	rm "${EXE}"
)}

msvc32_installer() {(
	EXE="radare2_installer-msvc_32-${VERSION}.exe"
	builder="vs2015_32"
	check "${EXE}" && return
	appveyor_download ${EXE} ${builder} 1
	output "${EXE}"
	rm "${EXE}"
)}

appveyor_download() {(
	OUTFILE=$1
	builder=$2
	installer=$3

	# Retrieve latest msvc release information
	latest_builds=$(curl -s "https://ci.appveyor.com/api/projects/radare/radare2-shvdd")
	# TODO Maybe the api can force the branch
	if ! echo "${latest_builds}" | grep -q '"branch":"master"'; then
		err "Cannot find latest appveyor release ..."
		return
	fi
	jobid=$(echo "${latest_builds}" | sed -e "s/^.*jobId\":\"\(.*\)\",.*builder=${builder},.*/\1/")
	msg "Found latest msvc jobid: ${jobid}"
	res=$(curl -s "https://ci.appveyor.com/api/buildjobs/${jobid}/artifacts")
	if [ -z "${installer}" ]; then
		search="radare2-${builder}.*\\.zip"
	else
		search="radare2_installer-${builder}.*\\.exe"
	fi
	artifact_name=$(echo "${res}" | sed -e 's/^.*"fileName":"\('${search}'\)","type":.*/\1/')
	if ! echo "${artifact_name}" | grep -q "${search}"; then
		err "File name seems invalid: '${artifact_name}' ${res}. Exiting..."
		return
	fi

	# Download latest release
	curl -L "https://ci.appveyor.com/api/buildjobs/${jobid}/artifacts/${artifact_name}" -o "${OUTFILE}"
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
