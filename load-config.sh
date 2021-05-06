#!/bin/bash

# Source: http://stackoverflow.com/a/246128
# This was accurate more than DIR_NAME=$(dirname $(readlink -f "$0"))
DIR_NAME="$( cd -P "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
cd ${DIR_NAME}

export PREFIX_COLOR_SUCCESS="\e[38;5;82m# "
export PREFIX_COLOR_WARNING="\e[38;5;202m"
export PREFIX_COLOR_ERROR="\e[31m"
export SUFFIX_COLOR_DEFAULT="\e[39m"

function exit_on_missing_config(){
  if [ ! -f "config.json" ]; then
    echo -e "${PREFIX_COLOR_ERROR}Please make sure to create config.json file and to configure it before creating any container that is using the proxy web server${SUFFIX_COLOR_DEFAULT}"
    echo -e "${PREFIX_COLOR_ERROR}cp config.json.example config.json${SUFFIX_COLOR_DEFAULT}"
    exit 1
  fi
}

function parse_config(){
  default="$1"
  shift;
  params="$@"
  attrs=""
  for i in ${params}; do
    attrs="${attrs}[${i}]"
  done
  echo -n $(cat config.json 2> /dev/null | python3 -c "import json,sys;print(json.load(sys.stdin)${attrs})" 2> /dev/null || echo $default)
}
function parse_config_n(){
  default="$1"
  shift;
  params="$@"
  attrs=""
  for i in ${params}; do
    attrs="${attrs}[${i}]"
  done
  echo -n $(cat config.json 2> /dev/null | python3 -c "import json,sys;print(len(json.load(sys.stdin)${attrs}))" 2> /dev/null || echo $default)
}

export N_PROJECTS=$(parse_config_n '0' "'projects'")
export N_TLS=$(parse_config_n '0' "'tls'")
export COMMON_TASKS_COMPATIBLE=$(parse_config '' "'common'" "'tasks_compatible'")
export COMMON_PROXY_CONF_PATH=$(parse_config '' "'common'" "'proxy_conf_path'")
