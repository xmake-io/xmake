add_rules("mode.release", "mode.debug")

add_requires("lua", "glib")

target("test")
    set_kind("binary")
    add_rules("vala")
    add_files("src/*.vala")
    add_packages("lua", "glib")
    add_values("vala.packages", "lua")
