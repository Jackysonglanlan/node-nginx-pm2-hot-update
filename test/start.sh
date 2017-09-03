#
#!/bin/sh
#
#

_start(){
  node ./node_modules/.bin/pm2 start test/configs/ecosystem.json --env dev
  # PORT=5000 node test/mock-server.js
}

##### run #####

main(){
  _start
}


main




