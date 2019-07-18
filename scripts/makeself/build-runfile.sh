#! /bin/bash

cd "$(dirname "$0")/../.."

# prepare files to pack
mkdir -p /tmp/xmake-makeself/xmake
cp -r ./core /tmp/xmake-makeself/xmake
cp -r ./scripts /tmp/xmake-makeself/xmake
cp -r ./xmake /tmp/xmake-makeself/xmake
cp ./*.md /tmp/xmake-makeself/xmake
cp makefile /tmp/xmake-makeself/xmake

cd /tmp/xmake-makeself
# install makeself
wget https://github.com/megastep/makeself/releases/download/release-2.4.0/makeself-2.4.0.run -O ./makeself-2.4.0.run
sh ./makeself-2.4.0.run

# make runfile
./makeself-2.4.0/makeself.sh --lsm ./xmake/scripts/makeself/lsm --help-header ./xmake/scripts/makeself/header ./xmake xmake.run xmake ./scripts/get.sh __local__

cp xmake.run "$(dirname "$0")"
