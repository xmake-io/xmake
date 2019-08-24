#!/usr/bin/env bash

# path constants
cd "$(dirname "$0")/../.."
xmakeroot=`pwd`
buildroot=$xmakeroot/scripts/makeself
tmpdir=/tmp/xmake-makeself
if [ -d $tmpdir ]; then
    rm -rf $tmpdir
fi
mkdir -p $tmpdir

# copy xmake repo to tmpdir/repo, remove git ignored files
cp -r $xmakeroot $tmpdir/repo
cd $tmpdir/repo || exit
git reset --hard HEAD
git clean -dfX
git submodule foreach git clean -dfX

# copy files to tmpdir/xmake
mkdir -p $tmpdir/xmake/scripts
cd $tmpdir/repo || exit
xmake l -v private.utils.bcsave --rootname='@programdir' -x 'scripts/**|templates/**' xmake || exit
cp -r ./xmake $tmpdir/xmake/xmake
cp -r ./core $tmpdir/xmake
cp ./scripts/get.sh $tmpdir/xmake/scripts
cp ./*.md $tmpdir/xmake
cp makefile $tmpdir/xmake
cd $tmpdir/xmake || exit
rm -rf ./core/src/tbox/tbox/src/demo
rm -rf ./core/src/tbox/tbox/src/tbox/platform/windows
rm -rf ./core/src/pdcurses

# prepare info texts
cd $tmpdir
cp $buildroot/* .
version=`cat ./xmake/core/xmake.lua | grep -E "^set_version" | grep -oE "[0-9]*\.[0-9]*\.[0-9]*"`
perl -pi -e "s/#xmake-version#/$version/g" ./header
perl -pi -e "s/#xmake-version#/$version/g" ./lsm

# make run file
cd $tmpdir
wget https://github.com/megastep/makeself/releases/download/release-2.4.0/makeself-2.4.0.run -O ./makeself-2.4.0.run
sh ./makeself-2.4.0.run
./makeself-2.4.0/makeself.sh \
    --gzip \
    --sha256 \
    --lsm ./lsm \
    --help-header ./header \
    ./xmake \
    $buildroot/xmake.gz.run \
    xmake-v$version-runfile \
    ./scripts/get.sh __local__
./makeself-2.4.0/makeself.sh \
    --xz \
    --sha256 \
    --lsm ./lsm \
    --help-header ./header \
    ./xmake \
    $buildroot/xmake.xz.run \
    xmake-v$version-runfile \
    ./scripts/get.sh __local__
