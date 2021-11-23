#!/bin/sh -eu

#GITHUB_TOKEN=XXXXXXXXXXXXXXXXXXXXXXXXXXXXX # perhaps not needed
GITHUB_REPOSITORY=CESNET/UltraGrid
DIR=$HOME/public_html/ug-nightly-archive/$(date +%Y%m%d)
TAG=continuous
JSON=$(mktemp)

curl -s -S -X GET https://api.github.com/repos/$GITHUB_REPOSITORY/releases/tags/continuous -o $JSON
RELEASE_ID=$(jq -r '.id' $JSON) # -H "Authorization: token $GITHUB_TOKEN"
for n in `curl -s -X GET https://api.github.com/repos/$GITHUB_REPOSITORY/releases/$RELEASE_ID/assets | grep browser_download_url | awk '{print $2}' | tr -d \"`; do
	wget -q -P $DIR $n
done

rm $JSON

