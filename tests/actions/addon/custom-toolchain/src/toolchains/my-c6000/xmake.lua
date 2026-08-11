-- a custom toolchain distributed as an addon
--
-- @see tests/apis/custom_toolchain for the same toolchain maintained inside a project,
-- distributing it as an addon is the recommended way
--
toolchain("my-c6000")
    set_kind("standalone")
    set_description("the custom toolchain of the tests")

    set_toolset("cc", "mycl6x")
    set_toolset("ld", "mycl6x")

    on_check(function (toolchain)
        return import("lib.detect.find_tool")("mycl6x")
    end)

    on_load(function (toolchain)
        toolchain:add("cxflags", "-DMY_C6000")
    end)
