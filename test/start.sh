#
#!/bin/sh
#
#

_start(){
  # node ./node_modules/.bin/pm2 start ecosystem.json --env production
  node test/mock-server.js
}

##### run #####

main(){
  _start
}


# main




