#!/bin/bash
DIR_NAME=$(dirname "$0")
cd ${DIR_NAME}
if test -f ".setup_done"; then
  ./1-setup-docker.sh
  echo "1"> .setup_done
fi

ls CTFd &>/dev/null || git clone https://github.com/CTFd/CTFd.git CTFd/
cd CTFd/
git fetch
git checkout tags/2.1.5
sudo pip3 install ruamel.yaml &>/dev/null || (sudo apt-get -y install python3-pip;sudo pip3 install ruamel.yaml)
cd ..
mkdir -p data/templates
./bin/merge-yaml.py docker-compose-base.yml CTFd/docker-compose.yml data/templates/docker-compose-merged.yml
diff data/templates/docker-compose-merged.yml docker-compose-merged-reference.yml || (
  echo "The CTFd/docker-compose.yml was chaanged. Please update the docker-compose-merged-reference.yml file to refresh the new docker-compose-files/ files";exit)
ln -sf ${PWD}/docker-compose-common.yml ${PWD}/CTFd/dcf-docker-compose-common.yml
echo "### Creating docker-compose files"
./2-create-new-projects-docker.sh
cd CTFd/
echo "### Generating TLS certificates"
../3-init-letsencrypt.sh
cd ..
echo "### Creating new projects"
./4-create-new-projects-nginx.sh
cd CTFd
echo "### Checking for the github.com/noraj/ctfd-theme-sigsegv2 plugin"
(ls CTFd/themes/sigsegv2 &>/dev/null && cd CTFd/themes/sigsegv2 && git pull && cd ../../..) || git clone https://github.com/noraj/ctfd-theme-sigsegv2.git CTFd/themes/sigsegv2
echo "### Adding logo and favicon files"
ls ${PWD}/CTFd/themes/core/static/img/logo.png.bak &>/dev/null || mv ${PWD}/CTFd/themes/core/static/img/logo.png ${PWD}/CTFd/themes/core/static/img/logo.png.bak
ls ${PWD}/CTFd/themes/core/static/img/favicon.ico.bak &>/dev/null || mv ${PWD}/CTFd/themes/core/static/img/favicon.ico ${PWD}/CTFd/themes/core/static/img/favicon.ico.bak
ln -sf ${PWD}/../logo.png ${PWD}/CTFd/themes/core/static/img/logo.png
ln -sf ${PWD}/../favicon.ico ${PWD}/CTFd/themes/core/static/img/favicon.ico

sum=""
for x in $(ls dcf-*.yml);do
  sum="${sum} -f ${x}"
done

echo "### Building the containers"
sudo docker-compose ${sum} --compatibility up -d --force-recreate #--build
