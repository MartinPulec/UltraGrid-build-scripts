if [ "${env_included-}" ]; then
	return
fi

env_included=1

export MACOSX_DEPLOYMENT_TARGET=10.15
# libc++ from  m10.15 is no llonger supported by clang 22
export CC=clang-mp-21
export CXX=clang++-mp-21

PATH=/opt/local/bin:/usr/local/bin:$PATH

QT_PATH=/usr/local/Qt-6.1.3
PATH=$PATH:$QT_PATH/bin

export PKG_CONFIG_PATH=/opt/local/include/pkgconf/libpkgconf
PKG_CONFIG_PATH="$PKG_CONFIG_PATH:/usr/local/lib/pkgconfig"
PKG_CONFIG_PATH="$PKG_CONFIG_PATH:/opt/local/lib/opencv4/pkgconfig"
export CPATH=/opt/local/include
export CPATH=${CPATH:+"$CPATH:"}/Library/NDI/include

export COMMON_OSX_FLAGS="-F/Library/Frameworks"

export LIBRARY_PATH=/opt/local/lib
export DYLD_LIBRARY_PATH=/usr/local/lib

export DYLIBBUNDLER_FLAGS="-s /usr/local/lib"
DYLIBBUNDLER_FLAGS="$DYLIBBUNDLER_FLAGS -s /opt/local/lib"
DYLIBBUNDLER_FLAGS="$DYLIBBUNDLER_FLAGS -s /Library/Frameworks"

export KEY_CHAIN=build.keychain
export KEY_CHAIN_PASS=dummy

export notarytool_credentials=$(cat $HOME/notarytool-credentials)

export OAUTH=$(cat $HOME/github-oauth-token)
