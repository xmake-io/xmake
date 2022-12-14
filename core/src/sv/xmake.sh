#!/bin/sh

target "sv"
    set_languages "c99"
    set_kind "static"
    add_includedirs "sv/include" "{public}"
    add_files "sv/src/*.c"

