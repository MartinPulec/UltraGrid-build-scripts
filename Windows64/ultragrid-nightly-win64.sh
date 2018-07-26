#!/bin/bash
set -e
set -x

exec > ultragrid-build64.log 2>&1

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

# key is BUILD
declare -A BRANCHES
BRANCHES["devel"]=devel
BRANCHES["master"]=master

# key is BUILD
declare -A CONF_FLAGS
CONF_FLAGS["devel"]=""
CONF_FLAGS["master"]=""

# key is BRANCH
declare -A GIT
GIT["master"]="https://github.com/CESNET/UltraGrid.git"
GIT["devel"]="https://github.com/MartinPulec/UltraGrid.git"


for BUILD in master devel
do
        BRANCH=${BRANCHES[$BUILD]}
        BUILD_DIR=ultragrid-nightly-$BUILD
        if [ $BRANCH = master ]; then
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
        if [ $BRANCH = "devel" ]; then
                ./autogen.sh # we need config.h for aja build script
                ./build_aja_lib_win64.sh
        fi
        cp -r ~/SpoutSDK src/
        ./build_spout64.sh

        read -a FLAGS <<< ${CONF_FLAGS[$BUILD]}
        ./autogen.sh --enable-aja --enable-spout "${FLAGS[@]}" --with-live555=/usr/local --enable-rtsp-server
        # --disable-dvs
        # --disable-jpeg --disable-cuda-dxt --disable-jpeg-to-dxt
        make -j 6

        for n in glew32.dll libstdc++-6.dll libfreeglut.dll SDL2.dll libwinpthread-1.dll libgcc_s_seh-1.dll libeay32.dll; do
        [ ! -e /mingw64/bin/$n ] || cp /mingw64/bin/$n bin
        done

        # TODO: remove when SDL2 reaches master
        if test ! -f src/video_display/sdl2.cpp; then
                rm bin/SDL2.dll
                cp /mingw64/bin/SDL.dll bin
        fi

        cp ../ffmpeg-latest-win64-shared/bin/*dll bin


        #cp "$MSVC11_PATH/VC/redist/x64/Microsoft.VC110.CRT/"* bin
        #cp "$MSVC12_PATH/VC/redist/x86/Microsoft.VC120.CRT/"* bin # pro AJA

        cp /usr/local/bin/libportaudio-2.dll bin
        #cp ~/pdcurses/pdcurses.dll bin
        ##cp ~/VideoMasterHD/Binaries/Vista32/*dll bin
        cp /usr/local/bin/gpujpeg.dll bin
        #cp ~/gpujpeg/x64/Release/cudart64_*.dll bin
        cp "$CUDA_PATH/bin/cudart64_92.dll" bin
        cp /usr/local/bin/spout_wrapper.dll bin
        cp ~/SpoutSDK/VS2012/Binaries/x64/Spout.dll bin
        cp /usr/local/bin/aja.dll bin
        # TODO: remove condition
        if [ -f COPYRIGHT ]; then
                cp COPYRIGHT bin/COPYRIGHT
        fi

        mv bin $DIR_NAME

        zip -r $ZIP_NAME $DIR_NAME
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

