add_rules("mode.debug", "mode.release")

add_requires("libxmake")

target("${TARGETNAME}")
    add_rules("xmake.cli")
    add_files("src/lni/*.c")
    add_files("src/lua/*.lua", {rootdir = "src"})
    add_packages("libxmake")

${FAQ}
