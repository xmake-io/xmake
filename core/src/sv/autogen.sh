#!/bin/sh
# autogen.sh --
#
# Run this in the top source directory to rebuild the infrastructure.

LIBTOOLIZE=${LIBTOOLIZE:=libtoolize}

set -xe
test -d m4 || mkdir -p m4
test -f m4/libtool.m4 || "$LIBTOOLIZE"
autoreconf --warnings=all --install --verbose "$@"

### end of file
