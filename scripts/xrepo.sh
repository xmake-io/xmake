#!/usr/bin/env bash
BASEDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
if [ -f "$BASEDIR/xmake" ]; then
    $BASEDIR/xmake lua private.xrepo "$@"
else
    xmake lua private.xrepo "$@"
fi
