#!/usr/bin/env bash

# path constants
cd "$(dirname "$0")/../.."
xmakeroot=`pwd`
buildroot=$xmakeroot/scripts/makeself
temproot=/tmp/xmake-makeself

# prepare files to pack
#   clean up temproot
rm -rf $temproot
mkdir -p $temproot

#   copy xmake repo to temproot/xmake-repo, remove git ignored files
cp -Tr $xmakeroot $temproot/xmake-repo
cd $temproot/xmake-repo
git clean -dfX
git submodule foreach git clean -dfX

#   copy files to temproot/xmake
mkdir -p $temproot/xmake/scripts
cd $temproot/xmake-repo
cp -r ./core $temproot/xmake
cp -r ./xmake $temproot/xmake
cp ./scripts/get.sh $temproot/xmake/scripts
cp ./*.md $temproot/xmake
cp makefile $temproot/xmake
cd $temproot/xmake
rm -rf ./core/src/tbox/tbox/src/demo
rm -rf ./core/src/pdcurses

# prepare info texts
cd $temproot
cp $buildroot/* .
version=`cat ./xmake/core/xmake.lua | grep -E "^set_version" | grep -oE "[0-9]*\.[0-9]*\.[0-9]*"`
sed -i "s/#xmake-version#/$version/g" ./header
sed -i "s/#xmake-version#/$version/g" ./lsm

# make run file
cd $temproot
wget https://github.com/megastep/makeself/releases/download/release-2.4.0/makeself-2.4.0.run -O ./makeself-2.4.0.run
sh ./makeself-2.4.0.run
./makeself-2.4.0/makeself.sh \
    --sha256 \
    --lsm ./lsm \
    --help-header ./header \
    ./xmake \
    $buildroot/xmake.run \
    xmake-v$version-runfile \
    ./scripts/get.sh __local__
