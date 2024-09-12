add_rules("mode.debug", "mode.release")

target("foo")
    set_kind("shared")
    add_files("src/foo.cpp")
    add_rules("utils.symbols.export_all", {export_classes = true})

target("bar")
    set_kind("shared")
    add_files("src/bar.cpp")
    add_rules("utils.symbols.export_all", {export_filter = function (symbol, opt)
        local filepath = opt.sourcefile or opt.objectfile
        if filepath and filepath:find("bar.cpp", 1, true) and symbol:find("add", 1, true) then
            print("export: %s at %s", symbol, filepath)
            return true
        end
    end})

target("demo")
    set_kind("binary")
    add_deps("foo", "bar")
    add_files("src/main.cpp")



