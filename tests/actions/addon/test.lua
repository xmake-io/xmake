import("core.base.global")

-- the payloads of the mocked addons
--
-- the plugins and templates are not namespaced, so they are named with the addon name to keep them unique,
-- the other payloads are always referenced with `@addon/<addon>/` or `@self/`, so they can use fixed names
local RULENAME     = "flash"
local RULEBASENAME = "base"
local TOOLCHAINAME = "xtensa"
local MODULENAME   = "sdkconfig"
local INCLUDESNAME = "check"

-- write a minimal plugin, it imports a module of its own addon with `@self`
--
-- e.g. <addondir>/plugins/<name>/xmake.lua
function _write_plugin(dir, name)
    io.writefile(path.join(dir, "xmake.lua"), string.format([[
task("%s")
    set_category("plugin")
    on_run("main")
    set_menu {usage = "xmake %s", description = "say hello from %s"}
]], name, name, name))
    io.writefile(path.join(dir, "main.lua"), string.format([[
function main()
    import("@self.%s")
    print("%s: " .. %s())
end
]], MODULENAME, name, MODULENAME))
end

-- write a minimal template, e.g. <addondir>/templates/<language>/<templateid>/xmake.lua
function _write_template(dir, lang, templateid)
    local templatedir = path.join(dir, "templates", lang, templateid)
    io.writefile(path.join(templatedir, "xmake.lua"), [[
target("${TARGET_NAME}")
    set_kind("binary")
    add_files("src/*.c")
]])
    io.writefile(path.join(templatedir, "src", "main.c"), [[
int main(int argc, char** argv) { return 0; }
]])
end

-- write two rules, the main one depends on the other one of the same addon with `@self`
--
-- e.g. <addondir>/rules/<name>/xmake.lua
function _write_rules(dir, name)
    io.writefile(path.join(dir, "rules", RULEBASENAME, "xmake.lua"), string.format([[
rule("%s")
    on_load(function (target)
        print("hello from rule %s")
    end)
]], RULEBASENAME, RULEBASENAME))
    io.writefile(path.join(dir, "rules", RULENAME, "xmake.lua"), string.format([[
rule("%s")
    add_deps("@self/%s")
    on_load(function (target)
        import("@self.%s")
        print("hello from rule %s of %s: " .. %s())
    end)
]], RULENAME, RULEBASENAME, MODULENAME, RULENAME, name, MODULENAME))
end

-- write a minimal toolchain, e.g. <addondir>/toolchains/<name>/xmake.lua
function _write_toolchain(dir, name)
    io.writefile(path.join(dir, "toolchains", TOOLCHAINAME, "xmake.lua"), string.format([[
toolchain("%s")
    set_kind("standalone")
    set_description("hello from toolchain %s of %s")
    on_load(function (toolchain)
        toolchain:set("toolset", "cc", "gcc")
    end)
]], TOOLCHAINAME, TOOLCHAINAME, name))
end

-- write a minimal module, e.g. <addondir>/modules/<name>.lua
function _write_module(dir, name)
    io.writefile(path.join(dir, "modules", MODULENAME .. ".lua"), string.format([[
function main()
    return "hello from module %s of %s"
end
]], MODULENAME, name))
end

-- write a minimal includes file, e.g. <addondir>/includes/<name>/xmake.lua
function _write_includes(dir, name)
    io.writefile(path.join(dir, "includes", INCLUDESNAME, "xmake.lua"), string.format([[
print("hello from includes %s of %s")
]], INCLUDESNAME, name))
end

-- write an addon payload directory, it provides all the supported payloads
function _write_addon(dir, name)
    _write_plugin(path.join(dir, "plugins", name), name)
    _write_template(dir, "c", name)
    _write_rules(dir, name)
    _write_toolchain(dir, name)
    _write_module(dir, name)
    _write_includes(dir, name)
end

