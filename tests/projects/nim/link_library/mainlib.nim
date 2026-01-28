import static

{.emit: """
#include <zlib.h>
#define STB_IMAGE_IMPLEMENTATION
#include <stb_image.h>
""".}

proc zlibVersion(): cstring {.importc: "zlibVersion", nodecl.}
proc stbi_set_flip_vertically_on_load(flag_true_if_should_flip: cint) {.importc: "stbi_set_flip_vertically_on_load", nodecl.}

echo "Zlib Version: ", zlibVersion()

stbi_set_flip_vertically_on_load(1)
echo "STB Image: Flip vertically on load set to 1"

echo "Calling static lib addTwo(10): ", addTwo(10)
echo "Calling static lib getAlphabet(): ", getAlphabet()
echo "Calling shared lib getMsg('test'): ", getMsg()

{.emit: """
#include <test_header.h>
""".}

var testHeaderVal {.importc: "TEST_HEADER_VAL", nodecl.}: cint
echo "TEST_HEADER_VAL: ", testHeaderVal

proc test_add_five(x: cint): cint {.importc: "test_add_five", nodecl.}
echo "test_add_five(55): ", test_add_five(55)

