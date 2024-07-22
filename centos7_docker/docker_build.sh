#!/bin/sh
sudo docker run -ti --rm -v $PWD:/root/mnt ultragrid-centos7 /root/mnt/build.sh
