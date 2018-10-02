#!/bin/sh

set -exu

export AJA_DIRECTORY=$HOME/ntv2sdk
export QT_SELECT=5
QT_PATH=/usr/local/Qt-5.11.2
export CPATH=$QT_PATH/include${CPATH:+":$CPATH"}
export LIBRARY_PATH=$QT_PATH/lib${LIBRARY_PATH:+":$LIBRARY_PATH"}
export PATH=$QT_PATH/bin:$PATH
export PKG_CONFIG_PATH=$QT_PATH/lib/pkgconfig${PKG_CONFIG_PATH:+":$PKG_CONFIG_PATH"}

DIR=UltraGrid-AppImage
APPDIR=UltraGrid.AppDir
GLIBC_VERSION=`ldd --version | head -n 1 | sed 's/.*\ \([0-9][0-9]*\.[0-9][0-9]*\)$/\1/'`
APPNAME=UltraGrid-nightly.glibc${GLIBC_VERSION}-x86_64.AppImage
LABEL="Linux%20build%20%28AppImage%2C%20glibc%20$GLIBC_VERSION%29"

cd /tmp
rm -rf $DIR

git clone -b master https://github.com/CESNET/UltraGrid.git $DIR
#git clone -b devel https://github.com/MartinPulec/UltraGrid.git $DIR

cd $DIR/

./autogen.sh --enable-plugins --enable-qt --enable-static-qt # --with-deltacast=/root/VideoMasterHD --with-sage=/root/sage-graphics-read-only/ --with-dvs=/root/sdk4.2.1.1 --enable-gpl
make

mkdir $APPDIR
mkdir tmpinstall
make DESTDIR=tmpinstall install
mv tmpinstall/usr/local/* $APPDIR

#mv gui/QT/uv-qt $APPDIR/bin
#cp -a /usr/local/lib/libgpujpeg.so* $APPDIR/lib

#cp gui/QT/uv-qt $APPDIR/bin

for n in $APPDIR/bin/* $APPDIR/lib/ultragrid/*
do
	for lib in `ldd $n | awk '{ print $3 }'`; do [ ! -f $lib ] || cp $lib $APPDIR/lib; done
done

# glibc libraries should not be bundled
# Taken from https://gitlab.com/probono/platformissues
for n in ld-linux.so.2 ld-linux-x86-64.so.2 libanl.so.1 libBrokenLocale.so.1 libcidn.so.1 libcrypt.so.1 libc.so.6 libdl.so.2 libm.so.6 libmvec.so.1 libnss_compat.so.2 libnss_db.so.2 libnss_dns.so.2 libnss_files.so.2 libnss_hesiod.so.2 libnss_nisplus.so.2 libnss_nis.so.2 libpthread.so.0 libresolv.so.2 librt.so.1 libthread_db.so.1 libutil.so.1 # libnsl.so.1 - is not in Fedora 28 by default
do
        if [ -f $APPDIR/lib/$n ]; then
                rm $APPDIR/lib/$n
        fi
done

cat << 'EOF' >> $APPDIR/uv-wrapper.sh
#!/bin/sh

set -u

DIR=`dirname $0`
export LD_LIBRARY_PATH=$DIR/lib${LD_LIBRARY_PATH:+":$LD_LIBRARY_PATH"}
# there is an issue with running_from_path() which evaluates this executable
# as being system-installed
#export PATH=$DIR/bin:$PATH

exec $DIR/bin/uv "$@"
EOF

chmod 755 $APPDIR/uv-wrapper.sh

cat << 'EOF' >> $APPDIR/AppRun
#!/bin/sh

set -u

DIR=`dirname $0`
export LD_LIBRARY_PATH=$DIR/lib${LD_LIBRARY_PATH:+":$LD_LIBRARY_PATH"}
# there is an issue with running_from_path() which evaluates this executable
# as being system-installed
#export PATH=$DIR/bin:$PATH

usage() {
	echo "usage:"
	echo "\tUltraGrid [--gui [args]]"
	echo "\t\tinvokes GUI"
	echo
	echo "\tUltraGrid --tool <t> [args]"
	echo "\t\ttool may be: "`ls $DIR/bin`
	echo
	echo "\tUltraGrid args"
	echo "\t\tinvokes command-line UltraGrid"
}

if [ $# -eq 0 ]; then
	usage
	$DIR/bin/uv-qt --with-uv $DIR/uv-wrapper.sh
elif [ x"$1" = x"--tool" ]; then
	TOOL=$2
	shift 2
	$DIR/bin/$TOOL "$@"
elif [ x"$1" = x"--gui" ]; then
	shift
	$DIR/bin/uv-qt --with-uv $DIR/uv-wrapper.sh "$@"
elif [ x"$1" = x"-h" -o x"$1" = x"--help" ]; then
	usage
	exit 0
else
	$DIR/bin/uv "$@"
fi

exit $?
EOF
chmod 755 $APPDIR/AppRun

cp data/ultragrid.png $APPDIR/ultragrid.png
cp data/uv-qt.desktop $APPDIR/ultragrid.desktop

appimagetool --comp gzip $APPDIR $APPNAME

curl -H "Authorization: token 54a22bf35bc39262b60007e79101c978a3a2ff0c" -X GET https://api.github.com/repos/CESNET/UltraGrid/releases/4347706/assets > assets.json
LEN=`jq "length" assets.json`
ID=
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

