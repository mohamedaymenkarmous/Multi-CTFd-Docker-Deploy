#!/bin/bash

# Source: http://stackoverflow.com/a/246128
# This was accurate more than DIR_NAME=$(dirname $(readlink -f "$0"))
DIR_NAME="$( cd -P "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
cd ${DIR_NAME}

# Load the configuration
. load-config.sh

if [ ! -z "${COMMON_PROXY_CONF_PATH}" ]; then
  if [ -d "${COMMON_PROXY_CONF_PATH}" ]; then
    real_path=$(readlink -f ${COMMON_PROXY_CONF_PATH})
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

container_names=""
if [ ! -z "$1" ]; then
  container_names="$@"
  echo -e "${PREFIX_COLOR_SUCCESS}Filtering the actions over the following containers ${container_names}...${SUFFIX_COLOR_DEFAULT}"
fi

if [ ! -z "$real_path" ]; then
  dcf_common="-f $real_path/docker-compose-files/dcf-docker-compose-common.yml"
  if [ ! -f "$real_path/docker-compose-files/dcf-docker-compose-common.yml" ]; then
    $real_path/2-create-new-projects-docker.sh
  fi
else
  dcf_common="-f dcf-docker-compose-common.yml"
fi

# The script needs to run from the location where the Dockerfile is located
cd CTFd

echo -e "${PREFIX_COLOR_SUCCESS}Building the CTFD containers...${SUFFIX_COLOR_DEFAULT}"
# It's possible to use the depends_on parameter in docker-compose file in the proxy service to make it wait for the
#   creation of the other containers but it's hard to manage when it comes to adding and removing the container names from that parameter
#   so I opted to start all the containers except the proxy then to start the proxy to make sure all the web servers defined in the upstream directive are reachable
sudo docker-compose ${sum} --compatibility up -d --force-recreate --build ${container_names}

echo -e "${PREFIX_COLOR_SUCCESS}Recreate the CTFD containers with the build ready...${SUFFIX_COLOR_DEFAULT}"
sudo docker-compose ${sum} --compatibility up -d --force-recreate ${container_names}

echo -e "${PREFIX_COLOR_SUCCESS}Building the reverse proxy container...${SUFFIX_COLOR_DEFAULT}"
# It's possible to use the depends_on parameter in docker-compose file in the proxy service to make it wait for the
#   creation of the other containers but it's hard to manage when it comes to adding and removing the container names from that parameter
#   so I opted to start all the containers except the proxy then to start the proxy to make sure all the web servers defined in the upstream directive are reachable
sudo docker-compose ${dcf_common} --compatibility up -d --force-recreate --build ${container_names}
