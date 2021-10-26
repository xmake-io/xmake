add_rules("mode.debug", "mode.release")
target("hello")
    set_kind("binary")
    set_extension(".axf")
    add_files("src/**.c", "src/**.s")

