# Syphon insatll:
# xcodebuild 'LD_DYLIB_INSTALL_NAME=@executable_path/../Frameworks/Syphon.framework/Versions/A/Syphon'
./autogen.sh --enable-qt
make -j 12 gui-bundle
.github/scripts/macOS/sign.sh uv-qt.app
make osx-gui-dmg
