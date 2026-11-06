#!/bin/sh -e

export GIT_DIR="$PWD"/ultragrid/.git
if [ -d "$GIT_DIR" ]; then
  cd ultragrid
  git fetch http://github.com/CESNET/UltraGrid.git master
  git checkout FETCH_HEAD
else
  git clone --depth 1 http://github.com/CESNET/UltraGrid.git ultragrid
  cd ultragrid
fi
git fetch --shallow-since=2026-10-31
git fetch --shallow-since=2026-10-31 https://github.com/MartinPulec/UltraGrid.git compat
git merge FETCH_HEAD
git config safe.directory '*'
./autogen.sh # generate configure + al.
make distclean # remove dist files
cd -

docker run -ti --rm -v "$PWD":/root/mnt ultragrid-alma8 /root/mnt/build.sh
