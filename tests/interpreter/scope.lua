
set_kind("static")
add_files("root.c")

target("target1")

    set_kind("static")
    add_files("*.c", "hello.c")
    add_files("$(projectdir)/test.c")

option("option1")

    add_option_links("pthread", "z")
