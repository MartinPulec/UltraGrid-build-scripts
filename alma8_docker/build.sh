#!/bin/sh -x

set -e

. scl_source enable gcc-toolset-15
export CUDA_FLAGS='-ccbin /usr/bin/gcc' # gcc 8 - 15 is unsupported by that CUDA

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
