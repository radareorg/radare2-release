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
	msg "Updating the website..."
}

publish_android() {
	msg "Publishing android binaries..."
	clone
}
