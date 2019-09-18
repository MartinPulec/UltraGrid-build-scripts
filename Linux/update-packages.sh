#!/bin/bash

set -xe

[ "$UID" -eq 0 ] || exec sudo "$0" "$@"

PATH=$PATH:/usr/local/bin
PKG_CONFIG_PATH=$PKG_CONFIG_PATH${PKG_CONFIG_PATH:+":"}/usr/local/lib/pkgconfig

. /home/toor/nightly-paths.sh
. /home/toor/ultragrid_nightly_common.sh

install_cineform() {
(
        cd /tmp
        rm -rf cineform-sdk
        git clone https://github.com/gopro/cineform-sdk.git
        cd cineform-sdk
        cmake3 . && make CFHDCodecStatic
        sudo cp libCFHDCodec.a /usr/local/lib
        sudo cp Common/* /usr/local/include
        sudo cp libcineformsdk.pc /usr/local/lib/pkgconfig/
)
}

install_cineform

cd /tmp
rm -rf nasm
git clone -b nasm-2.13.xx https://github.com/sezero/nasm.git
cd nasm
./autogen.sh
./configure
make nasm.1
make ndisasm.1
make install
cd /tmp
rm -rf nasm

cd /tmp
rm -rf x264
git clone http://git.videolan.org/git/x264.git
cd x264
./configure --disable-static --enable-shared --prefix=/usr/local/ultragrid-nightly
make install
cd /tmp
rm -rf x264

cd /tmp
rm -rf x265
hg clone https://bitbucket.org/multicoreware/x265
cd x265/build/linux
#./make-Makefiles.bash
cmake -G "Unix Makefiles" ../../source && cmake ../../source -DCMAKE_INSTALL_PREFIX:PATH=/usr/local/ultragrid-nightly -DHIGH_BIT_DEPTH:BOOL=ON
make install
cd /tmp
rm -rf x265

cd /tmp
rm -rf opus
git clone https://git.xiph.org/opus.git
cd opus
./autogen.sh
./configure --disable-static --enable-shared --prefix=/usr/local/ultragrid-nightly
make install
cd /tmp
rm -rf opus

cd /tmp
rm -rf libvpx
git clone https://chromium.googlesource.com/webm/libvpx
cd libvpx
./configure --disable-static --enable-shared --prefix=/usr/local/ultragrid-nightly
make install
cd /tmp
rm -rf libvpx

cd /tmp
rm -rf nv-codec-headers
git clone https://git.videolan.org/git/ffmpeg/nv-codec-headers.git
cd nv-codec-headers
make install
cd /tmp
rm -rf nv-codec-headers

cd /tmp
rm -rf ffmpeg
git clone git://source.ffmpeg.org/ffmpeg.git
cd ffmpeg
./configure --enable-gpl --enable-libx264 --enable-libx265 --enable-cuda --enable-cuvid --enable-libopus --enable-libx264 --enable-libspeex --enable-libvpx --extra-cflags=-I/usr/local/cuda/include --extra-ldflags=-L/usr/local/cuda/lib64 --enable-libmp3lame --enable-vaapi --enable-vdpau --enable-nvenc --enable-shared --prefix=/usr/local/ultragrid-nightly
make install
cd /tmp
rm -rf ffmpeg

cd /tmp
rm -rf GPUJPEG
git clone https://github.com/CESNET/GPUJPEG.git
cd GPUJPEG
./autogen.sh
make install
cd /tmp
rm -rf GPUJPEG
