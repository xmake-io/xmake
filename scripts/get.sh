#!/usr/bin/env bash

# xmake getter
# usage: bash <(curl -s <my location>) [branch|__local__|__run__] [commit/__install_only__]

set -o pipefail

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
    elif wget --version >/dev/null 2>&1
    then
        wget "$1" -O -
    fi
}

get_host_speed() {
    if [ `uname` == "Darwin" ]; then
        ping -c 1 -t 1 $1 2>/dev/null | egrep -o 'time=\d+' | egrep -o "\d+" || echo "65535"
    else
        ping -c 1 -W 1 $1 2>/dev/null | egrep -o 'time=\d+' | egrep -o "\d+" || echo "65535"
    fi
}

get_fast_host() {
    speed_gitee=$(get_host_speed "gitee.com")
    speed_github=$(get_host_speed "github.com")
    if [ $speed_gitee -le $speed_github ]; then
        echo "gitee.com" 
    else
        echo "github.com"
    fi
}

# get branch
branch=__run__
if [ x != "x$1" ]; then
    brancharr=($1)
    if [ ${#brancharr[@]} -eq 1 ]
    then
        branch=${brancharr[0]}
    fi
    echo "Branch: $branch"
fi

# get fasthost and git repository
if [ 'x__local__' != "x$branch" ]; then
    fasthost=$(get_fast_host)
    if [ "$fasthost" == "gitee.com" ]; then
        gitrepo="https://gitee.com/tboox/xmake.git"
        gitrepo_raw="https://gitee.com/tboox/xmake/raw/master"
    else
        gitrepo="https://github.com/xmake-io/xmake.git"
        #gitrepo_raw="https://github.com/xmake-io/xmake/raw/master"
        gitrepo_raw="https://cdn.jsdelivr.net/gh/xmake-io/xmake@master"
    fi
fi

if [ "$1" = "__uninstall__" ]
then
    # uninstall
    makefile=$(remote_get_content $gitrepo_raw/makefile)
    while which xmake >/dev/null 2>&1
    do
        pre=$(which xmake | sed 's/\/bin\/xmake$//')
        # don't care if make exists -- if there's no make, how xmake built and installed?
        echo "$makefile" | $make -f - uninstall prefix="$pre" 2>/dev/null || echo "$makefile" | $sudoprefix $make -f - uninstall prefix="$pre" || exit $?
    done
    exit
fi

# below is installation
# print a LOGO!
echo 'xmake, A cross-platform build utility based on Lua.   '
echo 'Copyright (C) 2015-2020 Ruki Wang, tboox.org, xmake.io'
echo '                         _                            '
echo '    __  ___ __  __  __ _| | ______                    '
echo '    \ \/ / |  \/  |/ _  | |/ / __ \                   '
echo '     >  <  | \__/ | /_| |   <  ___/                   '
echo '    /_/\_\_|_|  |_|\__ \|_|\_\____|                   '
echo '                         by ruki, tboox.org           '
echo '                                                      '
echo '   👉  Manual: https://xmake.io/#/getting_started     '
echo '   🙏  Donate: https://xmake.io/#/sponsor             '
echo '                                                      '

my_exit(){
    rv=$?
    if [ "x$1" != x ]
    then
        echo -ne '\x1b[41;37m'
        echo "$1"
        echo -ne '\x1b[0m'
    fi
    rm -rf $tmpdir 2>/dev/null
    if [ "x$2" != x ]
    then
        if [ $rv -eq 0 ];then rv=$2;fi
    fi
    exit "$rv"
}
test_tools()
{
    prog='#include <stdio.h>\n#include <readline/readline.h>\nint main(){readline(0);return 0;}'
    {
        git --version &&
        $make --version &&
        {
            echo -e "$prog" | cc -xc - -o /dev/null -lreadline ||
            echo -e "$prog" | gcc -xc - -o /dev/null -lreadline ||
            echo -e "$prog" | clang -xc - -o /dev/null -lreadline ||
            echo -e "$prog" | cc -xc - -o /dev/null -I/usr/local/include -L/usr/local/lib -lreadline ||
            echo -e "$prog" | gcc -xc - -o /dev/null -I/usr/local/include -L/usr/local/lib -lreadline ||
            echo -e "$prog" | clang -xc - -o /dev/null -I/usr/local/include -L/usr/local/lib -lreadline
        }
    } >/dev/null 2>&1
}
install_tools()
{
    { apt --version >/dev/null 2>&1 && $sudoprefix apt install -y git build-essential libreadline-dev ccache; } ||
    { yum --version >/dev/null 2>&1 && $sudoprefix yum install -y git readline-devel ccache && $sudoprefix yum groupinstall -y 'Development Tools'; } ||
    { zypper --version >/dev/null 2>&1 && $sudoprefix zypper --non-interactive install git readline-devel ccache && $sudoprefix zypper --non-interactive install -t pattern devel_C_C++; } ||
    { pacman -V >/dev/null 2>&1 && $sudoprefix pacman -S --noconfirm --needed git base-devel ccache; } ||
    { pkg list-installed >/dev/null 2>&1 && $sudoprefix pkg install -y git getconf build-essential readline ccache; } || # termux
    { pkg help >/dev/null 2>&1 && $sudoprefix pkg install -y git readline ccache ncurses; } || # freebsd
    { apk --version >/dev/null 2>&1 && $sudoprefix apk add gcc g++ make readline-dev ncurses-dev libc-dev linux-headers; }
}
test_tools || { install_tools && test_tools; } || my_exit "$(echo -e 'Dependencies Installation Fail\nThe getter currently only support these package managers\n\t* apt\n\t* yum\n\t* zypper\n\t* pacman\nPlease install following dependencies manually:\n\t* git\n\t* build essential like `make`, `gcc`, etc\n\t* libreadline-dev (readline-devel)\n\t* ccache (optional)')" 1
projectdir=$tmpdir
if [ 'x__local__' = "x$branch" ]; then
    if [ -d '.git' ]; then
        git submodule update --init --recursive
    fi
    cp -r . $projectdir
    cd $projectdir || my_exit 'Chdir Error'
elif [ 'x__run__' = "x$branch" ]; then
    version=$(git ls-remote --tags "$gitrepo" | tail -c 7)
    if xz --version >/dev/null 2>&1
    then
        pack=xz
    else
        pack=gz
    fi
    mkdir -p $projectdir
    runfile_url="https://cdn.jsdelivr.net/gh/xmake-mirror/xmake-releases@$version/xmake-$version.$pack.run"
    echo "downloading $runfile_url .."
    remote_get_content "$runfile_url" > $projectdir/xmake.run
    if [[ $? != 0 ]]; then
        runfile_url="https://github.com/xmake-io/xmake/releases/download/$version/xmake-$version.$pack.run"
        echo "downloading $runfile_url .."
        remote_get_content "$runfile_url" > $projectdir/xmake.run
    fi
    sh $projectdir/xmake.run --noexec --target $projectdir
else
    echo "cloning $gitrepo $branch .."
    if [ x != "x$2" ]; then
        git clone --depth=50 -b "$branch" "$gitrepo" --recurse-submodules $projectdir || my_exit "$(echo -e 'Clone Fail\nCheck your network or branch name')"
        cd $projectdir || my_exit 'Chdir Error'
        git checkout -qf "$2"
        cd - || my_exit 'Chdir Error'
    else 
        git clone --depth=1 -b "$branch" "$gitrepo" --recurse-submodules $projectdir || my_exit "$(echo -e 'Clone Fail\nCheck your network or branch name')"
    fi
fi

# do build
if [ 'x__install_only__' != "x$2" ]; then
    $make -C $projectdir --no-print-directory build 
    rv=$?
    if [ $rv -ne 0 ]
    then
        $make -C $projectdir/core --no-print-directory error
        my_exit "$(echo -e 'Build Fail\nDetail:\n' | cat - /tmp/xmake.out)" $rv
    fi
fi

# make bytecodes
#XMAKE_PROGRAM_DIR="$projectdir/xmake" \
#$projectdir/core/src/demo/demo.b l -v private.utils.bcsave --rootname='@programdir' -x 'scripts/**|templates/**' $projectdir/xmake || my_exit 'generate bytecode failed!'

# do install
if [ "$prefix" = "" ]; then
    prefix=~/.local
fi
if [ "x$prefix" != x ]; then
    $make -C $projectdir --no-print-directory install prefix="$prefix"|| my_exit 'Install Fail'
else
    $sudoprefix $make -C $projectdir --no-print-directory install || my_exit 'Install Fail'
fi
write_profile()
{
    grep -sq ".xmake/profile" $1 || echo -e "\n[[ -s \"\$HOME/.xmake/profile\" ]] && source \"\$HOME/.xmake/profile\" # load xmake profile" >> $1
}
install_profile()
{
    if [ ! -d ~/.xmake ]; then mkdir ~/.xmake; fi
    echo "export PATH=$prefix/bin:\$PATH" > ~/.xmake/profile
    if [ -f "$projectdir/scripts/register-completions.sh" ]; then
        cat "$projectdir/scripts/register-completions.sh" >> ~/.xmake/profile
    else
        remote_get_content "$gitrepo_raw/scripts/register-completions.sh" >> ~/.xmake/profile
    fi

    if   [[ "$SHELL" = */zsh ]]; then 
        write_profile ~/.zshrc
    elif [[ "$SHELL" = */ksh ]]; then 
        write_profile ~/.kshrc
    elif [[ "$SHELL" = */bash ]]; then 
        write_profile ~/.bashrc
        if [ "$(uname)" == "Darwin" ]; then
            write_profile ~/.bash_profile
        fi
    else write_profile ~/.profile 
    fi
    
}
install_profile
if xmake --version >/dev/null 2>&1; then xmake --version; else
    source ~/.xmake/profile
    xmake --version
    echo "Reload shell profile by running the following command now!"
    echo -e "\x1b[1msource ~/.xmake/profile\x1b[0m"
fi
