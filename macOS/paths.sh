QT=/usr/local/Qt-5.10.1
NDI=/Library/NDI
NDI_LIB=$NDI/lib/macOS

export CPATH=$CPATH${CPATH:+:}/opt/local/include:/usr/local/include:/usr/local/cuda/include:$QT/include:$NDI/include
export LIBRARY_PATH=/opt/local/lib:/usr/local/lib:/usr/local/cuda/lib:$QT/lib:$NDI_LIB
export PATH=/opt/local/bin:$PATH:/usr/local/bin:/usr/local/cuda/bin:$QT/bin
export PKG_CONFIG_PATH=$PKG_CONFIG_PATH${PKG_CONFIG_PATH:+:}/usr/local/lib/pkgconfig:$QT/lib/pkgconfig
PKG_CONFIG_PATH=/opt/local/libexec/ffmpeg7/lib/pkgconfig:$PKG_CONFIG_PATH
#export PKG_CONFIG=/opt/local/bin/pkg-config
export DYLD_LIBRARY_PATH=/usr/local/cuda/lib:/usr/local/lib:$NDI_LIB
export EXTRA_LIB_PATH=$DYLD_LIBRARY_PATH # needed for make, see Makefile.in, old UltraGrid, TOREMOVE
export DYLIBBUNDLER_FLAGS="-s /usr/local/cuda/lib -s $NDI_LIB -s /usr/local/lib -s /opt/local/lib" # new UG

export SDKROOT=/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX10.11.sdk
# export COMMON_OSX_FLAGS="-iframework $(xcrun --show-sdk-path)/System/Library/Frameworks"
export COMMON_OSX_FLAGS="-F/Library/Frameworks"
