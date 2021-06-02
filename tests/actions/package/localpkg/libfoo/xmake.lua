add_rules("mode.debug", "mode.release")

target("sub")
    set_kind("static")
    add_files("src/sub.cpp")
    add_headerfiles("src/sub.h")

target("add")
    set_kind("static")
    add_files("src/add.cpp")
    add_headerfiles("src/add.h")

target("foo")
    add_deps("add", "sub")
    set_kind("static")
    add_files("src/foo.cpp")
    add_headerfiles("src/foo.h")

