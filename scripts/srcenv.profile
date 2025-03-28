# cd projectdir
xmake_binaries=(
    "build/xmake"
    "build/xmake.exe"
    "core/build/xmake"
    "core/build/xmake.exe"
)

export XMAKE_PROGRAM_DIR=`pwd`/xmake
xmake_found=0
for xmake_binary in "${xmake_binaries[@]}"; do
    if [[ -x "$xmake_binary" ]] && ("$xmake_binary" --version); then
        xmake_found=1
        break
    fi
done

if [ $xmake_found -eq 0 ]; then
    unset xmake_binaries xmake_binary xmake_found
    echo "Error: Cannot find a working xmake executable"
    return 1
fi

alias xmake=`pwd`/$xmake_binary
export XMAKE_PROGRAM_FILE=`pwd`/$xmake_binary
alias xrepo=`pwd`/scripts/xrepo.sh

unset xmake_binaries xmake_binary xmake_found
xmake l xmake.programdir
xmake l xmake.programfile
