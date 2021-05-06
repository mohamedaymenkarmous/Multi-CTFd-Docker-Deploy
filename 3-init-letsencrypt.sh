#!/bin/bash

# Source: http://stackoverflow.com/a/246128
# This was accurate more than DIR_NAME=$(dirname $(readlink -f "$0"))
DIR_NAME="$( cd -P "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
cd ${DIR_NAME}

# Load the configuration
. load-config.sh || exit 1
exit_on_missing_config

# The script needs to run from the location where the Dockerfile is located
cd CTFd

#Source: https://raw.githubusercontent.com/wmnnd/nginx-certbot/master/init-letsencrypt.sh

rsa_key_size=4096
templates="../templates"
data_path="../data/certbot"

if ! [ -x "$(command -v docker-compose)" ]; then
  echo -e "${PREFIX_COLOR_ERROR}docker-compose is not installed. You need to run the scripts from the beginning${SUFFIX_COLOR_DEFAULT}" >&2
  exit 1
fi

if [ ! -z "${COMMON_PROXY_CONF_PATH}" ]; then
  cd ../
  if [ -d "${COMMON_PROXY_CONF_PATH}" ]; then
    real_path=$(readlink -f ${COMMON_PROXY_CONF_PATH})
    data_path=$real_path/data/certbot
  else
    echo "Error: File path specific in config.json:common.proxy_conf_path is not a directory";exit
  fi
  cd - > /dev/null
fi

if [ ! -e "${data_path}/conf/options-ssl-nginx.conf" ] || [ ! -e "${data_path}/conf/ssl-dhparams.pem" ]; then
  echo -e "${PREFIX_COLOR_SUCCESS}Downloading recommended TLS parameters...${SUFFIX_COLOR_DEFAULT}"
  mkdir -p "${data_path}/conf"
  curl -s https://raw.githubusercontent.com/certbot/certbot/master/certbot-nginx/certbot_nginx/_internal/tls_configs/options-ssl-nginx.conf > "${data_path}/conf/options-ssl-nginx.conf"
  curl -s https://raw.githubusercontent.com/certbot/certbot/master/certbot/certbot/ssl-dhparams.pem > "${data_path}/conf/ssl-dhparams.pem"
  echo
fi

sum=""
for x in $(ls -1 dcf-*.yml);do
  sum="${sum} -f ${x}"
done
if [ ! -z "$real_path" ]; then
  sum="${sum} -f $real_path/docker-compose-files/dcf-docker-compose-common.yml"
  if [ ! -f "$real_path/docker-compose-files/dcf-docker-compose-common.yml" ]; then
    $real_path/2-create-new-projects-docker.sh
  fi
fi

echo -e "${PREFIX_COLOR_SUCCESS}Cheching docker-compose config with the following files... ${sum}${SUFFIX_COLOR_DEFAULT}"
docker-compose ${sum} config > /dev/null || (echo -e "${PREFIX_COLOR_ERROR}There is a problem while checking the config of docker-compose for these files: ${sum}${SUFFIX_COLOR_DEFAULT}";exit 1)

if [ "$N_TLS" == "0" ]; then
  echo -e "${PREFIX_COLOR_WARNING}Skipped because there was no defined project in config.json file${SUFFIX_COLOR_DEFAULT}"
  exit 0
