#!/bin/sh

target "sv"
    set_kind "static"
    set_default false
    set_languages "c99"
    add_includedirs "sv/include" "{public}"
    add_files "sv/src/*.c"

