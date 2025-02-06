add_rules("mode.debug", "mode.release")
add_requires("libxmake")
target("ide")
    add_files("src/*.c")
    add_packages("libxmake")
    set_rundir(".")

