add_rules("mode.debug", "mode.release")

target("${TARGET_NAME}")
    add_rules("xcode.framework")
    add_files("src/*.m")
    add_files("src/Info.plist")
    add_headerfiles("src/*.h")

${FAQ}