-- write an addon package description, its payloads are placed in the `src` directory
--
-- addons in a repository are described as packages, e.g. <repodir>/addons/<first-letter>/<name>/xmake.lua
--
-- @param opt   the options, e.g. {deps = {"other-addon"}}
function _write_addon_package(dir, name, opt)
    opt = opt or {}
    local deps = ""
    for _, depname in ipairs(opt.deps) do
        deps = deps .. string.format("\n    add_deps(\"%s\", {kind = \"addon\"})", depname)
    end
    io.writefile(path.join(dir, "xmake.lua"), string.format([[
package("%s")
    set_kind("addon")
    set_description("say hello from %s")
    set_sourcedir(path.join(os.scriptdir(), "src"))%s
]], name, name, deps))
    _write_addon(path.join(dir, "src"), name)
end

-- create a temporary addon repository (packages layout: addons/<first-letter>/<name>) and register it
--
-- @param basenames the addon base names, e.g. {"hello", "world"}
-- @param opt       the options, e.g. {deps = {hello = {2}}}, the first addon depends on the second one
--
-- @return reponame, names, cleanup
function _mock_repo(basenames, opt)
    opt = opt or {}
    local suffix = path.filename(os.tmpfile()):gsub("[^%w]", "")
    local reponame = "addon-test-repo-" .. suffix
    local repodir = os.tmpfile() .. ".addon-repo"
    local names = {}
    for _, base in ipairs(basenames) do
        table.insert(names, base .. "-" .. suffix)
    end
    for idx, base in ipairs(basenames) do
        local name = names[idx]
        local deps = {}
        for _, depidx in ipairs(table.wrap((opt.deps or {})[base])) do
            table.insert(deps, names[depidx])
        end
        _write_addon_package(path.join(repodir, "addons", name:sub(1, 1), name), name, {deps = deps})
    end

    -- register the repository into the cache
    local cachefile = path.join(global.cachedir(), "repository")
    local cache = os.isfile(cachefile) and io.load(cachefile) or {}
    cache.repositories = cache.repositories or {}
    cache.repositories[reponame] = {repodir}
    io.save(cachefile, cache)

    -- we need to clear the quick search cache, it will be rebuilt on the next search
    os.tryrm(path.join(global.cachedir(), "quick_search"))

    local function cleanup()
        for _, name in ipairs(names) do
            try { function () os.runv("xmake", {"addon", "--remove", "--force", name}) end }
            os.tryrm(path.join(global.directory(), "addons", name))
        end
        local cache = os.isfile(cachefile) and io.load(cachefile) or {}
        if cache.repositories then
            cache.repositories[reponame] = nil
        end
        io.save(cachefile, cache)
        os.tryrm(path.join(global.cachedir(), "quick_search"))
        os.tryrm(repodir)
    end
    return reponame, names, cleanup
end

-- run the given function with a mocked repository, we always clean it up even if the test fails
function _with_repo(basenames, func, opt)
    local reponame, names, cleanup = _mock_repo(basenames, opt)
    try
    {
        function ()
            func(reponame, names)
        end,
        finally
        {
            cleanup
        }
    }
end

-- run `xmake config` in a temporary project and return its output
function _config_project(content)
    local projectdir = os.tmpfile() .. ".addon-project"
    os.tryrm(projectdir)
    io.writefile(path.join(projectdir, "xmake.lua"), content)
    local oldir = os.cd(projectdir)
    local out, errors
    try
    {
        function ()
            out = os.iorunv("xmake", {"config", "-y"})
        end,
        catch
        {
            function (e)
                errors = e
            end
        },
        finally
        {
            function ()
                os.cd(oldir)
                os.tryrm(projectdir)
            end
        }
    }
    if errors then
        raise(errors)
    end
    return out
end

-- install an addon from a repository, by plain name and by repo@name
function test_install_from_repo(t)
    _with_repo({"hello"}, function (reponame, names)
        local name = names[1]

        -- install by plain name (searched across all repositories)
        os.runv("xmake", {"addon", "--install", "-y", name})
        t:require(os.iorunv("xmake", {name}):find(name, 1, true))

        -- reinstall by repo@name
        os.runv("xmake", {"addon", "--remove", name})
        os.runv("xmake", {"addon", "--install", "-y", reponame .. "@" .. name})
        t:require(os.iorunv("xmake", {name}):find(name, 1, true))

        os.runv("xmake", {"addon", "--remove", name})
    end)
