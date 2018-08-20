#!/bin/sh
set -e
set -x

export CPATH=$CPATH:/opt/local/include:/usr/local/include:/usr/local/cuda/include
export LIBRARY_PATH=/opt/local/lib:/usr/local/cuda/lib
export DYLD_LIBRARY_PATH=/usr/local/cuda/lib
export PATH=/opt/local/bin:$PATH:/usr/local/bin:/usr/local/cuda/bin
export PKG_CONFIG_PATH=/usr/local/lib/pkgconfig
export PKG_CONFIG=/opt/local/bin/pkg-config
export BUILD_DIR=ultragrid-1.4
export PKG_CONFIG_PATH=`[ -n "$PKG_CONFIG_PATH" ] && echo "$PKG_CONFIG_PATH:" || true`/usr/local/lib/pkgconfig
export AJA_DIRECTORY=/Users/toor/ntv2sdkmac_13.0.0.79b79
export PKG_CONFIG_PATH=$PKG_CONFIG_PATH:/usr/local/share/ffmpeg/lib/pkgconfig-static/

cd /tmp
rm -rf $BUILD_DIR

git clone -b release/1.4 https://github.com/CESNET/UltraGrid.git $BUILD_DIR

cd $BUILD_DIR/

./autogen.sh --enable-gpl --enable-syphon --enable-rtsp-server --with-live555=/usr/local
( while :; do echo /usr/local/cuda/lib; done ) | make osx-gui-dmg

curl -H "Authorization: token 54a22bf35bc39262b60007e79101c978a3a2ff0c" -X GET https://api.github.com/repos/CESNET/UltraGrid/releases/5937352/assets > assets.json
LEN=`jq "length" assets.json`
for n in `seq 0 $(($LEN-1))`; do
        NAME=`jq '.['$n'].name' assets.json`
        if [ $NAME = "\"UltraGrid-1.4.dmg\"" ]; then
                ID=`jq '.['$n'].id' assets.json`
        fi
done

if [ -n "$ID" ]; then
        curl -H "Authorization: token 54a22bf35bc39262b60007e79101c978a3a2ff0c" -X DELETE 'https://api.github.com/repos/CESNET/UltraGrid/releases/assets/'$ID
fi

curl -H "Authorization: token 54a22bf35bc39262b60007e79101c978a3a2ff0c" -H 'Content-Type: application/gzip' -X POST 'https://uploads.github.com/repos/CESNET/UltraGrid/releases/5937352/assets?name=UltraGrid-1.4.dmg&label=macOS%20build' -T 'gui/UltraGrid GUI/UltraGrid.dmg'

