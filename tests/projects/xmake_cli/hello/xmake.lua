add_rules("mode.debug", "mode.release")
add_requires("libxmake")
target("hello")
    add_rules("xmake.cli")
    add_files("src/lni/*.c")
    add_packages("libxmake")

