#!/bin/bash

set -e
set -x

exec > ultragrid-build64-release.log 2>&1

export USERNAME=toor
export HOME=/home/$USERNAME

. ~/paths.sh

#export PATH=/usr/local/bin`[ -n "$PATH" ] && echo :$PATH`
#export CPATH=/usr/local/include`[ -n "$CPATH" ] && echo :$CPATH`
#export LIBRARY_PATH=/usr/local/lib`[ -n "$LIBRARY_PATH" ] && echo :$LIBRARY_PATH`
#export DELTACAST_DIRECTORY=~/VideoMasterHD
#export DVS_DIRECTORY=~/sdk4.2.1.1

#export CUDA_PATH=$CUDA_DIRECTORY
#export MSVC_PATH=/c/Program\ Files\ \(x86\)/Microsoft\ Visual\ Studio\ 11.0/

#export LIBRARY_PATH=$LIBRARY_PATH:~/gpujpeg/Release/
#export CPATH=$CPATH:~/gpujpeg/
#export PATH=$PATH:$MSVC_PATH/Common7/IDE/:$MSVC_PATH/VC/bin/
#export LIBRARY_PATH=$LIBRARY_PATH:$CUDA_PATH/lib/Win32/

BRANCH="release/1.5"
BUILD="release/1.5"
BUILD_DIR="ultragrid-1.5"
DIR_NAME="UltraGrid-1.5"
GIT="https://github.com/CESNET/UltraGrid.git"
GITHUB_RELEASE_ID=13297067
ZIP_NAME="UltraGrid-1.5-win64.zip"

echo Building $BUILD...

cd ~
rm -rf $BUILD_DIR
git clone --config http.postBuffer=1048576000 -b $BRANCH $GIT $BUILD_DIR
cd $BUILD_DIR
#cp -r ~/gpujpeg/Release/ gpujpeg
#cp -r ~/SpoutSDK .

./autogen.sh # we need config.h for aja build script
./build_aja_lib_win64.sh

cp -r ~/SpoutSDK src/
./build_spout64.sh

./autogen.sh --enable-aja --enable-spout --enable-qt --with-live555=/usr/local --enable-rtsp-server
# --disable-dvs
# --disable-jpeg --disable-cuda-dxt --disable-jpeg-to-dxt
make -j 6

if [ -f gui/QT/release/uv-qt.exe ]; then
        cp gui/QT/release/uv-qt.exe bin
fi

# Add dependencies
for exe in bin/*exe; do
        for n in `./get_dll_depends.sh "$exe"`; do
                cp "$n" bin
        done
done
# https://doc.qt.io/qt-5/windows-deployment.html
if [ -f bin/uv-qt.exe ]; then
        windeployqt bin/uv-qt.exe
fi

# TODO: check if cuda is really not needed
#cp "$CUDA_PATH/bin/cudart64_92.dll" bin
for n in COPYRIGHT NEWS README REPORTING-BUGS; do
        cp $n bin
done
cp speex-1.2rc1/COPYING bin/COPYING.speex

mv bin $DIR_NAME

zip -9 -r $ZIP_NAME $DIR_NAME

curl -H "Authorization: token 54a22bf35bc39262b60007e79101c978a3a2ff0c" -X GET https://api.github.com/repos/CESNET/UltraGrid/releases/$GITHUB_RELEASE_ID/assets > assets.json # --insecure
LEN=`jq "length" assets.json`
for n in `seq 0 $(($LEN-1))`; do
        NAME=`jq '.['$n'].name' assets.json`
        if [ $NAME = "\""$ZIP_NAME"\"" ]; then
                ID=`jq '.['$n'].id' assets.json`
        fi
done

if [ -n "$ID" ]; then
        curl -H "Authorization: token 54a22bf35bc39262b60007e79101c978a3a2ff0c" -X DELETE 'https://api.github.com/repos/CESNET/UltraGrid/releases/assets/'$ID # --insecure
fi

#LABEL="Windows%20build%20"$BRANCH
LABEL="Windows%20build"

curl -H "Authorization: token 54a22bf35bc39262b60007e79101c978a3a2ff0c" -H 'Content-Type: application/zip' -X POST "https://uploads.github.com/repos/CESNET/UltraGrid/releases/$GITHUB_RELEASE_ID/assets?name=$ZIP_NAME&label=$LABEL" -T $ZIP_NAME # --insecure

done

