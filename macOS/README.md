# Notes

## Dylibbundler

Install dylibbundler v2 with a wrapper if mac/XCode doesn't support codesigning:
```
#!/bin/sh
dylibbundler-real -ns "$@"
```
