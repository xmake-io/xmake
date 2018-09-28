package("cmake")

    set_kind("binary")
    set_homepage("https://cmake.org")
    set_description("A cross-platform family of tool designed to build, test and package software")

    if is_host("macosx") then
        add_urls("https://cmake.org/files/v3.11/cmake-3.11.4-Darwin-x86_64.tar.gz")
        add_versions("3.11.4", "2b5eb705f036b1906a5e0bce996e9cd56d43d73bdee8318ece3e5ce31657b812")
    elseif is_host("linux") and is_arch("x86_64") then
        add_urls("https://cmake.org/files/v3.11/cmake-3.11.4-Linux-x86_64.tar.gz")
        add_versions("3.11.4", "6dab016a6b82082b8bcd0f4d1e53418d6372015dd983d29367b9153f1a376435")
    elseif is_host("windows") then
        if os.arch() == "x64" then
            add_urls("https://cmake.org/files/v3.11/cmake-3.11.4-win64-x64.zip", {excludes = "*/doc/*"})
            add_versions("3.11.4", "d3102abd0ded446c898252b58857871ee170312d8e7fd5cbff01fbcb1068a6e5")
        else
            add_urls("https://cmake.org/files/v3.11/cmake-3.11.4-win32-x86.zip", {excludes = "*/doc/*"})
            add_versions("3.11.4", "b068001ff879f86e704977c50a8c5917e4b4406c66242366dba2674abe316579")
        end
    end

    on_install("macosx", function (package)
        os.cp("CMake.app/Contents/bin", package:installdir())
        os.cp("CMake.app/Contents/share", package:installdir())
    end)

    on_install("linux|x86_64", "windows", function (package)
        os.cp("bin", package:installdir())
        os.cp("share", package:installdir())
    end)

    on_install(function (package)
        import("package.manager").install("cmake")
    end)

    on_test(function (package)
        os.vrun("cmake --version")
    end)
