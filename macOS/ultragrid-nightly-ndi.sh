#!/bin/sh

exec > ~/ultragrid-build-ndi.log 2>&1

set -e
set -x

OAUTH=$(cat $HOME/github-oauth-token)
QT=/usr/local/Qt-5.10.1
NDI=/NewTek_NDI_SDK
SECPATH=$(cat $HOME/secret-path)

export CPATH=$CPATH${CPATH:+:}/opt/local/include:/usr/local/include:/usr/local/cuda/include:$QT/include:$NDI/include
export LIBRARY_PATH=/opt/local/lib:/usr/local/cuda/lib:$QT/lib:$NDI/lib/x64
export DYLD_LIBRARY_PATH=/usr/local/cuda/lib:$NDI/lib/x64
export PATH=/opt/local/bin:$PATH:/usr/local/bin:/usr/local/cuda/bin:$QT/bin
export PKG_CONFIG_PATH=$PKG_CONFIG_PATH${PKG_CONFIG_PATH:+:}/usr/local/lib/pkgconfig:$QT/lib/pkgconfig
export PKG_CONFIG=/opt/local/bin/pkg-config
export BUILD_DIR=ultragrid-nightly-ndi
export AJA_DIRECTORY=/Users/toor/ntv2sdkmac_13.0.0.79b79
export EXTRA_LIB_PATH=$DYLD_LIBRARY_PATH # needed for make, see Makefile.in

cd /tmp

rm -rf $BUILD_DIR

git clone -b devel https://github.com/MartinPulec/UltraGrid.git $BUILD_DIR

cd $BUILD_DIR/

export PKG_CONFIG_PATH=/usr/local/share/ffmpeg/lib/pkgconfig-static:$PKG_CONFIG_PATH

./autogen.sh --enable-syphon --enable-rtsp-server --with-live555=/usr/local --enable-qt --enable-static-qt --enable-ndi
make osx-gui-dmg

scp UltraGrid.dmg toor@martin-centos.local:/tmp/UltraGrid-ndi.dmg
ssh toor@martin-centos.local sudo mv /tmp/UltraGrid-ndi.dmg /var/www/html/$SECPATH
ssh toor@martin-centos.local sudo chcon -Rv --type=httpd_sys_content_t /var/www/html/$SECPATH/UltraGrid-ndi.dmg

rm -rf $BUILD_DIR

cd ..

