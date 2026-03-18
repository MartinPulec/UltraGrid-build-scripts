# Podepisování

S nastavením přístupu ke klíčence pro codesign je docela opruz -
přes uživatelský cron se mi to nepodařilo ani s asistencí GPT,
ani s klíčem v systémové klíčence (aby to codesign bylo ochotno
použít).

Řešením je uživatelská launch služba:
```
mv com.codesign.daily.plist ~/Library/LaunchAgent/
launchctl load ~/Library/LaunchAgent/com.codesign.daily.plist
```

Poznámky:
- poslední přákaz musí být spuštěn v GUI
- uživatel (xpulec) musí být přihlášen (ev. autologin), jinak se
služba nebude spouštět

debugování podepisování (problémová část):
např. `security -q find-identity -p codesigning build.keychain` (GPT nagenerue víc)

import klíče do klíčenky:
import_signing_key() v .github/scripts/environment.sh

Je nutné ještě dodat soubory notarytool-credentials (syntax v
.github/scripts/macOS/sign.sh) a github-oauth-token pro upload (dá se
nagenerovat ve Web UI). Natahují se v env.sh.

# Instalace macu

macport balíčky:
- asciidoctor
- autoconf
- automake
- cmake
- ffmpeg
- fluidsynth
- glew
- glfw
- ImageMagick
- jack
- jq
- libcaca
- libnatpmp
- libsdl2
- libsdl2_ttf
- libtool
- opencv4
- pkgconfig
- portaudio
- speexdsp
- wolfssl

volitelně:
- clang-18

dálě:
- Syphon (kompiluj s `xcodebuild .. MACOSX_DEPLOYMENT_TARGET=10.15`)
- NDI
- deltacast
- ximea
- libbacktrace
- libjuice
- libajantv2
- live555
- macdylibbundler

nefunguje (ale mohlo by jit zprovoznit?):
- cineform
- JPEG XS
- vulkan


Qt 6.1.3 (build fix https://trac.macports.org/ticket/68713), configure:
`../configure -release -nomake examples -opensource -confirm-license -prefix /usr/local/Qt-6.1.3`
