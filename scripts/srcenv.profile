# cd projectdir
export XMAKE_PROGRAM_DIR=`pwd`/xmake
alias xmake=`pwd`/build/xmake
export XMAKE_PROGRAM_FILE=`pwd`/build/xmake
alias xrepo=`pwd`/scripts/xrepo.sh
xmake --version
xmake l xmake.programdir
xmake l xmake.programfile
