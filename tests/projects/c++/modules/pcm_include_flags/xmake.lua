set_languages("c++20")
set_policy("build.c++.modules.std", false)

target("pcm_include_flags")
    set_kind("binary")
    add_files("main.cpp")
    add_files("answer.cppm", {includedirs = "file headers", sysincludedirs = "file system headers", defines = "FILE_VALUE=42"})
    add_includedirs("local headers")
    add_sysincludedirs("system headers")
    add_cxxflags("-Werror=unused-command-line-argument", {force = true})
    on_config(function (target)
        local compinst = target:compiler("cxx")
        local sourceopts = {target = target, sourcefile = "answer.cppm"}
        local pcmopts = table.join(sourceopts, {excludeconfigs = {"includedirs", "sysincludedirs"}})
        local sourceflags = compinst:compflags(sourceopts)
        local pcmflags = compinst:compflags(pcmopts)
        local sourceargs = table.concat(sourceflags, " ")
        local pcmargs = table.concat(pcmflags, " ")
        for _, dir in ipairs({"local headers", "system headers", "file headers", "file system headers"}) do
            assert(sourceargs:find(dir, 1, true), sourceargs)
            assert(not pcmargs:find(dir, 1, true), pcmargs)
        end
        assert(pcmargs:find("FILE_VALUE=42", 1, true), pcmargs)
        -- Alternating calls must preserve source flags and reuse the correct PCM flags.
        assert(table.concat(compinst:compflags(sourceopts), " ") == sourceargs)
        assert(table.concat(compinst:compflags(pcmopts), " ") == pcmargs)
        local sysonly = table.join(sourceopts, {excludeconfigs = {"includedirs"}})
        local sysargs = table.concat(compinst:compflags(sysonly), " ")
        assert(not sysargs:find("local headers", 1, true), sysargs)
        assert(sysargs:find("system headers", 1, true), sysargs)

        -- Check explicit configs with the configured compiler, preserving caller-supplied raw flags.
        local configs = {defines = {"KEEP=1"}, force = {cxxflags = {"-Iraw_include", "-fmodule-file=dep=dep.pcm"}}}
        local opts = table.join(pcmopts, {configs = configs})
        local expected = table.concat(compinst:compflags(opts), " ")
        configs.includedirs = {"argument headers"}
        configs.sysincludedirs = {"argument system headers"}
        assert(table.concat(compinst:compflags(opts), " ") == expected)
        assert(table.concat(configs.includedirs, " ") == "argument headers")
        assert(table.concat(configs.sysincludedirs, " ") == "argument system headers")
        local ordinary = table.concat(compinst:compflags(table.join(sourceopts, {configs = configs})), " ")
        assert(ordinary:find("argument headers", 1, true), ordinary)
        assert(ordinary:find("argument system headers", 1, true), ordinary)
        assert(expected:find("KEEP=1", 1, true), expected)
        assert(expected:find("-Iraw_include", 1, true), expected)
        assert(expected:find("-fmodule-file=dep=dep.pcm", 1, true), expected)
    end)
