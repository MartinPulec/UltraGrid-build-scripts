export PATH=/usr/local/bin:/usr/bin:/bin:/mingw32/bin`[ -n "$PATH" ] && echo :$PATH`
export CPATH=/usr/local/include`[ -n "$CPATH" ] && echo :$CPATH`
export LIBRARY_PATH=/usr/local/lib`[ -n "$LIBRARY_PATH" ] && echo :$LIBRARY_PATH`
export DELTACAST_DIRECTORY=~/VideoMasterHD
export DVS_DIRECTORY=~/sdk4.2.1.1

export CUDA_DIRECTORY=/c/Program\ Files/NVIDIA\ GPU\ Computing\ Toolkit/CUDA/v9.2
export MSVC_PATH=/c/Program\ Files\ \(x86\)/Microsoft\ Visual\ Studio\ 12.0/
export MSVC_PATH_W='C:\Program Files (x86)\Microsoft Visual Studio 12.0'

#export LIBRARY_PATH=$LIBRARY_PATH:~/gpujpeg/Release/
export CPATH=$CPATH:~/gpujpeg/:$CUDA_DIRECTORY/include
export PATH=$PATH:$MSVC_PATH/Common7/IDE/:$MSVC_PATH/VC/bin/:$CUDA_DIRECTORY/bin
export LIBRARY_PATH=$LIBRARY_PATH:$CUDA_PATH/lib/Win32/

export CPATH=$CPATH:~/pdcurses/
export LIBRARY_PATH=$LIBRARY_PATH:~/pdcurses/
export PKG_CONFIG_PATH=$PKG_CONFIG_PATH:/mingw32/lib/pkgconfig

#export CPATH=$CPATH:/c/Program\ Files\ \(x86\)/AJA/NTV2SDK/APIandSamples/ntv2projects/includes/:/c/Program\ Files\ \(x86\)/AJA/NTV2SDK/APIandSamples/ntv2projects/classes/:/c/Program\ Files\ \(x86\)/AJA/NTV2SDK/APIandSamples/ntv2projects/democlasses/:/c/Program\ Files\ \(x86\)/AJA/NTV2SDK/APIandSamples/ntv2projects/winclasses/:/c/Program\ Files\ \(x86\)/AJA/NTV2SDK/APIandSamples/ajaapi/
#export LIBRARY_PATH=$LIBRARY_PATH:/c/Program\ Files\ \(x86\)/AJA/NTV2SDK/APIandSamples/lib/Win32/
