all: CONFIG
	@$(SHELL) main.sh

CONFIG:
	cp -f CONFIG.def CONFIG

clean:
	rm -f log.txt

mrproper: clean
	rm -rf tmp
