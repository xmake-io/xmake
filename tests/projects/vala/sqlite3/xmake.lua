add_rules("mode.release", "mode.debug")

add_requires("sqlite3")
add_requires("glib", {system = false}) -- TODO we need improve glib package/on_fetch

target("test")
    set_kind("binary")
    add_rules("vala")
    add_files("src/*.vala")
    add_packages("sqlite3", "glib")
    add_values("vala.packages", "sqlite3")
