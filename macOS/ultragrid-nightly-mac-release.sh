#!/bin/sh

exec > ~/ultragrid-build-release.log 2>&1

set -e
set -x

QT=/usr/local/Qt-5.10.1

export CPATH=$CPATH${CPATH:+:}/opt/local/include:/usr/local/include:/usr/local/cuda/include:$QT/include
export LIBRARY_PATH=/opt/local/lib:/usr/local/cuda/lib:$QT/lib
export DYLD_LIBRARY_PATH=/usr/local/cuda/lib
export PATH=/opt/local/bin:$PATH:/usr/local/bin:/usr/local/cuda/bin:$QT/bin
export PKG_CONFIG_PATH=$PKG_CONFIG_PATH${PKG_CONFIG_PATH:+:}/usr/local/lib/pkgconfig:$QT/lib/pkgconfig
export PKG_CONFIG=/opt/local/bin/pkg-config
export AJA_DIRECTORY=/Users/toor/ntv2sdkmac_13.0.0.79b79
export EXTRA_LIB_PATH=$DYLD_LIBRARY_PATH # needed for make, see Makefile.in

BUILD_DIR=ultragrid-1.5
GITHUB_RELEASE_ID=13297067
OAUTH=$(cat $HOME/github-oauth-token)

cd /tmp

rm -rf $BUILD_DIR

git clone -b release/1.5 https://github.com/CESNET/UltraGrid.git $BUILD_DIR

cd $BUILD_DIR/

export PKG_CONFIG_PATH=/usr/local/share/ffmpeg/lib/pkgconfig-static:$PKG_CONFIG_PATH

./autogen.sh --enable-syphon --enable-rtsp-server --with-live555=/usr/local --enable-qt --enable-static-qt
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


