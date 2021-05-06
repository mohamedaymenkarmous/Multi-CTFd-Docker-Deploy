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
./2-create-new-projects-nginx.sh
cd CTFd/
echo "### Generating TLS certificates"
../3-init-letsencrypt.sh
echo "### Checking for the github.com/noraj/ctfd-theme-sigsegv2 plugin"
(ls CTFd/themes/sigsegv2 &>/dev/null && cd CTFd/themes/sigsegv2 && git pull && cd ../../..) || git clone https://github.com/noraj/ctfd-theme-sigsegv2.git CTFd/themes/sigsegv2
echo "### Adding logo and favicon files"
ls ${PWD}/CTFd/themes/core/static/img/logo.png.bak &>/dev/null || mv ${PWD}/CTFd/themes/core/static/img/logo.png ${PWD}/CTFd/themes/core/static/img/logo.png.bak
ls ${PWD}/CTFd/themes/core/static/img/favicon.ico.bak &>/dev/null || mv ${PWD}/CTFd/themes/core/static/img/favicon.ico ${PWD}/CTFd/themes/core/static/img/favicon.ico.bak
ln -sf ${PWD}/../logo.png ${PWD}/CTFd/themes/core/static/img/logo.png
ln -sf ${PWD}/../favicon.ico ${PWD}/CTFd/themes/core/static/img/favicon.ico
cd - > /dev/null
echo "### Building the containers"
./5-rebuild-containers.sh
