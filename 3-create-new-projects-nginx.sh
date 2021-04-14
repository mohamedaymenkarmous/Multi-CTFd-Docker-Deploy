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
common_proxy_conf_path=$(cat config.json |python3 -c "import json,sys;print(json.load(sys.stdin)['common']['proxy_conf_path'])" 2>/dev/null)

for i in $(seq 1 $n);do
  name=$(cat config.json |python3 -c "import json,sys;print(json.load(sys.stdin)['projects'][${i}-1]['name'])")
  hostname=$(cat config.json |python3 -c "import json,sys;print(json.load(sys.stdin)['projects'][${i}-1]['hostname'])")
  generic_hostname=$(cat config.json |python3 -c "import json,sys;print(json.load(sys.stdin)['projects'][${i}-1]['generic-hostname'])")
  default_server=$(cat config.json |python3 -c "import json,sys;print(json.load(sys.stdin)['projects'][${i}-1]['default-server'])")
  deferred_server=$(cat config.json |python3 -c "import json,sys;print(json.load(sys.stdin)['projects'][${i}-1]['deferred-server'])")
  tls_enabled=$(cat config.json |python3 -c "import json,sys;print(json.load(sys.stdin)['projects'][${i}-1]['tls-enabled'])")
  if [ "$tls_enabled" == "1" ]; then
    #ls nginx/sites-enabled/$name.conf &>/dev/null || (
      sed "s/REPLACED_NAME/${name}/g" <templates/nginx-vhost-template-https.conf > nginx/sites-enabled/${name}.conf.tmp;
      sed "s/REPLACED_HOSTNAME/${hostname}/g" <nginx/sites-enabled/${name}.conf.tmp > nginx/sites-enabled/${name}.conf;
      sed "s/REPLACED_HOSTNAME/${generic_hostname}/g" <templates/nginx-snakeoil-template.conf > nginx/snippets/snakeoil-${name}.conf
      if [ "$default_server" == "1" ]; then
        sed "s/REPLACED_DEFAULT_SERVER/default/g" <nginx/sites-enabled/${name}.conf > nginx/sites-enabled/${name}.conf.tmp;
      else
        sed "s/REPLACED_DEFAULT_SERVER//g" <nginx/sites-enabled/${name}.conf > nginx/sites-enabled/${name}.conf.tmp;
      fi
      if [ "$deferred_server" == "1" ]; then
        sed "s/REPLACED_DEFERRED_SERVER/deferred/g" <nginx/sites-enabled/${name}.conf.tmp > nginx/sites-enabled/${name}.conf;
      else
        sed "s/REPLACED_DEFERRED_SERVER//g" <nginx/sites-enabled/${name}.conf.tmp > nginx/sites-enabled/${name}.conf;
      fi
      rm nginx/sites-enabled/${name}.conf.tmp;

      if [ ! -z "$common_proxy_conf_path" ]; then
        if [ -d "$common_proxy_conf_path" ]; then
          real_path=$(readlink -f $common_proxy_conf_path)
          # I tried to use symbolic link but it can't be resolved inside the container
          # Example of isues: https://stackoverflow.com/questions/38485607/mount-host-directory-with-a-symbolic-link-inside-in-docker-container
          cp ${PWD}/nginx/snippets/snakeoil-${name}.conf $real_path/nginx/snippets/snakeoil-${name}.conf
          cp ${PWD}/nginx/sites-enabled/${name}.conf $real_path/nginx/sites-enabled/${name}.conf
        else
          echo "Error: File path specific in config.json:common.proxy_conf_path is not a directory";exit
        fi
      fi

    #)
  else
    #ls nginx/sites-enabled/$name.conf &>/dev/null || (
      sed "s/REPLACED_NAME/${name}/g" <templates/nginx-vhost-template-http.conf > nginx/sites-enabled/${name}.conf.tmp;
      sed "s/REPLACED_HOSTNAME/${hostname}/g" <nginx/sites-enabled/${name}.conf.tmp > nginx/sites-enabled/${name}.conf;
      if [ "$default_server" == "1" ]; then
        sed "s/REPLACED_DEFAULT_SERVER/default/g" <nginx/sites-enabled/${name}.conf > nginx/sites-enabled/${name}.conf.tmp;
      else
        sed "s/REPLACED_DEFAULT_SERVER//g" <nginx/sites-enabled/${name}.conf > nginx/sites-enabled/${name}.conf.tmp;
      fi
      if [ "$deferred_server" == "1" ]; then
        sed "s/REPLACED_DEFERRED_SERVER/deferred/g" <nginx/sites-enabled/${name}.conf.tmp > nginx/sites-enabled/${name}.conf;
      else
        sed "s/REPLACED_DEFERRED_SERVER//g" <nginx/sites-enabled/${name}.conf.tmp > nginx/sites-enabled/${name}.conf;
      fi
      rm nginx/sites-enabled/${name}.conf.tmp;

      if [ ! -z "$common_proxy_conf_path" ]; then
        if [ -d "$common_proxy_conf_path" ]; then
          real_path=$(readlink -f $common_proxy_conf_path)
          # I tried to use symbolic link but it can't be resolved inside the container
          # Example of isues: https://stackoverflow.com/questions/38485607/mount-host-directory-with-a-symbolic-link-inside-in-docker-container
          cp ${PWD}/nginx/sites-enabled/${name}.conf $real_path/nginx/sites-enabled/${name}.conf
        else
          echo "Error: File path specific in config.json:common.proxy_conf_path is not a directory";exit
        fi
      fi

    #)
  fi
done
