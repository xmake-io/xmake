
set_kind("static")

add_target("target1")

    set_kind("static")
    add_files("*.c", "hello.c")

add_option("option1")

    add_option_links("pthread", "z")
