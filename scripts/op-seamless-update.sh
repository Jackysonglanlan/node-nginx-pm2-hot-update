#
#! /bin/sh
#
#
# Usage:
#   op-seamless-update.sh dev readyForUpdate
#
#   $1: NODE_ENV value
#   $2: public method to invoke
#

. $(dirname "$0")/lib/utils.sh

_set_env(){
  export NODE_ENV=$1
}
_set_env ${1:? Missing NODE_ENV as 1st param}

use_red_green_echo "op-seamless-update:$NODE_ENV"

#### start ####

##
# $1: the node name in PM2 that needs to reload
#
_pm2_reload_node(){
  ./node_modules/.bin/pm2 --env $NODE_ENV reload "$1"
}

####################
##### public
####################

PAUSE_INTERVAL_BETWEEN_NODE_RELOAD=5s

SWAP_NODE_PORT=5000

ALL_OTHER_NODE_PORTS=(5001 5002)

readyForUpdate(){
  # 1. select 1 node to be 'tmp' node
  npm run op-nginx-upstream-to -- localhost:$SWAP_NODE_PORT
  
  green '--------------------------'
  green "Make sure *ALL* the throughout is redirected to node localhost:$SWAP_NODE_PORT...."
  green 'Then you can start updating !!!'
  green '--------------------------'
}

###### .... deploy new code to server ....

# array: (localhost:5001,localhost:5002,localhost:5003)
declare -a alreadyStartedNodes

##
# $1: the node's port which you want to update
#
_startNodeThenStreamToIt(){
  local port="$1"
  green "start updating $port"
  _pm2_reload_node "yqj-wit-work:$port"
  
  # wait some time to let the new node fully started
  sleep $PAUSE_INTERVAL_BETWEEN_NODE_RELOAD
  
  alreadyStartedNodes+="localhost:$port,"
  
  # toString() then remove the last ','
  local len=${#alreadyStartedNodes}
  local nginxUpstreamParam=${alreadyStartedNodes:0:len-1}
  
  # stream throughput back to new updated nodes
  green "streaming throughput back to new updated node: $nginxUpstreamParam"
  
  npm run op-nginx-upstream-to -- "$nginxUpstreamParam"
}

startUpdate(){
  # 2. batch update all other nodes except the one still working
  
  for port in ${ALL_OTHER_NODE_PORTS[@]}
  do
    _startNodeThenStreamToIt $port
    sleep 1
  done
  
  # 3. update the 'tmp' one then make the 'tmp' one back to work
  _startNodeThenStreamToIt $SWAP_NODE_PORT
  
  green '--------------------------'
  green "ALL NODES($alreadyStartedNodes) ARE UPDATED !!!"
  green '--------------------------'
}


# 根据第3个参数, 动态调用上面的方法
$2


