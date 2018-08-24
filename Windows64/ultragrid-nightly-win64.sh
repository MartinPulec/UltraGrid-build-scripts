#!/bin/bash
set -e
set -x

exec > ultragrid-build64.log 2>&1

export USERNAME=toor
export HOME=/home/$USERNAME

# checkout current build script
atexit() {
        git clone root@w54-136.fi.muni.cz:ultragrid-build ultragrid-build-tmp
        cp -r ultragrid-build-tmp/Windows64/* ~/
        rm -r ultragrid-build-tmp
}
trap atexit EXIT

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

# key is BUILD
declare -A BRANCHES
BRANCHES["devel-nogui"]=devel
BRANCHES["master"]=master
BRANCHES["master-nogui"]=master

# key is BUILD
declare -A CONF_FLAGS
CONF_FLAGS["devel-nogui"]=""
CONF_FLAGS["master"]="--enable-qt"
CONF_FLAGS["master-nogui"]=""

# key is BRANCH
declare -A GIT
GIT["master"]="https://github.com/CESNET/UltraGrid.git"
GIT["devel"]="https://github.com/MartinPulec/UltraGrid.git"

for BUILD in master-nogui master devel-nogui
do
        BRANCH=${BRANCHES[$BUILD]}
        BUILD_DIR=ultragrid-nightly-$BUILD
        if [ $BUILD = master ]; then
                DIR_NAME=UltraGrid
                ZIP_NAME=UltraGrid-nightly-win64.zip
        else
                DIR_NAME=UltraGrid-${BUILD}
                ZIP_NAME=UltraGrid-nightly-win64-$BUILD.zip
        fi

        echo Building $BUILD...

        cd ~
        rm -rf $BUILD_DIR
        git clone -b $BRANCH ${GIT[$BRANCH]} $BUILD_DIR
        cd $BUILD_DIR
        #cp -r ~/gpujpeg/Release/ gpujpeg
        #cp -r ~/SpoutSDK .

        ./autogen.sh # we need config.h for aja build script
        ./build_aja_lib_win64.sh

        cp -r ~/SpoutSDK src/
        ./build_spout64.sh

        read -a FLAGS <<< ${CONF_FLAGS[$BUILD]}
        ./autogen.sh --enable-aja --enable-spout "${FLAGS[@]}" --with-live555=/usr/local --enable-rtsp-server
        # --disable-dvs
        # --disable-jpeg --disable-cuda-dxt --disable-jpeg-to-dxt
        make -j 6

        if [ -f gui/QT/debug/uv-qt.exe ]; then
                cp gui/QT/debug/uv-qt.exe bin
        fi

        # Add dependencies
        for exe in bin/*exe; do
                for n in `./get_dll_depends.sh "$exe"`; do
                        cp "$n" bin
                done
        done

        # CUDA needs to be added manually for some reason - not listed in objdump
        # dependencies, maybe it is loaded dynamically?
        cp "$CUDA_PATH/bin/cudart64_92.dll" bin
        cp COPYRIGHT bin/COPYRIGHT

        mv bin $DIR_NAME

        zip -9 -r $ZIP_NAME $DIR_NAME
        #scp -i c:/mingw32/msys~/.ssh/id_rsa $ZIP_NAME pulec,ultragrid@frs.sourceforge.net:/home/frs/project/ultragrid

curl -H "Authorization: token 54a22bf35bc39262b60007e79101c978a3a2ff0c" -X GET https://api.github.com/repos/CESNET/UltraGrid/releases/4347706/assets > assets.json # --insecure
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
LABEL="Windows%2064-bit%20build%20"$BUILD

curl -H "Authorization: token 54a22bf35bc39262b60007e79101c978a3a2ff0c" -H 'Content-Type: application/zip' -X POST 'https://uploads.github.com/repos/CESNET/UltraGrid/releases/4347706/assets?name='$ZIP_NAME'&label='$LABEL -T $ZIP_NAME # --insecure

done

