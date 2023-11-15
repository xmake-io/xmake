set_version("1.0.0")
add_rules("mode.debug", "mode.release")

includes("@builtin/xpack")

add_requires("zlib", {configs = {shared = true}})

target("test")
    set_kind("binary")
    add_files("src/*.cpp")
    if is_plat("windows") then
        add_files("src/*.rc")
    end

target("foo")
    set_kind("shared")
    add_files("src/*.cpp")
    add_headerfiles("include/(*.h)")
    add_packages("zlib")

xpack("test")
    set_formats("nsis")
    set_description("hello")
    add_targets("test", "foo")
    set_basename("test-$(plat)-$(arch)-v$(version)")
    add_installfiles("src/(assets/*.png)", {prefixdir = "images"})
    set_iconfile("src/assets/xmake.ico")
    after_installcmd(function (package, batchcmds)
        batchcmds:cp("src/assets/*.txt", "resources/", {rootdir = "src"})
        batchcmds:mkdir("stub")
    end)
    after_uninstallcmd(function (package, batchcmds)
        batchcmds:rmdir("resources")
        batchcmds:rmdir("stub")
    end)

