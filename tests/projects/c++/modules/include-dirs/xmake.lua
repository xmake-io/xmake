add_rules("mode.debug", "mode.release")

rule("include")
    before_config(function (target)
        target:add("includedirs", "$(projectdir)/include")
    end)

target("src1")
    set_kind("static")
    add_rules("include")
    add_files("src/*.mpp", {public = true})
    add_defines("A")

target("src2")
    set_kind("binary")
    add_deps("src1")
    add_files("src/*.cpp")
