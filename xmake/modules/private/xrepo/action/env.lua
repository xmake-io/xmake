--!A cross-platform build utility based on Lua
--
-- Licensed under the Apache License, Version 2.0 (the "License");
-- you may not use this file except in compliance with the License.
-- You may obtain a copy of the License at
--
--     http://www.apache.org/licenses/LICENSE-2.0
--
-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.
--
-- Copyright (C) 2015-present, Xmake Open Source Community.
--
-- @author      ruki
-- @file        env.lua
--

-- imports
import("core.base.option")
import("core.base.task")
import("core.base.hashset")
import("core.base.global")
import("core.project.config")
import("core.project.project")
import("core.tool.toolchain")
import("lib.detect.find_tool")
import("private.action.run.runenvs")
import("private.action.require.impl.package")
import("private.action.require.impl.utils.get_requires")

-- get menu options
function menu_options()

    -- description
    local description = "Set environment and execute command, or print environment."

    -- menu options
    local options =
    {
        {'k', "kind",       "kv", nil, "Enable static/shared library.",
                                       values = {"static", "shared"}         },
        {'p', "plat",       "kv", nil, "Set the given platform."             },
        {'a', "arch",       "kv", nil, "Set the given architecture."         },
        {'m', "mode",       "kv", nil, "Set the given mode.",
                                       values = {"release", "debug"}         },
        {nil, "show",       "k",  nil, "Only show environment information."  },
        {'f', "configs",    "kv", nil, "Set the given extra package configs.",
                                       "e.g.",
                                       "    - xrepo env -f \"runtimes='MD'\" zlib cmake ..",
                                       "    - xrepo env -f \"regex=true,thread=true\" \"zlib,boost\" cmake .."},
        {nil, "add",        "k",  nil, "Add global environment config.",
                                       "e.g.",
                                       "    - xrepo env --add base.lua",
                                       "    - xrepo env --add myenv.lua"},
        {nil, "remove",     "k",  nil, "Remove global environment config.",
                                       "e.g.",
                                       "    - xrepo env --remove base",
                                       "    - xrepo env --remove myenv"},
        {"l", "list",       "k",  nil, "List all global environment configs.",
                                       "e.g.",
                                       "    - xrepo env --list"},
        {'b', "bind",       "kv", nil, "Bind the specified environment or package.",
                                       "e.g.",
                                       "    - xrepo env -b base shell",
                                       "    - xrepo env -b myenv shell",
                                       "    - xrepo env -b \"python 3.x\" shell",
                                       "    - xrepo env -b \"cmake,ninja,python 3.x\" shell",
                                       "    - xrepo env -b \"luajit 2.x\" luajit xx.lua"},
        {},
        {nil, "program",    "v",  nil, "Set the program name to be run.",
                                       "e.g.",
                                       "    - xrepo env",
                                       "    - xrepo env bash",
                                       "    - xrepo env shell (it will load bash/sh/cmd automatically)",
                                       "    - xrepo env python",
                                       "    - xrepo env luajit xx.lua"},
        {nil, "arguments",  "vs", nil, "Set the program arguments to be run"}
    }

    -- show menu options
    local function show_options()

        -- show usage
        cprint("${bright}Usage: $${clear cyan}xrepo env [options] [program] [arguments]")

        -- show description
        print("")
        print(description)

        -- show options
        option.show_options(options, "env")
    end
    return options, show_options, description
end

-- enter the working project
function _enter_project()
    local workdir = path.join(os.tmpdir(), "xrepo", "working")
    if not os.isdir(workdir) then
        os.mkdir(workdir)
        os.cd(workdir)
        os.vrunv(os.programfile(), {"create", "-P", "."})
    else
        os.cd(workdir)
        os.rm("*")
        os.vrunv(os.programfile(), {"create", "-P", "."})
    end
    project.chdir(workdir)
end

