#!/bin/bash -eu

install_cineform() {
(
        cd /tmp
        rm -rf cineform-sdk
        git clone https://github.com/gopro/cineform-sdk.git
        cd cineform-sdk
        /c/Program\ Files\ \(x86\)/Microsoft\ Visual\ Studio/2019/Community/Common7/IDE/CommonExtensions/Microsoft/CMake/CMake/bin/cmake.exe -DBUILD_STATIC=false -G "Visual Studio 16 2019" -A x64
        /c/Program\ Files\ \(x86\)/Microsoft\ Visual\ Studio/2019/Community/MSBuild/Current/Bin/MSBuild.exe CineFormSDK.sln -property:Configuration=Release
        cp Release/CFHDCodec.dll /usr/local/bin
        cp Release/CFHDCodec.lib /usr/local/lib
        cp Common/* /usr/local/include
        cp libcineformsdk.pc /usr/local/lib/pkgconfig/
        cd /tmp
        rm -rf cineform-sdk
)
}

install_ffmpeg() {
(
        cd /tmp
        rm -rf ffmpeg-latest-*
        wget https://ffmpeg.zeranoe.com/builds/win64/dev/ffmpeg-latest-win64-dev.zip
        wget https://ffmpeg.zeranoe.com/builds/win64/shared/ffmpeg-latest-win64-shared.zip
        unzip ffmpeg-latest-win64-dev.zip
        unzip ffmpeg-latest-win64-shared.zip
        cp -r ffmpeg-latest-win64-dev/include/* /usr/local/include
        cp -r ffmpeg-latest-win64-dev/lib/* /usr/local/lib
        cp -r ffmpeg-latest-win64-shared/bin/* /usr/local/bin
        rm -rf ffmpeg-latest-*
)
}

install_gpujpeg() {
(
        cd /tmp
        rm -rf gpujpeg
        git clone https://github.com/CESNET/GPUJPEG.git gpujpeg
        cd gpujpeg

        #export MSVC_PATH=/c/Program\ Files\ \(x86\)/Microsoft\ Visual\ Studio\ 12.0/
        #export PATH=$PATH:$MSVC_PATH/Common7/IDE/:$MSVC_PATH/VC/bin/
        #export PATH=$PATH:$CUDA_PATH\\bin
        #export INCLUDE=.

        nvcc -DGPUJPEG_EXPORTS -o gpujpeg.dll --shared src/gpujpeg_*c src/gpujpeg*cu

        cp gpujpeg.lib /usr/local/lib
        cp gpujpeg.dll /usr/local/bin
        cp -r libgpujpeg /usr/local/include

        cd ..
        rm -rf gpujpeg
)
}
install_cineform
install_ffmpeg
install_gpujpeg

