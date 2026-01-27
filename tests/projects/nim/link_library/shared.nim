proc mulTwo*(x: int): int =
  return x * 2

import tables, strutils

proc countWords*(input: string): string =
  var wordFrequencies = initCountTable[string]()
  for word in input.split(", "):
    wordFrequencies.inc(word)
  return "The most frequent word is '" & $wordFrequencies.largest & "'"

{.emit: """
#include "test.h"
""".}

proc getMsg*(): cstring {.exportc, dynlib.} =
    var msg: cstring
    {.emit: "`msg` = TEST_MSG;".}
    return msg
