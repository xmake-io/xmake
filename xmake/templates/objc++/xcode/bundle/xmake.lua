add_rules("mode.debug", "mode.release")

target("${TARGET_NAME}")
    add_rules("xcode.bundle")
    add_files("src/*.mm")
    add_files("src/Info.plist")
    add_headerfiles("src/*.h")

${FAQ}
