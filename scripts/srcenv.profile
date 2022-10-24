# cd projectdir
export XMAKE_PROGRAM_DIR=`pwd`/xmake
if [ -f `pwd`/core/build/xmake ]; then
    alias xmake=`pwd`/core/build/xmake
    export XMAKE_PROGRAM_FILE=`pwd`/core/build/xmake
else
    alias xmake=`pwd`/core/src/demo/demo.b
    export XMAKE_PROGRAM_FILE=`pwd`/core/src/demo/demo.b
fi
alias xrepo=`pwd`/scripts/xrepo.sh
xmake --version
xmake l xmake.programdir
xmake l xmake.programfile
