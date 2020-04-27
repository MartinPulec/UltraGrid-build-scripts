QT=/usr/local/Qt-5.10.1
NDI=/NewTek_NDI_SDK

export CPATH=$CPATH${CPATH:+:}/opt/local/include:/usr/local/include:/usr/local/cuda/include:$QT/include:$NDI/include
export LIBRARY_PATH=/opt/local/lib:/usr/local/cuda/lib:$QT/lib:$NDI/lib/x64
export DYLD_LIBRARY_PATH=/usr/local/cuda/lib:$NDI/lib/x64
export PATH=/opt/local/bin:$PATH:/usr/local/bin:/usr/local/cuda/bin:$QT/bin
export PKG_CONFIG_PATH=$PKG_CONFIG_PATH${PKG_CONFIG_PATH:+:}/usr/local/lib/pkgconfig:$QT/lib/pkgconfig
#export PKG_CONFIG=/opt/local/bin/pkg-config
export AJA_DIRECTORY=/Users/toor/ntv2sdkmac
export EXTRA_LIB_PATH=$DYLD_LIBRARY_PATH # needed for make, see Makefile.in

