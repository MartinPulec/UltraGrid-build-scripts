#!/bin/bash
set -e
set -x

exec > ultragrid-build64.log 2>&1 </dev/null

export USERNAME=toor
export HOME=/home/$USERNAME

# checkout current build script
atexit() {
        TMPDIR=$(mktemp -d --suffix=-ug-build-scripts)
        git clone https://github.com/MartinPulec/UltraGrid-build-scripts.git $TMPDIR
        cp -r $TMPDIR/Windows64/* ~/
        rm -r $TMPDIR
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

OAUTH=$(cat $HOME/github-oauth-token)

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

for BUILD in master
do
        BRANCH=${BRANCHES[$BUILD]}
        BUILD_DIR=ultragrid-nightly-$BUILD
        if [ $BUILD = master ]; then
                DIR_NAME=UltraGrid-nightly
                ZIP_NAME=UltraGrid-nightly-win64.zip
        else
                DIR_NAME=UltraGrid-nightly-${BUILD}
                ZIP_NAME=UltraGrid-nightly-win64-$BUILD.zip
        fi

        echo Building $BUILD...

        cd ~
        rm -rf $BUILD_DIR
        git clone --config http.postBuffer=1048576000 -b $BRANCH ${GIT[$BRANCH]} $BUILD_DIR
        cd $BUILD_DIR
        #cp -r ~/gpujpeg/Release/ gpujpeg
        #cp -r ~/SpoutSDK .

        git submodule init && git submodule update
        ( cd cineform-sdk && /c/Program\ Files/CMake/bin/cmake -DBUILD_STATIC=false -G "Visual Studio 15 2017" -A x64 . && /c/Program\ Files\ \(x86\)/Microsoft\ Visual\ Studio/2017/Community/MSBuild/15.0/Bin/MSBuild.exe CineFormSDK.sln -property:Configuration=Release && cp Release/CFHDCodec.dll /usr/local/bin )

        ./autogen.sh # we need config.h for aja build script
        ./build_aja_lib_win64.sh

        cp -r ~/SpoutSDK src/
        ./build_spout64.sh

        read -a FLAGS <<< ${CONF_FLAGS[$BUILD]}
        ./autogen.sh --enable-aja --enable-spout "${FLAGS[@]}" --with-live555=/usr/local --enable-rtsp-server --enable-cineform --enable-qt --enable-video-mixer --enable-rtsp
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
        #scp -i c:/mingw32/msys~/.ssh/id_rsa $ZIP_NAME pulec,ultragrid@frs.sourceforge.net:/home/frs/project/ultragrid

curl -H "Authorization: token $OAUTH" -X GET https://api.github.com/repos/CESNET/UltraGrid/releases/4347706/assets > assets.json # --insecure
LEN=`jq "length" assets.json`
for n in `seq 0 $(($LEN-1))`; do
        NAME=`jq '.['$n'].name' assets.json`
        if [ $NAME = "\""$ZIP_NAME"\"" ]; then
                ID=`jq '.['$n'].id' assets.json`
        fi
done

if [ -n "$ID" ]; then
        curl -H "Authorization: token $OAUTH" -X DELETE 'https://api.github.com/repos/CESNET/UltraGrid/releases/assets/'$ID # --insecure
fi

#LABEL="Windows%20build%20"$BRANCH
LABEL="Windows%20build"

curl -H "Authorization: token $OAUTH" -H 'Content-Type: application/zip' -X POST 'https://uploads.github.com/repos/CESNET/UltraGrid/releases/4347706/assets?name='$ZIP_NAME'&label='$LABEL -T $ZIP_NAME # --insecure

done

