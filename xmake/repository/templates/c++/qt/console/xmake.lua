add_rules("mode.debug", "mode.release")

target("${TARGET_NAME}")
    add_rules("qt.console")
    add_files("src/*.cpp")

${FAQ}
