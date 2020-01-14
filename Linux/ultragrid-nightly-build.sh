#!/bin/bash -eu

# Usage:
# ultragrid-nightly-win64.sh [-i] [branches]
#      -i    - interactive mode - print output to console
#   branches - list of branches to build

if test "${1:-}" = "-i"; then
        shift
elif ! test -t 1; then
	exec > ~/ultragrid-nightly-build.log 2>&1 </dev/null
fi

set -x

export AJA_DIRECTORY=$HOME/ntv2sdk
export QT_SELECT=5
COV_PATH=/home/toor/cov-analysis-linux64-2019.03/bin/
QT_PATH=/usr/local/Qt-5.10.1
export CPATH=$QT_PATH/include:/usr/local/include${CPATH:+":$CPATH"}
export EXTRA_LIB_PATH=$QT_PATH/lib:/usr/local/cuda/lib64:/usr/local/lib
export LIBRARY_PATH=$EXTRA_LIB_PATH${LIBRARY_PATH:+":$LIBRARY_PATH"}
export LD_LIBRARY_PATH=$EXTRA_LIB_PATH${LD_LIBRARY_PATH:+":$LD_LIBRARY_PATH"}
export PATH=$QT_PATH/bin:$COV_PATH:/usr/local/bin:$PATH
export PKG_CONFIG_PATH=$QT_PATH/lib/pkgconfig:/usr/local/lib/pkgconfig:${PKG_CONFIG_PATH:+":$PKG_CONFIG_PATH"}

. ~/nightly-paths.sh

GLIBC_VERSION=`ldd --version | head -n 1 | sed 's/.*\ \([0-9][0-9]*\.[0-9][0-9]*\)$/\1/'`
APPDIR=UltraGrid.AppDir
ARCH=`uname -m`
DATE=`date +%Y%m%d`
DIR=UltraGrid-AppImage
OAUTH=$(cat $HOME/github-oauth-token)

. ~/ultragrid_nightly_common.sh

# key is BUILD
declare -A BRANCHES
BRANCHES["master"]=master
# if unset, default is to use the build name as a branch

# key is BUILD
declare -A CONF_FLAGS
# text needs to be disabled because it caused crashes of AppImage
CONF_FLAGS["default"]="--disable-cmpto-j2k --disable-text --disable-ndi"
CONF_FLAGS["devel"]="$COMMON_ENABLE_ALL_FLAGS --disable-jack-transport --enable-alsa --enable-cmpto-j2k --enable-v4l2"
CONF_FLAGS["ndi"]="--disable-cmpto-j2k --disable text --enable-ndi"

# key is BRANCH
declare -A GIT
GIT["master"]="https://github.com/CESNET/UltraGrid.git"
GIT["default"]="https://github.com/MartinPulec/UltraGrid.git"

DEFAULT_BUILD_LIST="master devel"

