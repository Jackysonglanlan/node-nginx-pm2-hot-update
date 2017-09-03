#
#! /bin/sh
#
# 这个文件在 远端服务器 上执行!!
#
# 如果出现 sorry, you must have a tty to run sudo:
#
# 编辑 /etc/sudoers, 注释掉 Defaults    requiretty
#
# Usage:
#   post-deploy.sh inner.test /path/to/deploy
#
#   $1: NODE_ENV value
#   $2: application deployment path
#

DIR="${BASH_SOURCE%/*}"
if [[ ! -d "$DIR" ]]; then DIR="$PWD"; fi

. $DIR/../lib/utils.sh

_set_env(){
  export NODE_ENV=$1
}
_set_env ${1:? Missing NODE_ENV value as the 1st param}

SERVER_ROOT_DIR=${2:? Missing SERVER_ROOT_DIR as the 2nd param}

# 生成本次 pm2 部署时拉取的 git commit, 用于路由 dev/debug/load-balance 的 gitInfo 记录
_gene_git_info_file_to_project_dir(){
  local pm2_curr=$(git rev-parse HEAD)
  # pm2_curr is the hash
  
  # this file will be used in src/server/routes/dev/debug.js, route load-balance
  echo $(git log --oneline | grep "${pm2_curr:0:7}") > git.info
}

_build_logs_related_dir(){
  mkdir -p "$SERVER_ROOT_DIR/current/logs/{error,nginx,pids,pm2}"
}

_build_nginx_related_dir(){
  mkdir -p "$SERVER_ROOT_DIR/nginx"
  cp -rf production-only/nginx/static "$SERVER_ROOT_DIR/nginx"
}

_build_external_config_related_dir(){
  local extConfigDir="$SERVER_ROOT_DIR/external-config"
  mkdir -p "$extConfigDir"
  cp -f production-only/mongo.conf.yml "$extConfigDir"
  cp -f production-only/redis.conf "$extConfigDir"
}

# 配置日志滚动记录
_config_logrotate(){
  sudo cp -f scripts/pm2-hooks/yqj-* /etc/logrotate.d
  sudo chmod 644 /etc/logrotate.d/yqj-*
  
  # manually trigger the log rotation, it's ok if it fails
  /usr/sbin/logrotate -vdf /etc/logrotate.d/yqj-wit-work-logrotate || echo ''
}

_start_swagger_ui(){
  # start swagger ui if it hasn't started
  local isSwaggerUIRuning=$(ps aux | grep dev-only/swagger-ui | grep node)
  if [[ $isSwaggerUIRuning == '' ]]; then
    npm run dev-start-swagger-ui
  else
    echo 'swagger ui is already started...'
  fi
}

_update_servers(){
  echo
  echo '-----------------'
  echo 'UPDATE SERVERS...'
  echo '-----------------'
  
  local isNginxRuning=$(ps aux | grep nginx | grep $SERVER_ROOT_DIR)
  if [[ $isNginxRuning == "" ]]; then
    echo 'no nginx running, starting...'
    scripts/op-nginx.sh reload
    sudo nginx -c "$SERVER_ROOT_DIR/nginx/mechanic.conf"
    echo 'nginx started...'
    
    echo 'start servers via pm2...'
    npm run prod-start
  else
    echo 'nginx is already started, reloading...'
    
    # 根据不同环境(nginx的配置文件路径不同) 刷新 nginx 配置
    scripts/op-nginx.sh reload
    
    scripts/op-seamless-update.sh $NODE_ENV startUpdate
    
    # 测试环境才可以直接自动升级, 生产环境还是手工执行命令
    # if [[ $NODE_ENV != 'production' ]]; then
    #   echo 'start seamless updating servers...'
    #   # 由于是测试环境, 所以可以直接无缝升级, 不需要 ready 这一步
    #   scripts/op-seamless-update.sh $NODE_ENV startUpdate
    # else
    #   echo '--------- WARNING ----------'
    #   echo 'Node.js runs on PRODUCTION server, please updating servers MANUALLY in $SERVER_ROOT_DIR:'
    #   echo 'execute: npm run op-seamless-update-be-ready'
    #   echo 'execute: npm run op-seamless-update-start'
    #   echo '------- WARNING END --------'
    # fi
  fi
  
  echo '-----------------'
  echo 'DONE...'
  echo '-----------------'
  echo
}

#############
# public
#############

seamless_update_server(){
  _gene_git_info_file_to_project_dir
  
  _build_logs_related_dir
  
  _build_nginx_related_dir
  
  _build_external_config_related_dir
  
  _config_logrotate
  
  npm_install_if_needed package.json
  
  _update_servers
  
  # 非生产环境, 启动 swagger 方便其他工程师查看 API
  if [[ $NODE_ENV != 'production' ]]; then
    _start_swagger_ui
  fi
}

seamless_update_server


