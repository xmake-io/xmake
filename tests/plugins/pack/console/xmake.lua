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
    set_formats("nsis", "srpm", "rpm", "deb", "zip", "targz", "srczip", "srctargz", "runself", "wix", "dmg", "appimage")
    set_title("hello")
    set_author("ruki <waruqi@gmail.com>")
    set_description("A test installer.")
    set_homepage("https://xmake.io")
    set_license("Apache-2.0")
    set_licensefile("LICENSE.md")
    add_targets("test", "foo")
    add_installfiles("src/(assets/*.png)", {prefixdir = "images"})
    add_sourcefiles("(src/**)")
    add_sourcefiles("xmake.lua")
    add_components("LongPath")

    on_load(function (package)
        if package:with_source() then
            package:set("basename", "test-$(plat)-src-v$(version)")
        else
            package:set("basename", "test-$(plat)-$(arch)-v$(version)")
        end
        -- set icon file based on format (use PNG for appimage, ICO for other formats)
        local scriptdir = os.scriptdir()
        if package:format() == "appimage" then
            package:set("iconfile", path.join(scriptdir, "src/assets/xmake.png"))
        else
            package:set("iconfile", path.join(scriptdir, "src/assets/xmake.ico"))
        end
    end)

    after_installcmd(function (package, batchcmds)
        if package:format() == "runself" then
            batchcmds:runv("echo", {"hello"})
        else
            batchcmds:mkdir(package:installdir("resources"))
            batchcmds:cp("src/assets/*.txt", package:installdir("resources"), {rootdir = "src"})
            batchcmds:mkdir(package:installdir("stub"))
        end
    end)

    after_uninstallcmd(function (package, batchcmds)
        batchcmds:rmdir(package:installdir("resources"))
        batchcmds:rmdir(package:installdir("stub"))
    end)

xpack_component("LongPath")
    set_default(false)
    set_title("Enable Long Path")
    set_description("Increases the maximum path length limit, up to 32,767 characters (before 256).")
    on_installcmd(function (component, batchcmds)
        batchcmds:rawcmd("wix", [[
    <RegistryKey Root="HKLM" Key="SYSTEM\CurrentControlSet\Control\FileSystem">
        <RegistryValue Type="integer" Name="LongPathsEnabled" Value="1" KeyPath="yes"/>
    </RegistryKey>
        ]])
        batchcmds:rawcmd("nsis", [[
  ${If} $NoAdmin == "false"
    ; Enable long path
    WriteRegDWORD ${HKLM} "SYSTEM\CurrentControlSet\Control\FileSystem" "LongPathsEnabled" 1
  ${EndIf}]])
    end)
