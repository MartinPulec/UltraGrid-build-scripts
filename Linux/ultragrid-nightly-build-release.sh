#!/bin/sh

exec > ~/ultragrid-nightly-build-release.log 2>&1 </dev/null

set -exu

export AJA_DIRECTORY=$HOME/ntv2sdk
export QT_SELECT=5
QT_PATH=/usr/local/Qt-5.10.1
export CPATH=$QT_PATH/include:/usr/local/include${CPATH:+":$CPATH"}
export EXTRA_LIB_PATH=$QT_PATH/lib:/usr/local/cuda/lib64:/usr/local/lib
export LIBRARY_PATH=$EXTRA_LIB_PATH${LIBRARY_PATH:+":$LIBRARY_PATH"}
export LD_LIBRARY_PATH=$EXTRA_LIB_PATH${LD_LIBRARY_PATH:+":$LD_LIBRARY_PATH"}
export PATH=$QT_PATH/bin:/usr/local/bin:$PATH
export PKG_CONFIG_PATH=$QT_PATH/lib/pkgconfig:/usr/local/lib/pkgconfig:${PKG_CONFIG_PATH:+":$PKG_CONFIG_PATH"}

RELEASE=1.5
GITHUB_RELEASE_ID=13297067
BRANCH=release/$RELEASE
DIR=UltraGrid-AppImage
APPDIR=UltraGrid.AppDir
GLIBC_VERSION=`ldd --version | head -n 1 | sed 's/.*\ \([0-9][0-9]*\.[0-9][0-9]*\)$/\1/'`
APPNAME=UltraGrid-$RELEASE.glibc${GLIBC_VERSION}-x86_64.AppImage
LABEL="Linux%20build%20%28AppImage%2C%20glibc%20$GLIBC_VERSION%29"
OAUTH=$(cat $HOME/github-oauth-token)

. ~/ultragrid_nightly_common.sh

cd /tmp
rm -rf $DIR

git clone -b $BRANCH https://github.com/CESNET/UltraGrid.git $DIR
#git clone -b devel https://github.com/MartinPulec/UltraGrid.git $DIR

cd $DIR/

./autogen.sh --disable-video-mixer --disable-lavc-hw-accel-vdpau --disable-lavc-hw-accel-vaapi --enable-plugins --enable-qt --enable-static-qt --enable-rtsp-server --with-live555=/usr/local # --with-deltacast=/root/VideoMasterHD --with-sage=/root/sage-graphics-read-only/ --with-dvs=/root/sdk4.2.1.1 --enable-gpl
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

mkdir $APPDIR/lib/fonts
cp -r /usr/share/fonts/dejavu/* $APPDIR/lib/fonts


# glibc libraries should not be bundled
# Taken from https://gitlab.com/probono/platformissues
# libnsl.so.1 is not removed - is not in Fedora 28 by default
for n in ld-linux.so.2 ld-linux-x86-64.so.2 libanl.so.1 libBrokenLocale.so.1 libcidn.so.1 libcrypt.so.1 libc.so.6 libdl.so.2 libm.so.6 libmvec.so.1 libnss_compat.so.2 libnss_db.so.2 libnss_dns.so.2 libnss_files.so.2 libnss_hesiod.so.2 libnss_nisplus.so.2 libnss_nis.so.2 libpthread.so.0 libresolv.so.2 librt.so.1 libthread_db.so.1 libutil.so.1
do
        if [ -f $APPDIR/lib/$n ]; then
                rm $APPDIR/lib/$n
        fi
done

( cd $APPDIR/lib; rm -f libasound.so.2 libdrm.so.2 libEGL.so.1 libGL.so.1 libGLdispatch.so.0 libstdc++.so.6 libX* libxcb* libxshm* )

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
export QT_QPA_FONTDIR=$DIR/lib/fonts

usage() {
	printf "usage:\n"
	printf "\tUltraGrid [--gui [args]]\n"
	printf "\t\tinvokes GUI\n"
	printf "\n"
	printf "\tUltraGrid --tool <t> [args]\n"
	printf "\t\tinvokes specified tool\n"
	printf "\t\ttool may be: $(ls $DIR/bin | tr '\n' ' ')\n"
	printf "\n"
	printf "\tUltraGrid args\n"
	printf "\t\tinvokes command-line UltraGrid\n"
	printf "\n"
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

appimagetool --sign --comp gzip $APPDIR $APPNAME

delete_asset $GITHUB_RELEASE_ID $APPNAME $OAUTH

curl -H "Authorization: token $OAUTH" -H 'Content-Type: application/gzip' -X POST "https://uploads.github.com/repos/CESNET/UltraGrid/releases/$GITHUB_RELEASE_ID/assets?name=$APPNAME&label=$LABEL" -T $APPNAME

cd ..
rm -rf $DIR

