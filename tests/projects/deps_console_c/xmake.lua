-- define package
package("mbedtls")
    set_urls("git@github.com:ARMmbed/mbedtls.git")
    add_requires("git@github.com:glennrp/libpng.git@libpng >=1.6.28")
    on_build(function (package)
    end)
    on_install(function (package)
    end)
package_end()


package("zlib")
    set_urls           ("http://zlib.net/zlib-$(version).tar.gz",
                        "https://downloads.sourceforge.net/project/libpng/zlib/$(version)/zlib-$(version).tar.gz")
    set_versions       ("1.2.10", "1.2.11")
    set_sha256s        ("8d7e9f698ce48787b6e1c67e6bff79e487303e66077e25cb9784ac8835978017",
                        "c3e5e9fdd5004dcb542feda5ee4f0ff0744628baf8ed2dd5d66f8ca1197cb1a1")
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

