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

