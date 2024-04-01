add_rules("mode.debug", "mode.release")

target("bar")
    add_rules("module.binary")
    add_files("src/*.cpp")


