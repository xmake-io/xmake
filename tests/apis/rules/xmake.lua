
-- define rule: markdown
rule("markdown")
    on_build(function (target, sourcefile)
        print("compiling %s", sourcefile)
        os.cp(sourcefile, path.join(target:objectdir(), path.basename(sourcefile) .. ".html"))
    end)

-- define rule: man
rule("man")
    add_imports("core.project.rule")
    on_build_all(function (target, sourcefiles)
        local vars = {name = "xmake"}
        for _, sourcefile in ipairs(sourcefiles) do
            print("generating %s", sourcefile)
            io.gsub(sourcefile, "%[(.+)%]", function (name) return vars[name] end)
        end
        rule.build_all("markdown", target, sourcefiles)
    end)

-- define rule: c code
rule("c code")
    add_imports("core.tool.compiler")
    on_build(function (target, sourcefile)
        print("compiling %s", sourcefile)
        local objectfile = os.tmpfile() .. ".o"
        compiler.compile(sourcefile, objectfile, {sourcekind = "cc"})
        table.insert(target:objectfiles(), objectfile)
    end)

-- define rule: stub
rule("stub")
    before_build(function (target, sourcefile)
        print("before_build: %s", sourcefile)
    end)
    on_build(function (target, sourcefile)
        print("on_build: %s", sourcefile)
    end)
    after_build(function (target, sourcefile)
        print("after_build: %s", sourcefile)
    end)

    before_clean(function (target, sourcefile)
        print("before_clean: %s", sourcefile)
    end)
    on_clean(function (target, sourcefile)
        print("on_clean: %s", sourcefile)
    end)
    after_clean(function (target, sourcefile)
        print("after_clean: %s", sourcefile)
    end)

    before_install(function (target, sourcefile)
        print("before_install: %s", sourcefile)
    end)
    on_install(function (target, sourcefile)
        print("on_install: %s", sourcefile)
    end)
    after_install(function (target, sourcefile)
        print("after_install: %s", sourcefile)
    end)

    before_package(function (target, sourcefile)
        print("before_package: %s", sourcefile)
    end)
    on_package(function (target, sourcefile)
        print("on_package: %s", sourcefile)
    end)
    after_package(function (target, sourcefile)
        print("after_package: %s", sourcefile)
    end)

-- define target
target("test")

    -- set kind
    set_kind("binary")

    -- add files
    add_files("src/*.c") 
    add_files("src/man/*.in",   {rule = "man"})
    add_files("src/index.md",   {rule = "markdown"})
    add_files("src/test.c.in",  {rule = "c code"})
    add_files("src/empty.stub", {rule = "stub"})
