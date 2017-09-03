'use strict';

const http = require('http');

const server = http.createServer((req, res) => {
  res.writeHead(200, { 'Content-Type': 'text/plain' });
  res.end('yahhhhh');
});

const port = process.env.PORT;

console.log(`server listen to ${port}`);

if (!port) {
  throw new Error('Must set env PORT');
}

server.listen(port);
