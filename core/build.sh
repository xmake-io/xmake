#!/bin/sh
if [ -f .config.mak ]; then 
    rm .config.mak
fi
make f DEBUG=n PLAT=msvc ARCH=x86
make r
if [ $? -ne 0 ]; then 
    make o
fi
exit
