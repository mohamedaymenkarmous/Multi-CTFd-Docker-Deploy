#!/bin/bash

# Source: http://stackoverflow.com/a/246128
# This was accurate more than DIR_NAME=$(dirname $(readlink -f "$0"))
DIR_NAME="$( cd -P "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
cd ${DIR_NAME}

echo -e "${PREFIX_COLOR_SUCCESS}Creating docker-compose files...${SUFFIX_COLOR_DEFAULT}"
${PWD}/2-create-new-projects-docker.sh
echo -e "${PREFIX_COLOR_SUCCESS}Creating new projects...${SUFFIX_COLOR_DEFAULT}"
${PWD}/2-create-new-projects-nginx.sh
cd CTFd/
echo -e "${PREFIX_COLOR_SUCCESS}Generating TLS certificates...${SUFFIX_COLOR_DEFAULT}"
${PWD}/../3-init-letsencrypt.sh
