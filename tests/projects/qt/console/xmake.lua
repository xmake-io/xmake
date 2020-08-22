add_rules("mode.debug", "mode.release")

target("demo")
    add_rules("qt.console")
    add_files("src/*.cpp")

