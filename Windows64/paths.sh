export PATH=/mingw64/bin:/usr/local/bin:/usr/bin`[ -n "$PATH" ] && echo :$PATH`
export CUDA_PATH='C:\Program Files\NVIDIA GPU Computing Toolkit\CUDA\v10.1'
CUDA_PATH_C=`cygpath "$CUDA_PATH"`
export PATH=$PATH:$CUDA_PATH_C/bin
export CPATH=/usr/local/include`[ -n "$CPATH" ] && echo :$CPATH`
export PKG_CONFIG_PATH=$PKG_CONFIG_PATH:/mingw64/lib/pkgconfig
export LIBRARY_PATH=/usr/local/lib`[ -n "$LIBRARY_PATH" ] && echo :$LIBRARY_PATH`
export CPATH=$CPATH:$CUDA_PATH_C/include
export MSVC16_PATH=/c/Program\ Files\ \(x86\)/Microsoft\ Visual\ Studio/2019/Community/VC/Tools/MSVC/14.22.27905/bin/HostX64/x64
export PATH=$PATH:$MSVC16_PATH

