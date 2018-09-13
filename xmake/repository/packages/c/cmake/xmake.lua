package("cmake")

    set_kind("binary")
    set_homepage("https://cmake.org")
    set_description("A cross-platform family of tool designed to build, test and package software")

    on_build(function (package)
    end)

    on_install("macosx", "linux", function (package)
        import("package.manager.install")("cmake")
    end)

    on_install("windows", function (package)
        -- the winenv with cmake has been installed when installing git 
        raise()
    end)

