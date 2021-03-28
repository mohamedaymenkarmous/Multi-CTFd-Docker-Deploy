#!/bin/bash

n=$(cat config.json |python3 -c "import json,sys;print(len(json.load(sys.stdin)['projects']))")

if [ "$n" == "0" ]; then
  echo "Skipped"
fi

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
        sed "s/DEFAULT_SERVER/default/g" <nginx/sites-enabled/${name}.conf > nginx/sites-enabled/${name}.conf.tmp;
      else
        sed "s/DEFAULT_SERVER//g" <nginx/sites-enabled/${name}.conf > nginx/sites-enabled/${name}.conf.tmp;
      fi
      if [ "$deferred_server" == "1" ]; then
        sed "s/DEFERRED_SERVER/deferred/g" <nginx/sites-enabled/${name}.conf.tmp > nginx/sites-enabled/${name}.conf;
      else
        sed "s/DEFERRED_SERVER//g" <nginx/sites-enabled/${name}.conf.tmp > nginx/sites-enabled/${name}.conf;
      fi
      rm nginx/sites-enabled/${name}.conf.tmp;
    #)
  else
    #ls nginx/sites-enabled/$name.conf &>/dev/null || (
      sed "s/REPLACED_NAME/${name}/g" <templates/nginx-vhost-template-http.conf > nginx/sites-enabled/${name}.conf.tmp;
      sed "s/REPLACED_HOSTNAME/${hostname}/g" <nginx/sites-enabled/${name}.conf.tmp > nginx/sites-enabled/${name}.conf;
      if [ "$default_server" == "1" ]; then
        sed "s/DEFAULT_SERVER/default/g" <nginx/sites-enabled/${name}.conf > nginx/sites-enabled/${name}.conf.tmp;
      else
        sed "s/DEFAULT_SERVER//g" <nginx/sites-enabled/${name}.conf > nginx/sites-enabled/${name}.conf.tmp;
      fi
      if [ "$deferred_server" == "1" ]; then
        sed "s/DEFERRED_SERVER/deferred/g" <nginx/sites-enabled/${name}.conf.tmp > nginx/sites-enabled/${name}.conf;
      else
        sed "s/DEFERRED_SERVER//g" <nginx/sites-enabled/${name}.conf.tmp > nginx/sites-enabled/${name}.conf;
      fi
      rm nginx/sites-enabled/${name}.conf.tmp;
    #)
  fi
done

