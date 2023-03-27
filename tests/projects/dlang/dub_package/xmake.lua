add_rules("mode.debug", "mode.release")

add_requires("dub::log 0.4.3")

target("test")
    set_kind("binary")
    add_files("src/main.d")
    add_packages("dub::log")