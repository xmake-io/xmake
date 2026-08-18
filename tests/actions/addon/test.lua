import("core.base.global")
import("lib.detect.find_program")

-- the addon fixtures, each of them provides one kind of payload only
--
-- @note they are independent from each other, @see tests/actions/addon/custom-*

function _addondir(name)
    return path.join(os.scriptdir(), name)
end

function _remove(name)
    try { function () os.runv("xmake", {"addon", "--remove", "--force", name}) end }
end

-- install the given addon fixture from its local directory
function _install(name)
    _remove(name)
    os.runv("xmake", {"addon", "--install", _addondir(name)})
end

-- run the given function with the addons installed, we always remove them again
function _with_addons(names, func)
    for _, name in ipairs(names) do
        _install(name)
    end
    try
    {
        func,
        finally
        {
            -- @note try() swallows the errors if we do not re-raise them here
            function (ok, errors)
                for _, name in ipairs(names) do
                    _remove(name)
                end
                if not ok then
                    raise(errors)
                end
            end
        }
    }
end

-- create a temporary repository which indexes the given addon fixtures, and register it
--
-- @note the recipes only point at the fixtures with `set_sourcedir`, we need not generate any payload
function _with_repo(recipes, func)

    -- @note installing from a repository goes through the package manager, and it always
    -- needs git, which cannot be installed on the hosts without a package manager,
    -- e.g. dragonflybsd
    if not find_program("git") then
        print("git not found, we skip the repository tests!")
        return
    end

    local suffix = path.filename(os.tmpfile()):gsub("[^%w]", "")
    local reponame = "addon-test-repo-" .. suffix
    local repodir = os.tmpfile() .. ".addon-repo"
    for name, body in pairs(recipes) do
        io.writefile(path.join(repodir, "addons", name:sub(1, 1), name, "xmake.lua"),
            ("package(%q)\n    set_kind(\"addon\")\n    set_description(\"the addon fixture of the tests\")\n    %s\n"):format(name, body))
    end

    -- register the repository and clear the quick search cache, it will be rebuilt on the next search
    local cachefile = path.join(global.cachedir(), "repository")
    local cache = os.isfile(cachefile) and io.load(cachefile) or {}
    cache.repositories = cache.repositories or {}

    -- a killed test run may leave its temporary repository registered, and a dangling
    -- repository breaks every following xrepo command, so we drop them here
    for name, dirs in pairs(cache.repositories) do
        if name:startswith("addon-test-repo-") and not os.isdir(dirs[1]) then
            cache.repositories[name] = nil
        end
    end
    cache.repositories[reponame] = {repodir}
    io.save(cachefile, cache)
    os.tryrm(path.join(global.cachedir(), "quick_search"))

    try
    {
        function ()
            func(reponame)
        end,
        finally
        {
            -- @note try() swallows the errors if we do not re-raise them here
            function (ok, errors)
                for name, _ in pairs(recipes) do
                    _remove(name)
                end
                local cache = os.isfile(cachefile) and io.load(cachefile) or {}
                if cache.repositories then
                    cache.repositories[reponame] = nil
                end
                io.save(cachefile, cache)
                os.tryrm(path.join(global.cachedir(), "quick_search"))
                os.tryrm(repodir)
                if not ok then
                    raise(errors)
                end
            end
        }
    }
end

