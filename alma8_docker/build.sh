#!/bin/sh -x

set -e

export LD_LIBRARY_PATH=/usr/local/lib

git pull
./autogen.sh --enable-qt --enable-plugins
make -j 12
./data/scripts/Linux-AppImage/create-appimage.sh
mv UltraGrid-*-x86_64.AppImage /root/mnt
