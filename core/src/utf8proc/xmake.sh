#!/bin/sh

target "utf8proc"
    set_kind "static"
    set_default false
    add_defines "UTF8PROC_STATIC" "{public}"
    add_includedirs "utf8proc" "{public}"
    add_files "utf8proc/utf8proc.c"

