proc foo(n: int): int {.cdecl, exportc} =
  if n < 2:
    result = n
  else:
    result = foo(n - 1) + (n - 2).foo

