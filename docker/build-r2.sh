#!/bin/sh
VERSION=1.0.2
tar xzf /data/tmp/radare2-${VERSION}.tar.gz && cd radare2-${VERSION} || exit 1
sys/install.sh || exit 1
sys/debian.sh || exit 1
cp sys/debian/radare2/*.deb /data/out/${VERSION}