end

-- an addon can reference its own payloads with `@self`, it never needs to know its installed name
function test_self_reference(t)
    _with_repo({"hello"}, function (_, names)
        local name = names[1]
        os.runv("xmake", {"addon", "--install", "-y", name})

        -- the plugin imports its own module with `import("@self.<module>")`
        local out = os.iorunv("xmake", {name})
        t:require(out:find("hello from module " .. MODULENAME .. " of " .. name, 1, true))

        -- the rule depends on the other rule of the same addon with `add_deps("@self/<rule>")`
        out = _config_project(string.format([[
target("test")
    set_kind("phony")
    add_rules("@addon/%s/%s")
]], name, RULENAME))
        t:require(out:find("hello from rule " .. RULEBASENAME, 1, true))
        t:require(out:find("hello from rule " .. RULENAME .. " of " .. name, 1, true))

        os.runv("xmake", {"addon", "--remove", name})
    end)
end

-- the templates of an installed addon can be used by `xmake create`
function test_install_templates(t)
    _with_repo({"hello"}, function (_, names)
        local name = names[1]
        os.runv("xmake", {"addon", "--install", "-y", name})

        -- this template should be listed and grouped by its addon name
        local out = os.iorunv("xmake", {"create", "--list"})
        t:require(out:find(name, 1, true))

        -- we can create a new project from it
        local projectdir = os.tmpfile() .. ".addon-project"
        os.tryrm(projectdir)
        os.runv("xmake", {"create", "-l", "c", "-t", name, "-P", projectdir})
        t:require(os.isfile(path.join(projectdir, "xmake.lua")))
        t:require(os.isfile(path.join(projectdir, "src", "main.c")))
        os.tryrm(projectdir)

        os.runv("xmake", {"addon", "--remove", name})
    end)
end

-- the rules of an installed addon can be used with the `@addon/<addon>/` prefix
function test_install_rules(t)
    _with_repo({"hello"}, function (_, names)
        local name = names[1]
        os.runv("xmake", {"addon", "--install", "-y", name})

        -- it should be found in the global rules
        local script = string.format("import(\"core.project.rule\"); print(rule.rule(\"@addon/%s/%s\") ~= nil)", name, RULENAME)
        t:require(os.iorunv("xmake", {"lua", "-c", script}):find("true", 1, true))

        -- the addon name is always required
        local script2 = string.format("import(\"core.project.rule\"); print(rule.rule(\"@addon/%s\"))", RULENAME)
        t:require_not(try { function () os.iorunv("xmake", {"lua", "-c", script2}); return true end })

        os.runv("xmake", {"addon", "--remove", name})
    end)
end

-- the includes of an installed addon can be used with the `@addon/<addon>/` prefix
function test_install_includes(t)
    _with_repo({"hello"}, function (_, names)
        local name = names[1]
        os.runv("xmake", {"addon", "--install", "-y", name})

        local out = _config_project(string.format([[
includes("@addon/%s/%s")
target("test")
    set_kind("phony")
]], name, INCLUDESNAME))
        t:require(out:find("hello from includes " .. INCLUDESNAME .. " of " .. name, 1, true))

        os.runv("xmake", {"addon", "--remove", name})
    end)
end

-- the toolchains of an installed addon can be loaded with the `@addon/<addon>/` prefix
function test_install_toolchains(t)
    _with_repo({"hello"}, function (_, names)
        local name = names[1]
        os.runv("xmake", {"addon", "--install", "-y", name})

        local script = string.format("import(\"core.tool.toolchain\"); print(toolchain.load(\"@addon/%s/%s\"):get(\"description\"))", name, TOOLCHAINAME)
        t:require(os.iorunv("xmake", {"lua", "-c", script}):find("hello from toolchain " .. TOOLCHAINAME .. " of " .. name, 1, true))

        -- it can also be bound to a package, e.g. "@addon/<addon>/clang@llvm"
        local script2 = string.format("import(\"core.tool.toolchain\"); print(toolchain.load(\"@addon/%s/%s@llvm\"):config(\"packages\"))", name, TOOLCHAINAME)
        t:require(os.iorunv("xmake", {"lua", "-c", script2}):find("llvm", 1, true))

        -- it should not be found without the `@addon/<addon>/` prefix
        local script3 = string.format("import(\"core.tool.toolchain\"); print(toolchain.load(\"%s\"))", TOOLCHAINAME)
        t:require_not(try { function () os.iorunv("xmake", {"lua", "-c", script3}); return true end })

        os.runv("xmake", {"addon", "--remove", name})
    end)
