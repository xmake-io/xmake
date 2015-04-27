#!/bin/sh
if [ -f .config.mak ]; then 
    rm .config.mak
fi
make f DEBUG=n PLAT=msvc ARCH=x86
make r
exit
