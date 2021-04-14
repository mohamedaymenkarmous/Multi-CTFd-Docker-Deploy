#!/bin/bash

DIR_NAME=$(dirname "$0")
cd ${DIR_NAME}

if [ ! -f "config.json" ]; then
  echo "Please make sure to create config.json file and to configure it before creating any container"
  echo "cp config.json.template config.json"
fi

n=$(cat config.json |python3 -c "import json,sys;print(len(json.load(sys.stdin)['projects']))")

if [ "$n" == "0" ]; then
  echo "Skipped"
fi

common_tasks_compatible=$(cat config.json |python3 -c "import json,sys;print(json.load(sys.stdin)['common']['tasks_compatible'])" 2>/dev/null)

ls docker-compose-files &>/dev/null || mkdir docker-compose-files
for i in $(seq 1 $n);do
  name=$(cat config.json |python3 -c "import json,sys;print(json.load(sys.stdin)['projects'][${i}-1]['name'])")
  #ls docker-compose-files/$name.yml &>/dev/null || (
    sed "s/REPLACED_NAME/${name}/g" <templates/docker-compose-merged-template.yml > docker-compose-files/dcf-${name}.yml;
    # Due to this unexpected behavior, it's recommended to setup the full path in the docker-compose files: https://github.com/docker/compose/issues/8275
    sed "s;REPLACED_FULL_PATH;${PWD};g" <docker-compose-files/dcf-${name}.yml > docker-compose-files/dcf-${name}.yml.tmp;
    mv docker-compose-files/dcf-${name}.yml.tmp docker-compose-files/dcf-${name}.yml;
    ln -sf ${PWD}/docker-compose-files/dcf-${name}.yml ${PWD}/CTFd/dcf-${name}.yml
  #)
  if [ "$common_tasks_compatible" != "1" ]; then
    #grep "\- ctfd-${name}$" ${PWD}/CTFd/dcf-docker-compose-common.yml &>/dev/null || (
      # Due to this unexpected behavior, it's recommended to setup the full path in the docker-compose files: https://github.com/docker/compose/issues/8275
      sed "s;REPLACED_FULL_PATH;${PWD};g" <${PWD}/templates/docker-compose-common-template.yml > ${PWD}/docker-compose-files/dcf-docker-compose-common.yml;
    #  sed "s!#Depends_On_Here_Dont_Touch_This_Comment!#Depends_On_Here_Dont_Touch_This_Comment\n      - ctfd-${name}!g" <${PWD}/docker-compose-files/dcf-docker-compose-common.yml > ${PWD}/docker-compose-files/dcf-docker-compose-common.yml.tmp;
    #  mv ${PWD}/docker-compose-files/dcf-docker-compose-common.yml ${PWD}/docker-compose-files/dcf-docker-compose-common.yml.tmp)
    ln -sf ${PWD}/docker-compose-files/dcf-docker-compose-common.yml ${PWD}/CTFd/dcf-docker-compose-common.yml
  else
    rm ${PWD}/docker-compose-files/dcf-docker-compose-common.yml 2>/dev/null
    rm ${PWD}/CTFd/dcf-docker-compose-common.yml 2>/dev/null
  fi
done
