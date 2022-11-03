add_rules("mode.debug", "mode.release")

includes("ispc.lua")

target("test_ispc")
    set_kind("object")
    add_rules("utils.ispc", {header_extension = "_ispc.h"})
    add_files("src/*.ispc")
    set_values("ispc.flags", "--target=host")
    set_policy("build.across_targets_in_parallel", false)

target("test")
    set_kind("binary")
    add_deps("test_ispc")
    add_files("src/*.cpp")

