add_rules("mode.debug", "mode.release")

target("add")
    add_rules("module.binary")
    add_files("src/add.c")

target("sub")
    add_rules("module.binary")
    add_files("src/sub.c")

