#
# !/bin/sh
#

set -euo pipefail
trap "echo 'error: Script failed: see failed command above'" ERR

##### start #####

_start(){
  # node ./node_modules/.bin/pm2 start ecosystem.json --env test
  node test/mock-server.js
}

##### run #####

main(){
  _start
}


main




