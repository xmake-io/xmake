proc bar(n: int): int {.cdecl, exportc} =
  if n < 2:
    result = n
  else:
    result = bar(n - 1) + (n - 2).bar
