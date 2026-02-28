add_rules("mode.debug", "mode.release")

target("${TARGETNAME}")
    add_rules("qt.console")
    add_files("src/*.cpp")

${FAQ}
