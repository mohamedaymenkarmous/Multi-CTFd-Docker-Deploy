#!/bin/bash

cd CTFd
sum=""
for x in $(ls -1 dcf-*.yml);do
  sum="${sum} -f ${x}"
done
sudo docker-compose ${sum} down
sudo docker-compose ${sum} --compatibility up -d
