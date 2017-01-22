all: CONFIG
	@$(SHELL) main.sh -a

CONFIG:
	cp -f CONFIG.def CONFIG

clean:
	rm -f log.txt

mrproper: clean
	rm -rf tmp
