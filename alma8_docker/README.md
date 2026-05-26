## Prepare build environment

```
docker build -f Dockerfile -t ultragrid-alma8 .
```

##  Run (actual build)

Run `docker_build.sh` where the above image is prepared. This will
clone/update ultragrid/ subdirectory used by the actuall build.

If you do not want to build from upstream, just place your code to
ultragrid/ subdir as `docker_build.sh` does and run (last line) from
the script:
```
docker run -ti --rm -v "$PWD":/root/mnt ultragrid-alma8 /root/mnt/build.sh
```

(optionally configure for root-owned files not to leak from Docker run
to ultragrid/ directory - in `ultragrid/` run `./autogen.sh && make clean`)
