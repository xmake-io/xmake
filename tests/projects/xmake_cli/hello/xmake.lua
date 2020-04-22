add_rules("mode.debug", "mode.release")
add_requires("libxmake", {debug = is_mode("debug")})
target("hello")
    add_rules("xmake.cli")
    add_files("src/lni/*.c")
    add_packages("libxmake")

