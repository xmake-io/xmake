package("git")

    set_kind("binary")
    set_homepage("https://git-scm.com/")
    set_description("A free and open source distributed version control system")

    if os.host() == "windows" then
        if os.arch() == "x64" then
            add_urls("https://github.com/tboox/xmake-win64env/archive/$(version).zip", {alias = "github"})
            add_urls("https://gitlab.com/tboox/xmake-win64env/-/archive/$(version)/xmake-win64env-$(version).zip", {alias = "gitlab"})
            add_versions("github:v1.0.2", "33c7876930dd12041f253b662c2ded7a07c387341b2f91776d385ea88c90653e")
            add_versions("gitlab:v1.0.2", "733bcf61a32579d61f924f4910f686fbfcae4d6a83ad0ba05aada596cc6dc4ce")
        else
            add_urls("https://github.com/tboox/xmake-win32env/archive/$(version).zip", {alias = "github"})
            add_urls("https://gitlab.com/tboox/xmake-win32env/-/archive/$(version)/xmake-win32env-$(version).zip", {alias = "gitlab"})
            add_versions("github:v1.0.2", "5d98239c2726885f6c9faafe7394c67cf7fbc4419a5596bcf85ca6256af50550")
            add_versions("gitlab:v1.0.2", "1dd80a91602e857df2f6aa103adeb863c171955751ba04e53b7da9cc1ac64982")
        end
    end

    on_build(function (package)
    end)

    on_install("macosx", "linux", function (package)
        import("package.manager.install")("git")
    end)

    on_install("windows", function (package)

        -- install winenv with git
        local winenv_dir = path.translate("~/.xmake/winenv")
        os.mkdir(winenv_dir)
        os.cp("*", winenv_dir)

        -- load winenv 
        import("winenv", {rootdir = winenv_dir})(winenv_dir)
    end)

    on_test(function (package)
        os.vrun("git --version")
    end)
