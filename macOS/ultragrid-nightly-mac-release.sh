#!/bin/sh

exec > ~/ultragrid-build-release.log 2>&1 </dev/null

set -e
set -x

. $HOME/common.sh
. $HOME/paths.sh

BUILD_DIR=ultragrid-1.5
GITHUB_RELEASE_ID=13297067
OAUTH=$(cat $HOME/github-oauth-token)

cd /tmp

rm -rf $BUILD_DIR

git clone -b release/1.5 https://github.com/CESNET/UltraGrid.git $BUILD_DIR

cd $BUILD_DIR/

export PKG_CONFIG_PATH=/usr/local/share/ffmpeg/lib/pkgconfig-static:$PKG_CONFIG_PATH
./autogen.sh ${COMMON_FLAGS[@]}
make osx-gui-dmg

#scp -i /Users/toor/.ssh/id_rsa 'gui/UltraGrid GUI/UltraGrid.dmg' pulec,ultragrid@frs.sourceforge.net:/home/frs/project/ultragrid/UltraGrid-nightly-OSX.dmg
curl -H "Authorization: token $OAUTH" -X GET https://api.github.com/repos/CESNET/UltraGrid/releases/$GITHUB_RELEASE_ID/assets > assets.json
LEN=`jq "length" assets.json`
for n in `seq 0 $(($LEN-1))`; do
	NAME=`jq '.['$n'].name' assets.json`
	if [ $NAME = "\"UltraGrid-1.5.dmg\"" ]; then
		ID=`jq '.['$n'].id' assets.json`
	fi
done

if [ -n "$ID" ]; then
	curl -H "Authorization: token $OAUTH" -X DELETE 'https://api.github.com/repos/CESNET/UltraGrid/releases/assets/'$ID
fi

curl -H "Authorization: token $OAUTH" -H 'Content-Type: application/gzip' -X POST "https://uploads.github.com/repos/CESNET/UltraGrid/releases/$GITHUB_RELEASE_ID/assets?name=UltraGrid-1.5.dmg&label=macOS%20build" -T 'UltraGrid.dmg'


