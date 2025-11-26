set_version("1.0.0")
add_rules("mode.debug", "mode.release")

includes("@builtin/xpack")

target("macapp")
    add_rules("xcode.application")
    add_files("src/*.m", "src/**.storyboard", "src/*.xcassets")
    add_files("src/Info.plist")

xpack("macapp")
    set_formats("dmg")
    set_title("MacApp Test")
    set_author("ruki <waruqi@gmail.com>")
    set_description("A test macOS application installer.")
    set_homepage("https://xmake.io")
    set_license("Apache-2.0")
    add_targets("macapp")

