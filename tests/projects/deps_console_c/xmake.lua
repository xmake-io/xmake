-- define package
package("mbedtls")
    set_urls("https://github.com/ARMmbed/mbedtls.git")
    add_requires("https://github.com/glennrp/libpng.git@libpng >=1.6.28")
package_end()

-- group packages
package("zlib-mbedtls")
    add_requires("zlib >=1.2.11")
    add_requires("mbedtls master optional")
package_end()

-- requires
add_requires("zlib-mbedtls")
add_requires("xmake-repo@tboox.tbox >=1.5.1 <1.6.1 optional")

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

