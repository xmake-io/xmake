rule("xx.build")
    set_base("c++.build")
    set_extensions(".xx")
    on_load(function (target)
        local sourcebatch = target:sourcebatches()["xx.build"]
        sourcebatch.sourcekind = "cxx"
        sourcebatch.objectfiles = {}
        sourcebatch.dependfiles = {}
        for _, sourcefile in ipairs(sourcebatch.sourcefiles) do
            local objectfile = target:objectfile(sourcefile)
            local dependfile = target:dependfile(objectfile)
            table.insert(sourcebatch.objectfiles, objectfile)
            table.insert(sourcebatch.dependfiles, dependfile)
        end
        target:add("cxxflags", "-x c++")
    end)

rule("xx")
    set_base("c++")
    add_deps("xx.build")

target("test")
    set_kind("binary")
    add_rules("xx")
    add_files("src/*.xx")

