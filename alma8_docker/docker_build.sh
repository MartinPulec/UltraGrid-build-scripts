#!/bin/sh
docker run -ti --rm -v $PWD:/root/mnt ultragrid-alma8 /root/mnt/build.sh
