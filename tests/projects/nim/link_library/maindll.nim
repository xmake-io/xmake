import shared

echo "Calling shared lib mulTwo(10): ", mulTwo(10)
echo "Calling shared lib countWords('hello, world, hello'): ", countWords("hello, world, hello")
echo "Calling shared lib getMsg('test'): ", getMsg()

{.emit: """
#include <test_header.h>
""".}

var testHeaderVal {.importc: "TEST_HEADER_VAL", nodecl.}: cint
echo "TEST_HEADER_VAL: ", testHeaderVal

proc test_add_five(x: cint): cint {.importc: "test_add_five", nodecl.}
echo "test_add_five(80): ", test_add_five(80)

