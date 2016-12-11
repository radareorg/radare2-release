all:
	@$(SHELL) main.sh

clean:
	rm -f log.txt

mrproper: clean
	rm -rf tmp
