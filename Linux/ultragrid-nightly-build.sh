#!/bin/sh
set -e
set -x

DIR=UltraGrid-AppImage
APPDIR=UltraGrid.AppDir
APPNAME=UltraGrid-x86_64.AppImage
LABEL="AppImage%2064-bit"

cd /tmp
rm -rf $DIR

git clone -b master https://github.com/CESNET/UltraGrid.git $DIR

cd $DIR/

./autogen.sh --enable-plugins # --with-deltacast=/root/VideoMasterHD --with-sage=/root/sage-graphics-read-only/ --with-dvs=/root/sdk4.2.1.1 --enable-gpl
make

mkdir $APPDIR
mkdir tmpinstall
make DESTDIR=tmpinstall install
mv tmpinstall/usr/local/* $APPDIR

#mv gui/QT/uv-qt $APPDIR/bin
#cp -a /usr/local/lib/libgpujpeg.so* $APPDIR/lib

for n in $APPDIR/bin/* $APPDIR/lib/ultragrid/*
do
	for lib in `ldd $n | awk '{ print $3 }'`; do [ ! -f $lib ] || cp $lib $APPDIR/lib; done
done

echo \#\!/bin/sh > $APPDIR/AppRun
echo export LD_LIBRARY_PATH=\`dirname \$0\`/lib >> $APPDIR/AppRun
echo \`dirname \$0\`/bin/uv \$@ >> $APPDIR/AppRun
echo exit \$\? >> $APPDIR/AppRun
chmod 755 $APPDIR/AppRun

cp data/ultragrid.png $APPDIR/UltraGrid.png
cat<<EOF > $APPDIR/UltraGrid.desktop
[Desktop Entry]
Version=1.0
Name=UltraGrid
GenericName=RTP Streamer
Type=Application
Exec=uv
Icon=UltraGrid
StartupNotify=true
Terminal=false
Categories=AudioVideo;Recorder;Network;VideoConference;
EOF

/usr/local/bin/appimagetool-x86_64.AppImage $APPDIR

curl -H "Authorization: token 54a22bf35bc39262b60007e79101c978a3a2ff0c" -X GET https://api.github.com/repos/CESNET/UltraGrid/releases/4347706/assets > assets.json
LEN=`jq "length" assets.json`
for n in `seq 0 $(($LEN-1))`; do
	NAME=`jq '.['$n'].name' assets.json`
	if [ $NAME = \"$APPNAME\" ]; then
		ID=`jq '.['$n'].id' assets.json`
	fi
done

if [ -n "$ID" ]; then
	curl -H "Authorization: token 54a22bf35bc39262b60007e79101c978a3a2ff0c" -X DELETE 'https://api.github.com/repos/CESNET/UltraGrid/releases/assets/'$ID
fi

curl -H "Authorization: token 54a22bf35bc39262b60007e79101c978a3a2ff0c" -H 'Content-Type: application/gzip' -X POST 'https://uploads.github.com/repos/CESNET/UltraGrid/releases/4347706/assets?name='$APPNAME'&label='$LABEL -T $APPNAME

cd ..
rm -rf $DIR

