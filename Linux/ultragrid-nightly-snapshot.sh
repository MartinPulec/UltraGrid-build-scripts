#!/bin/sh

cd ~/ultragrid
git fetch github devel
git tag snapshot-devel-`date -I` FETCH_HEAD

