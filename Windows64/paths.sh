export PATH=/mingw64/bin:/usr/local/bin:/usr/bin`[ -n "$PATH" ] && echo :$PATH`
CUDA_PATH_C=`cygpath "$CUDA_PATH"`
export PATH=$PATH:$CUDA_PATH_C/bin
export CPATH=/usr/local/include`[ -n "$CPATH" ] && echo :$CPATH`
export PKG_CONFIG_PATH=$PKG_CONFIG_PATH:/mingw64/lib/pkgconfig
export LIBRARY_PATH=/usr/local/lib`[ -n "$LIBRARY_PATH" ] && echo :$LIBRARY_PATH`
export CPATH=$CPATH:$CUDA_PATH_C/include
export MSVC11_PATH=/c/Program\ Files\ \(x86\)/Microsoft\ Visual\ Studio\ 11.0/
export MSVC12_PATH=/c/Program\ Files\ \(x86\)/Microsoft\ Visual\ Studio\ 12.0/
export PATH=$PATH:$MSVC12_PATH/Common7/IDE/:$MSVC12_PATH/VC/bin/

