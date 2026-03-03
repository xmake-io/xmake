add_rules("mode.debug", "mode.release")

add_requires("libxmake")

target("${TARGET_NAME}")
    add_rules("xmake.cli")
    add_files("src/lni/*.c")
    add_files("src/lua/*.lua", {rootdir = "src"})
    add_packages("libxmake")

${FAQ}
