#!/bin/bash

# xmake getter
# usage: bash <(curl -s <my location>) [branch]

branch=
if [ x != x$1 ];then branch="-b $1";fi
git clone --depth=1 $branch https://github.com/tboox/xmake.git /tmp/$$xmake_getter || exit $?
make -C /tmp/$$xmake_getter --no-print-directory build || exit $?
IFS=':'
patharr=($PATH)
prefix=
for st in ${patharr[@]}
do
    if [[ "$st" = "$HOME"* ]]
    then
        cwd=$(pwd)
        mkdir -p "$st"
        cd "$st"/..
        mkdir -p share 2>/dev/null || continue
        prefix=$(pwd)
        cd "$cwd"
        break
    fi
done
if [ x$prefix != x ]
then
    make -C /tmp/$$xmake_getter --no-print-directory install prefix="$prefix"|| exit $?
elif [ 0 -eq $(id -u) ]
then
    make -C /tmp/$$xmake_getter --no-print-directory install || exit $?
else
    sudo make -C /tmp/$$xmake_getter --no-print-directory install || exit $?
fi
rm -rf /tmp/$$xmake_getter
xmake --version
