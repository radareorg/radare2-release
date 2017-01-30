all: config.json node_modules/node-irc
	node index.js

node_modules/node-irc:
	npm install node-irc

config.json:
	cp -f config.json.def config.json
