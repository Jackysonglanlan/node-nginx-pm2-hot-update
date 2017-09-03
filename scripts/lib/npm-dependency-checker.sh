# ! /bin/sh
#
# 计算 dependencies 和 devDependencies 段的数据有没有改动，如果有，则说明包有改变
#
# Usage:
# ./npm-dependency-checker.sh package.json
#
# $1: path/to/package.json

DIR="${BASH_SOURCE%/*}"
if [[ ! -d "$DIR" ]]; then DIR="$PWD"; fi

. $DIR/utils.sh

use_red_green_echo "scripts"

# $1: content of package.json
# @return content between "dependencies" to "devDependencies" of package.json
_extract_dependencies_section(){
  echo $1 | egrep -o '"dependencies.+devDependencies.+?\}' # extract dependencies and devDependencies
}

# $1: package.json file content
# @return md5sum of the dependencies section
_gene_package_json_dependency_finger_print(){
  local dependenciesSection=$(_extract_dependencies_section "$1") # embrace with "" to remove \n in content
  
  local plaform=$(uname)
  
  local md5Value=''
  if [[ $plaform == 'Darwin' ]]; then
    # mac
    md5Value=$(md5 -q -s "$dependenciesSection")
  else
    # linux
    md5Value=$(echo "$dependenciesSection" | md5sum)
    md5Value=${md5Value// /} # remove spaces
  fi
  
  echo $md5Value
}

###### public ######

# $1: package.json file content
# @return 0 if no need, 1 if needed
check_if_need_npm_install_with_finger_print_file(){
  local md5Value=$(_gene_package_json_dependency_finger_print "$1") # embrace with "" to remove \n in content
  local md5FileName='package.md5.log'
  
  if [[ -f $md5FileName ]]; then
    local md5FileContent=$(cat $md5FileName)
    if [[ $md5Value == $md5FileContent ]]; then
      # 文件没变, 不需要安装pkg
      echo 0 # 返回值
      return
    fi
  fi
  
  # 需要安装
  echo 1 # 返回值
}

# $1: package.json file content
gene_package_json_dependency_finger_print_file(){
  local md5Value=$(_gene_package_json_dependency_finger_print "$1") # embrace with "" to remove \n in content
  local md5FileName='package.md5.log'
  # 生成一个文件
  echo $md5Value > $md5FileName
}

packageJsonFileContent=$(cat ${2:? 'Usage: npm-dependency-checker.sh PUB_METHOD path/to/package.json'})

# dyna invoke public methods
$1 "$packageJsonFileContent"


