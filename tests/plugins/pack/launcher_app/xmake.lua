add_rules("mode.debug", "mode.release")

set_version("1.0.0")

includes("@builtin/xpack")

target("launcher_app")
    set_kind("binary")
    add_files("src/main.c")

xpack("launcherapp")
    set_formats("appimage", "runself", "deb", "srpm", "rpm", "targz", "zip", "tarxz", "srctargz", "srczip", "nsis", "wix", "dmg")
    set_title("Launcher Test")
    set_description("A test app that prints its argv and a known env var.")
    set_author("xmake <xmake@example.com>")
    set_license("Apache-2.0")
    set_homepage("https://xmake.io")
    add_targets("launcher_app")
    add_sourcefiles("(src/**)")
    add_sourcefiles("xmake.lua")
    add_runargs("--mode", "test")
    add_runenvs("XMAKE_TEST_ENV", "launcher-ok")

    on_load(function (package)
        if package:format() == "appimage" then
            package:set("iconfile", path.join(os.scriptdir(), "src", "assets", "xmake.png"))
        end
    end)
