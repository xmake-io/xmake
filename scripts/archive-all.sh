#!/usr/bin/env bash

# ./scripts/archive-all.sh v2.2.7
tag=$1
tmpdir=/tmp/.xmake_archive
xmakeroot=`pwd`
outputfile=$xmakeroot/xmake-$tag
if [ -d $tmpdir ]; then
    rm -rf $tmpdir
fi
mkdir $tmpdir

# copy xmake repo to temproot/xmake-repo, remove git ignored files
cp -r $xmakeroot $tmpdir/repo
cd $tmpdir/repo
git clean -dfX
git submodule foreach git clean -dfX

# clean some unused files
xmake l private.utils.bcsave -s -o $tmpdir/output $tmpdir/repo/xmake
rm -rf $tmpdir/repo/xmake
mv $tmpdir/output $tmpdir/repo/xmake
cd $tmpdir/repo
rm -rf tests
rm -rf core/src/tbox/tbox/src/demo
git add .
git commit -a -m "..."
git tag "$tag-1"
git archive --format "zip" -9 -o "$outputfile.zip" "$tag-1"
git archive --format "tar.gz" -9 -o "$outputfile.tar.gz" "$tag-1"
shasum -a 256 "$outputfile.zip"
shasum -a 256 "$outputfile.tar.gz"
