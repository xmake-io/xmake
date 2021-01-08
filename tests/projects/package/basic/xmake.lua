add_requires("tbox master", {debug = true})
add_requires("zlib >=1.2.11")
add_requires("pcre2", {system = false, optional = true})

add_rules("mode.debug", "mode.release")

target("console")
    set_kind("binary")
    add_files("src/*.c")
    add_packages("tbox", "zlib", "pcre2")

