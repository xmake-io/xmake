rule("xx")
    add_deps("c++")
    on_load(function (target)

        -- add .xx
        local rule = target:rule("c++.build"):clone()
        rule:set("extensions", ".xx")
        target:rule_add(rule)

        -- patch sourcebatch for .xx
        local sourcebatch = target:sourcebatches()["c++.build"]
        sourcebatch.sourcekind = "cxx"
        sourcebatch.objectfiles = {}
        sourcebatch.dependfiles = {}
        for _, sourcefile in ipairs(sourcebatch.sourcefiles) do
            local objectfile = target:objectfile(sourcefile)
            local dependfile = target:dependfile(objectfile)
            table.insert(sourcebatch.objectfiles, objectfile)
            table.insert(sourcebatch.dependfiles, dependfile)
        end

        -- force as c++ source file
        if target:is_plat("windows") then
            target:add("cxxflags", "/TP")
        else
            target:add("cxxflags", "-x c++")
        end
    end)

target("test")
    set_kind("binary")
    add_rules("xx")
    add_files("src/*.xx", "src/*.cc")

