publish_checksums() {(
	msg "Computing checksums..."
	cd out/${VERSION}
	rm -f checksums.sha1sum
	sha1sum * > checksums.sha1sum
)}

publish_irc() {
	msg "Updating IRC channel title..."
}

generate_web_config() {
	O="$1"
	: > $O
	echo '$radare2_version='$VERSION >> $O
	echo '$radare2_date='${RELEASE_DATE} >> $O
	echo '$radare2_sha1='`sha1sum ../../out/${VERSION}/radare2-${VERSION}.tar.gz | cut -d ' ' -f 1` >> $O

	echo '$radare2_bindings_version='${VERSION_BNDNGS} >> $O
	echo '$radare2_bindings_date='${RELEASE_DATE} >> $O
	echo '$radare2_bindings_sha1='`sha1sum ../../out/${VERSION}/radare2-bindings-${VERSION_BNDNGS}.tar.gz | cut -d ' ' -f 1` >> $O

	echo '$radare2_extras_version='${VERSION_EXTRAS} >> $O
	echo '$radare2_extras_date='${RELEASE_DATE} >> $O
	echo '$radare2_extras_sha1='`sha1sum ../../out/${VERSION}/radare2-extras-${VERSION_EXTRAS}.tar.gz | cut -d ' ' -f 1` >> $O

	echo '$radare2_osx_version='${VERSION} >> $O
	echo '$radare2_w32_version='${VERSION} >> $O
	echo '$radare2_w32_git_version='${VERSION} >> $O

	echo '
$radare1_version=1.5.2
$radare1_date=2010-05-23
$radare1_sha1=?b838776a85a7b7d56c10e4c94f3d0b37cebea72a

$valabind_version=0.10.0
$valabind_date=2016-01-20
$valabind_sha1=b5e0c2a7255736630fba0eba6c32e48bbed611eb

$ired_version=0.5.0
$ired_date=2013-07-08
$ired_sha1=575aa7bd1d63178c6802d680f75d43c3aa9d80fc

$sdb_version=0.10.5
$sdb_date=2016-08-16
$sdb_sha1=a8c1e85355bc153ef49fe9ec85fd456ee27097be

$acr_version=0.10.5
$acr_date=2016-08-16
$acr_sha1=f4f4d630eb934614699cae9c5ee5c523863869b9
' >> $O
}

publish_www() {(
	msg "Updating the website"
	cd tmp
	if [ -d radare.org ]; then
		cd radare.org
		git pull
	else
		git clone https://github.com/radare/radare.org
		cd radare.org
	fi
	generate_web_config r/web.config
	git diff
	git commit -a -m "Release ${VERSION}"
	git push
	#cat r/web.config
)}

publish_out() {
	msg "Publishing the binaries..."
	rsync --rsh="ssh -p ${OUT_SSH_PORT}" -avz out/${VERSION} ${OUT_SSH_PATH}
}

publish_cydia() {(
	msg "Publishing Cydia packages..."
	rsync -avz --rsh="ssh -p ${CYDIA_PORT}" \
		out/${VERSION}/radare2_${VERSION}_iphoneos-arm.deb \
		out/${VERSION}/radare2-arm32_${VERSION}_iphoneos-arm.deb \
		${CYDIA_PATH}
	msg "TODO: You should now remove the old deb packages and rebuild the package database by hand"
)}

publish_android_bin() {(
	arch="$1"
	git reset --hard >> $LOG
	git checkout master >> $LOG
	git pull >> ${LOG}
	git checkout android-${arch}
	cmp ../../out/${VERSION}/radare2-${VERSION}-android-${arch}.tar.gz radare2-1.0.0-git-android-${arch}.tar.gz && {
		msg "Already published ${VERSION} android build for radare2-${arch}"
		return
	}
	msg "Publishing android ${arch} binary..."
	git checkout master
	git branch -D android-${arch}
	git checkout -b android-${arch} || exit 1
	git checkout android-${arch} || exit 1
	cp -f ../../out/${VERSION}/radare2-${VERSION}-android-${arch}.tar.gz radare2-1.0.0-git-android-${arch}.tar.gz || exit 1
	echo "radare2 for android-${arch}" > README.md
	echo "========================" >> README.md
	echo "Date: `date +%Y-%m-%d`" >> README.md
	echo "Version: ${VERSION}" >> README.md
	git add *
	git commit -a -m "Release ${VERSION} for ${arch}" || exit 1
	git push --set-upstream origin android-${arch} -f || exit 1
)}

publish_android() {(
	msg "Publishing android binaries..."
	cd tmp || exit 1
	if [ -d radare2-bin ]; then
		cd radare2-bin || exit 1
		git reset --hard
		git pull
	else
		git clone https://github.com/radare/radare2-bin
		cd radare2-bin || exit 1
	fi
	publish_android_bin x86
	publish_android_bin arm
	publish_android_bin mips
	publish_android_bin aarch64
)}
