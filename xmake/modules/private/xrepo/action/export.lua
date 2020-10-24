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
-- @file        export.lua
--

-- imports
import("core.base.option")

-- get menu options
function menu_options()

    -- description
    local description = "export the given packages."

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
                                       "    - xrepo export --configs=\"vs_runtime=MD\" zlib",
                                       "    - xrepo export --configs=\"regex=true,thread=true\" boost"},
        {},
        {'o', "outputdir",  "kv", "packages","Set the exported packages directory."},
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

    -- enter working project directory
    local oldir = os.curdir()
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
    local outputdir = option.get("outputdir")
    if outputdir and not path.is_absolute(outputdir) then
        outputdir = path.absolute(outputdir, oldir)
    end
    if outputdir then
        table.insert(require_argv, "--exportdir=" .. outputdir)
    end
    local extra = nil
    if mode == "debug" then
        extra = extra or {}
        extra.debug = true
    end
    if kind == "shared" then
        extra = extra or {}
        extra.configs = extra.configs or {}
        extra.configs.shared = true
    end
    local configs = option.get("configs")
    if configs then
        extra = extra or {}
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
        table.insert(require_argv, "--extra=" .. extra_str)
    end
    table.join2(require_argv, packages)
    os.vexecv("xmake", require_argv)
end

-- main entry
function main(menu)
    local packages = option.get("packages")
    if packages then
        _export_packages(packages)
    else
        raise("please specify the packages to be exported.")
    end
end
