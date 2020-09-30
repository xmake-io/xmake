package("7z")

    set_kind("binary")
    set_homepage("https://www.7-zip.org/")
    set_description("A file archiver with a high compression ratio.")

    if os.host() == "windows" then
        if os.arch() == "x64" then
            set_urls("https://github.com/xmake-mirror/7zip/releases/download/$(version)/7z$(version)-x64.zip",
                     "https://gitlab.com/xmake-mirror/7zip-releases/raw/master/7z$(version)-x64.zip")
            add_versions("19.00", "fc21cf510d70a69bfa8e5b0449fe0a054fb76e2f8bd568364821f319c8b1d86d")
            add_versions("18.05", "e6e2d21e2c482f1b1c5a6d21ed80800ce1273b902cf4b9afa68621545540ee2f")
        else
            set_urls("https://github.com/xmake-mirror/7zip/releases/download/$(version)/7z$(version)-x86.zip",
                     "https://gitlab.com/xmake-mirror/7zip-releases/raw/master/7z$(version)-x86.zip")
            add_versions("19.00", "f84fab081a2d8a6b5868a2eaf01cd56017363fb24560259cea80567f8062334f")
            add_versions("18.05", "544c37bebee30437aba405071484e0ac6310332b4bdabe4ca7420a800d4b4b5e")
        end
    else
        add_urls("https://github.com/xmake-mirror/p7zip/archive/$(version).zip", {alias = "github"})
        add_urls("https://gitlab.com/xmake-mirror/p7zip/-/archive/$(version)/p7zip-$(version).zip", {alias = "gitlab"})
        add_urls("https://gitee.com/xmake-mirror/p7zip.git",
                 "https://github.com/xmake-mirror/p7zip.git",
                 "https://gitlab.com/xmake-mirror/p7zip.git")
        add_versions("github:16.02", "1cb98f266f8f6109d99d35473dfc8db71a9933b1dea58a89833650858e504b52")
        add_versions("gitlab:16.02", "93c6a14efb6dc9ee2fbb8c8fd4b5f319537c98182f8810f3b25cfa6363d9905b")
    end

    on_install("@macosx", "@linux", function (package)
        os.vrun("make 7z")
        os.cp("bin", package:installdir())
    end)

    on_install("@windows", function (package)
        os.cp("*", package:installdir("bin"))
    end)

    on_test(function (package)
        os.vrun("7z --help")
    end)
