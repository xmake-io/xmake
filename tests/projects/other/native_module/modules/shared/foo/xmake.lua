add_rules("mode.debug", "mode.release")

add_requires("lua")

target("add")
    add_rules("module.shared")
    add_files("src/add.cpp")
    add_packages("lua")

target("sub")
    add_rules("module.shared")
    add_files("src/sub.cpp")
    add_packages("lua")

