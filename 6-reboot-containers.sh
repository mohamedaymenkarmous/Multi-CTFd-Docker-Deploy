#!/bin/bash

cd CTFd
docker-compose -f dcf-ctf-securinets-quals-2020.yml -f dcf-docker-compose-common.yml down
docker-compose -f dcf-ctf-securinets-quals-2020.yml -f dcf-docker-compose-common.yml up -d
