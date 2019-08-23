#!/usr/bin/env bash

# ./scripts/archive-all.sh
tmpdir=/tmp/.xmake_archive
xmakeroot=`pwd`
if [ -d $tmpdir ]; then
    rm -rf $tmpdir
fi
mkdir $tmpdir

# clone xmake repo 
cp -r $xmakeroot $tmpdir/repo
cd $tmpdir/repo
git reset --hard HEAD
git clean -dfX
git submodule foreach git clean -dfX

# prepare files
xmake l -v private.utils.bcsave -s -o $tmpdir/repo/output $tmpdir/repo/xmake
cd $tmpdir/repo || exit
version=`cat core/xmake.lua | grep -E "^set_version" | grep -oE "[0-9]*\.[0-9]*\.[0-9]*"`
outputfile=$xmakeroot/xmake-v$version
rm -rf xmake
mv output xmake
rm -rf tests
rm -rf core/src/tbox/tbox/src/demo
cd core/src/tbox/tbox 
cd $tmpdir/repo || exit
rm -rf `find ./ -name ".git"`
ls -a -l
if [ -f "$outputfile.zip" ]; then
    rm "$outputfile.zip"
fi
if [ -f "$outputfile.7z" ]; then
    rm "$outputfile.7z"
fi
zip -qr "$outputfile.zip" .
7z a "$outputfile.7z" .
shasum -a 256 "$outputfile.zip"
shasum -a 256 "$outputfile.7z"
ls -l "$outputfile.zip"
ls -l "$outputfile.7z"
