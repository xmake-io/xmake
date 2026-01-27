proc addTwo*(x: int): int =
  return x + 2

proc getAlphabet*(): string =
  for letter in 'a'..'z':
    result.add(letter)
