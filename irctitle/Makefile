all: config.json node_modules
	node index.js

node_modules:
	yarn || npm install

config.json:
	cp config.json.def config.json