-- run the given command in a temporary project and return its output
function _run_project(content, argv, opt)
    opt = opt or {}
    local projectdir = os.tmpfile() .. ".addon-project"
    os.tryrm(projectdir)
    io.writefile(path.join(projectdir, "xmake.lua"), content)
    for file, filecontent in pairs(opt.files or {}) do
        io.writefile(path.join(projectdir, file), filecontent)
    end
    local oldir = os.cd(projectdir)
    local out, errors
    try
    {
        function () out = os.iorunv("xmake", argv) end,
        catch { function (e) errors = e end },
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

function _config_project(content)
    return _run_project(content, {"config", "-y"})
end

-- copy the given fixture project to a temporary directory and run the given function in it
--
-- @note we cannot run them in place, they would generate the lock and the build files,
-- @see tests/actions/addon/projects
--
function _with_project(name, func)
    local projectdir = os.tmpfile() .. ".addon-project"
    os.tryrm(projectdir)
    os.mkdir(projectdir)
    os.cp(path.join(os.scriptdir(), "projects", name, "*"), projectdir)
    local oldir = os.cd(projectdir)
    try
    {
        function ()
            func(projectdir)
        end,
        finally
        {
            -- @note try() swallows the errors if we do not re-raise them here
            function (ok, errors)
                os.cd(oldir)
                os.tryrm(projectdir)
                if not ok then
                    raise(errors)
                end
            end
        }
    }
end

-- only the payloads should be installed, our own files should not
function test_install(t)
    _with_addons({"custom-toolchain"}, function ()

        -- it has the `src` layout, e.g. set_sourcedir("src")
        local installdir = path.join(global.directory(), "addons", "custom-toolchain", "latest")
        t:require(os.isdir(path.join(installdir, "toolchains")))
        t:require(os.isdir(path.join(installdir, "modules")))
        for _, ourfile in ipairs({"src", "addon.lua"}) do
            t:require_not(os.exists(path.join(installdir, ourfile)))
        end

        -- the addon describes itself, we should get its description from the manifest
        t:require(os.iorunv("xmake", {"addon", "--list"}):find("the addon which provides a custom toolchain", 1, true))
    end)
end

-- an addon can provide a plugin, e.g. xmake hello_addon
function test_plugin(t)
    _with_addons({"custom-plugin"}, function ()
        t:require(os.iorunv("xmake", {"hello_addon", "-n", "xmake"}):find("hello from custom-plugin: xmake", 1, true))
    end)

    -- it should not be runnable after removing it
    t:require_not(try { function () os.runv("xmake", {"hello_addon"}); return true end })
end

-- an addon can provide a rule, e.g. add_rules("@addon/custom-rule/hello")
function test_rule(t)
    local projectfile = [[
target("test")
    set_kind("phony")
    add_rules("@addon/custom-rule/hello")
]]
    _with_addons({"custom-rule"}, function ()
        -- the rule imports a module of its own addon with `@self`
        t:require(_config_project(projectfile):find("custom-rule: hello from custom-rule: test", 1, true))
    end)

    -- it should fail if the addon which provides it is not installed
    t:require_not(try { function () _config_project(projectfile); return true end })
end

-- an addon can provide a module, e.g. import("@addon.custom-module.greeting")
function test_module(t)
    _with_addons({"custom-module"}, function ()
        local script = "import(\"@addon.custom-module.greeting\"); print(greeting(\"xmake\"))"
        t:require(os.iorunv("xmake", {"lua", "-c", script}):find("hello from custom-module: xmake", 1, true))

        -- the addon modules are namespaced, they cannot be imported with their plain names
        t:require_not(try { function () os.runv("xmake", {"lua", "-c", "import(\"greeting\")"}); return true end })
    end)
end

-- an addon can provide an includes file, e.g. includes("@addon/custom-include/check")
function test_include(t)
    _with_addons({"custom-include"}, function ()
        local out = _config_project([[
includes("@addon/custom-include/check")
target("test")
    set_kind("phony")
]])
        t:require(out:find("custom-include: includes check is loaded", 1, true))
    end)
end

-- an addon can provide a project template, e.g. xmake create -t customaddon.hello
function test_template(t)
    _with_addons({"custom-template"}, function ()
        t:require(os.iorunv("xmake", {"create", "--list", "-l", "c"}):find("customaddon.hello", 1, true))

        local projectdir = os.tmpfile() .. ".addon-project"
        os.tryrm(projectdir)
        os.runv("xmake", {"create", "-l", "c", "-t", "customaddon.hello", "-P", projectdir})
        t:require(os.isfile(path.join(projectdir, "src", "main.c")))
        os.tryrm(projectdir)
    end)
end

-- an addon can ship the package definitions in its includes file, so that a project
-- only needs `add_requires`, @see tests/actions/addon/custom-package
function test_include_packages(t)

    -- @note we need a compiler here, the project links against the package
    if not (find_program("gcc") or find_program("clang") or find_program("cc")) then
        return
    end
    _with_addons({"custom-package"}, function ()
        _with_project("custom-package", function ()
            t:require(os.iorunv("xmake", {"build", "-y"}):find("build ok", 1, true))
            t:require(os.iorunv("xmake", {"run"}):find("hello from the custom package", 1, true))
        end)
    end)
end

-- an addon can provide a toolchain and its tool modules
--
-- @see tests/apis/custom_toolchain for the same toolchain maintained inside a project
function test_toolchain(t)
    _with_addons({"custom-toolchain"}, function ()

        -- the toolchain can be loaded with the addon name
        local script = "import(\"core.tool.toolchain\"); print(toolchain.load(\"@addon/custom-toolchain/my-c6000\"):get(\"description\"))"
        t:require(os.iorunv("xmake", {"lua", "-c", script}):find("the custom toolchain of the tests", 1, true))

        -- its tool modules are exported by the manifest, so the internal calls can import them
        -- with their plain names, e.g. add_globalmodules("core.tools.mycl6x")
        --
        -- @note there is no builtin `mycl6x`, so they can only come from this addon
        local script2 = "import(\"core.tools.mycl6x\"); assert(mycl6x.compargv, \"invalid tool module!\"); " ..
                        "import(\"lib.detect.find_tool\"); assert(find_tool(\"mycl6x\"), \"mycl6x not found!\")"
        os.runv("xmake", {"lua", "-c", script2})

        -- and a project can build with it, the flags of the toolchain and of its tool module
        -- are both checked by the source file
        --
        -- @note its compiler is just the host one, so we can only build with it if there is one
        if find_program("gcc") or find_program("clang") or find_program("cc") then
            _run_project([[
target("test")
    set_kind("binary")
    set_toolchains("@addon/custom-toolchain/my-c6000")
    add_files("src/main.c")
]], {"build", "-y"}, {files = {["src/main.c"] = [[
#ifndef MY_C6000
#   error the flags of the addon toolchain are not used!
#endif
#ifndef MY_C6000_TOOL
#   error the flags of its tool module are not used!
#endif
int main(int argc, char** argv) { return 0; }
]]}})
        end
    end)
end

-- the addons which a project declares with `add_addons` are installed automatically
--
-- @note they must be installed before loading the project, it may use their includes files
function test_autofetch(t)
    local recipes = {["custom-include"] = ("set_sourcedir(%q)"):format(_addondir("custom-include"))}
    _with_repo(recipes, function ()
        _remove("custom-include")
        _with_project("autofetch", function (projectdir)

            -- it should be installed when loading the project, so that its includes file can be found,
            -- and we should tell the user why we install something, it may need to confirm and download
            local output = os.iorunv("xmake", {"config", "-y"})
            t:require(output:find("custom-include: includes check is loaded", 1, true))
            t:require(output:find("this project needs the addons", 1, true))

            -- and it should be locked
            local lockfile = path.join(projectdir, "xmake-addons.lock")
            t:require(os.isfile(lockfile))
            t:require(io.load(lockfile)["custom-include"] ~= nil)

            -- we should not install it again
            t:require_not(os.iorunv("xmake", {"config", "-y"}):find("install custom-include", 1, true))
        end)
    end)
end

-- every command builds the option menu, which merges the project tasks in a best-effort way,
-- so the commands which need not the project should never install its addons
function test_autofetch_skipped_for_option_menu(t)
    local recipes = {["custom-include"] = ("set_sourcedir(%q)"):format(_addondir("custom-include"))}
    _with_repo(recipes, function ()
        _remove("custom-include")
        _with_project("autofetch", function (projectdir)
            os.runv("xmake", {"addon", "--list"})
            os.runv("xmake", {"lua", "-c", "print(\"hello\")"})
            t:require_not(os.isfile(path.join(projectdir, "xmake-addons.lock")))
        end)
    end)
end

-- a complete project which declares its addons with `add_addons` and builds with them,
-- @see tests/actions/addon/projects/autofetch-build
function test_autofetch_build(t)

    -- @note the compiler of the custom toolchain is just the host one,
    -- so we can only build it if there is one
    if not (find_program("gcc") or find_program("clang") or find_program("cc")) then
        return
    end

    local names = {"custom-include", "custom-rule", "custom-toolchain"}
    local recipes = {}
    for _, name in ipairs(names) do
        recipes[name] = ("set_sourcedir(%q)"):format(_addondir(name))
    end
    _with_repo(recipes, function ()
        for _, name in ipairs(names) do
            _remove(name)
        end
        _with_project("autofetch-build", function (projectdir)

            -- all of them should be installed when loading the project, and it should build
            -- with their includes file, rule and toolchain, @see src/main.c
            local output = os.iorunv("xmake", {"build", "-y"})
            t:require(output:find("custom-include: includes check is loaded", 1, true))
            t:require(output:find("custom-rule: hello from custom-rule: hello", 1, true))
            t:require(output:find("build ok", 1, true))

            -- and all of them should be locked
            local lockinfo = io.load(path.join(projectdir, "xmake-addons.lock"))
            for _, name in ipairs(names) do
                t:require(lockinfo[name] ~= nil)
            end
        end)
    end)
end

-- a locked version which is not installed must not hide the addon
--
-- @note the auto-fetch installs the locked version, but the commands which do not load
-- the project content only pin it, e.g. `xmake lua`, @see project._pin_addons()
--
function test_autofetch_lock_missing_version(t)
    _with_addons({"custom-include"}, function ()
        _with_project("autofetch-lockmiss", function ()
            local script = "import(\"core.package.addon\"); print(addon.addons()[\"custom-include\"] ~= nil)"
            t:require(os.iorunv("xmake", {"lua", "-c", script}):find("true", 1, true))
        end)
    end)
end

-- the declared addons are checked, e.g. the reserved names
function test_autofetch_invalid(t)
    _with_project("autofetch-badname", function ()
        t:require_not(try { function () os.runv("xmake", {"config", "-y"}); return true end })
    end)
end

-- the addons can be installed from a repository, by plain name and by repo@name
function test_install_from_repo(t)
    local recipes = {["custom-plugin"] = ("set_sourcedir(%q)"):format(_addondir("custom-plugin")),
                     ["custom-module"] = ("set_sourcedir(%q)"):format(_addondir("custom-module"))}
    _with_repo(recipes, function (reponame)
        os.runv("xmake", {"addon", "--install", "-y", "custom-plugin"})
        t:require(os.iorunv("xmake", {"hello_addon"}):find("hello from custom-plugin", 1, true))

        os.runv("xmake", {"addon", "--remove", "custom-plugin"})
        os.runv("xmake", {"addon", "--install", "-y", reponame .. "@custom-plugin"})
        t:require(os.iorunv("xmake", {"hello_addon"}):find("hello from custom-plugin", 1, true))

        -- it should be searchable, and the addons should not be found by the package search
        --
        -- @note we cannot run the `xrepo` program here, it may not be in the PATH, e.g. on the ci,
        -- and `xrepo search` is just a wrapper of it
        --
        t:require(os.iorunv("xmake", {"addon", "--search", "custom-plugin"}):find("custom-plugin", 1, true))
        t:require_not(os.iorunv("xmake", {"lua", "private.xrepo", "search", "custom-plugin"}):find("custom-plugin", 1, true))

        -- and several of them can be installed in one shot, they are resolved and installed together
        os.runv("xmake", {"addon", "--remove", "--force", "custom-plugin"})
        os.runv("xmake", {"addon", "--install", "-y", "custom-plugin", reponame .. "@custom-module"})
        t:require(os.iorunv("xmake", {"hello_addon"}):find("hello from custom-plugin", 1, true))
        t:require(os.iorunv("xmake", {"lua", "-c", "import(\"@addon.custom-module.greeting\"); print(greeting(\"xmake\"))"})
            :find("hello from custom-module: xmake", 1, true))
    end)
end

-- an addon can depend on the other addons, they are installed and activated together
function test_addon_deps(t)
    local recipes = {
        ["custom-module"] = ("set_sourcedir(%q)"):format(_addondir("custom-module")),
        ["custom-plugin"] = ("set_sourcedir(%q)\n    add_deps(\"custom-module\", {kind = \"addon\"})"):format(_addondir("custom-plugin"))
    }
    _with_repo(recipes, function ()
        os.runv("xmake", {"addon", "--install", "-y", "custom-plugin"})
        local out = os.iorunv("xmake", {"addon", "--list"})
        t:require(out:find("custom-plugin", 1, true))
        t:require(out:find("custom-module", 1, true))

        -- we cannot remove the dependency, it's depended on by the other addon
        t:require_not(try { function () os.runv("xmake", {"addon", "--remove", "custom-module"}); return true end })
    end)
end

-- the plugins and the templates are not namespaced, the conflicts should be rejected when installing
function test_install_conflicts(t)
    _with_addons({"custom-plugin"}, function ()

        -- this addon provides the same plugin name
        local clonedir = os.tmpfile() .. ".addon-clone"
        os.tryrm(clonedir)
        io.writefile(path.join(clonedir, "addon.lua"), "addon(\"custom-plugin-clone\")\n")
        io.writefile(path.join(clonedir, "plugins", "hello_addon", "xmake.lua"),
            "task(\"hello_addon\")\n    set_category(\"plugin\")\n    set_menu {}\n    on_run(function () end)\n")
        t:require_not(try { function () os.runv("xmake", {"addon", "--install", "-y", clonedir}); return true end })
        os.tryrm(clonedir)

        -- and the other commands should still work
        t:require(os.iorunv("xmake", {"hello_addon"}):find("hello from custom-plugin", 1, true))
    end)
end

-- an addon is able to take over a builtin plugin, so we can move a deprecated builtin
-- plugin to an addon, e.g. `xmake format`
function test_install_override(t)

    -- the builtin plugin is used if we do not install the addon
    t:require_not(os.iorunv("xmake", {"format", "--help"}):find("Say hello instead of formatting", 1, true))

    _with_addons({"custom-override"}, function ()
        local out = os.iorunv("xmake", {"format"})
        t:require(out:find("hello from custom-override", 1, true))

        -- and it should not be reported as a conflict
        t:require_not(out:find("conflicts", 1, true))
        t:require(os.iorunv("xmake", {"format", "--help"}):find("Say hello instead of formatting", 1, true))
    end)

    -- the builtin plugin is used again after removing the addon
    t:require_not(os.iorunv("xmake", {"format", "--help"}):find("Say hello instead of formatting", 1, true))
end

-- the invalid installs should fail, and the `addon` name is reserved for the addon references
function test_invalid(t)
    t:require_not(try { function () os.runv("xmake", {"addon", "--install", "-y", "addon-test-missing"}); return true end })
    t:require_not(try { function () os.runv("xmake", {"addon", "--install", "-y", "somerepo@.."}); return true end })

    -- the addon name in its manifest must match the package name which distributes it
    local recipes = {["custom-plugin-badname"] = ("set_sourcedir(%q)"):format(_addondir("custom-plugin"))}
    _with_repo(recipes, function ()
        t:require_not(try { function () os.runv("xmake", {"addon", "--install", "-y", "custom-plugin-badname"}); return true end })
    end)

    -- the `addon` name is reserved
    t:require_not(try { function () _config_project([[
add_requires("addon")
target("test")
    set_kind("phony")
]]); return true end })
end
