#!/bin/ksh
# OS X 10.11 has too old bash (3.x) that doesn't know associative arrays

if ! test -t 1; then
        exec > ~/ultragrid-build-continuous.log 2>&1 </dev/null
fi

set -e
set -x

OAUTH=$(cat $HOME/github-oauth-token)
DATE=`date +%Y%m%d`
SECPATH=$(cat $HOME/secret-path)

. $HOME/common.sh
. $HOME/paths.sh
. ~/ultragrid_nightly_common.sh

# checkout current build script
atexit() {
        TMPDIR=$(mktemp -d)
        git clone https://github.com/MartinPulec/UltraGrid-build-scripts.git $TMPDIR
        cp $TMPDIR/ultragrid_nightly_common.sh $HOME
        cp -r $TMPDIR/macOS/*sh ~/
        crontab $TMPDIR/macOS/crontab
        rm -rf $TMPDIR
}
trap atexit EXIT

# key is BUILD
typeset -A BRANCHES
BRANCHES["devel"]=devel
BRANCHES["master"]=master
BRANCHES["ndi"]=master
# if unset, default is to use the build name as a branch

# key is BUILD
typeset -A CONF_FLAGS
CONF_FLAGS["default"]="--disable-ndi"
CONF_FLAGS["devel"]="$COMMON_ENABLE_ALL_FLAGS --enable-coreaudio --enable-syphon"
CONF_FLAGS["ndi"]="--enable-ndi"

# key is BRANCH
typeset -A GIT
GIT["master"]="https://github.com/CESNET/UltraGrid.git"
GIT["default"]="https://github.com/MartinPulec/UltraGrid.git"

DEFAULT_BUILD_LIST="master ndi devel"

for BUILD in ${@:-$DEFAULT_BUILD_LIST}
do
        cd /tmp
        BRANCH=${BRANCHES[$BUILD]-$BUILD}
        BUILD_DIR=ultragrid-nightly-$BUILD

        if [ "$BUILD" = master ]; then
                APPNAME=UltraGrid-nightly-alt.dmg
                #APPNAME_PATTERN="UltraGrid-[[:digit:]]\{8\}-macos.dmg"
                APPNAME_PATTERN="$APPNAME"
                LABEL="alternative%20macOS%20build%20%28macOS%2010%2E11%2B%2C%20with%20CUDA%29"
        else
                APPNAME=UltraGrid-nightly-$BUILD.dmg
                APPNAME_GLOB="UltraGrid-*-$BUILD.dmg"
                LABEL="macOS%20build%20%28$BUILD%29"
        fi

        rm -rf $BUILD_DIR

        git clone -b $BRANCH ${GIT[$BRANCH]-${GIT["default"]}} $BUILD_DIR

        cd $BUILD_DIR/

#export PKG_CONFIG_PATH=/usr/local/share/ffmpeg/lib/pkgconfig-static:$PKG_CONFIG_PATH

        ./autogen.sh ${COMMON_FLAGS[@]} ${CONF_FLAGS[$BUILD]-${CONF_FLAGS["default"]}}
        make gui-bundle
        make osx-gui-dmg

        #scp -i /Users/toor/.ssh/id_rsa 'gui/UltraGrid GUI/UltraGrid.dmg' pulec,ultragrid@frs.sourceforge.net:/home/frs/project/ultragrid/UltraGrid-nightly-OSX.dmg
        if [ "$BUILD" = ndi ]; then
                ssh toor@martin-centos.local sudo rm "/var/www/html/$SECPATH/$APPNAME_GLOB" || true
                scp UltraGrid.dmg toor@martin-centos.local:/tmp/$APPNAME
                ssh toor@martin-centos.local sudo mv /tmp/$APPNAME /var/www/html/$SECPATH
                ssh toor@martin-centos.local sudo chcon -Rv --type=httpd_sys_content_t /var/www/html/$SECPATH/$APPNAME
        elif [ "$BUILD" = devel ]; then
                 ssh toor@martin-centos.local "rm ~/public_html/ug-devel/$APPNAME_GLOB" || true
                 scp UltraGrid.dmg toor@martin-centos.local:public_html/ug-devel/$APPNAME
        else
                UPLOAD_URL=$(curl -s https://api.github.com/repos/CESNET/UltraGrid/releases/tags/continuous | jq -r .upload_url | sed "s/{.*}//")
                RELEASE_ID=$(curl -s https://api.github.com/repos/CESNET/UltraGrid/releases/tags/continuous | jq -r .id | sed "s/{.*}//")
                delete_asset $RELEASE_ID $APPNAME_PATTERN $OAUTH

                curl -H "Authorization: token $OAUTH" -H 'Content-Type: application/gzip' -X POST "$UPLOAD_URL?name=${APPNAME}&label=$LABEL" -T 'Ultragrid.dmg'
                #if [ "$BUILD" = "master" ]; then
                #        mv Ultragrid.dmg $APPNAME
                #        zsyncmake -C $APPNAME
                #        ZSYNC=UltraGrid-nightly-latest-macos.dmg.zsync
                #        mv $APPNAME.zsync $ZSYNC
                #        delete_asset 4347706 $ZSYNC $OAUTH
                #        curl -H "Authorization: token $OAUTH" -H 'Content-Type: application/x-zsync' -X POST 'https://uploads.github.com/repos/CESNET/UltraGrid/releases/4347706/assets?name='$ZSYNC -T $ZSYNC
                #fi
        fi

        cd ..
done

