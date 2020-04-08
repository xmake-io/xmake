add_rules("mode.debug", "mode.release")

target("${TARGETNAME}")
    add_rules("xcode.bundle")
    add_files("src/*.m")
    add_files("src/Info.plist")
    add_headerfiles("src/*.h")

${FAQ}
