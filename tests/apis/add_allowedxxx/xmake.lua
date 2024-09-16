add_rules("mode.debug", "mode.release")

set_defaultmode("releasedbg")
set_defaultplat("linux")
set_defaultarchs("macosx|arm64", "linux|i386", "armv7")

set_allowedmodes("releasedbg", "debug")
set_allowedplats("windows", "linux", "macosx")
set_allowedarchs("macosx|arm64", "macosx|x86_64", "linux|i386", "linux|x86_64")

target("test")
    set_kind("binary")
    add_files("src/*.cpp")

