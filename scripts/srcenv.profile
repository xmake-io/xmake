# cd projectdir
export XMAKE_PROGRAM_DIR=`pwd`/xmake
if [ -f `pwd`/core/build/xmake ]; then
    alias xmake=`pwd`/core/build/xmake
else
    alias xmake=`pwd`/core/src/demo/demo.b
fi
xmake --version
xmake l xmake.programdir
xmake l xmake.programfile
