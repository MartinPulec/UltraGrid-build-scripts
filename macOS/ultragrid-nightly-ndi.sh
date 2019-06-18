#!/bin/sh

exec > ~/ultragrid-build-ndi.log 2>&1 </dev/null

set -e
set -x

BUILD_DIR=ultragrid-nightly-ndi
OAUTH=$(cat $HOME/github-oauth-token)
SECPATH=$(cat $HOME/secret-path)
DATE=`date +%Y%m%d`
APPNAME=UltraGrid-${DATE}-ndi-macos.dmg
APPNAME_GLOB="UltraGrid-*-ndi-macos.dmg"


. $HOME/common.sh
. $HOME/paths.sh

cd /tmp

rm -rf $BUILD_DIR

git clone -b devel https://github.com/MartinPulec/UltraGrid.git $BUILD_DIR

cd $BUILD_DIR/

git submodule init && git submodule update
( cd cineform-sdk/ && cmake . && make CFHDCodecStatic )

#export PKG_CONFIG_PATH=/usr/local/share/ffmpeg/lib/pkgconfig-static:$PKG_CONFIG_PATH

./autogen.sh ${COMMON_FLAGS[@]} --enable-ndi
make osx-gui-dmg

ssh toor@martin-centos.local sudo rm "/var/www/html/$SECPATH/$APPNAME_GLOB" || true
scp UltraGrid.dmg toor@martin-centos.local:/tmp/$APPNAME
ssh toor@martin-centos.local sudo mv /tmp/$APPNAME /var/www/html/$SECPATH
ssh toor@martin-centos.local sudo chcon -Rv --type=httpd_sys_content_t /var/www/html/$SECPATH/$APPNAME

rm -rf $BUILD_DIR

cd ..

