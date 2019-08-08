#!/bin/bash

set -e
set -x

exec > ultragrid-build64-release.log 2>&1 </dev/null

export USERNAME=toor
export HOME=/home/$USERNAME

. ~/paths.sh
. ~/ultragrid_nightly_common.sh

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
OAUTH=$(cat $HOME/github-oauth-token)
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

if grep -q VS2012 build_spout64.sh; then
        cp -r ~/SpoutSDK src/
else
        cp -r ~/Spout2/SPOUTSDK/SpoutSDK src/
fi
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

delete_asset $GITHUB_RELEASE_ID $ZIP_NAME $OAUTH

#LABEL="Windows%20build%20"$BRANCH
LABEL="Windows%20build"

curl -H "Authorization: token $OAUTH" -H 'Content-Type: application/zip' -X POST "https://uploads.github.com/repos/CESNET/UltraGrid/releases/$GITHUB_RELEASE_ID/assets?name=$ZIP_NAME&label=$LABEL" -T $ZIP_NAME # --insecure

