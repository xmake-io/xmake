add_rules("mode.debug", "mode.release")

target("${TARGETNAME}")
    add_rules("xcode.framework")
    add_files("src/*.m")
    add_headerfiles("src/*.h")
    add_installfiles("src/Info.plist")
    --set_values("xcode.codesign_identity", "Apple Development: xxx@gmail.com (T3NA4MRVPU)")

${FAQ}
