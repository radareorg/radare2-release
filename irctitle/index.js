/* update irc title with last release info by pancake@nopcode.org in 2016 */

const ircClient = require('node-irc');
const C = require('./config.json');
const fs = require('fs');

function composeNewTopic() {
  const version = fs.readFileSync('../CONFIG').toString().split('\n').filter((a) => {
    return a.indexOf('VERSION=') === 0;
  })[0].split('=')[1];
  const sha1sum = fs.readFileSync('../out/' + version + '/checksums.sha1sum').toString().split('\n').filter((x) => {
    return x.indexOf('radare2-' + version + '.tar.gz') !== -1;
  })[0].split(' ')[0];
  return 'radare2-' + version+ '.tar.gz ' + sha1sum + ' -- https://rada.re http://cloud.rada.re http://radare.tv http://radare.today'
}

C.topic = composeNewTopic();

const irc = new ircClient(C.host, C.port, C.nick, C.name);
// irc.verbosity = 3;

irc.on('ready', function () {
  irc.join(C.channel);
  irc.say('nickserv', 'identify ' + C.nickserv);
  setTimeout(function() {
    irc.client.write('TOPIC #radare :' + C.topic + '\r\n');
    setTimeout(function() {
      console.log('byebye');
      irc.part(C.channel);
      irc.quit();
    }, 2000);
  }, 15000);
});

irc.on('PRIVMSG', function (data) {
  console.log(data);
});

irc.connect();
