#!/bin/bash

# xmake getter
# usage: bash <(curl -s <my location>) [branch]

# print a LOGO!
echo -ne '\x1b[07m'
echo '                  _               '
echo '                 | | _            '
echo '__  ___    ______| |/ /___        '
echo '\ \/ | \  / / _  | / / __ \       '
echo ' \  /|  \/ / / | |  |   __/       '
echo ' /  \| \__/\ \_| \ \ \ \__.       '
echo '/_/\_|_|  |_\___\_\|\_\__/  getter'
echo '                                  '
echo -e '\x1b[0m'

brew --version >/dev/null 2>&1 && brew install --HEAD xmake && xmake --version && exit
if [ 0 -ne $(id -u) ]
then
    sudoprefix=sudo
else
    sudoprefix=
fi
my_exit(){
    rv=$?
    if [ "x$1" != x ]
    then
        echo -ne '\x1b[41;37m'
        echo "$1"
        echo -ne '\x1b[0m'
    fi
    rm -rf /tmp/$$xmake_getter 2>/dev/null
    if [ "x$2" != x ]
    then
        if [ $rv -eq 0 ];then rv=$2;fi
    fi
    exit $rv
}
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
test_tools || { install_tools && test_tools; } || my_exit 'Dependencies Installation Fail' 1
branch=
if [ x != "x$1" ]
then
    branch="-b $1"
    echo "Branch: $1"
fi
git clone --depth=1 $branch https://github.com/tboox/xmake.git /tmp/$$xmake_getter || my_exit 'Clone Fail'
make -C /tmp/$$xmake_getter --no-print-directory build || my_exit 'Build Fail'
IFS=':'
patharr=($PATH)
prefix=
for st in ${patharr[@]}
do
    if [[ "$st" = "$HOME"* ]]
    then
        cwd=$(pwd)
        mkdir -p "$st"
        cd "$st"
        echo $$ > $$xmake_getter_test 2>/dev/null || continue
        rm $$xmake_getter_test 2>/dev/null || continue
        cd ..
        mkdir -p share 2>/dev/null || continue
        prefix=$(pwd)
        cd "$cwd"
        break
    fi
done
if [ "x$prefix" != x ]
then
    make -C /tmp/$$xmake_getter --no-print-directory install prefix="$prefix"|| my_exit 'Install Fail'
else
    $sudoprefix make -C /tmp/$$xmake_getter --no-print-directory install || my_exit 'Install Fail'
fi
xmake --version
