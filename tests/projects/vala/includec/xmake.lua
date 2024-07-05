add_rules("mode.release", "mode.debug")

add_requires("glib")

target("test")
    set_kind("binary")
    add_rules("vala")
    add_files("src/*.vala")
    add_files("src/*.c")
    add_packages("glib")
