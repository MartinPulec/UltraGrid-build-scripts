#!/bin/sh

exec > ~/ultragrid-nightly.log 2>&1

set -e
set -x

cd /tmp

# checkout current build script
atexit() {
        TMPDIR=$(mktemp -d)
        git clone ~/ultragrid-build $TMPDIR
        cp -r $TMPDIR/Linux/*sh /var/tmp
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
curl -H "Authorization: token 54a22bf35bc39262b60007e79101c978a3a2ff0c" -X PATCH https://api.github.com/repos/CESNET/UltraGrid/releases/4347706 -T - <<'EOF'
{
  "tag_name": "nightly",
  "target_commitish": "master",
  "name": "",
  "body": "",
  "draft": false,
  "prerelease": true
}
EOF

