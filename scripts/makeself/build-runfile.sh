#! /bin/bash

cd "$(dirname "$0")/../.."
xmakeroot=`pwd`
buildroot=$xmakeroot/scripts/makeself
temproot=/tmp/xmake-makeself

# prepare files to pack
rm -rf $temproot
mkdir -p $temproot/xmake/scripts
cp -r ./core $temproot/xmake
cp ./scripts/get.sh $temproot/xmake/scripts
cp -r ./xmake $temproot/xmake
cp ./*.md $temproot/xmake
cp makefile $temproot/xmake
cd $temproot/xmake
rm -rf ./core/.xmake ./core/build
rm -rf ./core/src/tbox/tbox/src/demo
rm -rf ./core/src/pdcurses

# prepare info texts
cd $temproot
cp $buildroot/* .
version=`cat ./xmake/core/xmake.lua | grep -E "^set_version" | grep -oE "[0-9]*\.[0-9]*\.[0-9]*"`
sed -i "s/#xmake-version#/$version/g" ./header
sed -i "s/#xmake-version#/$version/g" ./lsm

# install makeself
cd $temproot
wget https://github.com/megastep/makeself/releases/download/release-2.4.0/makeself-2.4.0.run -O ./makeself-2.4.0.run
sh ./makeself-2.4.0.run

# make runfile
./makeself-2.4.0/makeself.sh \
    --sha256 \
    --lsm ./lsm \
    --help-header ./header \
    ./xmake $xmakeroot/scripts/makeself/xmake.run \
    xmake \
    ./scripts/get.sh __local__