end

-- the modules of an installed addon can be imported with the `@addon.<addon>.` prefix
function test_install_modules(t)
    _with_repo({"hello"}, function (_, names)
        local name = names[1]
        os.runv("xmake", {"addon", "--install", "-y", name})

        local script = string.format("import(\"@addon.%s.%s\"); print(%s())", name, MODULENAME, MODULENAME)
        t:require(os.iorunv("xmake", {"lua", "-c", script}):find("hello from module " .. MODULENAME .. " of " .. name, 1, true))

        -- the addon name is always required
        local script2 = string.format("import(\"@addon.%s\")", MODULENAME)
        t:require_not(try { function () os.iorunv("xmake", {"lua", "-c", script2}); return true end })

        os.runv("xmake", {"addon", "--remove", name})
    end)
end

-- an addon can depend on the other addons with `add_deps(name, {kind = "addon"})`
function test_addon_deps(t)
    _with_repo({"hello", "world"}, function (_, names)
        local name, depname = names[1], names[2]

        -- installing the first addon should install and activate its addon dependency
        os.runv("xmake", {"addon", "--install", "-y", name})
        t:require(os.iorunv("xmake", {"addon", "--list"}):find(depname, 1, true))

        -- the payloads of the dependency should be usable, e.g. its plugin
        t:require(os.iorunv("xmake", {depname}):find(depname, 1, true))

        -- we cannot remove the dependency, it's depended on by the other addon
        t:require_not(try { function () os.runv("xmake", {"addon", "--remove", depname}); return true end })

        os.runv("xmake", {"addon", "--remove", name})
        os.runv("xmake", {"addon", "--remove", depname})
    end, {deps = {hello = {2}}})
end

-- the plugins and templates are not namespaced, the conflicts should be rejected when installing
function test_install_conflicts(t)
    _with_repo({"hello"}, function (_, names)
        local name = names[1]
        os.runv("xmake", {"addon", "--install", "-y", name})

        -- install another addon which provides the same plugin name
        local othername = name .. "-other"
        local dir = path.join(os.tmpfile() .. ".addon-conflict", othername)
        _write_plugin(path.join(dir, "plugins", name), name)
        _write_module(dir, name)
        try
        {
            function ()
                -- it should be rejected
                t:require_not(try { function () os.runv("xmake", {"addon", "--install", dir}); return true end })

                -- and the other commands should still work
                t:require(os.iorunv("xmake", {"addon", "--list"}):find(name, 1, true))
                t:require(os.iorunv("xmake", {name}):find(name, 1, true))
            end,
            finally
            {
                function ()
                    try { function () os.runv("xmake", {"addon", "--remove", "--force", othername}) end }
                    os.tryrm(path.directory(dir))
                end
            }
        }

        os.runv("xmake", {"addon", "--remove", name})
    end)
end

