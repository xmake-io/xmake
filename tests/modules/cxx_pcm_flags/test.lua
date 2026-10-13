import("core.tool.compiler")

function test_exclude_named_configs(t)
    local compinst = compiler.load("cxx")
    local configs = {
        defines = {"KEEP=1"},
        -- Raw flags are explicitly supplied by the caller, not generated from named configs.
        force = {cxxflags = {"-Iraw_include", "-fmodule-file=dep=dep.pcm"}}
    }
    local excluded = {"includedirs", "sysincludedirs"}
    local expected = compinst:compflags({configs = configs, excludeconfigs = excluded})
    configs.includedirs = {"local headers"}
    configs.sysincludedirs = {"system headers"}
    local original = table.clone(configs)
    t:are_equal(compinst:compflags({configs = configs, excludeconfigs = excluded}), expected)
    t:are_equal(configs, original)
    local ordinary = table.concat(compinst:compflags({configs = configs}), " ")
    assert(ordinary:find("local headers", 1, true))
    assert(ordinary:find("system headers", 1, true))
    assert(table.contains(expected, "-Iraw_include"))
    assert(table.contains(expected, "-fmodule-file=dep=dep.pcm"))
end
