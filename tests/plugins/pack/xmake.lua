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
    set_formats("nsis", "zip", "targz")
    set_title("hello")
    set_description("A test installer.")
    set_homepage("https://xmake.io")
    set_licensefile("LICENSE.md")
    add_targets("test", "foo")
    set_basename("test-$(plat)-$(arch)-v$(version)")
    add_installfiles("src/(assets/*.png)", {prefixdir = "images"})
    set_iconfile("src/assets/xmake.ico")
    add_components("LongPath")

    after_installcmd(function (package, batchcmds)
        batchcmds:mkdir(package:installdir("resources"))
        batchcmds:cp("src/assets/*.txt", package:installdir("resources"), {rootdir = "src"})
        batchcmds:mkdir(package:installdir("stub"))
    end)

    after_uninstallcmd(function (package, batchcmds)
        batchcmds:rmdir(package:installdir("resources"))
        batchcmds:rmdir(package:installdir("stub"))
    end)

xpack_component("LongPath")
    set_title("Enable Long Path")
    set_description("Increases the maximum path length limit, up to 32,767 characters (before 256).")
    on_installcmd(function (component, batchcmds)
        batchcmds:rawcmd("nsis", [[
  ${If} $NoAdmin == "false"
    ; Enable long path
    WriteRegDWORD ${HKLM} "SYSTEM\CurrentControlSet\Control\FileSystem" "LongPathsEnabled" 1
  ${EndIf}]])
    end)
