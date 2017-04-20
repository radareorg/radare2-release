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
	chmod +x bin/r2rls
	ln -fs $(shell pwd)/bin/r2rls $(DESTDIR)/$(BINDIR)/r2rls

uninstall:
	rm -f ${DESTDIR}/${BINDIR}/r2rls

mrproper: clean
	rm -rf tmp
