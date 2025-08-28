#!/bin/sh -x

source scl_source enable devtoolset-11

set -e

export LD_LIBRARY_PATH=/usr/local/lib

cd /root/ultragrid
git fetch
git reset --hard origin/master
./autogen.sh --enable-qt --enable-plugins\
 --enable-rtsp-server --enable-rtsp
make -j 12
rm UltraGrid-*-x86_64.AppImage
./data/scripts/Linux-AppImage/create-appimage.sh
mv UltraGrid-*-x86_64.AppImage /root/mnt
