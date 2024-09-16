add_rules("mode.debug", "mode.release")

add_requires("brew::pcre2/libpcre2-8", {alias = "pcre2"})

target("brew")
    set_kind("binary")
    add_files("src/*.cpp")
    add_packages("pcre2")

