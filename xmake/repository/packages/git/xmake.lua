package("git")

    set_kind("binary")
    set_homepage("https://git-scm.com/")
    set_description("A free and open source distributed version control system")

    if os.host() == "windows" then
        if os.arch() == "x64" then
            add_urls("https://github.com/tboox/xmake-win64env/archive/$(version).zip", {alias = "github"})
            add_urls("https://gitlab.com/tboox/xmake-win64env/-/archive/$(version)/xmake-win64env-$(version).zip", {alias = "gitlab"})
            add_versions("github:v1.0.1", "95170b1d144ebb30961611fd87b1e9404bbe37d2d904adb15f3e202bb3e19c21")
            add_versions("gitlab:v1.0.1", "00ec9a71d34725fb974fcdef3e6b21104a0b1681d0cd7d07ee64d4a73eed0c87")
        else
            add_urls("https://github.com/tboox/xmake-win32env/archive/$(version).zip", {alias = "github"})
            add_urls("https://gitlab.com/tboox/xmake-win32env/-/archive/$(version)/xmake-win32env-$(version).zip", {alias = "gitlab"})
            add_versions("github:v1.0.1", "3c46983379329a246596a2b5f0ff971b55e3eccbbfd34272e7121e13fb346db5")
            add_versions("gitlab:v1.0.1", "c9bd70a5394b9d943607268f876b81d29c360f7f2860375cec1e4146b44023bf")
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

