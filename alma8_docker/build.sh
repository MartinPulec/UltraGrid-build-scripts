#!/bin/sh -x

set -e

export LD_LIBRARY_PATH=/usr/local/lib

cd "$(mktemp -d)"

srcdir=/root/mnt/ultragrid
if [ ! -f $srcdir/configure ]; then
  cd $srcdir
  ./autogen.sh && make distclean
  cd -
fi
$srcdir/configure --enable-qt --enable-plugins \
  --enable-gpujpeg
make -j "$(nproc)"
export GIT_DIR=$srcdir/.git
git config --global --add safe.directory "$srcdir"
VERSION=$(git rev-parse --short HEAD)
export VERSION
$srcdir/data/scripts/Linux-AppImage/create-appimage.sh
make -C $srcdir/tools clean && rm -rf $srcdir/tools/src
mv UltraGrid-*-x86_64.AppImage /root/mnt
