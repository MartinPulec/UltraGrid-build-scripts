export PATH=/mingw64/bin:/usr/local/bin:/usr/bin`[ -n "$PATH" ] && echo :$PATH`
export PATH=$PATH:$CUDA_PATH\\bin
export CPATH=/usr/local/include`[ -n "$CPATH" ] && echo :$CPATH`
export PKG_CONFIG_PATH=$PKG_CONFIG_PATH:/mingw64/lib/pkgconfig
export LIBRARY_PATH=/usr/local/lib`[ -n "$LIBRARY_PATH" ] && echo :$LIBRARY_PATH`
export LIBRARY_PATH=$LIBRARY_PATH:~/gpujpeg/x64/Release
export CPATH=$CPATH:~/gpujpeg/:$CUDA_PATH/include
