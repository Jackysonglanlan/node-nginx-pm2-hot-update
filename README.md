
# Hot update your Node server via Nginx and PM2

## Personal use, NOT a production-level package. Sorry guys, no time.

## Install
For now, `npm i -S https://github.com/Jackysonglanlan/node-nginx-pm2-hot-update.git`
And you **MUST** have [PM2](http://pm2.io/) installed.

## TODO: I'm sure you can't understand what I wrote below, so need more documents

## Usage

After install, you get 2 executable scripts:

### `op-nginx` - auto-oparate nginx

 function | description | e.g 
----------|-------------|--------
 start | TODO | `op-nginx start --config=path/to/op-nginx-conf.json`
 reload | TODO | `op-nginx reload --config=path/to/op-nginx-conf.json`
 upstreamTo | TODO | `op-nginx upstreamTo --config=path/to/op-nginx-conf.json --site=foo --backends=ip:port,ip:port`

### `op-hot-update` - perform hot update via nginx and PM2

 function | description | e.g 
----------|-------------|--------
 prepare | TODO | `op-hot-update prepare path/to/op-nginx-conf.json foo ip:port`
 start | TODO | `op-hot-update start path/to/op-nginx-conf.json foo pm2App=ip:port pm2App=ip:port,pm2App=ip:port`

You can use these in you NPM scripts and your PM2's `post-deploy` script to make a better devops process.

## Credit
Based on [https://github.com/punkave/mechanic](https://github.com/punkave/mechanic), modify it for my own usage.
