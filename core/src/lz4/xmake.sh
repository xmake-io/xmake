#!/bin/sh

target "lz4"
    set_kind "static"
    set_default false
    set_warnings "all"
    add_includedirs "lz4/lib" "{public}"
    add_files "lz4/lib/lz4.c"
    add_files "lz4/lib/lz4frame.c"
    add_files "lz4/lib/lz4hc.c"
    add_files "lz4/lib/xxhash.c"
    add_defines "XXH_NAMESPACE=LZ4_"


