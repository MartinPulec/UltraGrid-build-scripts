#!/bin/sh

exec >~/ultragrid-archive.log 2>&1 </dev/null
set -exu

REMOTE=xpulec@frakira
RDIR='$HOME/public_html/ug-nightly-archive/'$(date +%Y%m%d)
TMPDIR=$(mktemp -d)

. ~/ultragrid_nightly_common.sh

ssh $REMOTE mkdir $RDIR
cd $TMPDIR
for n in `curl -X GET https://api.github.com/repos/CESNET/UltraGrid/releases/4347706/assets | grep browser_download_url | awk '{print $2}' | tr -d \"`; do
	wget $n
        scp $(basename $n) $REMOTE:$RDIR
done

rm -rf $TMPDIR

