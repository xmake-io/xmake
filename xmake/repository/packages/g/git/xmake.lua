package("git")

    set_kind("binary")
    set_homepage("https://git-scm.com/")
    set_description("A free and open source distributed version control system")

    if os.host() == "windows" then
        if os.arch() == "x64" then
            add_urls("https://github.com/git-for-windows/git/releases/download/v$(version).windows.1/MinGit-$(version)-64-bit.zip",
                     "https://gitlab.com/xmake-mirror/git-for-windows-releases/raw/master/MinGit-$(version)-64-bit.zip")
            if winos.version():gt("winxp") then
                add_versions("2.20.0", "f577f81c401535858761fc4857a105337cc12880b79e72f89d0740167083d287")
            else
                add_versions("2.10.0", "2e1101ec57da526728704c04792293613f3c5aa18e65f13a4129d00b54de2087")
            end
        else
            add_urls("https://github.com/git-for-windows/git/releases/download/v$(version).windows.1/MinGit-$(version)-32-bit.zip",
                     "https://gitlab.com/xmake-mirror/git-for-windows-releases/raw/master/MinGit-$(version)-32-bit.zip")
            if winos.version():gt("winxp") then
                add_versions("2.20.0", "39d3dce9f67d7ae884edf0416d28f6dd8e24b6326de8e509613a2b12fb4f0820")
            else
                add_versions("2.10.0", "36f890870126dcf840d87eaec7e55b8a483bc336ebf8970de2f9d549a3cfc195")
            end
        end
    end

    on_load("@windows", function (package)
        package:addenv("PATH", path.join("share", "MinGit", "mingw32", "bin"))
        package:addenv("PATH", path.join("share", "MinGit", "cmd"))
    end)

    on_install("@macosx", "@linux", function (package)
        import("package.manager.install_package")("git")
    end)

    on_install("@windows", function (package)
        os.cp("*", package:installdir("share/MinGit"))
    end)

    on_test(function (package)
        os.vrun("git --version")
    end)
