#
#! /bin/sh
#
# Usage:
#   op-seamless-update.sh pub_method params...
#

PAUSE_INTERVAL_BETWEEN_NODE_RELOAD_IN_SECOND=5

####################
##### private
####################

# $1: the prefix this log will use as "[prefix] xxxx"
use_red_green_echo() {
  prefix="$1"
  red() {
    echo "$(tput bold)$(tput setaf 1)[$prefix] $*$(tput sgr0)";
  }
  
  green() {
    echo "$(tput bold)$(tput setaf 2)[$prefix] $*$(tput sgr0)";
  }
  
  yellow() {
    echo "$(tput bold)$(tput setaf 3)[$prefix] $*$(tput sgr0)";
  }
}

use_red_green_echo "op-hot-update:${NODE_ENV:? "Missing NODE_ENV"}"

##
# $1: App name in PM2 that needs to reload
#
_pm2ReloadNode(){
  pm2 --env ${NODE_ENV:? "Missing NODE_ENV"} reload "$1"
}

# $1: op-nginx config file
# $2: Site's shortname for update, see op-nginx's json config file
# $3: backend list, ',' separated, like localhost:5001,localhost:5002,localhost:5003
_nginxUpstreamTo(){
  op-nginx upstreamTo --config=$1 --site=$2 --backends=$3
}

####################
##### public
####################

#### Step 1: select 1 node to be 'tmp' node
#
# params are the same as _nginxUpstreamTo
#
# e.g. NODE_ENV=dev bin/op-seamless-update.sh prepareHotUpdate foo localhost:5000
prepare(){
  _nginxUpstreamTo $1 $2 $3
  
  green '--------------------------'
  green "Make sure *ALL* the throughout is redirected to backend $3...."
  green 'Then you can start updating !!!'
  green '--------------------------'
}

###### .... hot update servers ....

# array: (localhost:5001,localhost:5002,localhost:5003)
declare -a alreadyUpdatedNodes

# $1: op-nginx config file
# $2: PM2 app name
# $3: Nginx backend
_startNodeThenStreamToIt(){
  local configFile="$1"
  local appName="$2"
  local backend="$3"
  
  green "start updating $appName"
  _pm2ReloadNode "$appName"
  
  # wait some time to let the new node fully started
  sleep ${PAUSE_INTERVAL_BETWEEN_NODE_RELOAD_IN_SECOND}s
  
  alreadyUpdatedNodes+="$backend,"
  
  # toString() then remove the last ','
  local len=${#alreadyUpdatedNodes}
  local nginxUpstreams=${alreadyUpdatedNodes:0:len-1}
  
  # stream throughput back to new updated nodes
  green "streaming Nginx throughput back to new updated node: $nginxUpstreams"
  _nginxUpstreamTo $configFile $appName "$nginxUpstreams"
}

#### Step 2: batch update all other nodes except the one still working
#
# $1: op-nginx config file
# $2: Site's shortname in op-nginx's config file
# $3: Swap backend, for temp use during updating, format: pm2_app_name=nginx_backend
# $4: All other backends, use the same format as swap backend, separated by ','
#
# e.g. NODE_ENV=dev bin/op-seamless-update.sh startHotUpdate foo foo:5000=localhost:5000 foo:5001=localhost:5001,foo:5002=localhost:5002
start(){
  local configFile=$1
  local siteName=$2
  local swapBackend=$3
  
  # to array
  IFS=',' read -r -a AllOtherBackends <<< "$4"

  for backend in ${AllOtherBackends[@]}
  do
    # parse backend to appname and nginx backend
    IFS='=' read -r -a tmpArr <<< "$backend"
    local pm2AppName=${tmpArr[0]}
    local nginxBackend=${tmpArr[1]}

    _startNodeThenStreamToIt $configFile $pm2AppName $nginxBackend
    sleep 1
  done

  # parse swap backend to appname and nginx backend
  IFS='=' read -r -a tmpArr <<< "$swapBackend"
  local pm2AppName=${tmpArr[0]}
  local nginxBackend=${tmpArr[1]}

  # 3. update the 'tmp' one then make the 'tmp' one back to work
  _startNodeThenStreamToIt $configFile $pm2AppName $nginxBackend

  green '--------------------------'
  green "ALL APPs in PM2 ARE UPDATED !!!"
  green '--------------------------'
}


# 动态调用上面的方法
$@


