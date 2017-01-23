all: CONFIG
	@$(SHELL) main.sh -a

CONFIG:
	cp -f CONFIG.def CONFIG

clean:
	rm -f log.txt

DESTDIR?=
PREFIX?=/usr
BINDIR?=$(PREFIX)/bin

install:
	echo '#!/bin/sh' > r2rls
	echo "cd \"`pwd`\"" >> r2rls
	echo "./main.sh $$*" >> r2rls
	chmod +x r2rls
	cp -f r2rls $(DESTDIR)/$(BINDIR)/r2rls

uninstall:
	rm -f ${DESTDIR}/${BINDIR}/r2rls

mrproper: clean
	rm -rf tmp
