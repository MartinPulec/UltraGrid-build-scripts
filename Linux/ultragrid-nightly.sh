#!/bin/sh

exec > ~/ultragrid-nightly.log 2>&1 </dev/null

set -e
set -x

OAUTH=$(cat $HOME/github-oauth-token)

. ~/ultragrid_nightly_common.sh

cd /tmp

# checkout current build script
atexit() {
        TMPDIR=$(mktemp -d)
        git clone https://github.com/MartinPulec/UltraGrid-build-scripts.git $TMPDIR
        cp -r $TMPDIR/Linux/*sh $HOME
        cp $TMPDIR/ultragrid_nightly_common.sh $HOME
        crontab $TMPDIR/Linux/crontab
        rm -r $TMPDIR
}
trap atexit EXIT

rm -rf ultragrid-nightly

git clone https://github.com/CESNET/UltraGrid.git ultragrid-nightly

cd ultragrid-nightly

git tag -d nightly
git tag nightly
git push -f git@github.com:CESNET/UltraGrid.git refs/tags/nightly:refs/tags/nightly

cd ..

rm -r ultragrid-nightly

# when overriding a tag, GITHUB makes from pre-relase a draft again - we need to release it again
curl -H "Authorization: token $OAUTH" -X PATCH https://api.github.com/repos/CESNET/UltraGrid/releases/4347706 -T - <<'EOF'
{
  "tag_name": "nightly",
  "target_commitish": "master",
  "name": "nightly builds",
  "body": "Current builds from GIT master branch. Here are [archived builds](https://147.251.54.146:8443/ug-nightly-archive/).",
  "draft": false,
  "prerelease": true
}
EOF

