#!/bin/bash

./3-create-new-projects-nginx.sh
cd CTFd/
echo "### Generating TLS certificates"
../4-init-letsencrypt.sh
