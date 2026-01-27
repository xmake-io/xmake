proc mulTwo*(x: int): int =
  return x * 2

import tables, strutils

proc countWords*(input: string): string =
  var wordFrequencies = initCountTable[string]()
  for word in input.split(", "):
    wordFrequencies.inc(word)
  return "The most frequent word is '" & $wordFrequencies.largest & "'"

