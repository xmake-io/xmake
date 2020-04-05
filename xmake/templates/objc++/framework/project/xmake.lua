add_rules("mode.debug", "mode.release")

target("${TARGETNAME}")
    add_rules("xcode.framework")
    add_files("src/*.mm")
    add_headerfiles("src/*.h")
    add_installfiles("src/Info.plist")

${FAQ}
