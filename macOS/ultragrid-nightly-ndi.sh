#!/bin/sh

exec > ~/ultragrid-build-ndi.log 2>&1 </dev/null

set -e
set -x

BUILD_DIR=ultragrid-nightly-ndi
OAUTH=$(cat $HOME/github-oauth-token)
NDI=/NewTek_NDI_SDK
SECPATH=$(cat $HOME/secret-path)

. $HOME/common.sh
. $HOME/paths.sh

cd /tmp

rm -rf $BUILD_DIR

git clone -b devel https://github.com/MartinPulec/UltraGrid.git $BUILD_DIR

cd $BUILD_DIR/

export PKG_CONFIG_PATH=/usr/local/share/ffmpeg/lib/pkgconfig-static:$PKG_CONFIG_PATH

./autogen.sh ${COMMON_FLAGS[@]} --enable-ndi
make osx-gui-dmg

scp UltraGrid.dmg toor@martin-centos.local:/tmp/UltraGrid-ndi.dmg
ssh toor@martin-centos.local sudo mv /tmp/UltraGrid-ndi.dmg /var/www/html/$SECPATH
ssh toor@martin-centos.local sudo chcon -Rv --type=httpd_sys_content_t /var/www/html/$SECPATH/UltraGrid-ndi.dmg

rm -rf $BUILD_DIR

cd ..

