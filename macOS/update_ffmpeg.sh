#!/bin/sh -exu

[ "$UID" -eq 0 ] || exec sudo "$0" "$@"

cd /tmp
rm -rf ffmpeg

git clone git://source.ffmpeg.org/ffmpeg.git


cd ffmpeg

./configure --prefix=/usr/local/share/ffmpeg --enable-gpl --disable-sdl2 --enable-libx264  --enable-libx265  --enable-videotoolbox --enable-audiotoolbox --enable-libopus --enable-libspeex --enable-libvpx # --enable-vda
make -j 42 && sudo make install
sudo cp -r /usr/local/share/ffmpeg/lib/pkgconfig/ /usr/local/share/ffmpeg/lib/pkgconfig-static/
for n in avcodec avdevice avfilter avformat avutil postproc swresample swscale; do
  sudo sed -i.bkp "s/^Libs:\(.*\)-l${n}/Libs:\1\/usr\/local\/share\/ffmpeg\/lib\/lib${n}.a/" /usr/local/share/ffmpeg/lib/pkgconfig-static/lib${n}.pc
done

./configure --prefix=/usr/local/share/ffmpeg-notoolbox --enable-gpl --disable-sdl2 --enable-libx264  --enable-libx265  --disable-videotoolbox --disable-audiotoolbox --enable-libopus --enable-libspeex --enable-libvpx # --enable-vda
make -j 42 && sudo make install
sudo cp -r /usr/local/share/ffmpeg-notoolbox/lib/pkgconfig/ /usr/local/share/ffmpeg-notoolbox/lib/pkgconfig-static/
 for n in avcodec avdevice avfilter avformat avutil postproc swresample swscale; do
  sudo sed -i.bkp "s/^Libs:\(.*\)-l${n}/Libs:\1\/usr\/local\/share\/ffmpeg-notoolbox\/lib\/lib${n}.a/" /usr/local/share/ffmpeg-notoolbox/lib/pkgconfig-static/lib${n}.pc
done

