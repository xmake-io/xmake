package("automake")

    set_kind("binary")
    set_homepage("https://www.gnu.org/software/automake/")
    set_description("A tool for automatically generating Makefile.in files compliant with the GNU Coding Standards.")

    if is_host("macosx", "linux") then
        add_urls("http://ftp.gnu.org/gnu/automake/automake-$(version).tar.gz",
                 "https://mirrors.ustc.edu.cn/gnu/automake/automake-$(version).tar.gz")
        add_versions("1.16.1", "608a97523f97db32f1f5d5615c98ca69326ced2054c9f82e65bade7fc4c9dea8")
        add_versions("1.15.1", "988e32527abe052307d21c8ca000aa238b914df363a617e38f4fb89f5abf6260")
        add_versions("1.9.6", "e6d3030dd3f7a07ee2075da5f77864a3cc3e78c5bf76bb48df23dbe3d6ba13b9")
        add_versions("1.9.5", "68712753fcb756f3707b7da554917afb348450eb8530cae3b623a067078596fd")
    end

    on_install("macosx", "linux", function (package)
        import("package.tools.autoconf").install(package)
        io.writefile(path.join(package:installdir("share", "aclocal"), "dirlist"), [[
            /usr/local/share/aclocal
            /usr/share/aclocal
        ]])
    end)

    on_test(function (package)
        os.vrun("automake --version")
    end)
