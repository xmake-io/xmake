add_rules("mode.debug", "mode.release")

set_version("1.0.0")

includes("@builtin/xpack")

target("launcher_app")
    set_kind("binary")
    add_files("src/main.c")

xpack("launcher_app")
    set_formats("appimage", "runself", "deb", "srpm", "rpm", "targz", "zip", "tarxz", "srctargz", "srczip", "nsis", "wix", "dmg")
    set_title("Launcher Test")
    set_description("A test app that prints its argv and a known env var.")
    set_author("xmake <xmake@example.com>")
    add_targets("launcher_app")
    add_runargs("--mode", "test")
    add_runenvs("XMAKE_TEST_ENV", "launcher-ok")
