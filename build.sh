CWD="${PWD}"
LOG="${CWD}/log.txt"

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
	msg "Preparing ${namver} in ${wrkdir}..."
	rm -rf "${wrkdir}"
	mkdir -p "${wrkdir}"
	tar xzf "tmp/${namver}.tar.gz" -C "${wrkdir}" || exit 1
	cd "${wrkdir}/${namver}"
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
	if [ -f "out/${VERSION}/radare2-${VERSION}-android-${arch}.tar.gz" ]; then
		msg "radare2-${VERSION}-android-${arch} is already done"
		return
	fi
	prepare radare2-${VERSION} tmp/android-${arch}
	msg "Building android-${arch}..."
	:> libr/libr.a
	sys/"android-${arch}.sh" >> ${LOG}
	output radare2-${VERSION}-android-${arch}.tar.gz 
)}

check() {
	file="$1"
	test -f "${CWD}/out/${VERSION}/${file}"
	ret=$?
	[ "$ret" = 0 ] && msg "found $file"
	return ${ret}
}

osx_build() {(
	check radare2-${VERSION}.pkg && return
	prepare radare2-${VERSION} tmp/osx-pkg
	msg "Building macOS package..."
	sys/osx-pkg.sh >> ${LOG}
	ls sys/osx-pkg
	output sys/osx-pkg/radare2-${VERSION}.pkg
)}

linux_build() {(
	arch="`uname -m`"
	check radare2-${VERSION}-${arch}.deb && return
	prepare radare2-${VERSION} tmp/osx-pkg
	msg "Building Debain GNU/Linux package..."
	sys/debian.sh >> ${LOG}
	output sys/debian/radare2/*.deb
)}

docker_linux_build() {(
	arch="$1"
	check radare2_${VERSION}_${arch}.deb && return
	cd docker-linux-${arch} || exit 1
	make
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
	check radare2-w32-${VERSION}.zip && return
	prepare radare2-${VERSION} tmp/mingw32
	msg "Building Debain GNU/Linux package..."
	sys/mingw32.sh >> ${LOG}
	output radare2-w32-${VERSION}.zip
)}

w64_build() {(
	check radare2-w64-${VERSION}.zip && return
	prepare radare2-${VERSION} tmp/mingw32
	msg "Building Debain GNU/Linux package..."
	sys/mingw64.sh >> ${LOG}
	output radare2-w64-${VERSION}.zip
)}

depends() {
	if [ ! -d "$1" ]; then
		git clone https://github.com/radare/$1
		wget https://github.com/radare/radare2/archive/1.0.2.tar.gz
	else
		(
		cd "$1"
		git reset --hard @~10
		git checkout master
		git pull
		)
	fi
}

grab_tarball() {(
	pkg="$1"
	ver="$2"
	[ -z "$ver" ] && ver="${VERSION}"
	mkdir -p out/${VERSION}
	cd out/${VERSION}
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
