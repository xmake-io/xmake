#!/usr/bin/env bash
BASEDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
if [ -f "$BASEDIR/../share/xmake/xmake.exe" ]; then
    $BASEDIR/../share/xmake/xmake.exe "$@"
fi
