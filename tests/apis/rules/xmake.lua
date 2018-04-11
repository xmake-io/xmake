
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
        rule.build("markdown", target, sourcefiles)
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

-- define target
target("test")

    -- set kind
    set_kind("binary")

    -- add rules
    add_rules("markdown")

    -- add files
    add_files("src/*.c") 
    add_files("src/man/*.in",   {rule = "man"})
    add_files("src/index.md")
    add_files("src/test.c.in",  {rule = "c code"})
