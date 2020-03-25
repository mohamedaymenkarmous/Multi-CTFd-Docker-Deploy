#!/bin/bash

n=$(cat config.json |python3 -c "import json,sys;print(len(json.load(sys.stdin)['projects']))")

if [ "$n" == "0" ]; then
  echo "Skipped"
fi

ls docker-compose-files &>/dev/null || mkdir docker-compose-files
for i in $(seq 1 $n);do
  name=$(cat config.json |python3 -c "import json,sys;print(json.load(sys.stdin)['projects'][${i}-1]['name'])")
  hostname=$(cat config.json |python3 -c "import json,sys;print(json.load(sys.stdin)['projects'][${i}-1]['hostname'])")
  generic_hostname=$(cat config.json |python3 -c "import json,sys;print(json.load(sys.stdin)['projects'][${i}-1]['generic-hostname'])")
  tls_enabled=$(cat config.json |python3 -c "import json,sys;print(json.load(sys.stdin)['projects'][${i}-1]['tls-enabled'])")
  #ls docker-compose-files/$name.yml &>/dev/null || (
    sed "s/REPLACED_NAME/${name}/g" <docker-compose-merged-template.yml > docker-compose-files/dcf-${name}.yml;
    ln -sf ${PWD}/docker-compose-files/dcf-${name}.yml ${PWD}/CTFd/dcf-${name}.yml
  #)
  grep "\- ctfd-${name}$" docker-compose-common.yml &>/dev/null || (
    sed "s!#Depends_On_Here_Dont_Touch_This_Comment!#Depends_On_Here_Dont_Touch_This_Comment\n      - ctfd-${name}!g" <docker-compose-common.yml > docker-compose-common.yml.tmp;
    mv docker-compose-common.yml.tmp docker-compose-common.yml)
  if [ "$tls_enabled" == "1" ]; then
    grep "\- ../letsencrypt-files/${generic_hostname}.ini:/etc/letsencrypt/cli.ini:ro$" docker-compose-common.yml &>/dev/null || (
      sed "s!#TLS_Certs_Here_Dont_Touch_This_Comment!#TLS_Certs_Here_Dont_Touch_This_Comment\n      - ../letsencrypt-files/${generic_hostname}.ini:/etc/letsencrypt/cli.ini:ro!g" <docker-compose-common.yml > docker-compose-common.yml.tmp;
      mv docker-compose-common.yml.tmp docker-compose-common.yml)
  fi
done
