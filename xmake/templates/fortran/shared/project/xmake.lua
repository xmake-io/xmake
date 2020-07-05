add_rules("mode.debug", "mode.release")

target("${TARGETNAME}_lib")
    set_kind("shared")
    add_files("src/test.f90")

target("${TARGETNAME}")
    set_kind("binary")
    add_deps("${TARGETNAME}_lib")
    add_files("src/main.f90")

