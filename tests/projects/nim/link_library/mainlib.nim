import static

{.emit: """
#include <zlib.h>
""".}

proc zlibVersion(): cstring {.importc: "zlibVersion", nodecl.}

echo "Zlib Version: ", zlibVersion()

echo "Calling static lib addTwo(10): ", addTwo(10)
echo "Calling static lib getAlphabet(): ", getAlphabet()
echo "Calling shared lib getMsg('test'): ", getMsg()
