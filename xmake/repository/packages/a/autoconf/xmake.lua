package("autoconf")

    set_kind("binary")
    set_homepage("https://www.gnu.org/software/autoconf/autoconf.html")
    set_description("An extensible package of M4 macros that produce shell scripts to automatically configure software source code packages.")

    if is_host("macosx", "linux") then
        add_urls("http://ftp.gnu.org/gnu/autoconf/autoconf-$(version).tar.gz",
                 "https://mirrors.ustc.edu.cn/gnu/autoconf/autoconf-$(version).tar.gz",
                 "git://git.sv.gnu.org/autoconf")
        add_versions("2.69", "954bd69b391edc12d6a4a51a2dd1476543da5c6bbf05a95b59dc0dd6fd4c2969")
        add_versions("2.68", "eff70a2916f2e2b3ed7fe8a2d7e63d72cf3a23684b56456b319c3ebce0705d99")
    end

    on_install("macosx", "linux", function (package)
        import("package.tools.autoconf").install(package)
    end)

    on_test(function (package)
        os.vrun("autoconf --version")
    end)
