#!/bin/bash

DIR_NAME=$(dirname "$0")
cd ${DIR_NAME}

if [ ! -f "config.json" ]; then
  echo "Please make sure to create config.json file and to configure it before creating any container"
  echo "cp config.json.template config.json"
fi

common_proxy_conf_path=$(cat config.json |python3 -c "import json,sys;print(json.load(sys.stdin)['common']['proxy_conf_path'])"  2>/dev/null)
if [ ! -z "$common_proxy_conf_path" ]; then
  if [ -d "$common_proxy_conf_path" ]; then
    real_path=$(readlink -f $common_proxy_conf_path)
  else
    echo "Error: File path specific in config.json:common.proxy_conf_path is not a directory";exit
  fi
fi

# The script needs to run from the location where the Dockerfile is located
cd CTFd

sum=""
for x in $(ls -1 dcf-*.yml | grep -v dcf-docker-compose-common.yml);do
  sum="${sum} -f ${x}"
done

cd - >/dev/null

if [ ! -z "$real_path" ]; then
  dcf_common="-f $real_path/docker-compose-common.yml"
  if [ ! -f "$real_path/docker-compose-common.yml" ]; then
    $real_path/2-create-new-projects-docker.sh
  fi
else
  dcf_common="-f dcf-docker-compose-common.yml"
fi

# The script needs to run from the location where the Dockerfile is located
cd CTFd

echo "### Building the containers"
# It's possible to use the depends_on parameter in docker-compose file in the proxy service to make it wait for the
#   creation of the other containers but it's hard to manage when it comes to adding and removing the container names from that parameter
#   so I opted to start all the containers except the proxy then to start the proxy to make sure all the web servers defined in the upstream directive are reachable
sudo docker-compose ${sum} --compatibility up -d --force-recreate #--build
sudo docker-compose ${dcf_common} --compatibility up -d --force-recreate
