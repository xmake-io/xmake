#!/bin/sh

cd "$1"
rm -rf actions core includes languages modules platforms plugins repository rules scripts templates themes
cp -rf "$2" "$1/.."