fi
# All letsencrypt configuration files should be generated before any containers starts
for i in $(seq 1 $N_PROJECTS);do
  hostnames=$(parse_config '' "'tls'" "${i}-1" "'hostnames'")
  setup=$(parse_config '0' "'tls'" "${i}-1" "'setup'")
  email=$(parse_config '' "'tls'" "${i}-1" "'email'")
  if [ "$setup" == "1" ]; then
    hostname=$(echo ${hostnames} | cut -d" " -f1)

    echo -e "${PREFIX_COLOR_SUCCESS}Backuping the old certificate...${SUFFIX_COLOR_DEFAULT}"
    bn=$(date +%s)
    cp -R $data_path/conf/live/${hostname} $data_path/conf/live/${hostname}.bak.$bn
    echo -e "${PREFIX_COLOR_SUCCESS}  Backup folder: $data_path/conf/live/${hostname}.bak.${bn}${SUFFIX_COLOR_DEFAULT}"

    mkdir -p "$data_path/conf/live/$hostname"

    echo -e "${PREFIX_COLOR_SUCCESS}Generating letsencrypt configuration files...${SUFFIX_COLOR_DEFAULT}"
    hostnames_formatted=$(echo $hostnames| tr ' ' ', ')
    sed "s/REPLACED_HOSTNAMES/${hostnames_formatted}/g" <${templates}/letsencrypt-template.ini > ${data_path}/conf/${hostname}.ini
    sed "s/REPLACED_EMAIL/${email}/g" <${data_path}/conf/${hostname}.ini > ${data_path}/conf/${hostname}.ini.bak
    mv ${data_path}/conf/${hostname}.ini.bak ${data_path}/conf/${hostname}.ini

    echo -e "${PREFIX_COLOR_SUCCESS}Creating dummy certificate for $hostname...${SUFFIX_COLOR_DEFAULT}"
    path="/etc/letsencrypt/live/${hostname}"
    docker-compose ${sum} run --rm --entrypoint "sh -c \"mkdir -p ${path} && \
      openssl req -x509 -nodes -newkey rsa:1024 -days 1\
        -keyout '$path/privkey.pem' \
        -out '$path/fullchain.pem' \
        -subj '/CN=localhost'\"" certbot

    echo -e "${PREFIX_COLOR_SUCCESS}Starting nginx...${SUFFIX_COLOR_DEFAULT}"
    docker-compose ${sum} up --force-recreate -d proxy

    # Waiting few seconds until the service is available
    sleep 2

    bad_response="0"
    for h in $hostnames; do
      http_response=$(curl --write-out '%{http_code}' --silent --output /dev/null http://$h/)
      echo -e "${PREFIX_COLOR_SUCCESS}  http://$h/ -> Response: $http_response${SUFFIX_COLOR_DEFAULT}"
      if [ "$http_response" = "000" ]; then
        bad_response="1"
      fi
    done
    if [ "$bad_response" = "1" ]; then
      echo -e "${PREFIX_COLOR_ERROR}Please make sure that all the web services are running and then execute 4-renew-certificates.sh${SUFFIX_COLOR_DEFAULT}"
    else
      echo -e "${PREFIX_COLOR_SUCCESS}Deleting dummy certificate for ${hostnames}...${SUFFIX_COLOR_DEFAULT}"
      docker-compose ${sum} run --rm --entrypoint "sh -c \"\
        rm -Rf /etc/letsencrypt/live/${hostname} && \
        rm -Rf /etc/letsencrypt/archive/${hostname} && \
        rm -Rf /etc/letsencrypt/renewal/${hostname}.conf\"" certbot

      echo -e "${PREFIX_COLOR_SUCCESS}Requesting Let's Encrypt certificate for ${hostnames}...${SUFFIX_COLOR_DEFAULT}"
      #Join $hostnames to -d args
      #domain_args=""
      #for domain in "${hostnames[@]}"; do
      #  domain_args="$domain_args -d $hostname"
      #done

      echo -e "${PREFIX_COLOR_SUCCESS}Certbot email registration...${SUFFIX_COLOR_DEFAULT}"
      docker-compose ${sum} run --rm --entrypoint "sh -c \"\
        certbot register --agree-tos --email ${email}\"" certbot

      echo -e "${PREFIX_COLOR_SUCCESS}Certbot TLS certificate regeneration...${SUFFIX_COLOR_DEFAULT}"
      docker-compose ${sum} run --rm --entrypoint "\
        certbot certonly --config /etc/letsencrypt/${hostname}.ini --expand" certbot | tee -a ${data_path}/log/${hostname}.log
        #certbot certonly --config /etc/letsencrypt/cli.ini --test-cert --expand" certbot
      new_file=$(cat ${data_path}/log/${hostname}.log | grep -A1 Congratulations | grep -Po '/live/\K[^\/]*' | tail -n1)
      if [ "${new_file}" = "${hostname}" ]; then
        echo -e "${PREFIX_COLOR_SUCCESS}Certificate created in /etc/letsencrypt/live/${hostname}${SUFFIX_COLOR_DEFAULT}"
      else
        echo -e "${PREFIX_COLOR_SUCCESS}Certificate created in /etc/letsencrypt/live/${new_file}${SUFFIX_COLOR_DEFAULT}"
        mv ${data_path}/conf/live/${new_file} ${data_path}/conf/live/${hostname}
        echo -e "${PREFIX_COLOR_SUCCESS}  Then moved to /etc/letsencrypt/live/${hostname}${SUFFIX_COLOR_DEFAULT}"
      fi
      echo -e "${PREFIX_COLOR_SUCCESS}Reloading nginx${SUFFIX_COLOR_DEFAULT}"
      docker-compose ${sum} exec proxy nginx -s reload
    fi
  else
    echo -e "${PREFIX_COLOR_SUCCESS}Reloading nginx...${SUFFIX_COLOR_DEFAULT}"
    docker-compose ${sum} exec proxy nginx -s reload
  fi
done
