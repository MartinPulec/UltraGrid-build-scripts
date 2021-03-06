#!/bin/bash

install_cineform() {
(
        cd /tmp
        rm -rf cineform-sdk
        git clone https://github.com/gopro/cineform-sdk.git
        cd cineform-sdk
        cmake . && make CFHDCodecStatic
        sudo cp libCFHDCodec.a /usr/local/lib
        sudo cp Common/* /usr/local/include
        sudo cp libcineformsdk.pc /usr/local/lib/pkgconfig/
        cd /tmp
        rm -rf cineform-sdk
)
}

install_gpujpeg() {
(
        cd /tmp
        rm -rf gpujpeg
        git clone https://github.com/CESNET/GPUJPEG.git gpujpeg
        mkdir gpujpeg/build
        cd gpujpeg/build
        cmake -DCMAKE_CXX_STANDARD=11 -DCMAKE_CXX_STANDARD_REQUIRED=YES ..
        cmake --build .
        sudo cmake --install .
        cd ../..
        rm -rf gpujpeg
)
}

install_cineform
install_gpujpeg

