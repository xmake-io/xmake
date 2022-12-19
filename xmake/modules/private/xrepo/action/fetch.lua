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
-- Copyright (C) 2015-present, TBOOX Open Source Group.
--
-- @author      ruki
-- @file        fetch.lua
--

-- imports
import("core.base.option")

-- get menu options
function menu_options()

    -- description
    local description = "Fetch library information of the given installed packages."

    -- menu options
    local options =
    {
        {'k', "kind",       "kv", nil, "Enable static/shared library.",
                                       values = {"static", "shared"}         },
        {'p', "plat",       "kv", nil, "Set the given platform."             },
        {'a', "arch",       "kv", nil, "Set the given architecture."         },
        {'m', "mode",       "kv", nil, "Set the given mode.",
                                       values = {"release", "debug"}         },
        {'f', "configs",    "kv", nil, "Set the given extra package configs.",
                                       "e.g.",
                                       "    - xrepo fetch --configs=\"vs_runtime='MD'\" zlib",
                                       "    - xrepo fetch --configs=\"regex=true,thread=true\" boost"},
        {nil, "system",     "k", "false", "Only fetch package on current system."},
        {},
        {nil, "toolchain",  "kv", nil, "Set the toolchain name."             },
        {nil, "includes",   "kv", nil, "Includes extra lua configuration files.",
                                       "e.g.",
                                       "    - xrepo fetch -p cross --toolchain=mytool --includes='toolchain1.lua" .. path.envsep() .. "toolchain2.lua'"},
        {nil, "deps",       "k",  nil, "Fetch packages with dependencies."   },
        {nil, "cflags",     "k",  nil, "Fetch cflags of the given packages." },
        {nil, "ldflags",    "k",  nil, "Fetch ldflags of the given packages."},
        {'e', "external",   "k",  nil, "Show cflags as external packages with -isystem."},
        {nil, "json",       "k",  nil, "Output package info as json format." },
        {},
        {nil, "packages",   "vs", nil, "The packages list.",
                                       "e.g.",
                                       "    - xrepo fetch zlib boost",
                                       "    - xrepo fetch /tmp/zlib.lua",
                                       "    - xrepo fetch -p iphoneos -a arm64 \"zlib >=1.2.0\"",
                                       "    - xrepo fetch -p android -m debug \"pcre2 10.x\"",
                                       "    - xrepo fetch -p mingw -k shared zlib",
                                       "    - xrepo fetch conan::zlib/1.2.11 vcpkg::zlib",
                                       "    - xrepo fetch brew::zlib",
                                       "    - xrepo fetch system::zlib (from pkgconfig, brew, /usr/lib ..)",
                                       "    - xrepo fetch pkgconfig::zlib"}
    }

    -- show menu options
    local function show_options()

        -- show usage
        cprint("${bright}Usage: $${clear cyan}xrepo fetch [options] packages")

        -- show description
        print("")
        print(description)

        -- show options
        option.show_options(options, "fetch")
    end
    return options, show_options, description
end

-- fetch packages
function _fetch_packages(packages)

    -- is package configuration file? e.g. xrepo install xxx.lua
    --
    -- xxx.lua
    --   add_requires("libpng", {system = false})
    --   add_requireconfs("libpng.*", {configs = {shared = true}})
    local packagefile
    if type(packages) == "string" or #packages == 1 then
        local filepath = table.unwrap(packages)
        if type(filepath) == "string" and filepath:endswith(".lua") and os.isfile(filepath) then
            packagefile = path.absolute(filepath)
        end
    end

    -- add includes to rcfiles
    local rcfiles = {}
    local includes = option.get("includes")
    if includes then
        table.join2(rcfiles, path.splitenv(includes))
    end

    -- enter working project directory
    local subdir = "working"
    if packagefile then
        subdir = subdir .. "-" .. hash.uuid(packagefile):split('-')[1]
    end
    local workdir = path.join(os.tmpdir(), "xrepo", subdir)
    if not os.isdir(workdir) then
        os.mkdir(workdir)
        os.cd(workdir)
        os.vrunv("xmake", {"create", "-P", "."})
    else
        os.cd(workdir)
    end
    if packagefile then
        assert(os.isfile("xmake.lua"), "xmake.lua not found!")
        io.writefile("xmake.lua", ('includes("%s")\ntarget("test", {kind = "phony"})'):format((packagefile:gsub("\\", "/"))))
    end

    -- do configure first
    local config_argv = {"f", "-c", "--require=n"}
    if option.get("diagnosis") then
        table.insert(config_argv, "-vD")
    end
    if option.get("plat") then
        table.insert(config_argv, "-p")
        table.insert(config_argv, option.get("plat"))
    end
    if option.get("arch") then
        table.insert(config_argv, "-a")
        table.insert(config_argv, option.get("arch"))
    end
    if option.get("toolchain") then
        table.insert(config_argv, "--toolchain=" .. option.get("toolchain"))
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
    local envs = {}
    if #rcfiles > 0 then
        envs.XMAKE_RCFILES = path.joinenv(rcfiles)
    end
    os.vrunv("xmake", config_argv, {envs = envs})

    -- do fetch
    local require_argv = {"require", "--fetch"}
    if option.get("yes") then
        table.insert(require_argv, "-y")
    end
    if option.get("verbose") then
        table.insert(require_argv, "-v")
    end
    if option.get("diagnosis") then
        table.insert(require_argv, "-D")
    end
    local fetchmodes = {}
    if option.get("deps") then
        table.insert(fetchmodes, "deps")
    end
    if option.get("cflags") then
        table.insert(fetchmodes, "cflags")
    end
    if option.get("ldflags") then
        table.insert(fetchmodes, "ldflags")
    end
    if option.get("external") then
        table.insert(fetchmodes, "external")
    end
    if option.get("json") then
        table.insert(fetchmodes, "json")
    end
    if #fetchmodes > 0 then
        table.insert(require_argv, "--fetch_modes=" .. table.concat(fetchmodes, ','))
    end
    local extra = {system = option.get("system")}
    if mode == "debug" then
        extra.debug = true
    end
    if kind then
        extra.configs = extra.configs or {}
        extra.configs.shared = kind == "shared"
    end
    local configs = option.get("configs")
    if configs then
        extra.configs = extra.configs or {}
        local extra_configs, errors = ("{" .. configs .. "}"):deserialize()
        if extra_configs then
            table.join2(extra.configs, extra_configs)
        else
            raise(errors)
        end
    end
    if not packagefile then
        -- avoid to override extra configs in add_requires/xmake.lua
        if extra then
            local extra_str = string.serialize(extra, {indent = false, strip = true})
            table.insert(require_argv, "--extra=" .. extra_str)
        end
        table.join2(require_argv, packages)
    end
    os.vexecv("xmake", require_argv, {envs = envs})
end

-- main entry
function main()
    local packages = option.get("packages")
    if packages then
        _fetch_packages(packages)
    else
        raise("please specify the package to be fetched.")
    end
end
