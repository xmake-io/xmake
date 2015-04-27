#!/bin/sh
rm .config.mak
make f DEBUG=n
make r
exit
