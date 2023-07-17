add_rules("mode.debug", "mode.release")

target("main")
    set_kind("binary")
    set_languages("cxx11")
    set_pmheader("src/header.h")
    add_files("src/*.mm", "src/*.c", "*.mm")

