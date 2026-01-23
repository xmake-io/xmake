set_version("1.0.0")
add_rules("mode.debug", "mode.release")

includes("@builtin/xpack")

add_requires("zlib", {configs = {shared = true}, system = false})

target("qtapp")
    add_rules("qt.widgetapp")
    add_headerfiles("src/*.h")
    add_files("src/*.cpp")
    add_files("src/mainwindow.ui")
    add_files("src/mainwindow.h")
    add_packages("zlib")

xpack("qtapp")
    set_formats("nsis", "dmg", "appimage", "zip", "targz")
    set_title("Qt Widget App")
    set_author("ruki <waruqi@gmail.com>")
    set_description("A Qt Widget Application example for xpack.")
    set_homepage("https://xmake.io")
    set_license("Apache-2.0")
    set_licensefile("LICENSE.md")
    add_targets("qtapp")

    on_load(function (package)
        package:set("basename", "qtapp-$(plat)-$(arch)-v$(version)")
        -- set icon file based on format (use PNG for appimage, ICO for other formats)
        local scriptdir = os.scriptdir()
        if package:format() == "appimage" then
            package:set("iconfile", path.join(scriptdir, "src/assets/xmake.png"))
        else
            package:set("iconfile", path.join(scriptdir, "src/assets/xmake.ico"))
        end
    end)

