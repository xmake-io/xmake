package("git")

    set_kind("binary")
    set_homepage("https://git-scm.com/")
    set_description("A free and open source distributed version control system")

    if os.host() == "windows" then
        local winenv_arch = ifelse(os.arch() == "x64", "win64", "win32")
        add_urls(format("https://github.com/tboox/xmake-%senv/archive/master.zip", winenv_arch))
        add_urls(format("https://coding.net/u/waruqi/p/xmake-%senv/git/archive/master", winenv_arch))
    else
        add_imports("package.manager.install")
    end

    on_build(function (package)
    end)

    on_install(function (package)
        install("git")
    end)

    on_install("windows", function (package)

        -- install winenv with git
        local winenv_dir = path.translate("~/.xmake/winenv")
        os.mkdir(winenv_dir)
        os.cp("*", winenv_dir)

        -- load winenv 
        import("winenv", {rootdir = winenv_dir})(winenv_dir)
    end)

