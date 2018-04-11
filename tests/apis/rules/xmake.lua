
-- define rule: markdown
rule("markdown")
    set_extensions(".md", ".markdown")
    on_build_file(function (target, sourcefile)
        os.cp(sourcefile, path.join(target:targetdir(), path.basename(sourcefile) .. ".html"))
    end)

-- define rule: man
rule("man")
    add_imports("core.project.rule")
    on_build_files(function (target, sourcefiles)
        for _, sourcefile in ipairs(sourcefiles) do
            print("generating man: %s", sourcefile)
        end
        rule.build_files("markdown", target, sourcefiles)
    end)

-- define rule: c code
rule("c code")
    add_imports("core.tool.compiler")
    on_build_file(function (target, sourcefile)
        local objectfile_o = os.tmpfile() .. ".o"
        local sourcefile_c = os.tmpfile() .. ".c"
        os.cp(sourcefile, sourcefile_c)
        compiler.compile(sourcefile_c, objectfile_o)
        table.insert(target:objectfiles(), objectfile_o)
    end)

-- define rule: stub3
rule("stub3")
    on_load(function (target)
        print("rule(stub3): on_load")
    end)

-- define rule: stub2
rule("stub2")
    on_load(function (target)
        print("rule(stub2): on_load")
    end)
    before_build(function (target)
        print("rule(stub2): before_build")
    end)
    on_build(function (target)
        print("rule(stub2): on_build")
    end)
    after_build(function (target)
        print("rule(stub2): after_build")
    end)

-- define rule: stub1
rule("stub1")
    add_deps("stub2")
    on_load(function (target)
        print("rule(stub1): on_load")
    end)

    before_build(function (target)
        print("rule(stub1): before_build")
    end)
    on_build(function (target)
        print("rule(stub1): on_build")
    end)
    after_build(function (target)
        print("rule(stub1): after_build")
    end)

    before_clean(function (target)
        print("rule(stub1): before_build")
    end)
    on_clean(function (target)
        print("rule(stub1): on_build")
    end)
    after_clean(function (target)
        print("rule(stub1): after_build")
    end)

    before_install(function (target)
        print("rule(stub1): before_install")
    end)
    on_install(function (target)
        print("rule(stub1): on_install")
    end)
    after_install(function (target)
        print("rule(stub1): after_install")
    end)

    before_uninstall(function (target)
        print("rule(stub1): before_uninstall")
    end)
    on_uninstall(function (target)
        print("rule(stub1): on_uninstall")
    end)
    after_uninstall(function (target)
        print("rule(stub1): after_uninstall")
    end)

    before_package(function (target)
        print("rule(stub1): before_package")
    end)
    on_package(function (target)
        print("rule(stub1): on_package")
    end)
    after_package(function (target)
        print("rule(stub1): after_package")
    end)

-- define target
target("test")

    -- set kind
    set_kind("binary")

    -- add rules
    add_rules("markdown", "stub1")

    -- add files
    add_files("src/*.c") 
    add_files("src/man/*.in",   {rule = "man"})
    add_files("src/index.md")
    add_files("src/test.c.in",  {rule = "c code"})
