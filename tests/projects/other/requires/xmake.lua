-- define package
package("mbedtls")
    set_urls("https://github.com/ARMmbed/mbedtls.git")
    add_deps("https://github.com/glennrp/libpng.git@libpng >=1.6.28")
package_end()

-- group packages
package("zlib-mbedtls")
    add_deps("zlib >=1.2.11", {system = false})
    add_deps("mbedtls", {optional = true})
package_end()

-- requires
add_requires("zlib-mbedtls")
add_requires("xmake-repo@tboox.tbox ~1.6.0", {alias = "tbox"})
add_requires("unknown", {optional = true})

-- add modes
add_rules("mode.debug", "mode.release")

-- add target
target("console_c")

    -- set kind
    set_kind("binary")

    -- add files
    add_files("src/*.c") 

    -- add packages
    add_packages("tbox", "zlib-mbedtls")

