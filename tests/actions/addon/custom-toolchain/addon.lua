addon("custom-toolchain")
    set_description("the addon which provides a custom toolchain")
    set_sourcedir("src")
    -- the tool modules are imported with their plain names by the internal calls,
    -- e.g. find_tool("mycl6x"), import("core.tools.mycl6x")
    add_globalmodules("core.tools.mycl6x", "detect.tools.find_mycl6x")
