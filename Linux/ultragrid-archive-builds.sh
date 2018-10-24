#!/bin/sh

exec >~/ultragrid-archive.log 2>&1 </dev/null
set -exu

DIR=/var/www/html/ug-nightly-archive/$(date +%Y%m%d)
TMPDIR=$(mktemp -d)
sudo mkdir $DIR
cd $TMPDIR
for n in `curl -X GET https://api.github.com/repos/CESNET/UltraGrid/releases/4347706/assets | grep browser_download_url | awk '{print $2}' | tr -d \"`; do
	wget $n
	sudo mv $(basename $n) $DIR
done

rm -rf $TMPDIR

