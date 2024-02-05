./autogen.sh --enable-qt
make -j 12 gui-bundle
.github/scripts/macOS/sign.sh uv-qt.app
make osx-gui-dmg
