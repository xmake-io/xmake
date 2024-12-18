#!/usr/bin/env bash

# xmake getter
# usage: bash <(curl -s <my location>) [branch|__local__|__run__] [commit/__install_only__]

set -o pipefail

#-----------------------------------------------------------------------------
# some helper functions
#

raise() {
    echo "$@" 1>&2 ; exit 1
}

test_z() {
    if test "x${1}" = "x"; then
        return 0
    fi
    return 1
}

test_nz() {
    if test "x${1}" != "x"; then
        return 0
    fi
    return 1
}

test_eq() {
    if test "x${1}" = "x${2}"; then
        return 0
    fi
    return 1
}

test_nq() {
    if test "x${1}" != "x${2}"; then
        return 0
    fi
    return 1
}

#-----------------------------------------------------------------------------
# prepare
#

# print a LOGO!
echo 'xmake, A cross-platform build utility based on Lua.   '
echo 'Copyright (C) 2015-present Ruki Wang, tboox.org, xmake.io'
echo '                         _                            '
echo '    __  ___ __  __  __ _| | ______                    '
echo '    \ \/ / |  \/  |/ _  | |/ / __ \                   '
echo '     >  <  | \__/ | /_| |   <  ___/                   '
echo '    /_/\_\_|_|  |_|\__ \|_|\_\____|                   '
echo '                         by ruki, xmake.io            '
echo '                                                      '
echo '   👉  Manual: https://xmake.io/#/getting_started     '
echo '   🙏  Donate: https://xmake.io/#/sponsor             '
echo '                                                      '

# has sudo?
if [ 0 -ne "$(id -u)" ]; then
    if sudo --version >/dev/null 2>&1
    then
        sudoprefix=sudo
    else
        sudoprefix=
    fi
else
    export XMAKE_ROOT=y
    sudoprefix=
fi

# make tmpdir
if [ -z "$TMPDIR" ]; then
    tmpdir=/tmp/.xmake_getter$$
else
    tmpdir=$TMPDIR/.xmake_getter$$
fi
if [ -d $tmpdir ]; then
    rm -rf $tmpdir
fi

# get make
if gmake --version >/dev/null 2>&1
then
    make=gmake
else
    make=make
fi

remote_get_content() {
    if curl --version >/dev/null 2>&1
    then
        curl -fSL "$1"
    elif wget --version >/dev/null 2>&1 || wget --help >/dev/null 2>&1
    then
        wget "$1" -O -
    fi
}

get_host_speed() {
    if [ `uname` == "Darwin" ]; then
        ping -c 1 -t 1 $1 2>/dev/null | egrep -o 'time=\d+' | egrep -o "\d+" || echo "65535"
    else
        ping -c 1 -W 1 $1 2>/dev/null | grep -E -o 'time=[0-9]+' | grep -E -o "[0-9]+" || echo "65535"
    fi
}

get_fast_host() {
    if test_eq "$GITHUB_ACTIONS" "true" || test_eq "$GITHUB_ACTIONS" "1"; then
        echo "github.com"
    else
        speed_gitee=$(get_host_speed "gitee.com")
        speed_github=$(get_host_speed "github.com")
        if [ $speed_gitee -le $speed_github ]; then
            echo "gitee.com"
        else
            echo "github.com"
        fi
    fi
}

