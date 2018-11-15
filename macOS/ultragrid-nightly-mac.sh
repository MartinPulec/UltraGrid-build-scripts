#!/bin/sh

exec > ~/ultragrid-build.log 2>&1 </dev/null

set -e
set -x

OAUTH=$(cat $HOME/github-oauth-token)
QT=/usr/local/Qt-5.10.1

export CPATH=$CPATH${CPATH:+:}/opt/local/include:/usr/local/include:/usr/local/cuda/include:$QT/include
export LIBRARY_PATH=/opt/local/lib:/usr/local/cuda/lib:$QT/lib
export DYLD_LIBRARY_PATH=/usr/local/cuda/lib
export PATH=/opt/local/bin:$PATH:/usr/local/bin:/usr/local/cuda/bin:$QT/bin
export PKG_CONFIG_PATH=$PKG_CONFIG_PATH${PKG_CONFIG_PATH:+:}/usr/local/lib/pkgconfig:$QT/lib/pkgconfig
export PKG_CONFIG=/opt/local/bin/pkg-config
export BUILD_DIR=ultragrid-nightly
export BUILD_DIR_ALT=ultragrid-nightly-alternative
export AJA_DIRECTORY=/Users/toor/ntv2sdkmac
export EXTRA_LIB_PATH=$DYLD_LIBRARY_PATH # needed for make, see Makefile.in

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

export PKG_CONFIG_PATH=/usr/local/share/ffmpeg/lib/pkgconfig-static:$PKG_CONFIG_PATH

./autogen.sh --enable-syphon --enable-rtsp-server --with-live555=/usr/local --enable-qt --enable-static-qt
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
./autogen.sh --enable-gpl --enable-syphon --enable-rtsp-server --with-live555=/usr/local --enable-qt --enable-static-qt
make osx-gui-dmg

#scp -i /Users/toor/.ssh/id_rsa 'gui/UltraGrid GUI/UltraGrid.dmg' pulec,ultragrid@frs.sourceforge.net:/home/frs/project/ultragrid/UltraGrid-nightly-OSX-32bit-w-QuickTime.dmg

curl -H "Authorization: token $OAUTH" -X GET https://api.github.com/repos/CESNET/UltraGrid/releases/4347706/assets > assets.json
LEN=`jq "length" assets.json`
for n in `seq 0 $(($LEN-1))`; do
	NAME=`jq '.['$n'].name' assets.json`
	if [ $NAME = "\"UltraGrid-nightly-macos-alt.dmg\"" ]; then
		ID=`jq '.['$n'].id' assets.json`
	fi
done

if [ -n "$ID" ]; then
	curl -H "Authorization: token $OAUTH" -X DELETE 'https://api.github.com/repos/CESNET/UltraGrid/releases/assets/'$ID
fi

curl -H "Authorization: token $OAUTH" -H 'Content-Type: application/gzip' -X POST 'https://uploads.github.com/repos/CESNET/UltraGrid/releases/4347706/assets?name=UltraGrid-nightly-macos-alt.dmg&label=macOS%20build%20%28alternative%2C%20without%20SSE4%20and%20videotoolbox%29' -T 'UltraGrid.dmg'

cd ..

#rm -rf $BUILD_DIR_ALT
