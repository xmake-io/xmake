-- define package
package("mbedtls")
    set_url("git@github.com:ARMmbed/mbedtls.git")
    on_build(function (package)
    end)
    on_install(function (package)
    end)
package_end()

-- requires
add_requires("zlib >=1.2.11")
add_requires("mbedtls master optional")
add_requires("xmake-repo@tboox.tbox >=1.5.1")
add_requires("git@github.com:glennrp/libpng.git@libpng >=1.6.28")

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

