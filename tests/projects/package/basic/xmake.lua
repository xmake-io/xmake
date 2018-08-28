
-- requires
add_requires("tbox master")
add_requires("zlib >=1.2.11", {optional = true})
add_requires("pcre2", {system = false})

-- add modes
add_rules("mode.debug", "mode.release")

-- add target
target("console")

    -- set kind
    set_kind("binary")

    -- add files
    add_files("src/*.c") 

    -- add packages
    add_packages("tbox", "zlib", "pcre2")