-- remove repeat environment values
function _deduplicate_pathenv(value)
    if value then
        local itemset = {}
        local results = {}
        for _, item in ipairs(path.splitenv(value)) do
            if not itemset[item] then
                table.insert(results, item)
                itemset[item] = true
            end
        end
        if #results > 0 then
            value = path.joinenv(results)
        end
    end
    return value
end

-- get environment directory
function _get_envsdir()
    return path.join(global.directory(), "envs")
end

-- get builtin environment directory
function _get_envsdir_builtin()
    return path.join(os.programdir(), "scripts", "xrepo", "envs")
end

-- get envfironment files
function _get_envfiles()
    local envfiles = {}
    for _, envsdir in ipairs({_get_envsdir(), _get_envsdir_builtin()}) do
        for _, envfile in ipairs(os.files(path.join(envsdir, "*.lua"))) do
            envfiles[path.basename(envfile)] = envfile
        end
    end
    return envfiles
end

-- get bound environment files or packages
function _get_boundenvs(opt)
    local packages = {}
    local files = {}
    local bind = (opt and opt.bind) or option.get("bind")
    if bind then
        local envfiles = _get_envfiles()
        for _, binditem in ipairs(bind:split(',', {plain = true})) do
            binditem = binditem:trim()
            if envfiles[binditem] then
                table.insert(files, envfiles[binditem])
            else
                table.insert(packages, binditem)
            end
        end
    else
        local program = option.get("program")
        if program then
            table.insert(packages, program)
        end
    end
    return packages, files
end

-- add values to environment variable
function _addenvs(envs, name, ...)
    local values = {...}
    if #values > 0 then
        local oldenv = envs[name]
        local appendenv = path.joinenv(values)
        if oldenv == "" or oldenv == nil then
            envs[name] = appendenv
        else
            envs[name] = appendenv .. path.envsep() .. oldenv
        end
    end
end

-- add package environments
function _package_addenvs(envs, instance)

    -- only for xmake::package
    if instance:is_system() then
        return
    end

    -- add run envs, e.g. PATH, LD_LIBRARY_PATH, DYLD_LIBRARY_PATH
    local installdir = instance:installdir({readonly = true})
    for name, values in pairs(instance:envs()) do
        _addenvs(envs, name, table.unpack(table.wrap(values)))
    end

    -- add library envs, e.g. ACLOCAL_PATH, PKG_CONFIG_PATH, CMAKE_PREFIX_PATH
    if instance:is_library() then
        local pkgconfig = path.join(installdir, "lib", "pkgconfig")
        if os.isdir(pkgconfig) then
            _addenvs(envs, "PKG_CONFIG_PATH", pkgconfig)
        end
        pkgconfig = path.join(installdir, "share", "pkgconfig")
        if os.isdir(pkgconfig) then
            _addenvs(envs, "PKG_CONFIG_PATH", pkgconfig)
        end
        local aclocal = path.join(installdir, "share", "aclocal")
        if os.isdir(aclocal) then
            _addenvs(envs, "ACLOCAL_PATH", aclocal)
        end
        _addenvs(envs, "CMAKE_PREFIX_PATH", installdir)
        if instance:is_plat("windows") then
            _addenvs(envs, "INCLUDE", path.join(installdir, "include"))
            _addenvs(envs, "LIBPATH", path.join(installdir, "lib"))
        else
            _addenvs(envs, "CPATH", path.join(installdir, "include"))
            _addenvs(envs, "LIBRARY_PATH", path.join(installdir, "lib"))
        end
    end
end

-- add toolchain environments
function _toolchain_addenvs(envs)
    for _, name in ipairs(project.get("target.toolchains")) do
        local toolchain_opt = project.extraconf("target.toolchains", name)
        local toolchain_inst = toolchain.load(name, toolchain_opt)
        if toolchain_inst then
            for k, v in pairs(toolchain_inst:runenvs()) do
                _addenvs(envs, k, table.unpack(path.splitenv(v)))
            end
        end
    end
