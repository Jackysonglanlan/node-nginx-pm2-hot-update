# !/bin/sh
# 这个文件是在 部署服务器上 执行的 !!!
#
# Usage:
#
# post-setup.sh NODE_ENV
#
# param1: NODE_ENV value


DIR="${BASH_SOURCE%/*}"
if [[ ! -d "$DIR" ]]; then DIR="$PWD"; fi

. $DIR/../lib/utils.sh

use_red_green_echo "post-setup"

set -euo pipefail
trap "echo 'error: Script failed: see failed command above'" ERR

# copy https cert to production server from CI server
if [[ ${1:? "Missing NODE_ENV as 1st param"} == production ]]; then
  green "copying https cert to production server: 112.124.106.207"
  # 下面的 https 证书，是提前拷贝到 CI 服务器中的，为了安全，没有放在 git 中
  scp /home/maintain/servers/jenkins/secret/yqj-wit-work/yiqijiao-net-https-cert.* deploy@112.124.106.207:/var/www/yqj-wit-work/nginx
fi


