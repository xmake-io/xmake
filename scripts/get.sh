#!/usr/bin/env bash

# xmake getter
# usage: bash <(curl -s <my location>) [[mirror:]branch] [commit/__install_only__]

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

remote_get_content() {
    if curl --version >/dev/null 2>&1
    then
        curl -fsSL "$1"
    elif wget --version >/dev/null 2>&1
    then
        wget -q "$1" -O -
    fi
}

if [ "$1" = "__uninstall__" ]
then
    # uninstall
    makefile=$(remote_get_content https://github.com/xmake-io/xmake/raw/master/makefile)
    while which xmake >/dev/null 2>&1
    do
        pre=$(which xmake | sed 's/\/bin\/xmake$//')
        # don't care if make exists -- if there's no make, how xmake built and installed?
        echo "$makefile" | make -f - uninstall prefix="$pre" 2>/dev/null || echo "$makefile" | $sudoprefix make -f - uninstall prefix="$pre" || exit $?
    done
    exit
fi

# below is installation
# print a LOGO!
echo '                         _                      '
echo '    __  ___ __  __  __ _| | ______              '
echo '    \ \/ / |  \/  |/ _  | |/ / __ \             '
echo '     >  <  | \__/ | /_| |   <  ___/             '
echo '    /_/\_\_|_|  |_|\__ \|_|\_\____| getter      '
echo '                                                '

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
    { apt --version >/dev/null 2>&1 && $sudoprefix apt install -y git build-essential libreadline-dev ccache; } ||
    { yum --version >/dev/null 2>&1 && $sudoprefix yum install -y git readline-devel ccache && $sudoprefix yum groupinstall -y 'Development Tools'; } ||
    { zypper --version >/dev/null 2>&1 && $sudoprefix zypper --non-interactive install git readline-devel ccache && $sudoprefix zypper --non-interactive install -t pattern devel_C_C++; } ||
    { pacman -V >/dev/null 2>&1 && $sudoprefix pacman -S --noconfirm --needed git base-devel ccache; } ||
    { pkg list-installed >/dev/null 2>&1 && $sudoprefix pkg install -y git getconf build-essential readline ccache; } 
}
test_tools || { install_tools && test_tools; } || my_exit "$(echo -e 'Dependencies Installation Fail\nThe getter currently only support these package managers\n\t* apt\n\t* yum\n\t* zypper\n\t* pacman\nPlease install following dependencies manually:\n\t* git\n\t* build essential like `make`, `gcc`, etc\n\t* libreadline-dev (readline-devel)\n\t* ccache (optional)')" 1
branch=master
mirror=tboox
IFS=':'
if [ x != "x$1" ]; then
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
projectdir=$tmpdir
if [ 'x__local__' != "x$branch" ]; then
    if [ x != "x$2" ]; then
        git clone --depth=50 -b "$branch" "https://github.com/$mirror/xmake.git" --recursive $projectdir || my_exit "$(echo -e 'Clone Fail\nCheck your network or branch name')"
        cd $projectdir || my_exit 'Chdir Error'
        git checkout -qf "$2"
        cd - || my_exit 'Chdir Error'
    else 
        git clone --depth=1 -b "$branch" "https://github.com/$mirror/xmake.git" --recursive $projectdir || my_exit "$(echo -e 'Clone Fail\nCheck your network or branch name')"
    fi
else
    if [ -d '.git' ]; then
        git submodule update --init --recursive
    fi
    cp -r . $projectdir
    cd $projectdir || my_exit 'Chdir Error'
fi

# do build
if [ 'x__install_only__' != "x$2" ]; then
    make -C $projectdir --no-print-directory build 
    rv=$?
    if [ $rv -ne 0 ]
    then
        make -C $projectdir/core --no-print-directory error
        my_exit "$(echo -e 'Build Fail\nDetail:\n' | cat - /tmp/xmake.out)" $rv
    fi
fi

# make bytecodes
export XMAKE_PROGRAM_DIR=$projectdir/xmake
$projectdir/core/src/demo/demo.b l -v private.utils.bcsave --rootname='@programdir' -x 'scripts/**|templates/**' $projectdir/xmake || my_exit 'generate bytecode failed!'
export XMAKE_PROGRAM_DIR=

# do install
if [ "$prefix" = "" ]; then
    prefix=~/.local
fi
if [ "x$prefix" != x ]; then
    make -C $projectdir --no-print-directory install prefix="$prefix"|| my_exit 'Install Fail'
else
    $sudoprefix make -C $projectdir --no-print-directory install || my_exit 'Install Fail'
fi
write_profile()
{
    grep -sq ".xmake/profile" $1 || echo "[[ -s \"\$HOME/.xmake/profile\" ]] && source \"\$HOME/.xmake/profile\" # load xmake profile" >> $1
}
install_profile()
{
    if [ ! -d ~/.xmake ]; then mkdir ~/.xmake; fi
    echo "export PATH=$prefix/bin:\$PATH" > ~/.xmake/profile
    echo '
if   [[ "$SHELL" = */zsh ]]; then
    # zsh parameter completion for xmake

    _xmake_zsh_complete() 
    {
    local completions=("$(XMAKE_SKIP_HISTORY=1 xmake lua private.utils.complete 0 nospace "$words")")

    reply=( "${(ps:\n:)completions}" )
    }

    compctl -f -S "" -K _xmake_zsh_complete xmake

elif [[ "$SHELL" = */bash ]]; then
    # bash parameter completion for xmake

    _xmake_bash_complete()
    {
    local word=${COMP_WORDS[COMP_CWORD]}

    local completions
    completions="$(XMAKE_SKIP_HISTORY=1 xmake lua private.utils.complete "${COMP_POINT}" "${COMP_LINE}" 2>/dev/null)"
    if [ $? -ne 0 ]; then
        completions=""
    fi

    COMPREPLY=( $(compgen -W "$completions" -- "$word") )
    }

    complete -o default -o nospace -F _xmake_bash_complete xmake

fi
' >> ~/.xmake/profile

    if   [[ "$SHELL" = */zsh ]]; then write_profile ~/.zshrc
    elif [[ "$SHELL" = */ksh ]]; then write_profile ~/.kshrc
    elif [[ "$SHELL" = */bash ]]; then write_profile ~/.bashrc
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
