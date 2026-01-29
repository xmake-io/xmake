proc addTwo*(x: int): int =
  return x + 2

proc getAlphabet*(): string =
  for letter in 'a'..'z':
    result.add(letter)

{.emit: """
#define TEST_STATIC
#include "test.h"
""".}

proc getMsg*(): cstring {.exportc, dynlib.} =
    var msg: cstring
    {.emit: "`msg` = TEST_MSG;".}
    return msg

{.emit: """
#include <test_header.h>
""".}

var testHeaderVal {.importc: "TEST_HEADER_VAL", nodecl.}: cint
echo "TEST_HEADER_VAL: ", testHeaderVal

proc test_add_five(x: cint): cint {.importc: "test_add_five", nodecl.}
echo "test_add_five(60): ", test_add_five(60)
