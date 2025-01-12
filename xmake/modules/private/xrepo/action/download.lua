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
-- @file        download.lua
--

-- imports
import("core.base.option")

-- get menu options
function menu_options()

    -- description
    local description = "Only download the given package source archive files."

    -- menu options
    local options =
    {
        {'k', "kind",          "kv", nil, "Enable static/shared library.",
                                       values = {"static", "shared"}},
        {'p', "plat",          "kv", nil, "Set the given platform."                                                                                        },
        {'a', "arch",          "kv", nil, "Set the given architecture."                                                                                    },
        {'m', "mode",          "kv", nil, "Set the given mode.",
                                       values = {"release", "debug"}},
        {'f', "configs",       "kv", nil, "Set the given extra package configs.",
                                       "e.g.",
                                       "    - xrepo download -f \"runtimes='MD'\" zlib",
                                       "    - xrepo download -f \"regex=true,thread=true\" boost"                                                          },
        {'j', "jobs",          "kv", tostring(os.default_njob()),
                                          "Set the number of parallel download jobs."                                                                      },
        {nil, "toolchain",      "kv", nil, "Set the toolchain name."                                                                                       },
        {nil, "toolchain_host", "kv", nil, "Set the host toolchain name."                                                                                  },
        {nil, "includes",      "kv", nil, "Includes extra lua configuration files.",
                                       "e.g.",
                                       "    - xrepo download -p cross --toolchain=mytool --includes='toolchain1.lua" .. path.envsep() .. "toolchain2.lua'" },
        {category = "Other Configuration"                                                                                                                  },
        {nil, "force",         "k",  nil, "Force to redownload all packages."                                                                              },
        {'o', "outputdir",     "kv", "packages","Set the packages download output directory."                                                              },
        {                                                                                                                                                  },
        {nil, "packages",      "vs", nil, "The packages list.",
                                       "e.g.",
                                       "    - xrepo download zlib boost",
                                       "    - xrepo download /tmp/zlib.lua",
                                       "    - xrepo download -p iphoneos -a arm64 \"zlib >=1.2.0\"",
                                       "    - xrepo download -p android [--ndk=/xxx] -m debug \"pcre2 10.x\"",
                                       "    - xrepo download -p mingw [--mingw=/xxx] -k shared zlib",
                                       "    - xrepo download conan::zlib/1.2.11 vcpkg::zlib",
                                        values = function (complete, opt) return import("private.xrepo.quick_search.completion")(complete, opt) end        }
    }

    -- show menu options
    local function show_options()

        -- show usage
        cprint("${bright}Usage: $${clear cyan}xrepo download [options] packages")

        -- show description
        print("")
        print(description)

        -- show options
        option.show_options(options, "download")
    end
    return options, show_options, description
end

-- download packages
function _download_packages(packages)

    -- is package configuration file? e.g. xrepo download xxx.lua
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
        for _, includefile in ipairs(path.splitenv(includes)) do
            table.insert(rcfiles, path.absolute(includefile))
        end
    end

    -- enter working project directory
    local subdir = "working"
    if packagefile then
        subdir = subdir .. "-" .. hash.uuid(packagefile):split('-')[1]
    end
    local origindir = os.curdir()
    local workdir = path.join(os.tmpdir(), "xrepo", subdir)
    if not os.isdir(workdir) then
        os.mkdir(workdir)
        os.cd(workdir)
        os.vrunv(os.programfile(), {"create", "-P", "."})
    else
        os.cd(workdir)
    end
    if packagefile then
        assert(os.isfile("xmake.lua"), "xmake.lua not found!")
        io.writefile("xmake.lua", ('includes("%s")\ntarget("test", {kind = "phony"})'):format((packagefile:gsub("\\", "/"))))
    end

    -- disable xmake-stats
    os.setenv("XMAKE_STATS", "false")

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
    if option.get("toolchain_host") then
        table.insert(config_argv, "--toolchain_host=" .. option.get("toolchain_host"))
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
    os.vrunv(os.programfile(), config_argv, {envs = envs})

    -- do download
    local require_argv = {"require", "--download"}
    if option.get("yes") then
        table.insert(require_argv, "-y")
    end
    if option.get("verbose") then
        table.insert(require_argv, "-v")
    end
    if option.get("diagnosis") then
        table.insert(require_argv, "-D")
    end
    if option.get("jobs") then
        table.insert(require_argv, "-j")
        table.insert(require_argv, option.get("jobs"))
    end
    if option.get("force") then
        table.insert(require_argv, "--force")
    end
    local outputdir = option.get("outputdir")
    if outputdir then
        if not path.is_absolute(outputdir) then
            outputdir = path.absolute(outputdir, os.workingdir())
        end
        table.insert(require_argv, "--packagedir=" .. outputdir)
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
        extra.system  = false
        extra.configs = extra.configs or {}
        local extra_configs, errors = ("{" .. configs .. "}"):deserialize()
        if extra_configs then
            table.join2(extra.configs, extra_configs)
        else
            raise(errors)
        end
    end
    if not packagefile then
        -- avoid overriding extra configs in add_requires/xmake.lua
        if extra then
            local extra_str = string.serialize(extra, {indent = false, strip = true})
            table.insert(require_argv, "--extra=" .. extra_str)
        end
        table.join2(require_argv, packages)
    end
    os.vexecv(os.programfile(), require_argv, {envs = envs})
end

-- main entry
function main()
    local packages = option.get("packages")
    if packages then
        _download_packages(packages)
    else
        raise("please specify the packages to be downloaded.")
    end
end
