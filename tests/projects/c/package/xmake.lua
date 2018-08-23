
-- define package
package("zlib-pcre2")
    add_deps("zlib >=1.2.11", {system = false})
    add_deps("pcre2", {optional = true})
package_end()

-- requires
add_requires("zlib-pcre2")
add_requires("xmake-repo@tboox.tbox ~1.6.0", {alias = "tbox"})
add_requires("unknown", {optional = true})

-- add modes
add_rules("mode.debug", "mode.release")

-- add target
target("console")

    -- set kind
    set_kind("binary")

    -- add files
    add_files("src/*.c") 

    -- add packages
    add_packages("tbox", "zlib-mbedtls")

