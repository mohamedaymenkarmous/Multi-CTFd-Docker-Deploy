#!/bin/bash

#Source: https://raw.githubusercontent.com/wmnnd/nginx-certbot/master/init-letsencrypt.sh

if ! [ -x "$(command -v docker-compose)" ]; then
  echo 'Error: docker-compose is not installed.' >&2
  exit 1
fi

rsa_key_size=4096
config="../config.json"
templates="../templates"
data_path="../data/certbot"

if [ ! -e "$data_path/conf/options-ssl-nginx.conf" ] || [ ! -e "$data_path/conf/ssl-dhparams.pem" ]; then
  echo "### Downloading recommended TLS parameters ..."
  mkdir -p "$data_path/conf"
  curl -s https://raw.githubusercontent.com/certbot/certbot/master/certbot-nginx/certbot_nginx/_internal/tls_configs/options-ssl-nginx.conf > "$data_path/conf/options-ssl-nginx.conf"
  curl -s https://raw.githubusercontent.com/certbot/certbot/master/certbot/certbot/ssl-dhparams.pem > "$data_path/conf/ssl-dhparams.pem"
  echo
fi

sum=""
for x in $(ls -1 dcf-*.yml);do
  sum="${sum} -f ${x}"
done

docker-compose ${sum} config > /dev/null || (echo "There is a problem while checking the config of docker-compose for these files: ${sum}";exit)

n=$(cat ${config} |python3 -c "import json,sys;print(len(json.load(sys.stdin)['tls']))")

if [ "$n" == "0" ]; then
  echo "Skipped"
fi
# All letsencrypt configuration files should be generated before any containers starts
for i in $(seq 1 $n);do
  hostnames=$(cat ${config} |python3 -c "import json,sys;print(json.load(sys.stdin)['tls'][${i}-1]['hostnames'])")
  setup=$(cat ${config} |python3 -c "import json,sys;print(json.load(sys.stdin)['tls'][${i}-1]['setup'])")
  email=$(cat ${config} |python3 -c "import json,sys;print(json.load(sys.stdin)['tls'][${i}-1]['email'])")
  if [ "$setup" == "1" ]; then

    hostname=$(echo $hostnames | cut -d" " -f1)

    echo "### Backuping the old certificate ..."
    bn=$(date +%s)
    cp -R $data_path/conf/live/${hostname} $data_path/conf/live/${hostname}.bak.$bn
    echo "Backup folder: $data_path/conf/live/$hostname.bak.$bn"

    mkdir -p "$data_path/conf/live/$hostname"

    echo "### Generating letsencrypt configuration files"
    hostnames_formatted=$(echo $hostnames| tr ' ' ', ')
    sed "s/REPLACED_HOSTNAMES/${hostnames_formatted}/g" <${templates}/letsencrypt-template.ini > ${data_path}/conf/${hostname}.ini
    sed "s/REPLACED_EMAIL/${email}/g" <${data_path}/conf/${hostname}.ini > ${data_path}/conf/${hostname}.ini.bak
    mv ${data_path}/conf/${hostname}.ini.bak ${data_path}/conf/${hostname}.ini

    echo "### Creating dummy certificate for $hostname ..."
    path="/etc/letsencrypt/live/$hostname"
    docker-compose ${sum} run --rm --entrypoint "sh -c \"mkdir -p $path && \
      openssl req -x509 -nodes -newkey rsa:1024 -days 1\
        -keyout '$path/privkey.pem' \
        -out '$path/fullchain.pem' \
        -subj '/CN=localhost'\"" certbot

    echo "### Starting nginx ..."
    docker-compose ${sum} up --force-recreate -d proxy

    bad_response="0"
    for h in $hostnames; do
      http_response=$(curl --write-out '%{http_code}' --silent --output /dev/null http://$h/)
      echo "http://$h/ -> Response: $http_response"
      if [ "$http_response" = "000" ]; then
        bad_response="1"
      fi
    done
    if [ "$bad_response" = "1" ]; then
      echo "Please make sure that all the web services are running and then execute 5-renew-certs.sh"
    else
      echo "### Deleting dummy certificate for $hostnames ..."
      docker-compose ${sum} run --rm --entrypoint "sh -c \"\
        rm -Rf /etc/letsencrypt/live/$hostname && \
        rm -Rf /etc/letsencrypt/archive/$hostname && \
        rm -Rf /etc/letsencrypt/renewal/$hostname.conf\"" certbot

      echo "### Requesting Let's Encrypt certificate for $hostnames ..."
      #Join $hostnames to -d args
      #domain_args=""
      #for domain in "${hostnames[@]}"; do
      #  domain_args="$domain_args -d $hostname"
      #done

      docker-compose ${sum} run --rm --entrypoint "sh -c \"\
        certbot register --agree-tos --email $email\"" certbot
      echo "### Email registration done"

      docker-compose ${sum} run --rm --entrypoint "\
        certbot certonly --config /etc/letsencrypt/${hostname}.ini --expand" certbot | tee -a $data_path/log/${hostname}.log
        #certbot certonly --config /etc/letsencrypt/cli.ini --test-cert --expand" certbot
      new_file=$(cat $data_path/log/$hostname.log | grep -A1 Congratulations | grep -Po '/live/\K[^\/]*')
      if [ "$new_file" = "$hostname" ]; then
        echo "Certificate created in /etc/letsencrypt/live/$hostname"
      else
        echo "Certificate created in /etc/letsencrypt/live/$new_file"
        mv $data_path/conf/live/$new_file $data_path/conf/live/$hostname
        echo "Then moved to /etc/letsencrypt/live/$hostname"
      fi
      echo "### Reloading nginx ..."
      docker-compose ${sum} exec proxy nginx -s reload
    fi

  else
    echo "### Reloading nginx ..."
    docker-compose ${sum} exec proxy nginx -s reload
  fi
done
