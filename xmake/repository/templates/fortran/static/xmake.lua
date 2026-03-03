add_rules("mode.debug", "mode.release")

target("${TARGET_NAME}_lib")
    set_kind("static")
    add_files("src/test.f90")

target("${TARGET_NAME}")
    set_kind("binary")
    add_deps("${TARGET_NAME}_lib")
    add_files("src/main.f90")

