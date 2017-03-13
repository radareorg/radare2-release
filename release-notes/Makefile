all: node_modules radare2
	cd radare2 ; git pull
	cd radare2 ; git pull --tags
	cd radare2 ; node ..

radare2:
	git clone https://github.com/radare/radare2

node_modules:
	yarn