# get branch
branch=__run__
if test_nz "$1"; then
    brancharr=($1)
    if [ ${#brancharr[@]} -eq 1 ]
    then
        branch=${brancharr[0]}
    fi
    echo "Branch: $branch"
fi

# get fasthost and git repository
if test_nq "$branch" "__local__"; then
    fasthost=$(get_fast_host)
    if test_eq "$fasthost" "gitee.com"; then
        gitrepo="https://gitee.com/tboox/xmake.git"
        gitrepo_raw="https://gitee.com/tboox/xmake/raw/master"
    else
        gitrepo="https://github.com/xmake-io/xmake.git"
        #gitrepo_raw="https://github.com/xmake-io/xmake/raw/master"
        gitrepo_raw="https://fastly.jsdelivr.net/gh/xmake-io/xmake@master"
    fi
fi

#-----------------------------------------------------------------------------
# install tools
#

test_tools() {
    prog='#include <stdio.h>\nint main(){return 0;}'
    {
        git --version &&
        $make --version &&
        {
            echo -e "$prog" | cc -xc - -o /dev/null ||
            echo -e "$prog" | gcc -xc - -o /dev/null ||
            echo -e "$prog" | clang -xc - -o /dev/null ||
            echo -e "$prog" | cc -xc -c - -o /dev/null -I/usr/include -I/usr/local/include ||
            echo -e "$prog" | gcc -xc -c - -o /dev/null -I/usr/include -I/usr/local/include ||
            echo -e "$prog" | clang -xc -c - -o /dev/null -I/usr/include -I/usr/local/include
        }
    } >/dev/null 2>&1
}

install_tools() {
    { apt --version >/dev/null 2>&1 && $sudoprefix apt install -y git build-essential libreadline-dev; } ||
    { yum --version >/dev/null 2>&1 && $sudoprefix yum install -y git readline-devel bzip2 && $sudoprefix yum groupinstall -y 'Development Tools'; } ||
    { zypper --version >/dev/null 2>&1 && $sudoprefix zypper --non-interactive install git readline-devel && $sudoprefix zypper --non-interactive install -t pattern devel_C_C++; } ||
    { pacman -V >/dev/null 2>&1 && $sudoprefix pacman -S --noconfirm --needed git base-devel ncurses readline; } ||
    { emerge -V >/dev/null 2>&1 && $sudoprefix emerge -atv dev-vcs/git; } ||
    { pkg list-installed >/dev/null 2>&1 && $sudoprefix pkg install -y git getconf build-essential readline; } || # termux
    { pkg help >/dev/null 2>&1 && $sudoprefix pkg install -y git readline ncurses; } || # freebsd
    { nix-env --version >/dev/null 2>&1 && nix-env -i git gcc readline ncurses; } || # nixos
    { apk --version >/dev/null 2>&1 && $sudoprefix apk add git gcc g++ make readline-dev ncurses-dev libc-dev linux-headers; } ||
    { xbps-install --version >/dev/null 2>&1 && $sudoprefix xbps-install -Sy git base-devel; } #void

}
test_tools || { install_tools && test_tools; } || raise "$(echo -e 'Dependencies Installation Fail\nThe getter currently only support these package managers\n\t* apt\n\t* yum\n\t* zypper\n\t* pacman\n\t* portage\n\t* xbps\n Please install following dependencies manually:\n\t* git\n\t* build essential like `make`, `gcc`, etc\n\t* libreadline-dev (readline-devel)')" 1

#-----------------------------------------------------------------------------
# install xmake
#

projectdir=$tmpdir
if test_eq "$branch" "__local__"; then
    if [ -d '.git' ]; then
        git submodule update --init --recursive
    fi
    cp -r . $projectdir
elif test_eq "$branch" "__run__"; then
    version=$(git ls-remote --tags "$gitrepo" | tail -c 7)
    pack=gz
    mkdir -p $projectdir
    runfile_url="https://fastly.jsdelivr.net/gh/xmake-mirror/xmake-releases@$version/xmake-$version.$pack.run"
    echo "downloading $runfile_url .."
    remote_get_content "$runfile_url" > $projectdir/xmake.run
    if [[ $? != 0 ]]; then
        runfile_url="https://github.com/xmake-io/xmake/releases/download/$version/xmake-$version.$pack.run"
        echo "downloading $runfile_url .."
        remote_get_content "$runfile_url" > $projectdir/xmake.run
    fi
    sh $projectdir/xmake.run --noexec --quiet --target $projectdir
else
    echo "cloning $gitrepo $branch .."
    if test_nz "$2"; then
        git clone --filter=tree:0 --no-checkout -b "$branch" "$gitrepo" --recurse-submodules $projectdir || raise "clone failed, check your network or branch name"
        cd $projectdir || raise 'chdir failed!'
        git checkout -qf "$2"
        cd - || raise 'chdir failed!'
    else
        git clone --depth=1 -b "$branch" "$gitrepo" --recurse-submodules $projectdir || raise "clone failed, check your network or branch name"
    fi
fi

# do build
if test_nq "$2" "__install_only__"; then
    if [ -f "$projectdir/configure" ]; then
        cd $projectdir || raise 'chdir failed!'
        ./configure || raise "configure failed!"
        cd - || raise 'chdir failed!'
    fi
    $make -C $projectdir --no-print-directory -j4 || raise "make failed!"
fi

# do install
if test_z "$prefix"; then
    prefix=~/.local
fi
if test_nz "$prefix"; then
    $make -C $projectdir --no-print-directory install PREFIX="$prefix" || raise "install failed!"
else
    $sudoprefix $make -C $projectdir --no-print-directory install || raise "install failed!"
fi

#-----------------------------------------------------------------------------
# install profile
#
install_profile() {
    export XMAKE_ROOTDIR="$prefix/bin"
    [[ "$PATH" =~ (^|:)"$XMAKE_ROOTDIR"(:|$) ]] || export PATH="$XMAKE_ROOTDIR:$PATH"
    xmake --version
    xmake update --integrate
}

install_profile
