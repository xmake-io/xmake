# cd projectdir
export XMAKE_PROGRAM_DIR=`pwd`/xmake
alias xmake=`pwd`/core/src/demo/demo.b
xmake --version
xmake l xmake.programdir
xmake l xmake.programfile
