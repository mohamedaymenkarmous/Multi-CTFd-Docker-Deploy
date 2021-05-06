#!/bin/bash

# Source: http://stackoverflow.com/a/246128
# This was accurate more than DIR_NAME=$(dirname $(readlink -f "$0"))
DIR_NAME="$( cd -P "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
cd ${DIR_NAME}

# Load the configuration
. load-config.sh || exit 1
exit_on_missing_config

if [ "$N_PROJECTS" == "0" ]; then
  echo -e "${PREFIX_COLOR_WARNING}Skipped because there was no defined project in config.json file${SUFFIX_COLOR_DEFAULT}"
  exit 0
fi

ls docker-compose-files &>/dev/null || mkdir docker-compose-files
for i in $(seq 1 $N_PROJECTS);do
  name=$(parse_config '' "'projects'" "${i}-1" "'name'")
  target=$(parse_config '' "'projects'" "${i}-1" "'target'")
  sed "s/REPLACED_NAME/${name}/g" <templates/docker-compose-merged-template.yml > docker-compose-files/dcf-${name}.yml;
  sed "s/REPLACED_TARGET/${target}/g" <docker-compose-files/dcf-${name}.yml > docker-compose-files/dcf-${name}.yml.tmp;
  mv docker-compose-files/dcf-${name}.yml.tmp docker-compose-files/dcf-${name}.yml;
  # Due to this unexpected behavior, it's recommended to setup the full path in the docker-compose files: https://github.com/docker/compose/issues/8275
  sed "s;REPLACED_FULL_PATH;${PWD};g" <${PWD}/docker-compose-files/dcf-${name}.yml > ${PWD}/docker-compose-files/dcf-${name}.yml.tmp;
  mv docker-compose-files/dcf-${name}.yml.tmp docker-compose-files/dcf-${name}.yml;
  ln -sf ${PWD}/docker-compose-files/dcf-${name}.yml ${PWD}/CTFd/dcf-${name}.yml
  if [ "${COMMON_TASKS_COMPATIBLE}" != "1" ]; then
    ln -sf ${PWD}/docker-compose-files/dcf-docker-compose-common.yml ${PWD}/CTFd/dcf-docker-compose-common.yml
  else
    rm ${PWD}/docker-compose-files/dcf-docker-compose-common.yml 2>/dev/null
    rm ${PWD}/CTFd/dcf-docker-compose-common.yml 2>/dev/null
  fi
done
