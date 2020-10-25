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
-- Copyright (C) 2015-2020, TBOOX Open Source Group.
--
-- @author      ruki
-- @file        env.lua
--

-- imports
import("core.base.option")

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
        {nil, "configs",    "kv", nil, "Set the given extra package configs.",
                                       "e.g.",
                                       "    - xrepo env --configs=\"vs_runtime=MD\" --packages=zlib",
                                       "    - xrepo env --configs=\"regex=true,thread=true\" --packages=boost"},
        {},
        {nil, "packages",   "kv", nil, "Set the packages list.",
                                       "e.g.",
                                       "    - xrepo env --packages=\"zlib,luajit 2.1x\""},
        {nil, "program",    "v", nil,  "Set the program name to be run",
                                       "e.g.",
                                       "    - xrepo env",
                                       "    - xrepo env --packages=\"python 3.x\" python",
                                       "    - xrepo env -p android --packages=\"zlib,luajit 2.1x\" cmake .."},
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

-- enter project
function _enter_project()

    -- enter working project directory
    local workdir = path.join(os.tmpdir(), "xrepo", "working")
    if not os.isdir(workdir) then
        os.mkdir(workdir)
        os.cd(workdir)
        os.vrunv("xmake", {"create", "-P", "."})
    else
        os.cd(workdir)
    end

    -- do configure first
    local config_argv = {"f", "-c"}
    if option.get("verbose") then
        table.insert(config_argv, "-v")
    end
    if option.get("diagnosis") then
        table.insert(config_argv, "-D")
    end
    if option.get("plat") then
        table.insert(config_argv, "-p")
        table.insert(config_argv, option.get("plat"))
    end
    if option.get("arch") then
        table.insert(config_argv, "-a")
        table.insert(config_argv, option.get("arch"))
    end
    local mode  = option.get("mode")
    if mode then
        table.insert(config_argv, "-m")
        table.insert(config_argv, mode)
    end
    local kind  = option.get("kind")
    if kind then
        table.insert(config_argv, "-k")
        table.insert(config_argv, kind)
    end
    os.vrunv("xmake", config_argv)
end

-- get package environments
function _package_envs()
    local envs = os.getenvs()
    local packages = option.get("packages")
    if packages then
        _enter_project()
        -- TODO
    end
    return envs
end

-- main entry
function main()
    local envs = _package_envs()
    local program = option.get("program")
    if program then
        os.execv(program, option.get("arguments"), {envs = envs})
    else
        print(envs)
    end
end
