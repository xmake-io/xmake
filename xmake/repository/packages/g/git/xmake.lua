package("git")

    set_kind("binary")
    set_homepage("https://git-scm.com/")
    set_description("A free and open source distributed version control system")

    if os.host() == "windows" then
        if os.arch() == "x64" then
            add_urls("https://github.com/tboox/xmake-win64env/archive/$(version).zip", {alias = "github"})
            add_urls("https://gitlab.com/tboox/xmake-win64env/-/archive/$(version)/xmake-win64env-$(version).zip", {alias = "gitlab"})
            add_versions("github:v1.0.3", "df43e419a358b136cfc0ae343560684321722a39713c205a7a894edd9d15b2b5")
            add_versions("gitlab:v1.0.3", "376807a3386f15e734f3b2f51ed5d151d434fb99b7349412a2fb9e83d5e29d5c")
        else
            add_urls("https://github.com/tboox/xmake-win32env/archive/$(version).zip", {alias = "github"})
            add_urls("https://gitlab.com/tboox/xmake-win32env/-/archive/$(version)/xmake-win32env-$(version).zip", {alias = "gitlab"})
            add_versions("github:v1.0.3", "2a3b71baae67f3ebb057748d1261970d18d80be52e88427a4719d2185594fc21")
            add_versions("gitlab:v1.0.3", "2a627f78349702a85b710399c14f5dc0acfdb5ad840765e3e2637d554a373807")
        end
    end

    on_install("macosx", "linux", function (package)
        import("package.manager.install")("git")
    end)

    on_install("windows", function (package)

        -- install winenv with git
        local winenv_dir = path.join(val("globaldir"), "winenv")
        os.mkdir(winenv_dir)
        os.cp("*", winenv_dir)

        -- load winenv 
        import("winenv", {rootdir = winenv_dir})(winenv_dir)
    end)

    on_test(function (package)
        os.vrun("git --version")
    end)
