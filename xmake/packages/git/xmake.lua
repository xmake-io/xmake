package("git")

    set_kind("binary")
    set_homepage("https://git-scm.com/")
    set_description("A free and open source distributed version control system")
    set_versions("v1.0.1")

    if os.host() == "windows" then
        if os.arch() == "x64" then
            add_urls("https://gitee.com/tboox/xmake-winenv/raw/master/win64/$(version).zip")
            add_urls("https://coding.net/u/waruqi/p/xmake-winenv/git/raw/master/win64/$(version).zip")
            add_urls("https://github.com/tboox/xmake-win64env/archive/$(version).zip")
            add_sha256s("v1.0.1", "95170b1d144ebb30961611fd87b1e9404bbe37d2d904adb15f3e202bb3e19c21")
        else
            add_urls("https://gitee.com/tboox/xmake-winenv/raw/master/win32/$(version).zip")
            add_urls("https://coding.net/u/waruqi/p/xmake-winenv/git/raw/master/win32/$(version).zip")
            add_urls("https://github.com/tboox/xmake-win32env/archive/$(version).zip")
            add_sha256s("v1.0.1", "3c46983379329a246596a2b5f0ff971b55e3eccbbfd34272e7121e13fb346db5")
        end
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

