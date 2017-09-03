#
#! /bin/sh
#
#
# Usage:
#   ./op-nginx.sh upstreamTo --site=foo --backends=localhost:5001,localhost:5002
#
# $1: public method
# $2 to $9: parameters of that public method
#

set -euo pipefail
trap "echo 'error: Script failed: see failed command above'" ERR

. $(dirname "$0")/lib/utils.sh

use_red_green_echo "op-nginx"

_invokeMechanic(){
  # 说明:
  # 1. 每次执行 mechanic 都需要传 --data 读取我们的配置, 否则会读取默认的 mechanic.json
  # 2. update 指令: 重新装载 mechanic.json 和 template.conf, 生成新的 nginx 配置, 然后执行 nginx -s reload 生效
  
  node ./production-only/nginx/mechanic/lib/index $@
}

#########################
##### public methods ####
#########################

# $1: --config=path/to/config.json
start(){
  _invokeMechanic start $@
}

# $1: --config=path/to/config.json
reload(){
  _invokeMechanic reload $@
}

##
# $1: --config=path/to/config.json
# $2: --site=site.shortname
# $3: --backends=list of backend
#
# e.g:
# upstreamTo --site=site_foo --backends=localhost:5001,localhost:5002
#
upstreamTo(){
  _invokeMechanic upstreamTo $@
}

yellow "executing op: $@"

# 外部直接传 方法名+参数 实现动态调用, 比如: ./op-nginx.sh upstreamTo --config=foo.json --site=site_foo --backends=localhost:5001,localhost:5002
$@

green 'operate nginx done!'
