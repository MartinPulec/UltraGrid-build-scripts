#!/bin/sh
set -e
set -x

exec > ~/ultragrid-build.log 2>&1

export CPATH=$CPATH:/opt/local/include:/usr/local/include:/usr/local/cuda/include
export LIBRARY_PATH=/opt/local/lib:/usr/local/cuda/lib
export DYLD_LIBRARY_PATH=/usr/local/cuda/lib
export PATH=/opt/local/bin:$PATH:/usr/local/bin:/usr/local/cuda/bin
export PKG_CONFIG_PATH=/usr/local/lib/pkgconfig
export PKG_CONFIG=/opt/local/bin/pkg-config
export BUILD_DIR=ultragrid-nightly
export BUILD_DIR_ALT=ultragrid-nightly-alternative
export PKG_CONFIG_PATH=`[ -n "$PKG_CONFIG_PATH" ] && echo "$PKG_CONFIG_PATH:" || true`/usr/local/lib/pkgconfig
export AJA_DIRECTORY=/Users/toor/ntv2sdkmac_13.0.0.79b79

cd /tmp

# checkout current build script
atexit() {
        git clone root@w54-136.fi.muni.cz:ultragrid-build ultragrid-build-tmp
        cp -r ultragrid-build-tmp/macOS/*sh ~/
        crontab ultragrid-build-tmp/macOS/crontab
        rm -r ultragrid-build-tmp
}
trap atexit EXIT

rm -rf $BUILD_DIR

git clone -b master https://github.com/CESNET/UltraGrid.git $BUILD_DIR

cd $BUILD_DIR/

export PKG_CONFIG_PATH=/usr/local/share/ffmpeg/lib/pkgconfig-static:$PKG_CONFIG_PATH

./autogen.sh --enable-syphon --enable-rtsp-server --with-live555=/usr/local --enable-qt
( while :; do echo /usr/local/cuda/lib; done ) | make osx-gui-dmg

#scp -i /Users/toor/.ssh/id_rsa 'gui/UltraGrid GUI/UltraGrid.dmg' pulec,ultragrid@frs.sourceforge.net:/home/frs/project/ultragrid/UltraGrid-nightly-OSX.dmg
curl -H "Authorization: token 54a22bf35bc39262b60007e79101c978a3a2ff0c" -X GET https://api.github.com/repos/CESNET/UltraGrid/releases/4347706/assets > assets.json
LEN=`jq "length" assets.json`
for n in `seq 0 $(($LEN-1))`; do
	NAME=`jq '.['$n'].name' assets.json`
	if [ $NAME = "\"UltraGrid-nightly-macos.dmg\"" ]; then
		ID=`jq '.['$n'].id' assets.json`
	fi
done

if [ -n "$ID" ]; then
	curl -H "Authorization: token 54a22bf35bc39262b60007e79101c978a3a2ff0c" -X DELETE 'https://api.github.com/repos/CESNET/UltraGrid/releases/assets/'$ID
fi

curl -H "Authorization: token 54a22bf35bc39262b60007e79101c978a3a2ff0c" -H 'Content-Type: application/gzip' -X POST 'https://uploads.github.com/repos/CESNET/UltraGrid/releases/4347706/assets?name=UltraGrid-nightly-macos.dmg&label=macOS%20build' -T 'Ultragrid.dmg'


cd ..

rm -rf $BUILD_DIR_ALT

# alternative

git clone -b master https://github.com/CESNET/UltraGrid.git $BUILD_DIR_ALT

cd $BUILD_DIR_ALT/

#export CFLAGS='-m32'
#export CXXFLAGS='-m32'
#export NVCCFLAGS='-m32'
#export LDFLAGS='-m32'
export ARCH='-msse2'
export PKG_CONFIG_PATH=/usr/local/share/ffmpeg-notoolbox/lib/pkgconfig-static:$PKG_CONFIG_PATH

#./autogen.sh --enable-quicktime --disable-jpeg --disable-deltacast --disable-rtsp  --disable-cuda --enable-syphon --disable-aja
./autogen.sh --enable-gpl --enable-syphon --enable-rtsp-server --with-live555=/usr/local --enable-qt
( while :; do echo /usr/local/cuda/lib; done ) | make osx-gui-dmg

#scp -i /Users/toor/.ssh/id_rsa 'gui/UltraGrid GUI/UltraGrid.dmg' pulec,ultragrid@frs.sourceforge.net:/home/frs/project/ultragrid/UltraGrid-nightly-OSX-32bit-w-QuickTime.dmg

curl -H "Authorization: token 54a22bf35bc39262b60007e79101c978a3a2ff0c" -X GET https://api.github.com/repos/CESNET/UltraGrid/releases/4347706/assets > assets.json
LEN=`jq "length" assets.json`
for n in `seq 0 $(($LEN-1))`; do
	NAME=`jq '.['$n'].name' assets.json`
	if [ $NAME = "\"UltraGrid-nightly-macos-alt.dmg\"" ]; then
		ID=`jq '.['$n'].id' assets.json`
	fi
done

if [ -n "$ID" ]; then
	curl -H "Authorization: token 54a22bf35bc39262b60007e79101c978a3a2ff0c" -X DELETE 'https://api.github.com/repos/CESNET/UltraGrid/releases/assets/'$ID
fi

curl -H "Authorization: token 54a22bf35bc39262b60007e79101c978a3a2ff0c" -H 'Content-Type: application/gzip' -X POST 'https://uploads.github.com/repos/CESNET/UltraGrid/releases/4347706/assets?name=UltraGrid-nightly-macos-alt.dmg&label=alternative%20macOS%20build%20%28wo%20SSE4%20and%20videotoolbox%29' -T 'UltraGrid.dmg'

cd ..

#rm -rf $BUILD_DIR_ALT
