#!/bin/sh

exec > ~/ultragrid-build.log 2>&1 </dev/null

set -e
set -x

BUILD_DIR=ultragrid-nightly
OAUTH=$(cat $HOME/github-oauth-token)

. $HOME/common.sh
. $HOME/paths.sh

cd /tmp

# checkout current build script
atexit() {
        TMPDIR=$(mktemp -d)
        git clone https://github.com/MartinPulec/UltraGrid-build-scripts.git $TMPDIR
        cp -r $TMPDIR/macOS/*sh ~/
        crontab $TMPDIR/macOS/crontab
        rm -rf $TMPDIR
}
trap atexit EXIT

rm -rf $BUILD_DIR

git clone -b master https://github.com/CESNET/UltraGrid.git $BUILD_DIR

cd $BUILD_DIR/

git submodule init && git submodule update
( cd cineform-sdk/ && cmake . && make CFHDCodecStatic )

#export PKG_CONFIG_PATH=/usr/local/share/ffmpeg/lib/pkgconfig-static:$PKG_CONFIG_PATH

./autogen.sh ${COMMON_FLAGS[@]} --enable-cineform
make osx-gui-dmg

#scp -i /Users/toor/.ssh/id_rsa 'gui/UltraGrid GUI/UltraGrid.dmg' pulec,ultragrid@frs.sourceforge.net:/home/frs/project/ultragrid/UltraGrid-nightly-OSX.dmg
curl -H "Authorization: token $OAUTH" -X GET https://api.github.com/repos/CESNET/UltraGrid/releases/4347706/assets > assets.json
LEN=`jq "length" assets.json`
for n in `seq 0 $(($LEN-1))`; do
	NAME=`jq '.['$n'].name' assets.json`
	if [ $NAME = "\"UltraGrid-nightly-macos.dmg\"" ]; then
		ID=`jq '.['$n'].id' assets.json`
	fi
done

if [ -n "$ID" ]; then
	curl -H "Authorization: token $OAUTH" -X DELETE 'https://api.github.com/repos/CESNET/UltraGrid/releases/assets/'$ID
fi

curl -H "Authorization: token $OAUTH" -H 'Content-Type: application/gzip' -X POST 'https://uploads.github.com/repos/CESNET/UltraGrid/releases/4347706/assets?name=UltraGrid-nightly-macos.dmg&label=macOS%20build' -T 'Ultragrid.dmg'


cd ..

