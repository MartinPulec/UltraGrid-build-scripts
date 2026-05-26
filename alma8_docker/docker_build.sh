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
git config safe.directory '*'
./autogen.sh # generate configure + al.
make distclean # remove dist files
cd -

docker run -ti --rm -v "$PWD":/root/mnt ultragrid-alma8 /root/mnt/build.sh
