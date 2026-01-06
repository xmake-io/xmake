add_rules("mode.debug", "mode.release")

package("cmake")
    set_kind("binary")
    set_homepage("https://cmake.org")
    set_description("A cross-platform family of tools designed to build, test and package software")

    local is_precompiled = true
    if is_host("macosx") then
        add_urls("https://cmake.org/files/v$(version).tar.gz", {version = function (version)
                return table.concat(table.slice((version):split('%.'), 1, 2), '.') .. "/cmake-" .. version .. (version:ge("3.20") and "-macos-universal" or "-Darwin-x86_64")
            end})
        add_urls("https://github.com/Kitware/CMake/releases/download/v$(version).tar.gz", {version = function (version)
                return version .. "/cmake-" .. version .. (version:ge("3.20") and "-macos-universal" or "-Darwin-x86_64")
            end})
        add_versions("4.2.1",  "0bb18f295e52d7e9309980e361e79e76a1d8da67a1587255cbe3696ea998f597")
    elseif is_host("linux") then
        if os.arch():find("arm64.*") then
            add_urls("https://cmake.org/files/v$(version)-aarch64.tar.gz", {version = function (version)
                    return table.concat(table.slice((version):split('%.'), 1, 2), '.') .. "/cmake-" .. version .. (version:ge("3.20") and "-linux" or "-Linux")
                end})
            add_urls("https://github.com/Kitware/CMake/releases/download/v$(version)-aarch64.tar.gz", {version = function (version)
                return version .. "/cmake-" .. version .. (version:ge("3.20") and "-linux" or "-Linux")
                end})
            add_versions("4.2.1",  "3e178207a2c42af4cd4883127f8800b6faf99f3f5187dccc68bfb2cc7808f5f7")
        else
            add_urls("https://cmake.org/files/v$(version)-x86_64.tar.gz", {version = function (version)
                    return table.concat(table.slice((version):split('%.'), 1, 2), '.') .. "/cmake-" .. version .. (version:ge("3.20") and "-linux" or "-Linux")
                end})
            add_urls("https://github.com/Kitware/CMake/releases/download/v$(version)-x86_64.tar.gz", {version = function (version)
                return version .. "/cmake-" .. version .. (version:ge("3.20") and "-linux" or "-Linux")
                end})
            add_versions("4.2.1",  "c059bff1e97a2b6b5b0c0872263627486345ad0ed083298cb21cff2eda883980")
        end
    elseif is_host("windows") then
        if os.arch() == "x64" then
            add_urls("https://cmake.org/files/v$(version).zip", {excludes = {"*/doc/*"}, version = function (version)
                    return table.concat(table.slice((version):split('%.'), 1, 2), '.') .. "/cmake-" .. version .. (version:ge("3.20") and "-windows-x86_64" or "-win64-x64")
                end})
            add_urls("https://github.com/Kitware/CMake/releases/download/v$(version).zip", {excludes = {"*/doc/*"}, version = function (version)
                    return version .. "/cmake-" .. version .. (version:ge("3.20") and "-windows-x86_64" or "-win64-x64")
                end})
            add_versions("4.2.1",  "dfc2b2afac257555e3b9ce375b12b2883964283a366c17fec96cf4d17e4f1677")
        elseif os.arch() == "x86" then
            add_urls("https://cmake.org/files/v$(version).zip", {excludes = {"*/doc/*"}, version = function (version)
                    return table.concat(table.slice((version):split('%.'), 1, 2), '.') .. "/cmake-" .. version .. (version:ge("3.20") and "-windows-i386" or "-win32-x86")
                end})
            add_urls("https://github.com/Kitware/CMake/releases/download/v$(version).zip", {excludes = {"*/doc/*"}, version = function (version)
                    return version .. "/cmake-" .. version .. (version:ge("3.20") and "-windows-i386" or "-win32-x86")
                end})
            add_versions("4.2.1",  "696129556482da90293f9d64c1fa68dbe06b0ede80331d7da9aaa03aada6aecf")
        elseif os.arch() == "arm64" then
            add_urls("https://cmake.org/files/v$(version).zip", {excludes = {"*/doc/*"}, version = function (version)
                    return table.concat(table.slice((version):split('%.'), 1, 2), '.') .. "/cmake-" .. version .. "-windows-arm64"
                end})
            add_urls("https://github.com/Kitware/CMake/releases/download/v$(version).zip", {excludes = {"*/doc/*"}, version = function (version)
                    return version .. "/cmake-" .. version .. "-windows-arm64"
                end})
            add_versions("4.2.1",  "96b097ca3a019cd62839d4805958ad0163dd1adedcfbe578730d57c098aaf667")
        end
    else
        add_urls("https://github.com/Kitware/CMake/releases/download/v$(version)/cmake-$(version).tar.gz")
        add_versions("4.2.1",  "414aacfac54ba0e78e64a018720b64ed6bfca14b587047b8b3489f407a14a070")
        is_precompiled = false
    end

    if is_precompiled then
        add_schemes("source")
        on_scheme("source", function (package, scheme)
            scheme:add("urls", "https://github.com/Kitware/CMake/releases/download/v$(version)/cmake-$(version).tar.gz")
            scheme:add("versions", "4.2.1",  "414aacfac54ba0e78e64a018720b64ed6bfca14b587047b8b3489f407a14a070")
        end)
    end

    on_install("@linux", "@windows", "@msys", "@cygwin", "@macosx", function (package)
        local scheme = package:current_scheme()
        if scheme:is_default() then
            raise("trigger failure when installing binaries, then we will fallback to install it from source tarball.")
        else
            import("core.base.option")
            os.vrunv("sh", {"./bootstrap", "--parallel=" .. (option.get("jobs") or tostring(os.default_njob())),
                "--prefix=" .. package:installdir(), "--", "-DCMAKE_USE_OPENSSL=OFF"})
            import("package.tools.make").install(package)
        end
    end)

    on_test(function (package)
        os.vrun("cmake --version")
    end)
package_end()

add_requires("cmake", {system = false})

target("test")
    set_kind("binary")
    add_files("src/*.cpp")
    add_packages("cmake")
