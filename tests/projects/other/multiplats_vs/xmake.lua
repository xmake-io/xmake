add_rules("mode.debug", "mode.release")

rule("vs2015_x86")
    on_load(function (target)
        target:set("arch", "x86")
        target:set("toolchains", "msvc", {vs = "2015"})
    end)

target("testvs_vs2015_x86")
    set_kind("binary")
    add_files("src/*.cpp", "src/*.rc")
    add_rules("vs2015_x86")

target("testvs")
    set_kind("binary")
    add_files("src/*.cpp", "src/*.rc")