for BUILD in ${@:-$DEFAULT_BUILD_LIST}
do
	if [ "$BUILD" = master ]; then
		SUFF=""
		LABEL_SUFF=""
	else
		SUFF="-$BUILD"
		LABEL_SUFF="%2C%20$BUILD"
	fi

	APPNAME=UltraGrid${SUFF}-${DATE}.glibc${GLIBC_VERSION}-${ARCH}.AppImage
	APPNAME_GLOB="UltraGrid${SUFF}-*-${ARCH}.AppImage"
	APPNAME_PATTERN="UltraGrid${SUFF}-[[:digit:]]\{8\}\.glibc$(echo $GLIBC_VERSION | sed 's/\./\\./g')-${ARCH}\.AppImage"
	LABEL="Linux%20build%20%28AppImage%2C%20$ARCH%2C%20glibc%20$GLIBC_VERSION$LABEL_SUFF%29"
	BRANCH=${BRANCHES[$BUILD]-$BUILD}

	cd /tmp
	rm -rf $DIR

	git clone -b $BRANCH ${GIT[$BRANCH]-${GIT["default"]}} $DIR
	#git clone -b devel https://github.com/MartinPulec/UltraGrid.git $DIR

	cd $DIR/

	./autogen.sh --disable-video-mixer --enable-plugins --enable-qt --enable-static-qt --enable-cineform ${CONF_FLAGS[$BUILD]-${CONF_FLAGS["default"]}} # --disable-lavc-hw-accel-vdpau --disable-lavc-hw-accel-vaapi --with-deltacast=/root/VideoMasterHD --with-sage=/root/sage-graphics-read-only/ --with-dvs=/root/sdk4.2.1.1 --enable-gpl

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

	( cd $APPDIR/lib; rm -f libasound.so.2 libdrm.so.2 libEGL.so.1 libGL.so.1 libGLdispatch.so.0 libstdc++.so.6  libX11-xcb.so.1 libX11.so.6 libXau.so.6 libXcursor.so.1 libXdmcp.so.6 libXext.so.6 libXfixes.so.3 libXi.so.6 libXinerama.so.1 libXrandr.so.2 libXrender.so.1 libXtst.so.6 libXxf86vm.so.1 libxcb* libxshm* )

	( cd $APPDIR/lib; rm -f libcmpto* ) # remove non-free components
	# indention inside heredoc should be leading tab and then spaces
	cat <<-'EOF' >> $APPDIR/uv-wrapper.sh
	#!/bin/sh

	set -u

	get_loader() {
	        LOADERS='/lib64/ld-linux-*so* /lib/ld-linux-*so* /lib*/ld-linux-*so*'
	        for n in $LOADERS; do
	                for m in `ls $n`; do
	                        if [ -x $m ]; then
	                                echo $m
	                                return
	                        fi
	                done
	        done
	}

	set_ld_preload() {
	        if [ ! -f $DIR/lib/ultragrid/ultragrid_aplay_jack.so ]; then
	                return
	        fi
	        local LOADER=$(get_loader)
	        if [ ! -x "$LOADER" ]; then
	                return
	        fi
	        S_LD_LIBRARY_PATH=$LD_LIBRARY_PATH
	        LD_LIBRARY_PATH=
	        JACK_LIB=$(LD_TRACE_LOADED_OBJECTS=1 $LOADER $DIR/lib/ultragrid/ultragrid_aplay_jack.so | grep libjack | grep -v 'not found' | awk '{print $3}')
	        LD_LIBRARY_PATH=$S_LD_LIBRARY_PATH
	        if [ -n "$JACK_LIB" ]; then
	                export LD_PRELOAD=$JACK_LIB${LD_PRELOAD:+" $LD_PRELOAD"}
	        fi
	}

	DIR=`dirname $0`
	export LD_LIBRARY_PATH=$DIR/lib${LD_LIBRARY_PATH:+":$LD_LIBRARY_PATH"}
	# there is an issue with running_from_path() which evaluates this executable
	# as being system-installed
	#export PATH=$DIR/bin:$PATH
	set_ld_preload

	exec $DIR/bin/uv "$@"
	EOF

	chmod 755 $APPDIR/uv-wrapper.sh

	cat <<-'EOF' >> $APPDIR/AppRun
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
	        printf "\tUltraGrid --help\n"
	        printf "\t\tprints this help\n"
	        printf "\n"
	        printf "\tUltraGrid --appimage-help\n"
	        printf "\t\tprints AppImage related options\n"
	        printf "\n"
	        printf "\tUltraGrid --update\n"
	        printf "\t\tupdates AppImage\n"
	        printf "\n"
	        printf "\tUltraGrid --tool uv --help\n"
	        printf "\t\tprints command-line UltraGrid help\n"
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
	elif [ x"$1" = x"-u" -o x"$1" = x"--update" ]; then
	        $DIR/appimageupdatetool $APPIMAGE
	        exit 0
	else
	        $DIR/uv-wrapper.sh "$@"
	fi

	exit $?
	EOF
	chmod 755 $APPDIR/AppRun

	cp data/ultragrid.png $APPDIR/ultragrid.png
	ln -s ultragrid.png $APPDIR/.DirIcon
	cp data/uv-qt.desktop $APPDIR/ultragrid.desktop
	wget https://github.com/AppImage/AppImageUpdate/releases/download/continuous/appimageupdatetool-x86_64.AppImage -O $APPDIR/appimageupdatetool
	chmod ugo+x $APPDIR/appimageupdatetool

	ZSYNC=UltraGrid-nightly-latest-Linux-x86_64.AppImage.zsync
	appimagetool --sign --comp gzip -u "zsync|https://github.com/CESNET/UltraGrid/releases/download/nightly/$ZSYNC" $APPDIR $APPNAME

	if [ "$BUILD" = "devel" ]; then
		rm $HOME/public_html/ug-devel/$APPNAME_GLOB || true
		cp $APPNAME $HOME/public_html/ug-devel
	else
		delete_asset 4347706 $APPNAME_PATTERN $OAUTH
		curl -H "Authorization: token $OAUTH" -H 'Content-Type: application/gzip' -X POST 'https://uploads.github.com/repos/CESNET/UltraGrid/releases/4347706/assets?name='$APPNAME'&label='$LABEL -T $APPNAME
		if [ "$BUILD" = "master" ]; then
			zsyncmake -C $APPNAME
			mv $APPNAME.zsync $ZSYNC
			delete_asset 4347706 $ZSYNC $OAUTH
			curl -H "Authorization: token $OAUTH" -H 'Content-Type: application/x-zsync' -X POST 'https://uploads.github.com/repos/CESNET/UltraGrid/releases/4347706/assets?name='$ZSYNC -T $ZSYNC
		fi
	fi

	cd ..
	rm -rf $DIR

done

# vim: set noexpandtab tw=0:
