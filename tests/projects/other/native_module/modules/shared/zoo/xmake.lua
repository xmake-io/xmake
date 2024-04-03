add_rules("mode.debug", "mode.release")

target("zoo")
    add_rules("module.shared")
    add_files("src/zoo.c")

