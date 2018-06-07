#!/bin/bash
rm ffmpeg-latest-win64-dev.zip
rm ffmpeg-latest-win64-shared.zip
wget https://ffmpeg.zeranoe.com/builds/win64/dev/ffmpeg-latest-win64-dev.zip
wget https://ffmpeg.zeranoe.com/builds/win64/shared/ffmpeg-latest-win64-shared.zip
rm -r ffmpeg-latest-win64-dev
rm -r ffmpeg-latest-win64-shared
unzip ffmpeg-latest-win64-dev.zip
unzip ffmpeg-latest-win64-shared.zip
cp -r ffmpeg-latest-win64-dev/include/* /usr/local/include
cp -r ffmpeg-latest-win64-dev/lib/* /usr/local/lib
cp -r ffmpeg-latest-win64-shared/bin/* /usr/local/bin
