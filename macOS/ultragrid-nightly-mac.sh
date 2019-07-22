#!/bin/ksh
# OS X 10.11 has too old bash (3.x) that doesn't know associative arrays

exec > ~/ultragrid-build.log 2>&1 </dev/null

set -e
set -x

OAUTH=$(cat $HOME/github-oauth-token)
DATE=`date +%Y%m%d`
SECPATH=$(cat $HOME/secret-path)

. $HOME/common.sh
. $HOME/paths.sh

# checkout current build script
atexit() {
        TMPDIR=$(mktemp -d)
        git clone https://github.com/MartinPulec/UltraGrid-build-scripts.git $TMPDIR
        cp -r $TMPDIR/macOS/*sh ~/
        crontab $TMPDIR/macOS/crontab
        rm -rf $TMPDIR
}
trap atexit EXIT

# key is BUILD
typeset -A BRANCHES
BRANCHES["master"]=master
BRANCHES["ndi"]=devel
# if unset, default is to use the build name as a branch

# key is BUILD
typeset -A CONF_FLAGS
CONF_FLAGS["default"]="--disable-ndi"
CONF_FLAGS["ndi"]="--enable-ndi"

# key is BRANCH
typeset -A GIT
GIT["master"]="https://github.com/CESNET/UltraGrid.git"
GIT["default"]="https://github.com/MartinPulec/UltraGrid.git"

for BUILD in master ndi
do
        cd /tmp
        BRANCH=${BRANCHES[$BUILD]-$BUILD}
        BUILD_DIR=ultragrid-nightly-$BUILD

        if [ "$BUILD" = master ]; then
                APPNAME=UltraGrid-${DATE}-macos.dmg
                APPNAME_PATTERN="UltraGrid-[[:digit:]]\{8\}-macos.dmg"
        else
                APPNAME=UltraGrid-${DATE}-$BUILD-macos.dmg
                APPNAME_GLOB="UltraGrid-*-$BUILD-macos.dmg"
                LABEL="macOS%20build%20%28$BUILD%29"
        fi

        rm -rf $BUILD_DIR

        git clone -b $BRANCH ${GIT[$BRANCH]-${GIT["default"]}} $BUILD_DIR

        cd $BUILD_DIR/

        git submodule init && git submodule update
        ( cd cineform-sdk/ && cmake . && make CFHDCodecStatic )

#export PKG_CONFIG_PATH=/usr/local/share/ffmpeg/lib/pkgconfig-static:$PKG_CONFIG_PATH

        ./autogen.sh ${COMMON_FLAGS[@]} ${CONF_FLAGS[$BUILD]-${CONF_FLAGS["default"]}}
        make osx-gui-dmg

        #scp -i /Users/toor/.ssh/id_rsa 'gui/UltraGrid GUI/UltraGrid.dmg' pulec,ultragrid@frs.sourceforge.net:/home/frs/project/ultragrid/UltraGrid-nightly-OSX.dmg
        if [ "$BUILD" != ndi ]; then
                curl -H "Authorization: token $OAUTH" -X GET https://api.github.com/repos/CESNET/UltraGrid/releases/4347706/assets > assets.json
                LEN=`jq "length" assets.json`
                for n in `seq 0 $(($LEN-1))`; do
                        NAME=`jq '.['$n'].name' assets.json`
                        if expr "$NAME" : "^\"$APPNAME_PATTERN\"$"; then
                                ID=`jq '.['$n'].id' assets.json`
                        fi
                done

                if [ -n "$ID" ]; then
                        curl -H "Authorization: token $OAUTH" -X DELETE 'https://api.github.com/repos/CESNET/UltraGrid/releases/assets/'$ID
                fi

                curl -H "Authorization: token $OAUTH" -H 'Content-Type: application/gzip' -X POST "https://uploads.github.com/repos/CESNET/UltraGrid/releases/4347706/assets?name=${APPNAME}&label=$LABEL" -T 'Ultragrid.dmg'
        else
                ssh toor@martin-centos.local sudo rm "/var/www/html/$SECPATH/$APPNAME_GLOB" || true
                scp UltraGrid.dmg toor@martin-centos.local:/tmp/$APPNAME
                ssh toor@martin-centos.local sudo mv /tmp/$APPNAME /var/www/html/$SECPATH
                ssh toor@martin-centos.local sudo chcon -Rv --type=httpd_sys_content_t /var/www/html/$SECPATH/$APPNAME
        fi

        cd ..
done

