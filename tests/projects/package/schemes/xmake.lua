add_rules("mode.debug", "mode.release")

package("ninja")
    set_kind("binary")
    set_homepage("https://ninja-build.org/")
    set_description("Small build system for use with gyp or CMake.")

    local function add_binary_urls(package, scheme_name)
        local scheme = package
        if scheme_name then
            scheme = package:scheme(scheme_name)
        end

        if is_host("macosx") then
            scheme:add("urls", "https://github.com/ninja-build/ninja/releases/download/v$(version)/ninja-mac.zip")
            scheme:add("versions", "1.13.1", "da7797794153629aca5570ef7c813342d0be214ba84632af886856e8f0063dd9")
            return true
        elseif is_host("linux") then
            scheme:add("urls", "https://github.com/ninja-build/ninja/releases/download/v$(version)/ninja-linux.zip")
            scheme:add("versions", "1.13.1", "0830252db77884957a1a4b87b05a1e2d9b5f658b8367f82999a941884cbe0238")
            return true
        elseif is_host("windows") then
            scheme:add("urls", "https://github.com/ninja-build/ninja/releases/download/v$(version)/ninja-win.zip")
            scheme:add("versions", "1.13.1", "26a40fa8595694dec2fad4911e62d29e10525d2133c9a4230b66397774ae25bf")
            return true
        end
    end

    local function add_source_urls(package, scheme_name)
        local scheme = package
        if scheme_name then
            scheme = package:scheme(scheme_name)
        end
        scheme:add("urls", "https://github.com/ninja-build/ninja/archive/refs/tags/v$(version).tar.gz")
        scheme:add("versions", "1.13.1",  "f0055ad0369bf2e372955ba55128d000cfcc21777057806015b45e4accbebf23")
    end

    if add_schemes then
        add_schemes("binary", "source")
        on_source(function (package)
            add_binary_urls(package, "binary")
            add_source_urls(package, "source")
        end)
    else
        -- for compatibility with older xmake versions
        on_source(function (package)
            if add_binary_urls(package) then
                package:data_set("scheme", "binary")
            else
                add_source_urls(package)
                package:data_set("scheme", "source")
            end
        end)
    end

    on_install("@linux", "@windows", "@msys", "@cygwin", "@macosx", function (package)
        local scheme = package:current_scheme()
        local scheme_name = scheme and scheme:name() or package:data("scheme")
        if scheme_name and scheme_name == "binary" then
            raise("trigger failure when installing binaries, then we will fallback to install it from source tarball.")
        else
            local configs = {}
            configs.version = package:version_str()
            os.cp(path.join(package:scriptdir(), "port", "xmake.lua"), "xmake.lua")
            import("package.tools.xmake").install(package, configs)
        end
    end)

    on_test(function (package)
        os.vrun("ninja --version")
    end)
package_end()

add_requires("ninja", {system = false})

target("test")
    set_kind("binary")
    add_files("src/*.cpp")
    add_packages("ninja")
