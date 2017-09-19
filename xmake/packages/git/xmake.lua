package("git")

    set_kind("binary")
    set_homepage("https://git-scm.com/")
    set_description("A free and open source distributed version control system")
--    add_imports("devel.package_manager", "lib.detect.find_tool")

    on_build(function (package)
    end)

    on_install(function (package)
--        package_manager.install("git")
    end)

    on_install("windows", function (package)
    end)

    on_test(function (package)
        assert(find_tool("git"))
    end)
