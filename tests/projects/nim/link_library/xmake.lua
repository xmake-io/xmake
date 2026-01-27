set_project("link_libs")
add_rules("mode.debug", "mode.release")

target("executablestatic")
    set_kind("binary")
    add_files("mainlib.nim")
    add_deps("staticlib")

target("executableshared")
    set_kind("binary")
    add_files("maindll.nim")
    add_deps("sharedlib")

target("staticlib")
    set_kind("static")
    add_files("static.nim")

target("sharedlib")
    set_kind("shared")
    add_files("shared.nim")
