#!/bin/sh
set -e
set -x

. /etc/os-release
DISTRO_VER=Ubuntu${VERSION_ID}
DISTRO_VER_URL="Ubuntu%20${VERSION_ID}"

DIR=UltraGrid-nightly-Linux64
TARGET=UltraGrid-nightly-${DISTRO_VER}

cd /tmp
rm -rf $DIR

git clone -b master https://github.com/CESNET/UltraGrid.git $DIR

cd $DIR/

./autogen.sh --enable-plugins # --with-deltacast=/root/VideoMasterHD --with-sage=/root/sage-graphics-read-only/ --with-dvs=/root/sdk4.2.1.1 --enable-gpl
make

mkdir $TARGET
mkdir tmpinstall
make DESTDIR=tmpinstall install
mv tmpinstall/usr/local/* $TARGET

#mv gui/QT/uv-qt $TARGET/bin
cp -a /usr/local/lib/libgpujpeg.so* lib

echo \#\!/bin/sh > $TARGET/run-ultragrid.sh
echo \`dirname \$0\`/bin/uv \$@ >> $TARGET/run-ultragrid.sh
echo exit \$\? >> $TARGET/run-ultragrid.sh
chmod 755 $TARGET/run-ultragrid.sh

curl -H "Authorization: token 54a22bf35bc39262b60007e79101c978a3a2ff0c" -X GET https://api.github.com/repos/CESNET/UltraGrid/releases/4347706/assets > assets.json
LEN=`jq "length" assets.json`
for n in `seq 0 $(($LEN-1))`; do
	NAME=`jq '.['$n'].name' assets.json`
	if [ $NAME = \"$TARGET.tar.gz\" ]; then
		ID=`jq '.['$n'].id' assets.json`
	fi
done

if [ -n "$ID" ]; then
	curl -H "Authorization: token 54a22bf35bc39262b60007e79101c978a3a2ff0c" -X DELETE 'https://api.github.com/repos/CESNET/UltraGrid/releases/assets/'$ID
fi

# and pack it
tar czf $TARGET.tar.gz $TARGET

curl -H "Authorization: token 54a22bf35bc39262b60007e79101c978a3a2ff0c" -H 'Content-Type: application/gzip' -X POST 'https://uploads.github.com/repos/CESNET/UltraGrid/releases/4347706/assets?name='$TARGET.tar.gz'&label='$DISTRO_VER_URL'%20build' -T $TARGET.tar.gz

#scp $TARGET.tar.gz pulec,ultragrid@frs.sourceforge.net:/home/frs/project/ultragrid/

cd ..
rm -rf $DIR

