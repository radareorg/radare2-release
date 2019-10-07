all: node_modules radare2
	cd radare2 ; git pull
	cd radare2 ; git pull --tags
	cd radare2 ; node ..

radare2:
	git clone https://github.com/radareorg/radare2

node_modules:
	yarn

clean:
	rm -f notes.txt

mrproper:
	rm -rf node_modules
