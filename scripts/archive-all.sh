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

# copy files to tmpdir/xmake
mkdir -p $tmpdir/xmake/scripts
cd $tmpdir/repo || exit
xmake l -v private.utils.bcsave --rootname='@programdir' -x 'scripts/**|templates/**' xmake || exit
cp -r ./core $tmpdir/xmake
cp -r ./xmake $tmpdir/xmake/xmake
cp ./scripts/get.sh $tmpdir/xmake/scripts
cp ./*.md $tmpdir/xmake
cp makefile $tmpdir/xmake
cp install $tmpdir/xmake
cd $tmpdir/xmake || exit
rm -rf ./core/src/tbox/tbox/src/demo

# archive files
version=`cat ./core/xmake.lua | grep -E "^set_version" | grep -oE "[0-9]*\.[0-9]*\.[0-9]*"`
outputfile=$xmakeroot/"xmake-v$version"
if [ -f "$outputfile.zip" ]; then
    rm "$outputfile.zip"
fi
if [ -f "$outputfile.7z" ]; then
    rm "$outputfile.7z"
fi
if [ -f "$outputfile.tar.gz" ]; then
    rm "$outputfile.tar.gz"
fi
zip -qr "$outputfile.zip" .
7z a "$outputfile.7z" .
tar -czf "$outputfile.tar.gz" .
shasum -a 256 "$outputfile.zip"
shasum -a 256 "$outputfile.7z"
shasum -a 256 "$outputfile.tar.gz"
ls -l "$outputfile.zip"
ls -l "$outputfile.7z"
ls -l "$outputfile.tar.gz"