end

-- add target environments
function _target_addenvs(envs)
    for _, target in ipairs(project.ordertargets()) do
        if target:is_binary() then
            _addenvs(envs, "PATH", target:targetdir())
        elseif target:is_shared() then
            if is_host("windows") then
                _addenvs(envs, "PATH", target:targetdir())
            elseif is_host("macosx") then
                _addenvs(envs, "DYLD_LIBRARY_PATH", target:targetdir())
            else
                _addenvs(envs, "LD_LIBRARY_PATH", target:targetdir())
            end
        end
        -- add run environments
        local addrunenvs = runenvs.make(target)
        for name, values in pairs(addrunenvs) do
            _addenvs(envs, name, table.unpack(table.wrap(values)))
        end
    end
end

-- get package environments
function _package_getenvs(opt)
    local envs = os.getenvs()
    local packages, envfiles = _get_boundenvs(opt)
    local has_envfiles = #envfiles > 0
    local has_packages = #packages > 0
    local in_project = os.isfile(os.projectfile()) and not option.get("bind")
    local oldir = os.curdir()
    if has_envfiles or has_packages then
        _enter_project()
        if has_envfiles then
            table.join2(project.rcfiles(), envfiles)
        else
            local envfile = os.tmpfile() .. ".lua"
            local file = io.open(envfile, "w")
            for _, requirename in ipairs(packages) do
                file:print("add_requires(\"%s\")", requirename)
            end
            file:close()
            table.insert(project.rcfiles(), envfile)
        end
    end
    if in_project or has_envfiles or has_packages then
        task.run("config", {}, {disable_dump = true})
        if in_project or has_envfiles then
            _toolchain_addenvs(envs)
        end
        local requires, requires_extra = get_requires()
        for _, instance in ipairs(package.load_packages(requires, {requires_extra = requires_extra})) do
            _package_addenvs(envs, instance)
        end
        if in_project then
            _target_addenvs(envs)
        end
    end
    local results = {}
    for k, v in pairs(envs) do
        results[k] = _deduplicate_pathenv(v)
    end
    os.cd(oldir)
    return results
end

-- get environment setting script
function _get_env_script(envs, shell, del)
    local prefix = ""
    local connector = "="
    local suffix = ""
    local default = ""
    if shell == "powershell" or shell == "pwsh" then
        prefix = "[Environment]::SetEnvironmentVariable('"
        connector = "','"
        suffix = "')"
        default = "$Null"
    elseif shell == "cmd" then
        prefix = "@set \""
        suffix = "\""
    elseif shell:endswith("sh") then
        if del then
            prefix = "unset '"
            connector = "'"
        else
            prefix = "export '"
            connector = "'='"
            suffix = "'"
        end
    end
    local exceptions = hashset.of("_", "PS1", "PROMPT", "!;", "!EXITCODE")
    local ret = ""
    if del then
        for name, _ in pairs(envs) do
            if not exceptions:has(name) then
                ret = ret .. prefix .. name .. connector .. default .. suffix .. "\n"
            end
        end
    else
        for name, value in pairs(envs) do
            if not exceptions:has(name) then
                ret = ret .. prefix .. name .. connector .. value .. suffix .. "\n"
            end
        end
    end
    return ret
end

