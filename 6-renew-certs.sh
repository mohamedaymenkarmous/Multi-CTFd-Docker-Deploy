#!/bin/bash

echo "### Creating docker-compose files"
./2-create-new-projects-docker.sh
echo "### Creating new projects"
./3-create-new-projects-nginx.sh
cd CTFd/
echo "### Generating TLS certificates"
../4-init-letsencrypt.sh
