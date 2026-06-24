#!/bin/sh -eu

GITHUB_TOKEN=$(cat ~/gh_token.txt)
OC_TOKEN=$(cat ~/owncloud_token.txt)
GITHUB_REPOSITORY=CESNET/UltraGrid
today=$(date +%Y-%m-%d)
DIR=$HOME/public_html/ug-nightly-archive/$today
TAG=continuous

atexit() {
	cd
	rm -rf "${tmpdir?}"
}

tmpdir=$(mktemp -d)
trap atexit EXIT

cd $tmpdir

# JSON=$(mktemp)
JSON=continuous.json

curl -Ss -X MKCOL\
 "https://owncloud.cesnet.cz/remote.php/webdav/ug-nightly-archive/$today"\
 --user "pulec@cesnet.cz:$OC_TOKEN"

curl -s -S -X GET https://api.github.com/repos/$GITHUB_REPOSITORY/releases/tags/continuous -o $JSON
RELEASE_ID=$(jq -r '.id' $JSON) # -H "Authorization: token $GITHUB_TOKEN"
for n in `curl -s -X GET https://api.github.com/repos/$GITHUB_REPOSITORY/releases/$RELEASE_ID/assets | grep browser_download_url | awk '{print $2}' | tr -d \"`; do
	# wget -q -P $DIR $n
	wget -q "$n"
	name=$(basename "$n")
	curl -Ss -T "$name" "https://owncloud.cesnet.cz/remote.php/webdav/\
ug-nightly-archive/$today/" --user "pulec@cesnet.cz:$OC_TOKEN"
done

