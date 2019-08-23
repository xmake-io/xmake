#!/usr/bin/env bash

# ./scripts/archive-all.sh
tmpdir=/tmp/.xmake_archive
xmakeroot=`pwd`
if [ -d $tmpdir ]; then
    rm -rf $tmpdir
fi
mkdir $tmpdir

# copy xmake repo to temproot/xmake-repo, remove git ignored files
cp -r $xmakeroot $tmpdir/repo
cd $tmpdir/repo
git reset --hard HEAD
git clean -fd
git submodule foreach git clean -fd

# prepare files
version=`cat core/xmake.lua | grep -E "^set_version" | grep -oE "[0-9]*\.[0-9]*\.[0-9]*"`
outputfile=$xmakeroot/xmake-v$version
xmake l -v private.utils.bcsave -s -o $tmpdir/repo/output $tmpdir/repo/xmake
rm -rf xmake
mv output xmake
rm -rf tests
rm -rf core/src/tbox/tbox/src/demo
cd core/src/tbox/tbox
git add .
git commit -a -m "..."
cd -
git add .
git commit -a -m "..."
git tag "v$version-1"
ls -l
git archive --format "zip" -9 -o "$outputfile.zip" "v$version-1"
git archive --format "tar.gz" -9 -o "$outputfile.tar.gz" "v$version-1"
shasum -a 256 "$outputfile.zip"
shasum -a 256 "$outputfile.tar.gz"
