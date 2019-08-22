#!/usr/bin/env bash

# ./scripts/archive-all.sh v2.2.7
tag=$1
format="tar.gz"
projectdir=/tmp/.xmake_archive
outputfile=`pwd`/xmake-$tag.$format
if [ -d $projectdir ]; then
    rm -rf $projectdir
fi
git clone --depth=1 -b "$tag" "https://github.com/xmake-io/xmake.git" --recursive $projectdir
cd $projectdir
rm -rf tests
git add .
git commit -a -m "..."
git tag "$tag-1"
git archive --format $format -o $outputfile "$tag-1"
shasum -a 256 $outputfile
