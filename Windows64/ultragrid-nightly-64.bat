if [%1]==[] goto noparam
c:\msys64\usr\bin\bash --login -c /home/toor/ultragrid-nightly-win64.sh %1
goto :eof

:noparam
REM SET PATH=c:/msys64;c:/msys64/mingw64/bin;c:/msys64/usr/bin;%PATH%

REM c:\msys64\usr\bin\bash --login -c /home/toor/ultragrid-nightly-win64-release.sh
REM c:\msys64\usr\bin\bash --login -c /home/toor/ultragrid-nightly-win64.sh
