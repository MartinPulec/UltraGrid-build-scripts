#!/bin/sh -eux

exec > ~/ultragrid-build.log 2>&1 </dev/null

. ~/env.sh

cd /tmp
rm -rf ultragrid
git clone --depth 1 https://github.com/CESNET/UltraGrid.git ultragrid
#git clone http://frakira.fi.muni.cz/~xpulec/ultragrid.git ultragrid
cd ultragrid
./autogen.sh --enable-qt --with-object-remove=src/audio/playback/aes67.o \
	--disable-vulkan # --disable-cineform
make -j "$(getconf NPROCESSORS_ONLN)" gui-bundle

#security default-keychain -s build.keychain
#security unlock-keychain -p dummy build.keychain
export notarytool="notarytool"
path_old=$PATH
#PATH="$PATH:/Volumes/macos11\ -\ Data/Applications/Xcode-beta.app/Contents/Developer/usr/bin"
PATH="$PATH:/Volumes/macos11 - Data/Applications/Xcode-beta.app/Contents/Developer/usr/bin"
export notarytool=notarytool
#security list-keychain -d user
#security -q find-identity -p codesigning "$KEY_CHAIN" 2>&1
.github/scripts/macOS/sign.sh uv-qt.app
PATH=$path_old

make osx-gui-dmg

. ~/ultragrid_nightly_common.sh

UPLOAD_URL=$(curl -s https://api.github.com/repos/CESNET/UltraGrid/releases/tags/continuous | jq -r .upload_url | sed "s/{.*}//")
RELEASE_ID=$(curl -s https://api.github.com/repos/CESNET/UltraGrid/releases/tags/continuous | jq -r .id | sed "s/{.*}//")
APPNAME=UltraGrid-nightly-alt.dmg
#APPNAME_PATTERN="UltraGrid-[[:digit:]]\{8\}-macos.dmg"
APPNAME_PATTERN="$APPNAME"
#LABEL="alternative%20macOS%20build%20%28macOS%2010%2E12%2B%2C%20with%20CUDA%29"
LABEL="alternative%20macOS%20build%20%28macOS%2010%2E15%2B%29"
delete_asset $RELEASE_ID $APPNAME_PATTERN $OAUTH

curl -H "Authorization: token $OAUTH" -H 'Content-Type: application/gzip' -X POST "$UPLOAD_URL?name=${APPNAME}&label=$LABEL" -T 'Ultragrid.dmg'