-- get prompt
function _get_prompt(bnd)
    bnd = bnd or option.get("bind")
    local prompt
    local packages, envfiles = _get_boundenvs({bind = bnd})
    if #packages > 0 or #envfiles > 0 then
        if #packages == 0 and #envfiles == 1 then
            prompt = path.basename(envfiles[1])
        else
            prompt = bnd:sub(1, math.min(#bnd, 16))
            if bnd ~= prompt then
                prompt = prompt .. ".."
            end
        end
        prompt = "[" .. prompt .. "]"
    elseif not bnd then
        assert(os.isfile(os.projectfile()), "xmake.lua not found!")
        prompt = path.filename(os.projectdir())
        prompt = "[" .. prompt .. "]"
    end
    return prompt or ""
end

-- get information of current virtual environment
function info(key, bnd)
    if key == "prompt" then
        local prompt = _get_prompt(bnd)
        io.write(prompt)
    elseif key == "envfile" then
        print(os.tmpfile())
    elseif key == "config" then
        _package_getenvs({bind = bnd})
    elseif key:startswith("script.") then
        local shell = key:match("script%.(.+)")
        io.write(_get_env_script(_package_getenvs({bind = bnd}), shell, false))
    elseif key:startswith("backup.") then
        local shell = key:match("backup%.(.+)")

        -- remove current environment variables first
        io.write(_get_env_script(_package_getenvs({bind = bnd}), shell, true))
        io.write(_get_env_script(os.getenvs(), shell, false))
    end
end

-- run shell
function _run_shell(envs)
    local shell = os.shell()
    local args = table.wrap(option.get("arguments"))
    if shell == "pwsh" or shell == "powershell" then
        os.execv("pwsh", args, {envs = envs})
    elseif shell == "nu" then
        if #args ~=0 then
            table.insert(args, 1, "-c")
        end
        os.execv("nu", args, {envs = envs})
    elseif shell:endswith("sh") then
        local prompt = _get_prompt()
        local ps1 = os.getenv("PS1")
        if ps1 then
            prompt = prompt .. ps1
        elseif is_host("macosx") then
            prompt = prompt .. " \\W > "
        else
            prompt = prompt .. " > "
        end
        os.execv(shell, args, {envs = table.join({PS1 = prompt}, envs)})
    elseif shell == "cmd" or is_host("windows") then
        local prompt = _get_prompt()
        prompt = prompt .. " $P$G"
        local args = table.join({"/k", "set PROMPT=" .. prompt}, args)
        os.execv("cmd", args, {envs = envs})
    else
        assert("shell not found!")
    end
end

function main()
    if option.get("list") then
        local envname = option.get("program")
        if envname then
            for _, envsdir in ipairs({_get_envsdir(), _get_envsdir_builtin()}) do
                local envfile = path.join(envsdir, envname .. ".lua")
                if os.isfile(envfile) then
                    print("%s:", envfile)
                    io.cat(envfile)
                end
            end
        else
            print("%s (builtin):", _get_envsdir_builtin())
            local count = 0
            for _, envfile in ipairs(os.files(path.join(_get_envsdir_builtin(), "*.lua"))) do
                local envname = path.basename(envfile)
                print("  - %s", envname)
                count = count + 1
            end
            print("%s:", _get_envsdir())
            for _, envfile in ipairs(os.files(path.join(_get_envsdir(), "*.lua"))) do
                local envname = path.basename(envfile)
                print("  - %s", envname)
                count = count + 1
            end
            print("envs(%d) found!", count)
        end
    elseif option.get("add") then
        local envfile = assert(option.get("program"), "please set environment config file!")
        if os.isfile(envfile) then
            os.vcp(envfile, path.join(_get_envsdir(), path.filename(envfile)))
        end
    elseif option.get("remove") then
        local envname = assert(option.get("program"), "please set environment config name!")
        os.rm(path.join(_get_envsdir(), envname .. ".lua"))
    else
        local program = option.get("program")
        if program and program == "shell" and not is_subhost("windows") then
            wprint("The shell was not integrated with xmake. Some features might be missing. Please switch to your default shell, and run `xmake update --integrate` to integrate the shell.")
        end
        local envs = _package_getenvs()
        if program and not option.get("show") then
            if envs and envs.PATH then
                os.setenv("PATH", envs.PATH)
            end
            if program == "shell" then
                _run_shell(envs)
            else
                os.execv(program, option.get("arguments"), {envs = envs})
            end
        else
            print(envs)
        end
    end
end
