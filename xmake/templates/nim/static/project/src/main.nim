proc foo(n: int): int {.cdecl, importc}

echo foo(2)
