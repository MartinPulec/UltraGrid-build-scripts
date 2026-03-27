FROM almalinux:8

WORKDIR /build

RUN dnf -y install clang
RUN dnf -y install git
RUN dnf -y install autoconf automake pkgconf
ENV CC clang-20
ENV CXX clang++-20
RUN dnf install -y make
RUN dnf -y install 'dnf-command(config-manager)'
RUN dnf config-manager --set-enabled powertools
RUN dnf -y install epel-release
RUN dnf -y install https://download1.rpmfusion.org/free/el/rpmfusion-free-release-8.noarch.rpm
RUN dnf -y install https://download1.rpmfusion.org/nonfree/el/rpmfusion-nonfree-release-8.noarch.rpm
RUN dnf -y install ffmpeg
RUN dnf -y install glew-devel glfw-devel
RUN dnf -y install qt5-devel
RUN dnf -y install ffmpeg-devel
RUN dnf -y install  soxr-devel speexdsp-devel
#RUN ./autogen.sh --enable-qt --enable-gl-display --enable-libavcodec --enable-gpujpeg
RUN dnf config-manager --add-repo https://developer.download.nvidia.com/compute/cuda/repos/rhel8/x86_64/cuda-rhel8.repo
RUN dnf -y install cmake cuda-compiler-11-8 cuda-cudart-11-8
ENV CUDACXX /usr/local/cuda-11.8/bin/nvcc
RUN git clone https://github.com/CESNET/GPUJPEG.git gpujpeg && mkdir gpujpeg/build
RUN dnf -y install cuda-cudart-devel-11-8
RUN cd gpujpeg/build && cmake -DCMAKE_CUDA_ARCHITECTURES=35 .. && make -j $(nproc) install
RUN dnf -y install which # qmake needs this
RUN dnf -y install openssl-devel
RUN dnf -y install libcurl-devel opencv-devel SDL2-devel SDL2_ttf-devel
RUN dnf -y install ImageMagick-devel
RUN dnf -y install libtool # pcp
RUN dnf -y install libnatpmp-devel
ENV PKG_CONFIG_PATH /usr/local/lib/pkgconfig:/usr/local/lib64/pkgconfig
RUN dnf -y install nasm # svt jpeg xs
RUN dnf -y install mesa-vulkan-devel vulkan-headers vulkan-loader
RUN dnf -y install meson dbus-devel
# last one supporting meson 0.53.2 in U20.04
RUN git clone https://github.com/PipeWire/pipewire && cd pipewire && git checkout 19bcdaebe29b95edae2b285781dab1cc841be638 &&\
./autogen.sh -Dtests=disabled && make -j "$(nproc)"
RUN git clone https://github.com/CESNET/UltraGrid.git ultragrid
WORKDIR /build/ultragrid
RUN .github/scripts/install-common-deps.sh
RUN .github/scripts/Linux/install_others.sh ndi svt_jpegxs 

RUN dnf -y install sudo # ximea installer
RUN XIMEA_DOWNLOAD_URL=https://www.ximea.com\
$(curl -f https://www.ximea.com/software-downloads | \
                grep -v 35adfeed-8e15-4b4d-8364-bd5a65cba5c4 | \
                sed -n "/Linux_SP.tgz/"\
' { s-^.*\(/getattachment[^"]*\).*$-\1-; p; }' | head -n 1) \
.github/scripts/Linux/install_others.sh ximea

RUN dnf -y install file # mkappimage
