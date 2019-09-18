delete_asset() {
        RELEASE_ID=${1?}
        PATTERN=${2?}
        OAUTH=${3?}
	curl -H "Authorization: token $OAUTH" -X GET https://api.github.com/repos/CESNET/UltraGrid/releases/$RELEASE_ID/assets > assets.json
	LEN=`jq "length" assets.json`
	for n in `seq 0 $(($LEN-1))`; do
		NAME=`jq '.['$n'].name' assets.json`
		if expr "$NAME" : "\"$PATTERN\"$"; then
                        ID=`jq '.['$n'].id' assets.json`
                        curl -H "Authorization: token $OAUTH" -X DELETE "https://api.github.com/repos/CESNET/UltraGrid/releases/assets/$ID"
		fi
	done
}

COMMON_ENABLE_ALL_FLAGS="--enable-all --disable-alsa --disable-bluefish444 --disable-cmpto-j2k --disable-coreaudio --disable-deltacast --disable-dshow --disable-dvs --disable-lavc-hw-accel-vaapi --disable-lavc-hw-accel-vdpau --disable-sage --disable-sdl1 --disable-syphon --disable-spout --disable-v4l2 --disable-wasapi"
# todo - remove deltacast
