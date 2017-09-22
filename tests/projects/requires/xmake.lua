-- define package
package("mbedtls")
    set_urls("https://github.com/ARMmbed/mbedtls.git")
    add_deps("https://github.com/glennrp/libpng.git@libpng >=1.6.28")
package_end()

-- group packages
package("zlib-mbedtls")
    add_deps("zlib >=1.2.11", {system = false})
    add_deps("mbedtls")
package_end()

-- requires
add_requires("zlib-mbedtls")
add_requires("xmake-repo@tboox.tbox ~1.6.0", {alias = "tbox"})
add_requires("unknown", {optional = true})

-- the debug mode
if is_mode("debug") then
    
    -- enable the debug symbols
    set_symbols("debug")

    -- disable optimization
    set_optimize("none")
end

-- the release mode
if is_mode("release") then

    -- set the symbols visibility: hidden
    set_symbols("hidden")

    -- enable fastest optimization
    set_optimize("fastest")

    -- strip all symbols
    set_strip("all")
end

-- add target
target("console_c")

    -- set kind
    set_kind("binary")

    -- add files
    add_files("src/*.c") 

    -- add packages
    add_packages("tbox", "zlib-mbedtls")

