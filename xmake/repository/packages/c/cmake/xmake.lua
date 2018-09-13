package("cmake")

    set_kind("binary")
    set_homepage("https://cmake.org")
    set_description("A cross-platform family of tool designed to build, test and package software")

    if os.host() == "windows" then
        if os.arch() == "x64" then
            add_urls("https://cmake.org/files/v3.11/cmake-3.11.4-win64-x64.msi")
            add_versions("3.11.4", "56e3605b8e49cd446f3487da88fcc38cb9c3e9e99a20f5d4bd63e54b7a35f869")
        else
            add_urls("https://cmake.org/files/v3.11/cmake-3.11.4-win32-x86.msi")
            add_versions("3.11.4", "72b3b82b6d2c2f3a375c0d2799c01819df8669dc55694c8b8daaf6232e873725")
        end
    end

    on_build(function (package)
    end)

    on_install("macosx", "linux", function (package)
        import("package.manager.install")("cmake")
    end)

    on_install("windows", function (package)
        os.vrunv("msiexec.exe", {"/i", package:originfile(), "/quiet", "/qn", "/norestart"})
    end)

