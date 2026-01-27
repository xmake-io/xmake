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
