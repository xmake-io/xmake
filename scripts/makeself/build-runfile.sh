#! /bin/bash

cd "$(dirname "$0")/../.."
xmakeroot=`pwd`
temproot=/tmp/xmake-makeself

# prepare files to pack
rm -rf $temproot
mkdir -p $temproot/xmake
cp -r ./core $temproot/xmake
cp -r ./scripts $temproot/xmake
cp -r ./xmake $temproot/xmake
cp ./*.md $temproot/xmake
cp makefile $temproot/xmake
cd $temproot/xmake
rm -rf ./.xmake ./build
rm -rf ./core/src/tbox/tbox/src/demo
rm -rf ./core/src/pdcurses

version=`cat ./core/xmake.lua | grep -E "^set_version" | grep -oE "[0-9]*\.[0-9]*\.[0-9]*"`
sed -i "s/#xmake-version#/$version/g" ./scripts/makeself/header
sed -i "s/#xmake-version#/$version/g" ./scripts/makeself/lsm

cd $temproot
# install makeself
wget https://github.com/megastep/makeself/releases/download/release-2.4.0/makeself-2.4.0.run -O ./makeself-2.4.0.run
sh ./makeself-2.4.0.run

# make runfile
./makeself-2.4.0/makeself.sh \
    --sha256 \
    --lsm ./xmake/scripts/makeself/lsm \
    --help-header ./xmake/scripts/makeself/header \
    ./xmake $xmakeroot/scripts/makeself/xmake.run \
    xmake \
    ./scripts/get.sh __local__