-- a complete addon with the optional `src` layout, @see tests/actions/addon/demo-addon
--
-- it provides all the payload kinds and has its own files (README, tests) which must not be installed
function test_demo_addon(t)
    local name = "demo-addon"
    local addondir = path.join(os.scriptdir(), name)
    try
    {
        function ()
            os.runv("xmake", {"addon", "--install", addondir})

            -- only the payloads of the `src` directory should be installed
            local installdir = path.join(global.directory(), "addons", name, "latest")
            for _, payloaddir in ipairs({"plugins", "rules", "toolchains", "modules", "includes", "templates"}) do
                t:require(os.isdir(path.join(installdir, payloaddir)))
            end
            for _, ourfile in ipairs({"src", "tests", "README.md"}) do
                t:require_not(os.exists(path.join(installdir, ourfile)))
            end

            -- the plugin imports a module of its own addon with `@self`
            t:require(os.iorunv("xmake", {"demo_hello", "-n", "xmake"}):find("hello from demo-addon: xmake", 1, true))

            -- the module can be imported with the addon name
            local script = "import(\"@addon.demo-addon.greeting\"); print(greeting(\"module\"))"
            t:require(os.iorunv("xmake", {"lua", "-c", script}):find("hello from demo-addon: module", 1, true))

            -- the toolchain can be loaded with the addon name
            local script2 = "import(\"core.tool.toolchain\"); print(toolchain.load(\"@addon/demo-addon/demo\"):get(\"description\"))"
            t:require(os.iorunv("xmake", {"lua", "-c", script2}):find("the demo toolchain", 1, true))

            -- the template should be listed
            t:require(os.iorunv("xmake", {"create", "--list", "-l", "c"}):find("demoaddon.hello", 1, true))

            -- the includes and the rules should work in a real project
            local out = _config_project([[
includes("@addon/demo-addon/check")
target("test")
    set_kind("phony")
    add_rules("@addon/demo-addon/app")
]])
            t:require(out:find("demo-addon: includes check is loaded", 1, true))
            t:require(out:find("demo-addon: rule base is loaded", 1, true))
            t:require(out:find("demo-addon: rule app is loaded, hello from demo-addon: test", 1, true))
        end,
        finally
        {
            function ()
                try { function () os.runv("xmake", {"addon", "--remove", "--force", name}) end }
            end
        }
    }
end

-- install an addon from a local directory, then remove it
function test_install_from_local(t)
    local suffix = path.filename(os.tmpfile()):gsub("[^%w]", "")
    local name = "hello-local-" .. suffix
    local dir = path.join(os.tmpfile() .. ".addon-local", name)
    _write_addon(dir, name)
    try
    {
        function ()
            os.runv("xmake", {"addon", "--install", dir})
            t:require(os.iorunv("xmake", {name}):find(name, 1, true))

            -- the removed addon should no longer be runnable
            os.runv("xmake", {"addon", "--remove", name})
            t:require_not(try { function () os.runv("xmake", {name}); return true end })
        end,
        finally
        {
            function ()
                try { function () os.runv("xmake", {"addon", "--remove", name}) end }
                os.tryrm(path.directory(dir))
            end
        }
    }
end

-- --list shows the installed addons and their payloads
function test_list(t)
    _with_repo({"hello", "world"}, function (_, names)

        -- install the first addon, leave the second only available
        os.runv("xmake", {"addon", "--install", "-y", names[1]})
        local out = os.iorunv("xmake", {"addon", "--list"})
        t:require(out:find("the installed addons:", 1, true))
        t:require(out:find(names[1], 1, true))

        -- the payloads of the installed addon should be shown, e.g. (plugins, rules, templates)
        t:require(out:find("plugins", 1, true))
        t:require(out:find("templates", 1, true))

        -- the addon which is not installed should be shown in the available addons
        t:require(out:find("the available addons:", 1, true))
        t:require(out:find(names[2], 1, true))

        os.runv("xmake", {"addon", "--remove", names[1]})
    end)
end

-- --search finds the addons in the repositories, it reuses `xrepo search --addon`
function test_search(t)
    _with_repo({"hello"}, function (_, names)
        local name = names[1]
        local out = os.iorunv("xmake", {"addon", "--search", name})
        t:require(out:find(name, 1, true))

        -- the addons should not be found by the package search
        local packages_out = os.iorunv("xrepo", {"search", name})
        t:require_not(packages_out:find(name, 1, true))
    end)
end

-- the `addon` package name is reserved for the addon references
function test_reserved_name(t)
    t:require_not(try { function () _config_project([[
add_requires("addon")
target("test")
    set_kind("phony")
]]); return true end })
end

-- invalid installs should fail
function test_install_invalid(t)
    t:require_not(try { function () os.runv("xmake", {"addon", "--install", "-y", "addon-test-missing"}); return true end })
    t:require_not(try { function () os.runv("xmake", {"addon", "--install", "-y", "somerepo@.."}); return true end })
end
