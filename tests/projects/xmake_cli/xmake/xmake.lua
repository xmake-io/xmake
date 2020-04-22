add_rules("mode.debug", "mode.release")
add_requires("libxmake")
target("xmake")
    add_rules("xmake.cli")
    add_files("src/*.c")
    if is_plat("windows") then
        add_files("src/*.rc")
    end
    add_packages("libxmake")

