#!/bin/bash

# xmake getter
# usage: bash <(curl -s <my location>) [branch]

brew --version >/dev/null 2>&1 && brew install --HEAD xmake && xmake --version && exit
if [ 0 -ne $(id -u) ]
then
    sudoprefix=sudo
else
    sudoprefix=
fi
test_tools()
{
    {
        git --version &&
        make --version &&
        {
            cc --version ||
            gcc --version ||
            clang --version
        }
    } >/dev/null 2>&1
}
install_tools()
{
    { apt-get --version >/dev/null 2>&1 && $sudoprefix apt-get install -y git build-essential; } ||
    { yum --version >/dev/null 2>&1 && $sudoprefix yum install -y git && $sudoprefix yum groupinstall -y 'Development Tools'; } ||
    { zypper --version >/dev/null 2>&1 && $sudoprefix zypper --non-interactive install git && $sudoprefix zypper --non-interactive install -t pattern devel_C_C++; } ||
    { pacman -V >/dev/null 2>&1 && $sudoprefix pacman -S --noconfirm git base-devel; }
}
test_tools || { install_tools && test_tools; } ||
{
    rv=$?
    echo 'Dependencies Installation Fail'
    if [ $rv -ne 0 ];then exit $rv;else exit 1;fi
}
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
else
    $sudoprefix make -C /tmp/$$xmake_getter --no-print-directory install || exit $?
fi
rm -rf /tmp/$$xmake_getter
xmake --version
