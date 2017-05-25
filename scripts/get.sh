#!/bin/bash

# xmake getter
# usage: bash <(curl -s <my location>) [[mirror:]branch] [commit/__install_only__]

set -o pipefail
# print a LOGO!
echo '                         _                      '
echo '    __  ___ __  __  __ _| | ______              '
echo '    \ \/ / |  \/  |/ _  | |/ / __ \             '
echo '     >  <  | \__/ | /_| |   <  ___/             '
echo '    /_/\_\_|_|  |_|\__ \|_|\_\____| getter      '
echo '                                                '

if [ 'x__local__' != "x$1" ]
then
    brew --version >/dev/null 2>&1 && brew install --HEAD xmake && xmake --version && exit
fi

if [ 0 -ne "$(id -u)" ]
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
    exit "$rv"
}
test_tools()
{
    prog='#include<stdio.h>\n#include<readline/readline.h>\nint main(){readline(0);return 0;}'
    {
        git --version &&
        make --version &&
        {
            echo -e "$prog" | cc -xc - -o /dev/null -lreadline ||
            echo -e "$prog" | gcc -xc - -o /dev/null -lreadline ||
            echo -e "$prog" | clang -xc - -o /dev/null -lreadline
        }
    } >/dev/null 2>&1
}
install_tools()
{
    { apt-get --version >/dev/null 2>&1 && $sudoprefix apt-get install -y git build-essential libreadline-dev; } ||
    { yum --version >/dev/null 2>&1 && $sudoprefix yum install -y git readline-devel && $sudoprefix yum groupinstall -y 'Development Tools'; } ||
    { zypper --version >/dev/null 2>&1 && $sudoprefix zypper --non-interactive install git readline-devel && $sudoprefix zypper --non-interactive install -t pattern devel_C_C++; } ||
    { pacman -V >/dev/null 2>&1 && $sudoprefix pacman -S --noconfirm --needed git base-devel; }
}
test_tools || { install_tools && test_tools; } || my_exit 'Dependencies Installation Fail' 1
branch=master
mirror=tboox
IFS=':'
if [ x != "x$1" ]
then
    brancharr=($1)
    if [ ${#brancharr[@]} -eq 1 ]
    then
        branch=${brancharr[0]}
    fi
    if [ ${#brancharr[@]} -eq 2 ]
    then
        branch=${brancharr[1]}
        mirror=${brancharr[0]}
    fi
    echo "Branch: $branch"
fi
if [ 'x__local__' != "x$branch" ]
then
    git clone --depth=50 -b "$branch" "https://github.com/$mirror/xmake.git" /tmp/$$xmake_getter || my_exit 'Clone Fail'
    if [ x != "x$2" ]
    then
        cd /tmp/$$xmake_getter || my_exit 'Chdir Error'
        git checkout -qf "$2"
        cd - || my_exit 'Chdir Error'
    fi
else
    cp -r "$(git rev-parse --show-toplevel 2>/dev/null || hg root 2>/dev/null || echo "$PWD")" /tmp/$$xmake_getter || my_exit 'Clone Fail'
fi
if [ 'x__install_only__' != "x$2" ]
then
    make -C /tmp/$$xmake_getter --no-print-directory build 
    rv=$?
    if [ $rv -ne 0 ]
    then
        make -C /tmp/$$xmake_getter/core --no-print-directory error
        my_exit 'Build Fail' $rv
    fi
fi
# PATHclone=$PATH
# patharr=($PATHclone)
if [ "$prefix" = "" ]
then
    prefix=~/.local
fi
# for st in "${patharr[@]}"
# do
#     if [[ "$st" = "$HOME"* ]]
#     then
#         cwd=$PWD
#         mkdir -p "$st"
#         cd "$st" || continue
#         echo $$ > $$xmake_getter_test 2>/dev/null || continue
#         rm $$xmake_getter_test 2>/dev/null || continue
#         cd .. || continue
#         mkdir -p share 2>/dev/null || continue
#         prefix=$(pwd)
#         cd "$cwd" || my_exit 'Chdir Error'
#         break
#     fi
# done
if [ "x$prefix" != x ]
then
    make -C /tmp/$$xmake_getter --no-print-directory install prefix="$prefix"|| my_exit 'Install Fail'
else
    $sudoprefix make -C /tmp/$$xmake_getter --no-print-directory install || my_exit 'Install Fail'
fi
shell_profile(){
    if   [[ "$SHELL" = */zsh ]]; then echo ~/.zshrc
    elif [[ "$SHELL" = */ksh ]]; then echo ~/.kshrc
    else echo ~/.bash_profile; fi
}
xmake --version >/dev/null 2>&1 && xmake --version || {
    echo "export PATH=$prefix/bin:\$PATH" >> $(shell_profile)
    export PATH=$prefix/bin:$PATH
    xmake --version
    echo -e "Reload shell profile by running \x1b[1msource '$(shell_profile)'\x1b[0m now!"
}
