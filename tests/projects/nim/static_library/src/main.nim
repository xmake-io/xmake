proc foo(n: int): int {.cdecl, importc}
proc bar(n: int): int {.cdecl, importc}

echo foo(2)
echo bar(2)
