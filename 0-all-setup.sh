#!/bin/bash

DIR_NAME=$(dirname "$0")
cd ${DIR_NAME}

if [ ! -f "config.json" ]; then
  echo "Please make sure to create config.json file and to configure it before creating any container"
  echo "cp config.json.template config.json"
fi

if [ ! -f ".setup_done" ]; then
  ./1-setup-docker.sh
  echo "1"> .setup_done
fi

ls CTFd &>/dev/null || git clone https://github.com/CTFd/CTFd.git CTFd/
cd CTFd/
git fetch
cd ..
# Commented for now but it'll be decomissionned once we know that it's no longer useful. I'm still trying to understand why I didn't have used it
# The CTFd template is now manually created from templates/docker-compose-merged-template.yml
#sudo apt-get -y install python3-pip
#sudo pip3 install ruamel.yaml
#mkdir -p data/templates
#./bin/merge-yaml.py docker-compose-base.yml CTFd/docker-compose.yml data/templates/docker-compose-merged.yml
#diff data/templates/docker-compose-merged.yml docker-compose-merged-reference.yml || (
#  echo "The CTFd/docker-compose.yml was chaanged. Please update the docker-compose-merged-reference.yml file to refresh the new docker-compose-files/ files";exit)
echo "### Creating docker-compose files"
./2-create-new-projects-docker.sh
echo "### Creating new projects"
./3-create-new-projects-nginx.sh
cd CTFd/
echo "### Generating TLS certificates"
../4-init-letsencrypt.sh
echo "### Checking for the github.com/noraj/ctfd-theme-sigsegv2 plugin"
(ls CTFd/themes/sigsegv2 &>/dev/null && cd CTFd/themes/sigsegv2 && git pull && cd ../../..) || git clone https://github.com/noraj/ctfd-theme-sigsegv2.git CTFd/themes/sigsegv2
echo "### Adding logo and favicon files"
ls ${PWD}/CTFd/themes/core/static/img/logo.png.bak &>/dev/null || mv ${PWD}/CTFd/themes/core/static/img/logo.png ${PWD}/CTFd/themes/core/static/img/logo.png.bak
ls ${PWD}/CTFd/themes/core/static/img/favicon.ico.bak &>/dev/null || mv ${PWD}/CTFd/themes/core/static/img/favicon.ico ${PWD}/CTFd/themes/core/static/img/favicon.ico.bak
ln -sf ${PWD}/../logo.png ${PWD}/CTFd/themes/core/static/img/logo.png
ln -sf ${PWD}/../favicon.ico ${PWD}/CTFd/themes/core/static/img/favicon.ico

common_proxy_conf_path=$(cat ../config.json |python3 -c "import json,sys;print(json.load(sys.stdin)['common']['proxy_conf_path'])"  2>/dev/null)
if [ ! -z "$common_proxy_conf_path" ]; then
  cd ..
  if [ -d "$common_proxy_conf_path" ]; then
    real_path=$(readlink -f $common_proxy_conf_path)
  else
    echo "Error: File path specific in config.json:common.proxy_conf_path is not a directory";exit
  fi
  cd - > /dev/null
fi

sum=""
for x in $(ls -1 dcf-*.yml | grep -v dcf-docker-compose-common.yml);do
  sum="${sum} -f ${x}"
done
if [ ! -z "$real_path" ]; then
  dcf_common="-f $real_path/docker-compose-common.yml"
  if [ ! -f "$real_path/docker-compose-common.yml" ]; then
    $real_path/2-create-new-projects-docker.sh
  fi
else
  dcf_common="-f dcf-docker-compose-common.yml"
fi

echo "### Building the containers"
sudo docker-compose ${sum} --compatibility up -d --force-recreate #--build
# It's possible to use the depends_on parameter in docker-compose file in the proxy service to make it wait for the
#   creation of the other containers but it's hard to manage when it comes to adding and removing the container names from that parameter
sudo docker-compose ${dcf_common} --compatibility up -d --force-recreate
