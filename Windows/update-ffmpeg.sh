#!/bin/bash
wget https://ffmpeg.zeranoe.com/builds/win32/dev/ffmpeg-latest-win32-dev.zip
wget https://ffmpeg.zeranoe.com/builds/win32/shared/ffmpeg-latest-win32-shared.zip
rm -f ffmpeg-latest-win32-dev
rm -f ffmpeg-latest-win32-shared
unzip ffmpeg-latest-win32-dev.zip
unzip ffmpeg-latest-win32-shared.zip
cp -r ffmpeg-latest-win32-dev/include/* /usr/local/include
cp -r ffmpeg-latest-win32-dev/lib/* /usr/local/lib
cp -r ffmpeg-latest-win32-shared/bin/* /usr/local/bin
