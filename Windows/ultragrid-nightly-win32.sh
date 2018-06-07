#!/bin/sh
set -e
set -x

exec > c:/ultragrid-build.log 2>&1

export USERNAME=host
export HOME=/home/host

. ~/paths.sh

export PATH=/usr/local/bin`[ -n "$PATH" ] && echo :$PATH`
export CPATH=/usr/local/include`[ -n "$CPATH" ] && echo :$CPATH`
export LIBRARY_PATH=/usr/local/lib`[ -n "$LIBRARY_PATH" ] && echo :$LIBRARY_PATH`
export DELTACAST_DIRECTORY=~/VideoMasterHD
export DVS_DIRECTORY=~/sdk4.2.1.1

export CUDA_PATH=$CUDA_DIRECTORY
export MSVC_PATH=/c/Program\ Files\ \(x86\)/Microsoft\ Visual\ Studio\ 11.0/
export MSVC12_PATH=/c/Program\ Files\ \(x86\)/Microsoft\ Visual\ Studio\ 12.0/

export LIBRARY_PATH=$LIBRARY_PATH:~/gpujpeg/Release/
export CPATH=$CPATH:~/gpujpeg/
export PATH=$PATH:$MSVC_PATH/Common7/IDE/:$MSVC_PATH/VC/bin/
export LIBRARY_PATH=$LIBRARY_PATH:$CUDA_PATH/lib/Win32/

declare -A GIT

GIT["master"]="https://github.com/CESNET/UltraGrid.git"
GIT["devel"]="https://github.com/MartinPulec/UltraGrid.git"

for BRANCH in master devel
do
        BUILD_DIR=ultragrid-nightly-$BRANCH
        if [ $BRANCH = master ]; then
                DIR_NAME=UltraGrid
                ZIP_NAME=UltraGrid-nightly-win32.zip
        else
                DIR_NAME=UltraGrid-$BRANCH
                ZIP_NAME=UltraGrid-nightly-win32-$BRANCH.zip
        fi

        echo Building branch $BRANCH...
                   
        cd ~
        rm -rf $BUILD_DIR
        git clone -b $BRANCH ${GIT[$BRANCH]} $BUILD_DIR
        cd $BUILD_DIR
        cp -r ~/gpujpeg/Release/ gpujpeg
        cp -r ~/SpoutSDK .
	if [ -f build_aja_lib_win32.sh ]; then
		AJA=yes
		enable_aja=--enable-aja
		mkdir bin
		./autogen.sh # we need config.h now
		./build_aja_lib_win32.sh
	else
		AJA=no
		enable_aja=
	fi
        ./autogen.sh --enable-gpl --disable-dvs --with-live555=/usr/local --enable-spout $enable_aja
        # --disable-jpeg --disable-cuda-dxt --disable-jpeg-to-dxt
        make -j 20 

        for n in glew32.dll libgcc_s_dw2-1.dll libstdc++-6.dll libportaudio-2.dll libfreeglut.dll SDL.dll libwinpthread-1.dll libeay32.dll; do
        [ ! -e /mingw32/bin/$n ] || cp /mingw32/bin/$n bin
        done

        #LIBAV_DIR=`ls -d ../libav-win32-*|tail -n 1`
        #cp $LIBAV_DIR/usr/bin/* bin
        #cp ../ffmpeg-20150721-git-6b96c70-win32-shared/bin/*.dll bin
        #cp ../libav-i686-w64-mingw32-20160125/usr/bin/*.dll bin
        cp ../ffmpeg-latest-win32-shared/bin/*dll bin


        cp "$MSVC_PATH/VC/redist/x86/Microsoft.VC110.CRT/"* bin
        cp "$MSVC12_PATH/VC/redist/x86/Microsoft.VC120.CRT/"* bin
        cp "$CUDA_PATH/bin/cudart32_80.dll" bin

        cp ~/pdcurses/pdcurses.dll bin
        #cp ~/VideoMasterHD/Binaries/Vista32/*dll bin
        #cp /mingw/i686-w64-mingw32/lib/libgcc_s_dw2-1.dll bin
        cp ~/gpujpeg/Release/gpujpeg.dll bin
	cp /usr/local/bin/spout_sender.dll bin # TODO: remove
	cp /usr/local/bin/spout_wrapper.dll bin
	cp /usr/local/bin/Spout.dll bin

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
LABEL="Windows%20build%20"$BRANCH

curl -H "Authorization: token 54a22bf35bc39262b60007e79101c978a3a2ff0c" -H 'Content-Type: application/zip' -X POST 'https://uploads.github.com/repos/CESNET/UltraGrid/releases/4347706/assets?name='$ZIP_NAME'&label='$LABEL -T $ZIP_NAME # --insecure

done

