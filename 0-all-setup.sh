#!/bin/bash

# Source: http://stackoverflow.com/a/246128
# This was accurate more than DIR_NAME=$(dirname $(readlink -f "$0"))
DIR_NAME="$( cd -P "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
cd ${DIR_NAME}

# Load the configuration
. load-config.sh

if [ ! -f ".setup_done" ]; then
  ${PWD}/1-setup-docker.sh
  echo "1"> .setup_done
fi

container_names=""
if [ ! -z "$1" ]; then
  container_names="$@"
fi

ls CTFd &>/dev/null || git clone https://github.com/CTFd/CTFd.git CTFd/
cd CTFd/
git pull
cd ..

echo -e "${PREFIX_COLOR_SUCCESS}Creating docker-compose files...${SUFFIX_COLOR_DEFAULT}"
${PWD}/2-create-new-projects-docker.sh
echo -e "${PREFIX_COLOR_SUCCESS}Creating new projects...${SUFFIX_COLOR_DEFAULT}"
${PWD}/2-create-new-projects-nginx.sh
cd CTFd/
echo -e "${PREFIX_COLOR_SUCCESS}Generating TLS certificates...${SUFFIX_COLOR_DEFAULT}"
${PWD}/../3-init-letsencrypt.sh

#echo "### Checking for the github.com/noraj/ctfd-theme-sigsegv2 plugin"
#(ls CTFd/themes/sigsegv2 &>/dev/null && cd CTFd/themes/sigsegv2 && git pull && cd ../../..) || git clone https://github.com/noraj/ctfd-theme-sigsegv2.git CTFd/themes/sigsegv2
#echo "### Adding logo and favicon files"
#ls ${PWD}/CTFd/themes/core/static/img/logo.png.bak &>/dev/null || mv ${PWD}/CTFd/themes/core/static/img/logo.png ${PWD}/CTFd/themes/core/static/img/logo.png.bak
#ls ${PWD}/CTFd/themes/core/static/img/favicon.ico.bak &>/dev/null || mv ${PWD}/CTFd/themes/core/static/img/favicon.ico ${PWD}/CTFd/themes/core/static/img/favicon.ico.bak
#ln -sf ${PWD}/../logo.png ${PWD}/CTFd/themes/core/static/img/logo.png
#ln -sf ${PWD}/../favicon.ico ${PWD}/CTFd/themes/core/static/img/favicon.ico
cd - > /dev/null

echo -e "${PREFIX_COLOR_SUCCESS}Building the containers...${SUFFIX_COLOR_DEFAULT}"
${PWD}/4-rebuild-containers.sh ${container_names}
