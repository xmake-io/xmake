add_rules("mode.debug", "mode.release")

target("foo")
    set_kind("static")
    add_files("src/interface.cpp")
    add_headerfiles("src/*.h")


