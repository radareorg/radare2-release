publish_checksums() {(
	msg "Computing checksums..."
	cd out/${VERSION}
	rm -f checksums.sha1sum
	sha1sum * > checksums.sha1sum
)}

publish_irc() {
	msg "Updating IRC channel title..."
}

publish_www() {
	msg "Updating the website"
}

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
	msg "Publishing android ${arch} binary..."
	git reset --hard
	git checkout master
	git pull >> ${LOG}
	git checkout android-${arch}
	cmp ../../out/${VERSION}/radare2-${VERSION}-android-${arch}.tar.gz radare2-1.0.0-git-android-${arch}.tar.gz && {
		msg "Already published ${VERSION} android build for radare2-${arch}"
		return
	}

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
