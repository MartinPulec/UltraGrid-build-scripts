#!/bin/sh

exec > ~/ultragrid-nightly-snapshot.log 2>&1 </dev/null

cd ~/ultragrid
git fetch github devel
git tag snapshot-devel-`date -I` FETCH_HEAD

