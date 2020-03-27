#!/bin/sh

exec > ~/ultragrid-nightly.log 2>&1 </dev/null

set -e
set -x

OAUTH=$(cat $HOME/github-oauth-token)

. ~/ultragrid_nightly_common.sh

## Make and upload doxygen documentation to frakira.
## Must be called inside UltraGrid source directory.
mk_upload_doxy() {
         doxygen Doxyfile
         scp -r documentation xpulec@frakira:public_html/ultragrid-doxygen-new
         ssh xpulec@frakira rm -rf public_html/ultragrid-doxygen
         ssh xpulec@frakira mv public_html/ultragrid-doxygen-new public_html/ultragrid-doxygen
}

cd /tmp

# checkout current build script
atexit() {
        TMPDIR=$(mktemp -d)
        git clone https://github.com/MartinPulec/UltraGrid-build-scripts.git $TMPDIR
        cp -r $TMPDIR/Linux/*sh $HOME
        cp $TMPDIR/ultragrid_nightly_common.sh $HOME
        crontab $TMPDIR/Linux/crontab
        rm -rf $TMPDIR
}
trap atexit EXIT

rm -rf ultragrid-nightly

git clone https://github.com/CESNET/UltraGrid.git ultragrid-nightly

cd ultragrid-nightly

mk_upload_doxy

do_not_run() {
        git tag -d nightly
        git tag nightly
        git push -f git@github.com:CESNET/UltraGrid.git refs/tags/nightly:refs/tags/nightly

        # when overriding a tag, GITHUB makes from pre-relase a draft again - we need to release it again
        curl -H "Authorization: token $OAUTH" -X PATCH https://api.github.com/repos/CESNET/UltraGrid/releases/4347706 -T - <<'EOF'
        {
          "tag_name": "nightly",
          "target_commitish": "master",
          "name": "nightly builds",
          "body": "Current builds from GIT master branch. Here are [archived builds](https://frakira.fi.muni.cz/~xpulec/ug-nightly-archive/).",
          "draft": false,
          "prerelease": true
        }
        EOF
}

cd ..
rm -r ultragrid-nightly

