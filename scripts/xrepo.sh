#!/usr/bin/env sh
SCRIPT=$(readlink -f "$0")
BASEDIR=$(dirname "$SCRIPT")
echo $BASEDIR
if [ -f "$BASEDIR/xmake" ]; then
    $BASEDIR/xmake lua private.xrepo "$@"
else
    xmake lua private.xrepo "$@"
fi
