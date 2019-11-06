#!/bin/bash -ex

# Usage:
# ultragrid-nightly-win64.sh [-i] [branches]
#      -i    - interactive mode - print output to console
#   branches - list of branches to build

if test "${1:-}" = "-i"; then
        shift
else
        exec > ultragrid-build64.log 2>&1 </dev/null
fi

export USERNAME=toor
export HOME=/home/$USERNAME

# checkout current build script
atexit() {
        TMPDIR=$(mktemp -d --suffix=-ug-build-scripts)
        git clone https://github.com/MartinPulec/UltraGrid-build-scripts.git $TMPDIR
        cp $TMPDIR/ultragrid_nightly_common.sh $HOME
        cp -r $TMPDIR/Windows64/* ~/
        rm -rf $TMPDIR
}
trap atexit EXIT

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

OAUTH=$(cat $HOME/github-oauth-token)

# key is BUILD
declare -A BRANCHES
BRANCHES["devel"]=devel
BRANCHES["master"]=master
BRANCHES["ndi"]=master
# if unset, default is to use the build name as a branch

# key is BUILD
declare -A CONF_FLAGS
CONF_FLAGS["default"]="--disable-ndi"
CONF_FLAGS["devel"]="$COMMON_ENABLE_ALL_FLAGS --enable-dshow --disable-screen --enable-spout --enable-wasapi"
CONF_FLAGS["ndi"]="--enable-ndi"

# key is BRANCH
declare -A GIT
GIT["master"]="https://github.com/CESNET/UltraGrid.git"
GIT["default"]="https://github.com/MartinPulec/UltraGrid.git"

DEFAULT_BUILD_LIST="master ndi devel"

for BUILD in ${@:-$DEFAULT_BUILD_LIST}
do
        BRANCH=${BRANCHES[$BUILD]-$BUILD}
        BUILD_DIR=ultragrid-nightly-$BUILD
        DATE=`date +%Y%m%d`
        if [ $BUILD = master ]; then
                LABEL="Windows%20build"
                SUFF=
        else
                LABEL="Windows%20build%20%28$BUILD%29"
                SUFF=-${BUILD}
        fi
        DIR_NAME=UltraGrid-${DATE}${SUFF}
        ZIP_NAME=UltraGrid-${DATE}${SUFF}-win64.zip
        ZIP_NAME_GLOB="UltraGrid-*${SUFF}-win64.zip"
        ZIP_NAME_PATTERN="UltraGrid-[[:digit:]]\{8\}${SUFF}-win64.zip"

        echo Building $BUILD...

        cd ~
        rm -rf $BUILD_DIR
        git clone --config http.postBuffer=1048576000 -b $BRANCH ${GIT[$BRANCH]-${GIT["default"]}} $BUILD_DIR
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

        read -a FLAGS <<< ${CONF_FLAGS[$BUILD]-${CONF_FLAGS["default"]}}
        ./autogen.sh --enable-aja --enable-jack --enable-spout "${FLAGS[@]}" --with-live555=/usr/local --enable-rtsp-server --enable-cineform --enable-qt --enable-video-mixer --enable-rtsp
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
        for n in COPYRIGHT NEWS README.md REPORTING-BUGS.md; do
                cp $n bin
        done
        cp speex-1.2rc1/COPYING bin/COPYING.speex

        mv bin $DIR_NAME

        zip -9 -r $ZIP_NAME $DIR_NAME
        #scp -i c:/mingw32/msys~/.ssh/id_rsa $ZIP_NAME pulec,ultragrid@frs.sourceforge.net:/home/frs/project/ultragrid

        if [ $BUILD = "ndi" ]; then
                SECPATH=$(cat $HOME/secret-path)
                scp $ZIP_NAME toor@martin-centos.local:/tmp
                ssh toor@martin-centos.local sudo rm "/var/www/html/$SECPATH/$ZIP_NAME_GLOB" || true
                ssh toor@martin-centos.local sudo mv /tmp/$ZIP_NAME /var/www/html/$SECPATH
                ssh toor@martin-centos.local sudo chcon -Rv \
                        --type=httpd_sys_content_t /var/www/html/$SECPATH/$ZIP_NAME
        elif [ $BUILD = "devel" ]; then
                ssh toor@martin-centos.local "rm ~/public_html/ug-devel/$ZIP_NAME_GLOB" || true
                scp $ZIP_NAME toor@martin-centos.local:public_html/ug-devel
        else
                delete_asset 4347706 $ZIP_NAME_PATTERN $OAUTH

                curl -H "Authorization: token $OAUTH" -H 'Content-Type: application/zip' -X POST 'https://uploads.github.com/repos/CESNET/UltraGrid/releases/4347706/assets?name='$ZIP_NAME'&label='$LABEL -T $ZIP_NAME # --insecure
        fi
done

