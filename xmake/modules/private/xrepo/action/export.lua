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
-- @file        export.lua
--

-- imports
import("core.base.option")
import("core.base.task")

-- get menu options
function menu_options()

    -- description
    local description = "Export the given packages."

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
                                       "    - xrepo export -f \"vs_runtime='MD'\" zlib",
                                       "    - xrepo export -f \"regex=true,thread=true\" boost"},
        {},
        {nil, "includes",   "kv", nil, "Includes extra lua configuration files."},
        {nil, "toolchain",  "kv", nil, "Set the toolchain name."             },
        {nil, "shallow",    "k",  nil, "Does not export dependent packages."},
        {'o', "packagedir", "kv", "packages","Set the exported packages directory."},
        {nil, "packages",   "vs", nil, "The packages list.",
                                       "e.g.",
                                       "    - xrepo export zlib boost",
                                       "    - xrepo export -p iphoneos -a arm64 \"zlib >=1.2.0\"",
                                       "    - xrepo export -p android -m debug \"pcre2 10.x\"",
                                       "    - xrepo export -p mingw -k shared zlib",
                                       "    - xrepo export conan::zlib/1.2.11 vcpkg::zlib"}
    }

    -- show menu options
    local function show_options()

        -- show usage
        cprint("${bright}Usage: $${clear cyan}xrepo export [options] packages")

        -- show description
        print("")
        print(description)

        -- show options
        option.show_options(options, "export")
    end
    return options, show_options, description
end

-- export packages
function _export_packages(packages)

    -- is package configuration file? e.g. xrepo export xxx.lua
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
    local oldir = os.curdir()
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

    -- do export
    local require_argv = {"require", "--export"}
    if option.get("yes") then
        table.insert(require_argv, "-y")
    end
    if option.get("verbose") then
        table.insert(require_argv, "-v")
    end
    if option.get("diagnosis") then
        table.insert(require_argv, "-D")
    end
    if option.get("shallow") then
        table.insert(require_argv, "--shallow")
    end
    local packagedir = option.get("packagedir")
    if packagedir and not path.is_absolute(packagedir) then
        packagedir = path.absolute(packagedir, oldir)
    end
    if packagedir then
        table.insert(require_argv, "--packagedir=" .. packagedir)
    end
    local extra = {system = false}
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
        if extra then
            local extra_str = string.serialize(extra, {indent = false, strip = true})
            table.insert(require_argv, "--extra=" .. extra_str)
        end
        table.join2(require_argv, packages)
    end
    os.vexecv("xmake", require_argv, {envs = envs})
end

-- export packages in current project
function _export_current_packages(packages)

    -- do export
    local require_argv = {export = true}
    if option.get("yes") then
        require_argv.yes = true
    end
    if option.get("verbose") then
        require_argv.verbose = true
    end
    if option.get("diagnosis") then
        require_argv.diagnosis = true
    end
    local packagedir = option.get("packagedir")
    if packagedir and not path.is_absolute(packagedir) then
        packagedir = path.absolute(packagedir, oldir)
    end
    if packagedir then
        require_argv.packagedir = packagedir
    end
    local extra = {system = false}
    local mode  = option.get("mode")
    if mode == "debug" then
        extra.debug = true
    end
    local kind = option.get("kind")
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
    if extra then
        local extra_str = string.serialize(extra, {indent = false, strip = true})
        require_argv.extra = extra_str
    end
    task.run("require", require_argv)
end

-- main entry
function main()
    local packages = option.get("packages")
    if packages then
        _export_packages(packages)
    elseif os.isfile(os.projectfile()) then
        _export_current_packages()
    else
        raise("please specify the packages to be exported.")
    end
end
